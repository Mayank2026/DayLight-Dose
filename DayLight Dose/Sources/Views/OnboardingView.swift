import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userPreferences: [UserPreferences]
    
    @State private var currentPage = 0
    @State private var selectedSkinType = 3
    @State private var selectedClothingLevel = 1
    @State private var userAge = 30
    @State private var showingAgePicker = false
    @State private var currentGradientColors: [Color] = []
    
    private let onboardingPages = [
        OnboardingPage(
            title: "Welcome to DayLight Dose",
            subtitle: "Your personal Vitamin D companion",
            description: "Track your daily sun exposure and optimize your Vitamin D intake with precision.",
            imageName: "sun.max.fill"
        ),
        OnboardingPage(
            title: "Smart UV Tracking",
            subtitle: "Real-time monitoring",
            description: "Get accurate UV index data for your location and track your exposure in real-time.",
            imageName: "location.fill"
        ),
        OnboardingPage(
            title: "Personalized Sessions",
            subtitle: "Tailored to you",
            description: "Calculate optimal sun exposure time based on your skin type, clothing, and location.",
            imageName: "person.fill"
        ),
        OnboardingPage(
            title: "Health Insights",
            subtitle: "Track your progress",
            description: "Monitor your Vitamin D intake and maintain healthy levels throughout the year.",
            imageName: "heart.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 0) {
                // Page indicator
                HStack {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageView(page: onboardingPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Bottom section
                VStack(spacing: 20) {
                    if currentPage == onboardingPages.count - 1 {
                        // Preferences section for the last page
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
                    }
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                        }
                        Spacer()
                        if currentPage < onboardingPages.count - 1 {
                            Button("Next") {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(25)
                        } else {
                            Button("Get Started") {
                                completeOnboarding()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showingAgePicker) {
            AgePickerView(selectedAge: $userAge)
        }
        .onAppear {
            currentGradientColors = gradientColors
        }
    }
    
    private func completeOnboarding() {
        let prefs = userPreferences.first ?? UserPreferences()
        prefs.skinType = selectedSkinType
        prefs.clothingLevel = selectedClothingLevel
        prefs.userAge = userAge
        prefs.hasCompletedOnboarding = true
        prefs.updatedAt = Date()
        if userPreferences.isEmpty {
            modelContext.insert(prefs)
        }
        try? modelContext.save()
        dismiss()
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

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: page.imageName)
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct SkinTypeButton: View {
    let skinType: Int
    let isSelected: Bool
    let action: () -> Void
    private var skinTypeInfo: (name: String, color: Color) {
        switch skinType {
        case 1: return ("Very Fair", Color(red: 0.95, green: 0.8, blue: 0.7))
        case 2: return ("Fair", Color(red: 0.9, green: 0.75, blue: 0.65))
        case 3: return ("Light", Color(red: 0.85, green: 0.7, blue: 0.6))
        case 4: return ("Medium", Color(red: 0.75, green: 0.6, blue: 0.5))
        case 5: return ("Dark", Color(red: 0.6, green: 0.45, blue: 0.35))
        case 6: return ("Very Dark", Color(red: 0.45, green: 0.3, blue: 0.2))
        default: return ("Unknown", Color.gray)
        }
    }
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(skinTypeInfo.color)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                    )
                Text(skinTypeInfo.name)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
        .frame(width: 60)
    }
}

struct ClothingLevelButton: View {
    let level: Int
    let isSelected: Bool
    let action: () -> Void
    private var levelInfo: (name: String, icon: String) {
        switch level {
        case 0: return ("Minimal", "figure.dress.line.vertical.figure")
        case 1: return ("Light", "tshirt")
        case 2: return ("Moderate", "figure.arms.open")
        case 3: return ("Heavy", "figure.walk")
        default: return ("Unknown", "questionmark")
        }
    }
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.orange : Color.white.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: levelInfo.icon)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                }
                Text(levelInfo.name)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
        .frame(width: 70)
    }
}

struct AgePickerView: View {
    @Binding var selectedAge: Int
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack {
                Picker("Age", selection: $selectedAge) {
                    ForEach(1...100, id: \.self) { age in
                        Text("\(age) years").tag(age)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.orange)
                .cornerRadius(25)
                .padding()
            }
            .navigationTitle("Select Age")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: UserPreferences.self, inMemory: true)
} 