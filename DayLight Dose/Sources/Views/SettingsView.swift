import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userPreferences: [UserPreferences]
    @State private var showingOnboarding = false
    @State private var showingAgePicker = false
    @State private var currentGradientColors: [Color] = []
    
    private var preferences: UserPreferences? {
        userPreferences.first
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 0) {
                // Header (like LearnView)
                HStack {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Main content
                List {
                    Section("Personal Information") {
                        if let prefs = preferences {
                            HStack {
                                Text("Skin Type")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(prefs.skinTypeDescription)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .listRowBackground(Color.white.opacity(0.1))
                            HStack {
                                Text("Clothing Level")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(prefs.clothingLevelDescription)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .listRowBackground(Color.white.opacity(0.1))
                            HStack {
                                Text("Age")
                                    .foregroundColor(.white)
                                Spacer()
                                Button("\(prefs.userAge) years") {
                                    showingAgePicker = true
                                }
                                .foregroundColor(.white)
                            }
                            .listRowBackground(Color.white.opacity(0.1))
                        }
                    }
                    Section("App Settings") {
                        Button("Update Preferences") {
                            showingOnboarding = true
                        }
                        .foregroundColor(.white)
                        .listRowBackground(Color.white.opacity(0.1))
                    }
                    Section("About") {
                        HStack {
                            Text("Version")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                    }
                }
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
                .listStyle(.insetGrouped)
            }
            .sheet(isPresented: $showingOnboarding) {
                HealthInsightsPreferencesView()
            }
            .sheet(isPresented: $showingAgePicker) {
                if let prefs = preferences {
                    AgePickerView(selectedAge: Binding(
                        get: { prefs.userAge },
                        set: { newAge in
                            prefs.userAge = newAge
                            prefs.updatedAt = Date()
                            try? modelContext.save()
                        }
                    ))
                }
            }
            .onAppear {
                currentGradientColors = gradientColors
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: currentGradientColors.isEmpty ? [Color(hex: "4a90e2"), Color(hex: "7bb7e5")] : currentGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var gradientColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        let timeProgress = Double(hour) + Double(minute) / 60.0
        if timeProgress < 5 || timeProgress > 22 {
            return [Color(hex: "0f1c3d"), Color(hex: "0a1228")]
        } else if timeProgress < 6 {
            return [Color(hex: "1e3a5f"), Color(hex: "2d4a7c")]
        } else if timeProgress < 6.5 {
            return [Color(hex: "3d5a80"), Color(hex: "5c7cae")]
        } else if timeProgress < 7 {
            return [Color(hex: "5c7cae"), Color(hex: "ee9b7a")]
        } else if timeProgress < 8 {
            return [Color(hex: "f4a261"), Color(hex: "87ceeb")]
        } else if timeProgress < 10 {
            return [Color(hex: "5ca9d6"), Color(hex: "87ceeb")]
        } else if timeProgress < 16 {
            return [Color(hex: "4a90e2"), Color(hex: "7bb7e5")]
        } else if timeProgress < 17 {
            return [Color(hex: "5ca9d6"), Color(hex: "87b8d4")]
        } else if timeProgress < 18.5 {
            return [Color(hex: "f4a261"), Color(hex: "e76f51")]
        } else if timeProgress < 19.5 {
            return [Color(hex: "e76f51"), Color(hex: "c44569")]
        } else if timeProgress < 20.5 {
            return [Color(hex: "c44569"), Color(hex: "6a4c93")]
        } else {
            return [Color(hex: "6a4c93"), Color(hex: "1e3a5f")]
        }
    }
}

// A view for updating preferences, showing only the Health Insights screen and preferences form
struct HealthInsightsPreferencesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userPreferences: [UserPreferences]
    @State private var selectedSkinType = 3
    @State private var selectedClothingLevel = 1
    @State private var userAge = 30
    @State private var showingAgePicker = false

    var body: some View {
        ZStack {
            // Use the same dynamic background as the rest of the app
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                OnboardingPageView(page: OnboardingPage(
                    title: "Health Insights",
                    subtitle: "Track your progress",
                    description: "Monitor your Vitamin D intake and maintain healthy levels throughout the year.",
                    imageName: "heart.fill"
                ))
                Spacer()
                VStack(spacing: 16) {
                    // Skin Type Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skin Type")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        HStack(spacing: 12) {
                            ForEach(1...6, id: \.self) { skinType in
                                SkinTypeButton(
                                    skinType: skinType,
                                    isSelected: selectedSkinType == skinType,
                                    action: { selectedSkinType = skinType }
                                )
                            }
                        }
                    }
                    // Clothing Level Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Clothing Level")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        HStack(spacing: 12) {
                            ForEach(0...3, id: \.self) { level in
                                ClothingLevelButton(
                                    level: level,
                                    isSelected: selectedClothingLevel == level,
                                    action: { selectedClothingLevel = level }
                                )
                            }
                        }
                    }
                    // Age Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        Button(action: { showingAgePicker = true }) {
                            HStack {
                                Text("\(userAge) years")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                Button("Save Preferences") {
                    savePreferences()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.2))
                .cornerRadius(25)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingAgePicker) {
            AgePickerView(selectedAge: $userAge)
        }
        .onAppear {
            if let prefs = userPreferences.first {
                selectedSkinType = prefs.skinType
                selectedClothingLevel = prefs.clothingLevel
                userAge = prefs.userAge
            }
        }
    }

    private func savePreferences() {
        let prefs = userPreferences.first ?? UserPreferences()
        prefs.skinType = selectedSkinType
        prefs.clothingLevel = selectedClothingLevel
        prefs.userAge = userAge
        prefs.updatedAt = Date()
        if userPreferences.isEmpty {
            modelContext.insert(prefs)
        }
        try? modelContext.save()
        dismiss()
    }

    private var gradientColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        let timeProgress = Double(hour) + Double(minute) / 60.0
        if timeProgress < 5 || timeProgress > 22 {
            return [Color(hex: "0f1c3d"), Color(hex: "0a1228")]
        } else if timeProgress < 6 {
            return [Color(hex: "1e3a5f"), Color(hex: "2d4a7c")]
        } else if timeProgress < 6.5 {
            return [Color(hex: "3d5a80"), Color(hex: "5c7cae")]
        } else if timeProgress < 7 {
            return [Color(hex: "5c7cae"), Color(hex: "ee9b7a")]
        } else if timeProgress < 8 {
            return [Color(hex: "f4a261"), Color(hex: "87ceeb")]
        } else if timeProgress < 10 {
            return [Color(hex: "5ca9d6"), Color(hex: "87ceeb")]
        } else if timeProgress < 16 {
            return [Color(hex: "4a90e2"), Color(hex: "7bb7e5")]
        } else if timeProgress < 17 {
            return [Color(hex: "5ca9d6"), Color(hex: "87b8d4")]
        } else if timeProgress < 18.5 {
            return [Color(hex: "f4a261"), Color(hex: "e76f51")]
        } else if timeProgress < 19.5 {
            return [Color(hex: "e76f51"), Color(hex: "c44569")]
        } else if timeProgress < 20.5 {
            return [Color(hex: "c44569"), Color(hex: "6a4c93")]
        } else {
            return [Color(hex: "6a4c93"), Color(hex: "1e3a5f")]
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: UserPreferences.self, inMemory: true)
}
