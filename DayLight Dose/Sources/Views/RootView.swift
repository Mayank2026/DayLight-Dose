//
//  RootView.swift
//  DayLight Dose
//
//  Created by Mayank Verma on 15/07/25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userPreferences: [UserPreferences]
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
    }
    
    private var hasCompletedOnboarding: Bool {
        userPreferences.first?.hasCompletedOnboarding ?? false
    }
}

#Preview {
    RootView()
        .modelContainer(for: UserPreferences.self, inMemory: true)
}
