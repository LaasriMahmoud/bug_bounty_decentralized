/**
 * Basic Web Crypto API implementation for Client-Side Encryption
 */

/**
 * Generate a new random AES-GCM key to encrypt the report.
 */
export async function generateKey(): Promise<CryptoKey> {
    return await window.crypto.subtle.generateKey(
        {
            name: "AES-GCM",
            length: 256,
        },
        true,
        ["encrypt", "decrypt"]
    );
}

/**
 * Encrypt data using the provided key.
 */
export async function encryptData(key: CryptoKey, data: string): Promise<{ ciphertext: string, iv: string }> {
    const iv = window.crypto.getRandomValues(new Uint8Array(12));
    const encodedData = new TextEncoder().encode(data);

    const encryptedContent = await window.crypto.subtle.encrypt(
        {
            name: "AES-GCM",
            iv: iv,
        },
        key,
        encodedData
    );

    // Convert to base64 for safe JSON storage
    const encryptedBytes = new Uint8Array(encryptedContent);
    const ciphertextBase64 = Buffer.from(encryptedBytes).toString("base64");
    const ivBase64 = Buffer.from(iv).toString("base64");

    return { ciphertext: ciphertextBase64, iv: ivBase64 };
}

/**
 * Decrypt data using the provided key and IV.
 */
export async function decryptData(key: CryptoKey, ciphertextBase64: string, ivBase64: string): Promise<string> {
    const ciphertext = Buffer.from(ciphertextBase64, "base64");
    const iv = Buffer.from(ivBase64, "base64");

    const decryptedContent = await window.crypto.subtle.decrypt(
        {
            name: "AES-GCM",
            iv: new Uint8Array(iv),
        },
        key,
        new Uint8Array(ciphertext)
    );

    return new TextDecoder().decode(decryptedContent);
}

/**
 * Export key to raw format (for the researcher to keep locally)
 */
export async function exportKey(key: CryptoKey): Promise<string> {
    const exported = await window.crypto.subtle.exportKey("raw", key);
    return Buffer.from(new Uint8Array(exported)).toString("base64");
}
