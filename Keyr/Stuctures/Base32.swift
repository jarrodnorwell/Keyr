//
//  Base32.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import Foundation

nonisolated struct Base32 {
    static func decodeToData(_ base32: String) -> Data? {
        let base32String = base32.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "=", with: "")
            .uppercased()

        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        var bits = 0
        var value: UInt32 = 0
        var output = Data()

        for ch in base32String {
            guard let idx = alphabet.firstIndex(of: ch) else {
                // invalid char
                return nil
            }

            value = (value << 5) | UInt32(idx)
            bits += 5

            if bits >= 8 {
                let shift = bits - 8
                let byte = UInt8((value >> UInt32(shift)) & 0xFF)
                output.append(byte)
                bits -= 8
                value &= (1 << shift) - 1
            }
        }
        return output
    }
}
