//
//  MemberStats.swift
//  UITest
//
//  Created by Avineet Singh on 12/12/25.
//

import Foundation

// Data Model
struct MemberStats: Identifiable, Equatable {
    let id = UUID()
    let month: String
    let value: Double
    
    static func == (lhs: MemberStats, rhs: MemberStats) -> Bool {
        return lhs.month == rhs.month && lhs.value == rhs.value
    }
}

