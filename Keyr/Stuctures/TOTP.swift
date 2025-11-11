//
//  TOTP.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import CommonCrypto
import Foundation
import CryptoKit

nonisolated struct TOTP {
    static func generate(secretBase32: String, digits: Int = 6, time: Date = Date(), period: Int = 30, algorithm: OTPAlgorithm = .sha1) throws -> String {
        guard let secretData = Base32.decodeToData(secretBase32) else {
            throw TOTPError.invalidSecret
        }
        
        let counter = UInt64(floor(time.timeIntervalSince1970 / Double(period)))
        let counterData = counter.bigEndianData
        
        let hmacData: Data
        
        switch algorithm {
        case .sha1:
            hmacData = hmacSHA1(key: secretData, message: counterData)
        case .sha256:
            let key = SymmetricKey(data: secretData)
            let mac = HMAC<SHA256>.authenticationCode(for: counterData, using: key)
            hmacData = Data(mac)
        case .sha512:
            let key = SymmetricKey(data: secretData)
            let mac = HMAC<SHA512>.authenticationCode(for: counterData, using: key)
            hmacData = Data(mac)
        }
        
        // dynamic truncation
        let offset = Int(hmacData.last! & 0x0F)
        let truncated = hmacData.subdata(in: offset..<(offset + 4))
        var number = UInt32(bigEndian: truncated.withUnsafeBytes { $0.load(as: UInt32.self) })
        number &= 0x7FFFFFFF
        let mod = UInt32(pow(10, Double(digits)))
        let otp = number % mod
        return String(format: "%0*u", digits, otp)
    }
    
    // CommonCrypto-based HMAC-SHA1
    private static func hmacSHA1(key: Data, message: Data) -> Data {
        var result = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        key.withUnsafeBytes { keyPtr in
            message.withUnsafeBytes { msgPtr in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1),
                       keyPtr.baseAddress,
                       key.count,
                       msgPtr.baseAddress,
                       message.count,
                       &result)
            }
        }
        return Data(result)
    }
}
