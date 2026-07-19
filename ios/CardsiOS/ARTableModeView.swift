import ARKit
import RealityKit
import SwiftUI

struct ARTableModeView: View {
    @Environment(\.dismiss) private var dismiss
    let card: GameManifest.Deck.Card?
    let manifest: GameManifest
    @State private var markerStatus = "Find the printed Cards table marker to align this shared surface."

    var body: some View {
        NavigationStack {
            Group {
                if ARWorldTrackingConfiguration.isSupported {
                    ZStack(alignment: .bottom) {
                        ARTableContainer(card: card, manifest: manifest, markerStatus: $markerStatus)
                            .ignoresSafeArea()

                        VStack(spacing: 6) {
                            Text(card?.text ?? "Move the phone until a horizontal surface is found.")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                            Text(markerStatus)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(16)
                    }
                } else {
                    ContentUnavailableView(
                        "AR unavailable",
                        systemImage: "arkit",
                        description: Text("This device does not support AR world tracking. The conventional live table remains fully available.")
                    )
                }
            }
            .navigationTitle("AR Table")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ARTableContainer: UIViewRepresentable {
    let card: GameManifest.Deck.Card?
    let manifest: GameManifest
    @Binding var markerStatus: String

    func makeCoordinator() -> Coordinator { Coordinator(markerStatus: $markerStatus) }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        configuration.detectionImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: .main) ?? []
        view.session.delegate = context.coordinator
        view.session.run(configuration)

        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.25, 0.25)))
        let table = ModelEntity(
            mesh: .generatePlane(width: 0.62, depth: 0.42, cornerRadius: 0.03),
            materials: [SimpleMaterial(color: .init(red: 0.05, green: 0.25, blue: 0.16, alpha: 0.82), isMetallic: false)]
        )
        table.name = "digital-table"
        anchor.addChild(table)

        let cardEntity = makeCardEntity()
        cardEntity.position = [0, 0.004, 0]
        anchor.addChild(cardEntity)
        view.scene.addAnchor(anchor)
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        guard let entity = view.scene.findEntity(named: "current-card") as? ModelEntity else { return }
        entity.model?.materials = [cardMaterial()]
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        @Binding private var markerStatus: String

        init(markerStatus: Binding<String>) { _markerStatus = markerStatus }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard anchors.contains(where: { ($0 as? ARImageAnchor)?.referenceImage.name == "cards-table-marker-v1" }) else { return }
            Task { @MainActor in
                markerStatus = "Shared marker ready · every phone is anchored to the same physical table."
            }
        }

        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            guard anchors.contains(where: { ($0 as? ARImageAnchor)?.referenceImage.name == "cards-table-marker-v1" }) else { return }
            Task { @MainActor in markerStatus = "Marker lost · keep the printed marker in view to realign." }
        }
    }

    private func makeCardEntity() -> ModelEntity {
        let entity = ModelEntity(
            mesh: .generateBox(width: 0.12, height: 0.004, depth: 0.18, cornerRadius: 0.012),
            materials: [cardMaterial()]
        )
        entity.name = "current-card"
        return entity
    }

    private func cardMaterial() -> SimpleMaterial {
        let colour: UIColor
        if card == nil {
            colour = .white
        } else {
            colour = UIColor(Color(hex: manifest.presentation.accentStartHex))
        }
        return SimpleMaterial(color: colour, isMetallic: false)
    }
}
