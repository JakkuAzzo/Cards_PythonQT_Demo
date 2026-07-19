import Foundation
import Combine

@MainActor
final class NearbyTableSession: ObservableObject {
    enum Role: Equatable {
        case localPreview
        case host
        case guest

        var label: String {
            switch self {
            case .localPreview: return "Local preview"
            case .host: return "Hosting nearby"
            case .guest: return "Joined nearby"
            }
        }
    }

    @Published private(set) var state = MultiplayerGameState()
    @Published private(set) var role: Role = .localPreview
    @Published private(set) var sessionCode = ""
    @Published private(set) var connectedPeers: [String] = []
    @Published private(set) var statusMessage = "Use local preview or start a nearby table."

    let manifest: GameManifest
    let localPlayerID: String
    let localPlayerName: String
    private let engine: MultiplayerEngine
    private var transport: (any NearbyTransport)?

    init(manifest: GameManifest = .tableTalk, playerName: String = "You") {
        self.manifest = manifest
        self.localPlayerID = UUID().uuidString
        self.localPlayerName = playerName
        self.engine = MultiplayerEngine(manifest: manifest)
    }

    func beginLocalPreview() throws {
        disconnect()
        role = .localPreview
        try ensureLocalPlayer()
        statusMessage = "Local preview · no nearby device connected"
    }

    func host() throws {
        try host(using: makeAppleTransport())
    }

    func hostBluetooth() throws {
        try host(using: BluetoothLETransport(localPeerID: localPlayerID, displayName: localPlayerName))
    }

    private func host(using transport: any NearbyTransport) throws {
        disconnect()
        role = .host
        sessionCode = Self.makeSessionCode()
        try ensureLocalPlayer()
        configure(transport)
        self.transport = transport
        transport.host(sessionID: sessionCode)
        statusMessage = "Sharing table \(sessionCode) · waiting for nearby players"
    }

    func join(code: String) {
        join(code: code, using: makeAppleTransport())
    }

    func joinBluetooth(code: String) {
        join(code: code, using: BluetoothLETransport(localPeerID: localPlayerID, displayName: localPlayerName))
    }

    private func join(code: String, using transport: any NearbyTransport) {
        disconnect()
        role = .guest
        sessionCode = Self.normalizedCode(code)
        guard !sessionCode.isEmpty else {
            statusMessage = "Enter the host’s table code first."
            role = .localPreview
            return
        }
        configure(transport)
        self.transport = transport
        transport.join(sessionID: sessionCode)
        statusMessage = "Looking for table \(sessionCode)…"
    }

    func disconnect() {
        transport?.disconnect()
        transport = nil
        connectedPeers = []
        if role != .localPreview {
            statusMessage = "Nearby session ended."
        }
        role = .localPreview
        sessionCode = ""
        engine.reset()
        state = engine.state
    }

    func start() throws {
        guard role != .guest else {
            sendCommand("start")
            return
        }
        try applyHostCommand(.start(seed: UInt64.random(in: 1...UInt64.max)))
    }

    func addLocalPreviewGuest(id: String, name: String) throws {
        guard role == .localPreview else { return }
        _ = try engine.handle(.join(id: id, name: name))
        state = engine.state
    }

    func draw() throws {
        guard let player = state.activePlayer else { return }
        if role == .guest {
            sendCommand("draw", playerID: player.id)
        } else {
            try applyHostCommand(.draw(playerID: player.id))
        }
    }

    func endTurn() throws {
        guard let player = state.activePlayer else { return }
        if role == .guest {
            sendCommand("end-turn", playerID: player.id)
        } else {
            try applyHostCommand(.endTurn(playerID: player.id))
        }
    }

    private func makeAppleTransport() -> AppleNearbyTransport {
        AppleNearbyTransport(localPeerID: localPlayerID, displayName: localPlayerName)
    }

