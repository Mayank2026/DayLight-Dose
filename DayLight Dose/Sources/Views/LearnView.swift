//
//  LearnView.swift
//  DayLight Dose
//
//  Created by Mayank Verma on 15/07/25.
//

import SwiftUI
import CoreLocation

struct LearnView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var currentGradientColors: [Color] = []
    @State private var selectedTopic: LearnTopic = .vitaminD
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Learn")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Topic selector
                topicSelector
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTopic {
                        case .vitaminD:
                            vitaminDContent
                        case .uvIndex:
                            uvIndexContent
                        case .skinTypes:
                            skinTypesContent
                        case .clothing:
                            clothingContent
                        case .tips:
                            tipsContent
                        case .calculator:
                            uvCalculatorContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            currentGradientColors = gradientColors
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
    
    private var topicSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LearnTopic.allCases, id: \.self) { topic in
                    TopicButton(
                        topic: topic,
                        isSelected: selectedTopic == topic,
                        action: { selectedTopic = topic }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var vitaminDContent: some View {
        VStack(spacing: 20) {
            InfoCard(
                title: "What is Vitamin D?",
                icon: "sun.max.fill",
                content: "Vitamin D is a fat-soluble vitamin that plays a crucial role in bone health, immune function, and overall well-being. It's often called the 'sunshine vitamin' because your body produces it when skin is exposed to sunlight."
            )
            
            InfoCard(
                title: "Why is Vitamin D Important?",
                icon: "heart.fill",
                content: "• Strengthens bones and teeth\n• Supports immune system function\n• Helps regulate mood and sleep\n• Reduces inflammation\n• May protect against certain diseases"
            )
            
            InfoCard(
                title: "How Much Do You Need?",
                icon: "target",
                content: "The recommended daily intake varies by age:\n• Adults: 600-800 IU\n• Seniors: 800-1000 IU\n• Pregnant women: 600-800 IU\n\nHowever, many experts suggest higher amounts (2000-4000 IU) for optimal health."
            )
            
            InfoCard(
                title: "Sun vs Supplements",
                icon: "pills.fill",
                content: "Sunlight is the most natural way to get vitamin D, but supplements can help during winter months or for those with limited sun exposure. The app helps you optimize your sun exposure for vitamin D production."
            )
        }
    }
    
    private var uvIndexContent: some View {
        VStack(spacing: 20) {
            InfoCard(
                title: "What is the UV Index?",
                icon: "sun.max",
                content: "The UV Index measures the strength of ultraviolet radiation from the sun. It ranges from 0 (low) to 11+ (extreme). Higher values mean faster vitamin D production but also increased risk of sunburn."
            )
            
            InfoCard(
                title: "UV Index Scale",
                icon: "chart.bar.fill",
                content: "• 0-2: Low (minimal risk)\n• 3-5: Moderate (some risk)\n• 6-7: High (high risk)\n• 8-10: Very High (very high risk)\n• 11+: Extreme (extreme risk)"
            )
            
            InfoCard(
                title: "Best Times for Vitamin D",
                icon: "clock.fill",
                content: "The best time for vitamin D production is when the UV Index is between 3-7, typically:\n• 10 AM - 2 PM in summer\n• 11 AM - 3 PM in winter\n• Avoid peak hours (UV 8+) to prevent sunburn"
            )
            
            InfoCard(
                title: "Factors Affecting UV",
                icon: "cloud.sun.fill",
                content: "• Time of day and season\n• Latitude and altitude\n• Cloud cover and pollution\n• Skin type and age\n• Clothing coverage\n• Sunscreen use"
            )
        }
    }
    
    private var skinTypesContent: some View {
        VStack(spacing: 20) {
            InfoCard(
                title: "Fitzpatrick Skin Types",
                icon: "person.fill",
                content: "Skin types are classified based on how your skin responds to sun exposure. This affects both vitamin D production and sunburn risk."
            )
            
            SkinTypeCard(
                type: 1,
                description: "Very Fair",
                characteristics: "Always burns, never tans",
                burnTime: "10-15 minutes",
                vitaminDFactor: "High production"
            )
            
            SkinTypeCard(
                type: 2,
                description: "Fair",
                characteristics: "Usually burns, tans minimally",
                burnTime: "15-20 minutes",
                vitaminDFactor: "Good production"
            )
            
            SkinTypeCard(
                type: 3,
                description: "Light",
                characteristics: "Sometimes burns, tans gradually",
                burnTime: "20-30 minutes",
                vitaminDFactor: "Moderate production"
            )
            
            SkinTypeCard(
                type: 4,
                description: "Medium",
                characteristics: "Rarely burns, tans easily",
                burnTime: "30-45 minutes",
                vitaminDFactor: "Lower production"
            )
            
            SkinTypeCard(
                type: 5,
                description: "Dark",
                characteristics: "Very rarely burns, tans very easily",
                burnTime: "45-60 minutes",
                vitaminDFactor: "Much lower production"
            )
            
            SkinTypeCard(
                type: 6,
                description: "Very Dark",
                characteristics: "Never burns, deeply pigmented",
                burnTime: "60+ minutes",
                vitaminDFactor: "Lowest production"
            )
        }
    }
    
    private var clothingContent: some View {
        VStack(spacing: 20) {
            InfoCard(
                title: "Clothing and Vitamin D",
                icon: "tshirt.fill",
                content: "The amount of skin exposed to sunlight directly affects vitamin D production. More exposed skin means faster vitamin D synthesis."
            )
            
            ClothingCard(
                level: "Nude",
                exposure: "100%",
                description: "Maximum vitamin D production",
                icon: "person.fill"
            )
            
            ClothingCard(
                level: "Minimal (Swimwear)",
                exposure: "80%",
                description: "Very high vitamin D production",
                icon: "figure.pool.swim"
            )
            
            ClothingCard(
                level: "Light (Shorts & T-shirt)",
                exposure: "40%",
                description: "Moderate vitamin D production",
                icon: "tshirt"
            )
            
            ClothingCard(
                level: "Moderate (Long sleeves)",
                exposure: "15%",
                description: "Low vitamin D production",
                icon: "tshirt.fill"
            )
            
            ClothingCard(
                level: "Heavy (Fully covered)",
                exposure: "5%",
                description: "Minimal vitamin D production",
                icon: "person.fill.checkmark"
            )
        }
    }
    
    private var tipsContent: some View {
        VStack(spacing: 20) {
            InfoCard(
                title: "Optimizing Vitamin D Production",
                icon: "lightbulb.fill",
                content: "Follow these tips to maximize vitamin D production while minimizing sunburn risk."
            )
            
            TipCard(
                title: "Timing is Everything",
                content: "Aim for 10-30 minutes of sun exposure when UV Index is 3-7. Avoid peak hours (UV 8+) to prevent sunburn.",
                icon: "clock"
            )
            
            TipCard(
                title: "Expose More Skin",
                content: "Expose arms, legs, and torso when possible. Face and hands alone provide limited vitamin D production.",
                icon: "person.fill"
            )
            
            TipCard(
                title: "Know Your Skin Type",
                content: "Fairer skin types need less time but are more prone to sunburn. Darker skin types need more time but are more protected.",
                icon: "person.crop.circle"
            )
            
            TipCard(
                title: "Consider Your Location",
                content: "Higher altitudes and lower latitudes have stronger UV. Adjust exposure time accordingly.",
                icon: "location.fill"
            )
            
            TipCard(
                title: "Seasonal Adjustments",
                content: "Winter months may require longer exposure or supplementation, especially at higher latitudes.",
                icon: "snowflake"
            )
            
            TipCard(
                title: "Listen to Your Body",
                content: "Stop exposure before you feel any burning sensation. Gradual exposure is better than overexposure.",
                icon: "ear.fill"
            )
            
            TipCard(
                title: "Avoid Sunscreen During Vitamin D Time",
                content: "Sunscreen blocks UVB rays needed for vitamin D production. Use it after your vitamin D session or when UV is high.",
                icon: "shield.slash"
            )
            
            TipCard(
                title: "Build Up Gradually",
                content: "Start with shorter sessions and gradually increase exposure time as your skin adapts to sun exposure.",
                icon: "arrow.up.circle"
            )
            
            TipCard(
                title: "Monitor Your Progress",
                content: "Use the app to track your sessions and ensure you're getting consistent vitamin D exposure throughout the week.",
                icon: "chart.line.uptrend.xyaxis"
            )
        }
    }
    
    private var uvCalculatorContent: some View {
        VStack(spacing: 20) {
            InfoCard(
                title: "UV Index Calculator",
                icon: "function",
                content: "Use this calculator to estimate UV Index based on location, date, and time. This helps you plan optimal vitamin D exposure times."
            )
            
            UVCalculatorCard()
        }
    }
}

enum LearnTopic: CaseIterable {
    case vitaminD, uvIndex, skinTypes, clothing, tips, calculator
    
    var title: String {
        switch self {
        case .vitaminD: return "Vitamin D"
        case .uvIndex: return "UV Index"
        case .skinTypes: return "Skin Types"
        case .clothing: return "Clothing"
        case .tips: return "Tips"
        case .calculator: return "Calculator"
        }
    }
    
    var icon: String {
        switch self {
        case .vitaminD: return "sun.max.fill"
        case .uvIndex: return "chart.bar.fill"
        case .skinTypes: return "person.fill"
        case .clothing: return "tshirt.fill"
        case .tips: return "lightbulb.fill"
        case .calculator: return "function"
        }
    }
}

struct TopicButton: View {
    let topic: LearnTopic
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: topic.icon)
                    .font(.system(size: 16))
                
                Text(topic.title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.2))
            )
        }
    }
}

