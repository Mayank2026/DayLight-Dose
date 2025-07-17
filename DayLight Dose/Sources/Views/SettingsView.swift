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
        NavigationView {
            ZStack {
                backgroundGradient
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
                                .foregroundColor(.black)
                            }
                            .listRowBackground(Color.white.opacity(0.1))
                        }
                    }
                    Section("App Settings") {
                        Button("Update Preferences") {
                            showingOnboarding = true
                        }
                        .foregroundColor(.black)
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
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.clear, for: .navigationBar)
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
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

#Preview {
    SettingsView()
        .modelContainer(for: UserPreferences.self, inMemory: true)
}
