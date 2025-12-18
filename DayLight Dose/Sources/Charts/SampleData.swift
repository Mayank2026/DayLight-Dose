//
//  SampleData.swift
//  UITest
//
//  Created by Avineet Singh on 12/12/25.
//

import Foundation

// Sample data for different member categories
struct SampleData {
    // All Members Data
    static let allMembersData: [MemberStats] = [
        .init(month: "Jan", value: 210),
        .init(month: "Feb", value: 530),
        .init(month: "Mar", value: 375),
        .init(month: "Apr", value: 420),
        .init(month: "May", value: 380),
        .init(month: "Jun", value: 632),
        .init(month: "Jul", value: 610)
    ]
    
    // Active Members Data
    static let activeMembersData: [MemberStats] = [
        .init(month: "Jan", value: 180),
        .init(month: "Feb", value: 450),
        .init(month: "Mar", value: 320),
        .init(month: "Apr", value: 380),
        .init(month: "May", value: 340),
        .init(month: "Jun", value: 520),
        .init(month: "Jul", value: 490)
    ]
    
    // Enrolled Members Data
    static let enrolledMembersData: [MemberStats] = [
        .init(month: "Jan", value: 150),
        .init(month: "Feb", value: 380),
        .init(month: "Mar", value: 280),
        .init(month: "Apr", value: 340),
        .init(month: "May", value: 310),
        .init(month: "Jun", value: 450),
        .init(month: "Jul", value: 420)
    ]
    
    // Total members count for each category
    static func totalMembers(for category: String) -> String {
        switch category {
        case "All":
            return "1,930"
        case "Active":
            return "1,420"
        case "Enrolled":
            return "1,180"
        default:
            return "1,930"
        }
    }
    
    // Get data for a specific category
    static func data(for category: String) -> [MemberStats] {
        switch category {
        case "All":
            return allMembersData
        case "Active":
            return activeMembersData
        case "Enrolled":
            return enrolledMembersData
        default:
            return enrolledMembersData
        }
    }
}

