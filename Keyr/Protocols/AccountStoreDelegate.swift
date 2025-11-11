//
//  AccountStoreDelegate.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import Foundation

protocol AccountStoreDelegate : AnyObject {
    func accountStoreDidUpdate(_ store: AccountStore)
    
    func accountStore(_ store: AccountStore, didLoadAccounts accounts: [Account])
    
    func accountStore(_ store: AccountStore, didAddAccount account: Account)
    func accountStore(_ store: AccountStore, didRemoveAccount account: Account)
    func accountStore(_ store: AccountStore, didRenameAccount account: Account)
}
