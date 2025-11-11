//
//  UInt64.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import Foundation

nonisolated extension UInt64 {
    var bigEndianData: Data {
        var be = self.bigEndian
        return Data(bytes: &be, count: MemoryLayout.size(ofValue: be))
    }
}