    private func configure(_ transport: any NearbyTransport) {
        transport.onPeersChanged = { [weak self] peers in
            guard let self else { return }
            self.connectedPeers = peers
            if self.role == .guest, !peers.isEmpty {
                self.sendHello()
            } else if self.role == .host {
                self.statusMessage = peers.isEmpty
                    ? "Sharing table \(self.sessionCode) · waiting for nearby players"
                    : "Nearby table ready · \(peers.count) player\(peers.count == 1 ? "" : "s") connected"
            }
        }
        transport.onEnvelope = { [weak self] envelope in self?.receive(envelope) }
    }

    private func ensureLocalPlayer() throws {
        guard state.players.isEmpty else { return }
        _ = try engine.handle(.join(id: localPlayerID, name: localPlayerName))
        state = engine.state
    }

    private func receive(_ envelope: NearbyEnvelope) {
        guard envelope.protocolVersion == 1,
              envelope.sessionID == sessionCode,
              envelope.senderID != localPlayerID,
              envelope.recipientID == nil || envelope.recipientID == localPlayerID else { return }
        switch envelope.type {
        case .hello where role == .host:
            let name = envelope.payload["name"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let name, !name.isEmpty else { return }
            if !state.players.contains(where: { $0.id == envelope.senderID }) {
                do {
                    _ = try engine.handle(.join(id: envelope.senderID, name: name))
                    state = engine.state
                } catch {
                    sendError(String(describing: error), recipientID: envelope.senderID)
                    return
                }
            }
            broadcastSnapshot()

        case .command where role == .host:
            do {
                switch envelope.payload["action"] {
                case "start": try applyHostCommand(.start(seed: UInt64.random(in: 1...UInt64.max)))
                case "draw":
                    guard let playerID = envelope.payload["playerID"] else { return }
                    try applyHostCommand(.draw(playerID: playerID))
                case "end-turn":
                    guard let playerID = envelope.payload["playerID"] else { return }
                    try applyHostCommand(.endTurn(playerID: playerID))
                default: break
                }
            } catch {
                sendError(String(describing: error), recipientID: envelope.senderID)
            }

        case .snapshot where role == .guest:
            guard let encoded = envelope.payload["state"],
                  let data = Data(base64Encoded: encoded),
                  let snapshot = try? JSONDecoder().decode(MultiplayerGameState.self, from: data) else { return }
            engine.applyHostSnapshot(snapshot)
            state = engine.state
            statusMessage = "Connected to \(state.players.first(where: { $0.isHost })?.name ?? "host") · revision \(state.revision)"

        case .error:
            statusMessage = envelope.payload["message"] ?? "The host could not accept that action."
        default:
            break
        }
    }

    private func applyHostCommand(_ command: MultiplayerCommand) throws {
        _ = try engine.handle(command)
        state = engine.state
        broadcastSnapshot()
    }

    private func sendHello() {
        send(type: .hello, payload: ["name": localPlayerName])
    }

    private func sendCommand(_ action: String, playerID: String? = nil) {
        var payload = ["action": action]
        if let playerID { payload["playerID"] = playerID }
        send(type: .command, payload: payload)
    }

    private func broadcastSnapshot() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        send(type: .snapshot, payload: ["state": data.base64EncodedString()])
    }

    private func sendError(_ message: String, recipientID: String) {
        send(type: .error, recipientID: recipientID, payload: ["message": message])
    }

    private func send(type: NearbyEnvelope.MessageType, recipientID: String? = nil, payload: [String: String]) {
        guard role != .localPreview, !sessionCode.isEmpty else { return }
        transport?.send(NearbyEnvelope(
            protocolVersion: 1,
            sessionID: sessionCode,
            messageID: UUID().uuidString,
            senderID: localPlayerID,
            revision: state.revision,
            type: type,
            recipientID: recipientID,
            payload: payload
        ))
    }

    private static func makeSessionCode() -> String {
        "CARDS-" + String(Int.random(in: 1000...9999))
    }

    private static func normalizedCode(_ value: String) -> String {
        value.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }
}
