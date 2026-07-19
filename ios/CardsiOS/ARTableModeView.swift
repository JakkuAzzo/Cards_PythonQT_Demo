import ARKit
import RealityKit
import SwiftUI

struct ARTableModeView: View {
    @Environment(\.dismiss) private var dismiss
    let card: GameManifest.Deck.Card?
    let manifest: GameManifest
    @State private var markerStatus = "Tap a horizontal surface to place a table, or use the printed marker for shared alignment."
    @State private var placementRequest = 0

    var body: some View {
        NavigationStack {
            Group {
                if ARWorldTrackingConfiguration.isSupported {
                    ZStack(alignment: .bottom) {
                        ARTableContainer(card: card, manifest: manifest, markerStatus: $markerStatus, placementRequest: $placementRequest)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Place ahead", systemImage: "viewfinder") { placementRequest += 1 }
                }
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
    @Binding var placementRequest: Int

    func makeCoordinator() -> Coordinator { Coordinator(card: card, manifest: manifest, markerStatus: $markerStatus) }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        configuration.detectionImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: .main) ?? []
        view.session.delegate = context.coordinator
        view.session.run(configuration)
        context.coordinator.view = view
        view.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:))))
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        if context.coordinator.lastPlacementRequest != placementRequest {
            context.coordinator.lastPlacementRequest = placementRequest
            context.coordinator.placeTableInFront()
        }
        guard let entity = view.scene.findEntity(named: "current-card") as? ModelEntity else { return }
        entity.model?.materials = [cardMaterial()]
    }

    final class Coordinator: NSObject, ARSessionDelegate {
        weak var view: ARView?
        let card: GameManifest.Deck.Card?
        let manifest: GameManifest
        var lastPlacementRequest = 0
        private var placedAnchor: AnchorEntity?
        @Binding private var markerStatus: String

        init(card: GameManifest.Deck.Card?, manifest: GameManifest, markerStatus: Binding<String>) {
            self.card = card
            self.manifest = manifest
            _markerStatus = markerStatus
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view else { return }
            let point = recognizer.location(in: view)
            let result = view.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .horizontal).first
                ?? view.raycast(from: point, allowing: .estimatedPlane, alignment: .horizontal).first
            guard let result else {
                markerStatus = "Keep moving the phone until a horizontal surface is found, then tap to place the table."
                return
            }
            placeTable(at: result.worldTransform, status: "Table placed on this surface. Tap another surface to move it.")
        }

        func placeTableInFront() {
            guard let view else { return }
            let camera = view.cameraTransform.matrix
            let point = camera * SIMD4<Float>(0, -0.24, -0.72, 1)
            var transform = camera
            transform.columns.3 = SIMD4<Float>(point.x, point.y, point.z, 1)
            placeTable(at: transform, status: "Table placed in front of you. Tap a surface to lock it to a real table.")
        }

        private func placeTable(at transform: simd_float4x4, status: String) {
            guard let view else { return }
            if let placedAnchor { view.scene.removeAnchor(placedAnchor) }
            let anchor = AnchorEntity(world: transform)
            let table = ModelEntity(
                mesh: .generatePlane(width: 0.62, depth: 0.42, cornerRadius: 0.03),
                materials: [SimpleMaterial(color: .init(red: 0.05, green: 0.25, blue: 0.16, alpha: 0.86), isMetallic: false)]
            )
            table.name = "digital-table"
            anchor.addChild(table)
            let cardEntity = ModelEntity(
                mesh: .generateBox(width: 0.12, height: 0.004, depth: 0.18, cornerRadius: 0.012),
                materials: [cardMaterial()]
            )
            cardEntity.name = "current-card"
            cardEntity.position = [0, 0.004, 0]
            anchor.addChild(cardEntity)
            view.scene.addAnchor(anchor)
            placedAnchor = anchor
            markerStatus = status
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard anchors.contains(where: { ($0 as? ARImageAnchor)?.referenceImage.name == "cards-table-marker-v1" }) else { return }
            guard let marker = anchors.compactMap({ $0 as? ARImageAnchor }).first(where: { $0.referenceImage.name == "cards-table-marker-v1" }) else { return }
            Task { @MainActor in placeTable(at: marker.transform, status: "Shared marker ready · every phone is anchored to the same physical table.") }
        }

        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            guard anchors.contains(where: { ($0 as? ARImageAnchor)?.referenceImage.name == "cards-table-marker-v1" }) else { return }
            Task { @MainActor in markerStatus = "Marker lost · keep the printed marker in view to realign." }
        }

        private func cardMaterial() -> SimpleMaterial {
            SimpleMaterial(color: card == nil ? .white : UIColor(Color(hex: manifest.presentation.accentStartHex)), isMetallic: false)
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
