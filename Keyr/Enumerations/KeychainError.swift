//
//  KeychainError.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import Foundation

enum KeychainError : Error {
    case unhandled(status: OSStatus)
}
