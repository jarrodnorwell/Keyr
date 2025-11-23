//
//  AccountStore.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import Foundation
import UIKit

class AccountStore {
    var accounts: [Account] = [] {
        didSet {
            save()
            if let delegate {
                delegate.accountStore(self, didLoadAccounts: accounts)
            }
        }
    }
    private let keychain = KeychainStore()
    private var timer: Timer?
    weak var delegate: AccountStoreDelegate?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if let self, let delegate = self.delegate {
                delegate.accountStoreDidUpdate(self)
            }
        }
    }

    deinit {
        timer?.invalidate()
    }

    @MainActor
    func load() async {
        do {
            let loaded = try keychain.loadAccounts()
            DispatchQueue.main.async {
                self.accounts = loaded
            }
        } catch {
            print("Keychain load error: \(error)")
            DispatchQueue.main.async {
                self.accounts = []
            }
        }
    }

    func add(_ account: Account) {
        accounts.append(account)
        save()
        
        if let delegate {
            delegate.accountStore(self, didAddAccount: account)
        }
    }

    func delete(at index: Int) {
        guard accounts.indices.contains(index) else {
            return
        }
        
        let account: Account = accounts[index]
        
        accounts.remove(at: index)
        save()
        
        if let delegate {
            delegate.accountStore(self, didRemoveAccount: account)
        }
    }

    /*
    func move(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              accounts.indices.contains(sourceIndex),
              accounts.indices.contains(destinationIndex) else { return }

        let item = accounts.remove(at: sourceIndex)
        accounts.insert(item, at: destinationIndex)
        save()
        delegate?.accountStoreDidUpdate(self)
    }*/
    
    @objc private func reloadFromKeychain() {
        do {
            let loaded = try keychain.loadAccounts()
            
            if loaded != self.accounts {
                self.accounts = loaded
                if let delegate {
                    delegate.accountStore(self, didLoadAccounts: self.accounts)
                }
            }
        } catch {
            print("iCloud sync: failed to reload: \(error)")
        }
    }
    
    func rename(at index: Int, to name: String) {
        guard accounts.indices.contains(index) else {
            return
        }
        
        let account = accounts[index]
        account.name = name
        
        accounts[index] = account
        save()
        
        if let delegate {
            delegate.accountStore(self, didRenameAccount: account)
        }
    }

    private func save() {
        do {
            try keychain.saveAccounts(accounts)
        } catch {
            print("Keychain save error: \(error)")
        }
    }
}