struct InfoCard: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
    }
}

struct SkinTypeCard: View {
    let type: Int
    let description: String
    let characteristics: String
    let burnTime: String
    let vitaminDFactor: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Type \(type)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                DetailRow(label: "Characteristics:", value: characteristics)
                DetailRow(label: "Burn Time:", value: burnTime)
                DetailRow(label: "Vitamin D:", value: vitaminDFactor)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ClothingCard: View {
    let level: String
    let exposure: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(level)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text(exposure)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TipCard: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(2)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct UVCalculatorCard: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var calculatedUV: Double?
    @State private var showingResult = false
    @State private var isDetectingLocation = false
    @State private var locationInput = ""
    @State private var isSearching = false
    @State private var searchResults: [LocationResult] = []
    @State private var selectedLocation: LocationResult?
    @State private var showingSearchResults = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Location section
            VStack(spacing: 12) {
                HStack {
                    Text("Location:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: detectLocation) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                            Text("Detect")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .disabled(isDetectingLocation)
                }
                
                // Location search input
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                    
                    TextField("Search for a city or location...", text: $locationInput)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .onChange(of: locationInput) { _, newValue in
                            searchLocation(query: newValue)
                        }
                    
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                // Search results
                if showingSearchResults && !searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(searchResults.prefix(5), id: \.id) { result in
                            Button(action: { selectLocation(result) }) {
                                HStack {
                                    Image(systemName: "mappin.circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Text(result.country)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                            }
                            
                            if result.id != searchResults.prefix(5).last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                            }
                        }
                    }
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                }
                
                // Selected location display
                if let selected = selectedLocation {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selected.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(selected.country)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button(action: { clearSelectedLocation() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                } else if let location = locationManager.location {
                    // Current location display
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(locationManager.locationName.isEmpty ? "Current Location" : locationManager.locationName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Date and time pickers
            VStack(spacing: 12) {
                HStack {
                    Text("Date:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                }
                
                HStack {
                    Text("Time:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                }
            }
            
            // Calculate button
            Button(action: calculateUV) {
                Text("Calculate UV Index")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(8)
            }
            .disabled(selectedLocation == nil && locationManager.location == nil)
            
            // Result
            if showingResult, let uv = calculatedUV {
                VStack(spacing: 8) {
                    Text("Estimated UV Index")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(String(format: "%.1f", uv))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(uvDescription(uv))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
    }
    
    private func calculateUV() {
        let lat: Double
        let lon: Double
        
        if let selected = selectedLocation {
            lat = selected.latitude
            lon = selected.longitude
        } else if let location = locationManager.location {
            lat = location.coordinate.latitude
            lon = location.coordinate.longitude
        } else {
            return
        }
        
        // Simple UV calculation based on latitude, date, and time
        // This is a simplified model - real UV calculation is much more complex
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedTime)
        let month = calendar.component(.month, from: selectedDate)
        
        // Base UV based on latitude (higher at equator)
        let latFactor = 1.0 - abs(lat) / 90.0
        
        // Seasonal factor (higher in summer)
        let seasonalFactor = 1.0 + 0.5 * sin(Double(month - 6) * .pi / 6.0)
        
        // Time factor (peak at solar noon)
        let timeFactor = 1.0 - pow(Double(hour - 12) / 6.0, 2)
        let timeFactorClamped = max(0.0, min(1.0, timeFactor))
        
        // Calculate estimated UV
        let estimatedUV = 8.0 * latFactor * seasonalFactor * timeFactorClamped
        
        calculatedUV = estimatedUV
        showingResult = true
    }
    
    private func detectLocation() {
        isDetectingLocation = true
        
        // Request location permission if needed
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestPermission()
        }
        
        // Start location updates
        locationManager.startUpdatingLocation()
        
        // Stop detecting after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isDetectingLocation = false
            locationManager.stopUpdatingLocation()
        }
    }
    
    private func searchLocation(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            showingSearchResults = false
            return
        }
        
        isSearching = true
        showingSearchResults = true
        
        // Use CLGeocoder to search for locations
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(query) { placemarks, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let placemarks = placemarks {
                    searchResults = placemarks.prefix(10).map { placemark in
                        LocationResult(
                            id: UUID(),
                            name: placemark.locality ?? placemark.administrativeArea ?? placemark.name ?? "Unknown",
                            country: placemark.country ?? "Unknown",
                            latitude: placemark.location?.coordinate.latitude ?? 0,
                            longitude: placemark.location?.coordinate.longitude ?? 0
                        )
                    }
                } else {
                    searchResults = []
                }
            }
        }
    }
    
    private func selectLocation(_ location: LocationResult) {
        selectedLocation = location
        locationInput = ""
        searchResults = []
        showingSearchResults = false
    }
    
    private func clearSelectedLocation() {
        selectedLocation = nil
    }
    
    private func uvDescription(_ uv: Double) -> String {
        switch uv {
        case 0..<3:
            return "Low - Minimal risk of sunburn"
        case 3..<6:
            return "Moderate - Some risk of sunburn"
        case 6..<8:
            return "High - High risk of sunburn"
        case 8..<11:
            return "Very High - Very high risk of sunburn"
        default:
            return "Extreme - Extreme risk of sunburn"
        }
    }
}

struct LocationResult {
    let id: UUID
    let name: String
    let country: String
    let latitude: Double
    let longitude: Double
}

#Preview {
    LearnView()
} 