import CryptoKit
import Foundation

/// Encrypts whole nearby envelopes before BLE framing. The displayed pairing secret
/// is high entropy; the short table code is deliberately not used as a key.
struct BLEEnvelopeCipher {
    private let key: SymmetricKey

    init(pairingSecret: String, sessionID: String) {
        let material = Data((pairingSecret + "|" + sessionID).utf8)
        key = SymmetricKey(data: SHA256.hash(data: material))
    }

    func seal(_ plaintext: Data) throws -> Data {
        try AES.GCM.seal(plaintext, using: key).combined ?? Data()
    }

    func open(_ combined: Data) throws -> Data {
        try AES.GCM.open(AES.GCM.SealedBox(combined: combined), using: key)
    }

    static func makePairingSecret() -> String {
        Data((0..<24).map { _ in UInt8.random(in: .min ... .max) }).base64EncodedString()
    }
}
