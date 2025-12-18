//
//  SampleData.swift
//  DayLight Dose
//
//  Created by Avineet Singh on 12/12/25.
//

import Foundation

/// Sample data for previews and experimentation with the chart components.
/// The live UI now uses real `VitaminDSession` data; this remains for Xcode previews
/// or for using the chart views in isolation.
struct SampleData {
    // Example: total vitamin D per day (IU) over a week
    static let dailyVitaminD: [MemberStats] = [
        .init(month: "Mon", value: 850),
        .init(month: "Tue", value: 1200),
        .init(month: "Wed", value: 640),
        .init(month: "Thu", value: 980),
        .init(month: "Fri", value: 1500),
        .init(month: "Sat", value: 1320),
        .init(month: "Sun", value: 700)
    ]
    
    // Example: number of tracked sessions per day
    static let dailySessions: [MemberStats] = [
        .init(month: "Mon", value: 1),
        .init(month: "Tue", value: 2),
        .init(month: "Wed", value: 1),
        .init(month: "Thu", value: 2),
        .init(month: "Fri", value: 3),
        .init(month: "Sat", value: 2),
        .init(month: "Sun", value: 1)
    ]
    
    // Example: average UV index per day
    static let dailyAverageUV: [MemberStats] = [
        .init(month: "Mon", value: 3.2),
        .init(month: "Tue", value: 4.5),
        .init(month: "Wed", value: 2.8),
        .init(month: "Thu", value: 3.9),
        .init(month: "Fri", value: 5.1),
        .init(month: "Sat", value: 4.3),
        .init(month: "Sun", value: 2.5)
    ]
    
    /// Convenience getter for previews to pick the appropriate sample set.
    static func data(for metric: String) -> [MemberStats] {
        switch metric {
        case "Vitamin D":
            return dailyVitaminD
        case "Sessions":
            return dailySessions
        case "UV":
            return dailyAverageUV
        default:
            return dailyVitaminD
        }
    }
}
