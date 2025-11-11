//
//  KeychainStore.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import Foundation
import Security

class KeychainStore {
    private let service = "com.antique.Keyr"
    private let accountsKey = "accounts"

    func saveAccounts(_ accounts: [Account]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(accounts)

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: accountsKey
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        let addQuery = query.merging([kSecValueData: data]) { (_, new) in new }
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status: status)
        }
    }

    func loadAccounts() throws -> [Account] {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: accountsKey,
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess else { throw KeychainError.unhandled(status: status) }
        guard let data = item as? Data else { return [] }
        let decoder = JSONDecoder()
        return try decoder.decode([Account].self, from: data)
    }
}
