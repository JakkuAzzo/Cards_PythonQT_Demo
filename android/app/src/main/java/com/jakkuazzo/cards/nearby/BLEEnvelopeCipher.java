package com.jakkuazzo.cards.nearby;

import android.util.Base64;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

/** AES-GCM envelope encryption shared with the iOS BLE transport. */
public final class BLEEnvelopeCipher {
    private static final int NONCE_BYTES = 12;
    private final SecretKeySpec key;

    public BLEEnvelopeCipher(String pairingSecret, String sessionId) {
        try {
            byte[] material = (pairingSecret + "|" + sessionId).getBytes(StandardCharsets.UTF_8);
            key = new SecretKeySpec(MessageDigest.getInstance("SHA-256").digest(material), "AES");
        } catch (Exception error) { throw new IllegalStateException("Could not create Bluetooth cipher", error); }
    }

    public byte[] seal(byte[] plaintext) throws Exception {
        byte[] nonce = new byte[NONCE_BYTES];
        new SecureRandom().nextBytes(nonce);
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(128, nonce));
        byte[] encrypted = cipher.doFinal(plaintext);
        byte[] combined = new byte[nonce.length + encrypted.length];
        System.arraycopy(nonce, 0, combined, 0, nonce.length);
        System.arraycopy(encrypted, 0, combined, nonce.length, encrypted.length);
        return combined;
    }

    public byte[] open(byte[] combined) throws Exception {
        if (combined.length <= NONCE_BYTES) throw new IllegalArgumentException("Invalid encrypted Bluetooth envelope");
        byte[] nonce = java.util.Arrays.copyOfRange(combined, 0, NONCE_BYTES);
        byte[] encrypted = java.util.Arrays.copyOfRange(combined, NONCE_BYTES, combined.length);
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(128, nonce));
        return cipher.doFinal(encrypted);
    }

    public static String makePairingSecret() {
        byte[] value = new byte[24];
        new SecureRandom().nextBytes(value);
        return Base64.encodeToString(value, Base64.NO_WRAP);
    }
}
