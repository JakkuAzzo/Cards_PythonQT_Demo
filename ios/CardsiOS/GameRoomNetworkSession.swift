import Foundation
import Combine

enum GameRoomKind: String, Codable, Equatable {
    case poker
    case guessWho = "guess-who"
}

struct GameRoomCommand: Codable, Equatable {
    let action: String
    let playerID: String
    let characterID: String?
    let amount: Int?
}

/// Host-authoritative connection layer for Poker and Guess Who. Rules live in the
/// game engine; this object enforces delivery, revision ordering, and privacy.
@MainActor
final class GameRoomNetworkSession: ObservableObject {
    enum Role: Equatable { case host, guest }

    @Published private(set) var revision = 0
    @Published private(set) var peers: [String] = []
    @Published private(set) var status = "Not connected"

    let roomKind: GameRoomKind
    let localPlayerID: String
    let localPlayerName: String
    let sessionCode: String
    let role: Role
    var onHostCommand: ((GameRoomCommand) -> Bool)?
    var onPublicSnapshot: ((Data) -> Void)?
    var onPrivateState: ((Data) -> Void)?

    private let transport: any NearbyTransport

    init(
        roomKind: GameRoomKind,
        localPlayerID: String = UUID().uuidString,
        localPlayerName: String,
        sessionCode: String,
        role: Role,
        transport: any NearbyTransport
    ) {
        self.roomKind = roomKind
        self.localPlayerID = localPlayerID
        self.localPlayerName = localPlayerName
        self.sessionCode = sessionCode
        self.role = role
        self.transport = transport
        transport.onPeersChanged = { [weak self] peers in
            self?.peers = peers
            if self?.role == .guest, !peers.isEmpty { self?.sendHello() }
        }
        transport.onEnvelope = { [weak self] envelope in self?.receive(envelope) }
    }

    func connect() {
        if role == .host {
            transport.host(sessionID: sessionCode)
            status = "Hosting \(roomKind.rawValue) · share \(sessionCode)"
        } else {
            transport.join(sessionID: sessionCode)
            status = "Looking for \(roomKind.rawValue) \(sessionCode)…"
        }
    }

    func disconnect() { transport.disconnect(); status = "Disconnected" }

    func submit(_ command: GameRoomCommand) {
        guard command.playerID == localPlayerID else { return }
        if role == .host {
            if onHostCommand?(command) == true { revision += 1 }
        } else {
            send(type: .command, payload: encode(command))
            status = "Command sent to host"
        }
    }

    func publish(publicState: Data, privateStates: [String: Data] = [:]) {
        guard role == .host else { return }
        revision += 1
        send(type: .snapshot, payload: ["game": roomKind.rawValue, "state": publicState.base64EncodedString()])
        for (recipientID, state) in privateStates {
            send(type: .privateEvent, recipientID: recipientID, payload: ["game": roomKind.rawValue, "state": state.base64EncodedString()])
        }
    }

    private func receive(_ envelope: NearbyEnvelope) {
        guard envelope.protocolVersion == 1,
              envelope.sessionID == sessionCode,
              envelope.senderID != localPlayerID,
              envelope.recipientID == nil || envelope.recipientID == localPlayerID,
              envelope.payload["game"] == nil || envelope.payload["game"] == roomKind.rawValue else { return }
        switch envelope.type {
        case .hello where role == .host:
            status = "\(envelope.payload["name"] ?? "Guest") joined \(roomKind.rawValue)"
        case .command where role == .host:
            guard let command = decode(GameRoomCommand.self, from: envelope.payload), command.playerID == envelope.senderID else { return }
            if onHostCommand?(command) == true { revision += 1 }
        case .snapshot where role == .guest:
            guard envelope.revision >= revision, let state = decodeState(envelope.payload) else { return }
            revision = envelope.revision
            onPublicSnapshot?(state)
            status = "Synced at revision \(revision)"
        case .privateEvent where role == .guest:
            guard envelope.revision >= revision, let state = decodeState(envelope.payload) else { return }
            revision = envelope.revision
            onPrivateState?(state)
        case .error:
            status = envelope.payload["message"] ?? "Host rejected the action"
        default: break
        }
    }

    private func sendHello() { send(type: .hello, payload: ["game": roomKind.rawValue, "name": localPlayerName]) }
    private func send(type: NearbyEnvelope.MessageType, recipientID: String? = nil, payload: [String: String]) {
        transport.send(NearbyEnvelope(protocolVersion: 1, sessionID: sessionCode, messageID: UUID().uuidString, senderID: localPlayerID, revision: revision, type: type, recipientID: recipientID, payload: payload))
    }
    private func encode<T: Encodable>(_ value: T) -> [String: String] {
        guard let data = try? JSONEncoder().encode(value) else { return [:] }
        return ["game": roomKind.rawValue, "command": data.base64EncodedString()]
    }
    private func decode<T: Decodable>(_ type: T.Type, from payload: [String: String]) -> T? {
        guard let value = payload["command"], let data = Data(base64Encoded: value) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    private func decodeState(_ payload: [String: String]) -> Data? {
        guard let value = payload["state"] else { return nil }
        return Data(base64Encoded: value)
    }
}
