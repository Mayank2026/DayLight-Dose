//
//  DataModels.swift
//  DayLight Dose
//
//  Created by Mayank Verma on 15/07/25.
//

import Foundation
import SwiftData

@Model
final class UserPreferences {
    var clothingLevel: Int = 1 // Default to light clothing
    var skinType: Int = 3 // Default to type 3
    var userAge: Int = 30
    var useAgeFactor: Bool = true
    var hasCompletedOnboarding: Bool = false // Tracks if onboarding is complete
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(clothingLevel: Int = 1, skinType: Int = 3, userAge: Int = 30, useAgeFactor: Bool = true) {
        self.clothingLevel = clothingLevel
        self.skinType = skinType
        self.userAge = userAge
        self.useAgeFactor = useAgeFactor
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var skinTypeDescription: String {
        switch skinType {
        case 1: return "Very Fair"
        case 2: return "Fair"
        case 3: return "Light"
        case 4: return "Medium"
        case 5: return "Dark"
        case 6: return "Very Dark"
        default: return "Unknown"
        }
    }
    
    var clothingLevelDescription: String {
        switch clothingLevel {
        case -1: return "Nude"
        case 0: return "Minimal"
        case 1: return "Light"
        case 2: return "Moderate"
        case 3: return "Heavy"
        default: return "Unknown"
        }
    }
}

@Model
final class VitaminDSession {
    var startTime: Date
    var endTime: Date?
    var totalIU: Double
    var averageUV: Double
    var peakUV: Double
    var clothingLevel: Int
    var skinType: Int
    var userAge: Int
    var duration: Double // Duration in seconds
    
    init(startTime: Date, endTime: Date? = nil, totalIU: Double = 0, averageUV: Double = 0, peakUV: Double = 0, clothingLevel: Int, skinType: Int, userAge: Int = 30) {
        self.startTime = startTime
        self.endTime = endTime
        self.totalIU = totalIU
        self.averageUV = averageUV
        self.peakUV = peakUV
        self.clothingLevel = clothingLevel
        self.skinType = skinType
        self.userAge = userAge
        self.duration = endTime?.timeIntervalSince(startTime) ?? 0
    }
    
    var durationString: String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        
        if minutes == 0 {
            return "\(seconds)s"
        } else if seconds == 0 {
            return "\(minutes)m"
        } else {
            return "\(minutes)m \(seconds)s"
        }
    }
    
    var clothingLevelDescription: String {
        switch clothingLevel {
        case -1: return "Nude"
        case 0: return "Minimal"
        case 1: return "Light"
        case 2: return "Moderate"
        case 3: return "Heavy"
        default: return "Unknown"
        }
    }
    
    var skinTypeDescription: String {
        switch skinType {
        case 1: return "Very Fair"
        case 2: return "Fair"
        case 3: return "Light"
        case 4: return "Medium"
        case 5: return "Dark"
        case 6: return "Very Dark"
        default: return "Unknown"
        }
    }
}

@Model
final class CachedUVData {
    var latitude: Double
    var longitude: Double
    var date: Date
    var hourlyUVData: Data? // Store as JSON data
    var hourlyCloudCoverData: Data? // Store as JSON data
    var maxUV: Double
    var sunrise: Date
    var sunset: Date
    var lastUpdated: Date
    
    // Computed properties to convert between Array and Data
    var hourlyUV: [Double] {
        get {
            guard let data = hourlyUVData else { return [] }
            return (try? JSONDecoder().decode([Double].self, from: data)) ?? []
        }
        set {
            hourlyUVData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var hourlyCloudCover: [Double] {
        get {
            guard let data = hourlyCloudCoverData else { return [] }
            return (try? JSONDecoder().decode([Double].self, from: data)) ?? []
        }
        set {
            hourlyCloudCoverData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(latitude: Double, longitude: Double, date: Date, hourlyUV: [Double], hourlyCloudCover: [Double], maxUV: Double, sunrise: Date, sunset: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.date = date
        self.hourlyUVData = try? JSONEncoder().encode(hourlyUV)
        self.hourlyCloudCoverData = try? JSONEncoder().encode(hourlyCloudCover)
        self.maxUV = maxUV
        self.sunrise = sunrise
        self.sunset = sunset
        self.lastUpdated = Date()
    }
}

