//
//  AESUtil.swift
//  haveseeyou
//
//  AES-128-ECB 加解密工具
//  对应 Dart 端的 EveningAppAesUtil（package:encrypt）
//  - key   : privateKey（base64 解码后的 UTF-8 字节）
//  - iv    : 16 字节（ECB 模式下不参与运算，仅占位）
//  - mode  : ECB
//  - pad   : PKCS7
//

import Foundation
import CommonCrypto

enum AESUtil {

    // MARK: - 解密（密文为 base64 字符串 → 明文 UTF-8 字符串）

    /// AES-128-ECB 解密
    /// - Parameter content: 服务端返回的 base64 加密字符串
    /// - Returns: 解密后的明文（UTF-8）；若失败返回 nil
    static func aes128Decrypt(_ content: String) -> String? {
        guard !content.isEmpty else { return content }

        guard let keyData = keyData(),
              let cipherData = Data(base64Encoded: content) else {
            #if DEBUG
            print("⚠️ [AES] 解密参数异常：key 或 cipher 不合法")
            #endif
            return nil
        }

        guard let plainData = crypt(data: cipherData,
                                    key: keyData,
                                    operation: CCOperation(kCCDecrypt)) else {
            #if DEBUG
            print("⚠️ [AES] 解密时发生错误")
            #endif
            return nil
        }

        return String(data: plainData, encoding: .utf8)
    }

    // MARK: - 加密（明文字符串 → base64 密文字符串）

    /// AES-128-ECB 加密
    /// - Parameter content: 待加密的明文
    /// - Returns: base64 编码的密文；若失败返回 nil
    static func aes128Encrypt(_ content: String) -> String? {
        guard !content.isEmpty else { return content }

        guard let keyData = keyData(),
              let plainData = content.data(using: .utf8) else {
            #if DEBUG
            print("⚠️ [AES] 加密参数异常：key 或 plain 不合法")
            #endif
            return nil
        }

        guard let cipherData = crypt(data: plainData,
                                     key: keyData,
                                     operation: CCOperation(kCCEncrypt)) else {
            #if DEBUG
            print("⚠️ [AES] 加密时发生错误")
            #endif
            return nil
        }

        return cipherData.base64EncodedString()
    }

    // MARK: - 私有：构建 key

    /// AES 密钥是 16 个字节的原始字符串，直接使用 UTF-8 编码
    private static func keyData() -> Data? {
        guard let data = aesKey.data(using: .utf8) else {
            #if DEBUG
            print("⚠️ [AES] aesKey 编码失败")
            #endif
            return nil
        }
        // AES-128 要求 key 长度 16 字节
        guard data.count == kCCKeySizeAES128 else {
            #if DEBUG
            print("⚠️ [AES] key 长度异常: \(data.count)，期望 \(kCCKeySizeAES128)")
            #endif
            return nil
        }
        return data
    }

    // MARK: - 私有：CCCrypt 通用调用

    private static func crypt(data: Data,
                              key: Data,
                              operation: CCOperation) -> Data? {
        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        var numBytesProcessed = 0

        let status: CCCryptorStatus = buffer.withUnsafeMutableBytes { bufferPtr in
            data.withUnsafeBytes { dataPtr in
                key.withUnsafeBytes { keyPtr in
                    CCCrypt(
                        operation,
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode),
                        keyPtr.baseAddress,
                        kCCKeySizeAES128,
                        nil,                        // ECB 模式不需要 IV
                        dataPtr.baseAddress,
                        data.count,
                        bufferPtr.baseAddress,
                        bufferSize,
                        &numBytesProcessed
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            #if DEBUG
            print("⚠️ [AES] CCCrypt 失败，status=\(status)")
            #endif
            return nil
        }

        return buffer.prefix(numBytesProcessed)
    }
}
