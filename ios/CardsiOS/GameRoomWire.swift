import Foundation

/// The stable BLE service contract used by both the iOS and Android clients.
enum CardsBLEContract {
    static let serviceUUID = "B9BB2D71-0B11-4E39-A5DF-0F17C4E81001"
    static let streamUUID = "B9BB2D71-0B11-4E39-A5DF-0F17C4E81002"
    static let maximumPacketPayload = 160
}

/// Length-prefixes a nearby envelope before Bluetooth splits it across writes.
struct BLEPacketFramer {
    private var pending = Data()

    static func packets(for envelope: Data, maximumPayload: Int = CardsBLEContract.maximumPacketPayload) -> [Data] {
        precondition(maximumPayload > 0)
        precondition(envelope.count <= Int(UInt16.max))
        var stream = Data([UInt8((envelope.count >> 8) & 0xff), UInt8(envelope.count & 0xff)])
        stream.append(envelope)
        return stride(from: 0, to: stream.count, by: maximumPayload).map {
            stream.subdata(in: $0..<min($0 + maximumPayload, stream.count))
        }
    }

    mutating func append(packet: Data) -> [Data] {
        pending.append(packet)
        var envelopes: [Data] = []
        while pending.count >= 2 {
            let length = Int(pending[pending.startIndex]) << 8 | Int(pending[pending.startIndex + 1])
            guard pending.count >= length + 2 else { break }
            envelopes.append(pending.subdata(in: 2..<(length + 2)))
            pending.removeSubrange(0..<(length + 2))
        }
        return envelopes
    }
}

struct SharedARAlignment: Codable, Equatable {
    static let markerID = "cards-table-marker-v1"
    static let markerWidthMetres = 0.16

    let markerID: String
    let markerWidthMetres: Double
    let revision: Int
    let position: [Float]
    let orientation: [Float]

    var isValid: Bool {
        markerID == Self.markerID && markerWidthMetres == Self.markerWidthMetres && revision >= 0 && position.count == 3 && orientation.count == 4
    }
}
