//
//  OTPAlgorithm.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import Foundation

enum OTPAlgorithm : String, Codable, Hashable {
    case sha1 = "sha1"
    case sha256 = "sha256"
    case sha512 = "sha512"
    
    var string: String { rawValue.uppercased() }
}
