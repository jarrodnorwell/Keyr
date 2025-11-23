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

        // Base query
        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: accountsKey,
            kSecAttrSynchronizable: kCFBooleanTrue as Any  // <-- iCloud sync
        ]

        // Remove previous copy
        SecItemDelete(baseQuery as CFDictionary)

        // Add updated version
        var addQuery = baseQuery
        addQuery[kSecValueData] = data

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
            kSecAttrSynchronizable: kCFBooleanTrue as Any, // <-- must match save
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return []
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status: status)
        }

        guard let data = item as? Data else {
            return []
        }

        let decoder = JSONDecoder()
        return try decoder.decode([Account].self, from: data)
    }
}
