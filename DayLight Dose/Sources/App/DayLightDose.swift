//
//  DayLightDose.swift
//  DayLight Dose
//
//  Created by Mayank Verma on 15/07/25.
//

import SwiftUI
import SwiftData

@main
struct DayLightDose: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var healthManager = HealthManager()
    @StateObject private var uvService = UVService()
    @StateObject private var vitaminDCalculator = VitaminDCalculator()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Configure ModelContainer with proper storage location
            let schema = Schema([
                UserPreferences.self,
                VitaminDSession.self,
                CachedUVData.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Perform migration from UserDefaults to SwiftData
            MigrationService.migrateUserDefaults(to: modelContainer.mainContext)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(locationManager)
                .environmentObject(healthManager)
                .environmentObject(uvService)
                .environmentObject(vitaminDCalculator)
                .environmentObject(networkMonitor)
                .modelContainer(modelContainer)
        }
    }
}

