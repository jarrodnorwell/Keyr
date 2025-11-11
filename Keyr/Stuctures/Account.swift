//
//  Account.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import Foundation

nonisolated final class Account : Codable, Equatable, Hashable, @unchecked Sendable {
    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: UUID
    
    let issuer: String
    var name: String,
        secretBase32: String
    let digits: Int,
        period: Int
    let algorithm: OTPAlgorithm
    
    init(id: UUID = .init(), issuer: String, name: String = "Account", secretBase32: String,
         digits: Int = 6, period: Int = 30, algorithm: OTPAlgorithm = .sha1) {
        self.id = id
        self.issuer = issuer
        self.name = name
        self.secretBase32 = secretBase32
        self.digits = digits
        self.period = period
        self.algorithm = algorithm
    }
    
    var string: String { name }
    
    var code: String {
        do {
            return try TOTP.generate(secretBase32: secretBase32,
                              digits: digits,
                              time: .init(),
                              period: period,
                              algorithm: algorithm)
        } catch {
            return "Unknown"
        }
    }
}
