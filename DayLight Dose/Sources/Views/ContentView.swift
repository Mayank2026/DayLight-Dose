//
//  ContentView.swift
//  DayLight Dose
//
//  Created by Mayank Verma on 15/07/25.
//

import CoreLocation
import UIKit
import SwiftData
import WidgetKit
import Combine
import Foundation
import FoundationModels
import SwiftUI

// --- Guided generation models for AI summaries ---
@Generable
struct DailySummary {
    @Guide(description: "A 2–3 sentence overview of the user's current sunlight and vitamin D status, explicitly referencing UV index, vitamin D rate, clothing, skin type, and today's total vitamin D.")
    let overview: String
    
    @Guide(description: "Two concise, concrete tips tailored to the user's stats. Focus on safe sun exposure and vitamin D optimisation for the rest of the day, without assuming time of day and without repeating generic advice.")
    let tips: [DailyTip]
}

@Generable
struct DailyTip {
    @Guide(description: "A short, punchy title for the tip, like 'Adjust Midday Exposure' or 'Balance Supplements and Sun'. Do NOT include markdown characters such as ** or bullet markers.")
    let title: String
    
    @Guide(description: "1–2 sentences of actionable advice based on the user's actual stats.")
    let body: String
}

@Generable
struct SessionSummary {
    @Guide(description: "A 2–3 sentence friendly summary of this single vitamin D session, describing vitamin D absorption, how effective the session was, and how UV, clothing, skin type, and age contributed.")
    let summary: String
    
    @Guide(description: "1–3 concise insights or notable patterns about this session (for example, efficiency, timing, or intensity), without giving prescriptive tips or advice.")
    let insights: String
}

// MARK: - Guided-generation helpers

enum TextGenerationMode {
    case dailySummary
    case sessionAnalysis
}

// The streaming API yields `DailySummary.PartiallyGenerated`, so we accept that here
private func renderDailySummary(from summary: DailySummary.PartiallyGenerated) -> String {
    var sections: [String] = []
    
    if let overview = summary.overview {
        sections.append("**Sunshine and Vitamin D Overview:** \(overview)")
    }
    
    return sections.joined(separator: "\n\n")
}

// Likewise, the session analysis stream yields `SessionSummary.PartiallyGenerated`
private func renderSessionSummary(from summary: SessionSummary.PartiallyGenerated) -> String {
    // Only show the high-level session summary here.
    // Detailed insights are surfaced separately in the dedicated "Session Insights" card.
    return summary.summary ?? ""
}

// --- Multiline skeleton shimmer for summary loading ---
struct MultilineShimmerView: View {
    let lineCount: Int
    let lineHeight: CGFloat
    let spacing: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<lineCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: lineHeight / 2)
                    .fill(Color.white.opacity(0.13))
                    .frame(
                        width: index == lineCount - 1 && lineCount > 1
                            ? CGFloat.random(in: 80...160)
                            : CGFloat.random(in: 220...320),
                        height: lineHeight
                    )
                    .shimmering() // <-- Move shimmer here!
            }
        }
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerEffect())
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(15))
                        .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                        .animation(
                            Animation.linear(duration: 1.2)
                                .repeatForever(autoreverses: false),
                            value: phase
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped() // <-- Ensure shimmer overlay is clipped to bounds
                }
                .allowsHitTesting(false)
            )
            .onAppear {
                phase = 1
            }
    }
}

@available(iOS 26, *)
@MainActor
class TextGenerationViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var isStreaming: Bool = false
    @Published var primaryTipTitle: String = ""
    @Published var primaryTipBody: String = ""
    @Published var sessionInsights: String = ""
    private var session: LanguageModelSession?
    private var streamingTask: Task<Void, Never>?
    private let mode: TextGenerationMode

    init(mode: TextGenerationMode = .dailySummary) {
        self.mode = mode
        Task {
            do {
                switch mode {
                case .dailySummary:
                    session = try await LanguageModelSession {
                        """
                        You are a helpful sunlight and vitamin D assistant. Using the stats provided in the prompt, generate:
                        1) A 2–3 sentence overview of the user's current situation.
                        2) Two short, concrete tips focused on safe sun exposure and vitamin D optimisation for the rest of the day.
                        
                        Do not ask the user questions, do not mention specific times like “morning sun”, and avoid repeating the same advice across calls. Keep the tone friendly, concise, and specific to the numbers you are given.
                        """
                    }
                case .sessionAnalysis:
                    session = try await LanguageModelSession {
                        """
                        You are a helpful vitamin D session analyst. Using the stats for a single past session, generate:
                        1) A 2–3 sentence summary of the session's effectiveness.
                        2) A short section of additional insights or patterns you notice.
                        
                        Do not provide tips or future recommendations; just describe and interpret what happened in this session in clear, friendly language.
                        """
                    }
                }
            } catch {
                print("Failed to create LanguageModelSession: \(error)")
            }
        }
    }

    func generateText() {
        // Cancel any in-flight streaming task
        streamingTask?.cancel()
        output = ""
        primaryTipTitle = ""
        primaryTipBody = ""
        sessionInsights = ""

        streamingTask = Task {
            guard let session else { return }
            await MainActor.run {
                self.isStreaming = true
            }

            do {
                switch mode {
                case .dailySummary:
                    let stream = session.streamResponse(to: input, generating: DailySummary.self)
                    for try await snapshot in stream {
                        let rendered = renderDailySummary(from: snapshot.content)
                        await MainActor.run {
                            self.output = rendered
                            if let tip = snapshot.content.tips?.first {
                                self.primaryTipTitle = tip.title ?? ""
                                self.primaryTipBody = tip.body ?? ""
                            }
                        }
                    }
                case .sessionAnalysis:
                    let stream = session.streamResponse(to: input, generating: SessionSummary.self)
                    for try await snapshot in stream {
                        let rendered = renderSessionSummary(from: snapshot.content)
                        await MainActor.run {
                            self.output = rendered
                            if let insights = snapshot.content.insights {
                                self.sessionInsights = insights
                            }
                        }
                    }
                }
            } catch {
                if Task.isCancelled {
                    // Swallow cancellation errors
                } else {
                    await MainActor.run {
                        self.output = "Error: \(error.localizedDescription)"
                    }
                }
            }

            await MainActor.run {
                self.isStreaming = false
            }
        }
    }
}

// Fallback for earlier iOS versions
struct ContentViewLegacy: View {
    var body: some View {
        VStack {
            Text("This feature requires iOS 26 or newer.")
                .font(.title2)
                .foregroundColor(.secondary)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

@available(iOS 26, *)
struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var uvService: UVService
    @EnvironmentObject var vitaminDCalculator: VitaminDCalculator
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var userPreferences: [UserPreferences]
    
    @State private var showClothingPicker = false
    @State private var showSkinTypePicker = false
    @State private var showSunscreenPicker = false
    @State private var showManualExposureSheet = false
    @State private var showSessionCompletionSheet = false
    @State private var pendingSessionStartTime: Date? = nil
    @State private var pendingSessionAmount: Double = 0
    @State private var todaysTotal: Double = 0
    @State private var currentGradientColors: [Color] = []
    @State private var showInfoSheet = false
    @State private var lastUVUpdate: Date = UserDefaults.standard.object(forKey: "lastUVUpdate") as? Date ?? Date()
    @State private var timerCancellable: AnyCancellable?
    @StateObject private var summaryViewModel = TextGenerationViewModel()
    @State private var selectedSession: VitaminDSession? = nil
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common)
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            GeometryReader { geometry in
                if uvService.hasNoData {
                    // No data available view
                    VStack(spacing: 20) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No Data Available")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Connect to the internet to fetch UV data")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        if locationManager.location != nil {
                            Button(action: {
                                if let location = locationManager.location {
                                    uvService.fetchUVData(for: location)
                                }
                            }) {
                                Text("Retry")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(25)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            headerSection
                            uvSection
                            vitaminDSection
                            exposureToggle
                            clothingSection
                            skinTypeSection
                            // --- Summary Section ---
                            if #available(iOS 26, *) {
                                VStack(alignment: .leading, spacing: 18) {
                                    Text("Summary")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                        .padding(.bottom, 2)
                                    // HIDE PROMPT: Do not show TextEditor
                                    Button(action: {
                                        summaryViewModel.input = """
User stats for a personalised sunlight and vitamin D summary:

- UV Index: \(String(format: "%.1f", uvService.currentUV))
- Burn Limit: \(uvService.currentUV == 0 ? "---" : formatSafeTime(safeExposureTime))
- Max UVI: \(String(format: "%.1f", uvService.displayMaxUV))
- Sunrise: \(formatTime(uvService.displaySunrise))
- Sunset: \(formatTime(uvService.displaySunset))
- Cloud Cover: \(Int(uvService.currentCloudCover))%
- Altitude: \(Int(uvService.currentAltitude))m
- Location: \(locationManager.locationName)
- Vitamin D Rate: \(formatVitaminDNumber(vitaminDCalculator.currentVitaminDRate / 60.0)) IU/min
- Session Vitamin D: \(formatVitaminDNumber(vitaminDCalculator.sessionVitaminD)) IU
- Today's Total Vitamin D: \(formatTodaysTotal(todaysTotal + vitaminDCalculator.sessionVitaminD)) IU
- Clothing: \(vitaminDCalculator.clothingLevel.description)
- Skin Type: \(vitaminDCalculator.skinType.description)
- Age: \(vitaminDCalculator.userAge)
"""
                                        summaryViewModel.generateText()
                                    }) {
                                        HStack(spacing: 8) {
                                            if summaryViewModel.isStreaming {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            }
                                            Text(summaryViewModel.isStreaming ? "Analyzing..." : "Generate Analysis")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .padding(.vertical, 2)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                    }
                                    .buttonStyle(.glass)
                                    .disabled(summaryViewModel.isStreaming)
                                    .padding(.top, 2)
                                    Group {
                                        if summaryViewModel.output.isEmpty {
                                            // While waiting for the first tokens, show skeleton
                                            if summaryViewModel.isStreaming {
                                                MultilineShimmerView(lineCount: 3, lineHeight: 16, spacing: 12)
                                                    .frame(height: 60)
                                                    .padding(.top, 4)
                                            }
                                        } else {
                                            MultilineShimmerView(lineCount: 3, lineHeight: 16, spacing: 12)
                                                .opacity(0) // keep layout height stable when showing text
                                                .frame(height: 0)
                                            
                                            VStack(spacing: 8) {
                                                HStack(spacing: 6) {
                                                    Image(systemName: "apple.intelligence")
                                                        .font(.system(size: 22, weight: .semibold))
                                                        .foregroundColor(.white)
                                                    Text(summaryViewModel.isStreaming ? "AI-generated summary (updating…)" : "AI-generated summary")
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.7))
                                                }
                                                .frame(maxWidth: .infinity)
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text(.init(summaryViewModel.output))
                                                        .multilineTextAlignment(.leading)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                }
                                                .padding()
                                                .background(Color.white.opacity(0.10))
                                                .cornerRadius(12)
                                                .foregroundColor(.white)
                                                .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)
                                                .transition(.opacity)
                                            }
                                            
                                            // Tip of the Day card
                                            if !summaryViewModel.primaryTipTitle.isEmpty {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    HStack(spacing: 8) {
                                                        Image(systemName: "lightbulb.max")
                                                            .font(.system(size: 18, weight: .semibold))
                                                            .foregroundColor(.yellow)
                                                        Text("Tip of the Day")
                                                            .font(.subheadline.weight(.semibold))
                                                            .foregroundColor(.white)
                                                    }
                                                    if !summaryViewModel.primaryTipTitle.isEmpty {
                                                        Text(summaryViewModel.primaryTipTitle)
                                                            .font(.headline)
                                                            .foregroundColor(.white)
                                                    }
                                            if !summaryViewModel.primaryTipBody.isEmpty {
                                                Text(summaryViewModel.primaryTipBody)
                                                    .font(.subheadline)
                                                    .foregroundColor(.white.opacity(0.85))
                                            }
                                                }
                                                .padding()
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color.white.opacity(0.12))
                                                .cornerRadius(14)
                                                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
                                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.25))
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                            } else {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Summary")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Summarization is only available on iOS 26 and newer.")
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding()
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(8)
                                }
                                .padding()
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .padding(.bottom, uvService.isOfflineMode ? 40 : 0)
                        .animation(.easeInOut(duration: 0.3), value: uvService.isOfflineMode)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                        .frame(width: geometry.size.width)
                    }
                    .scrollDisabled(contentFitsInScreen(geometry: geometry))
                }
            }
            
            // Offline mode indicator as thin bar at bottom
            if uvService.isOfflineMode && !uvService.hasNoData {
                VStack {
                    Spacer()
                    HStack(spacing: 7) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 14))
                        if let lastUpdate = uvService.lastSuccessfulUpdate {
                            Text("Offline • Using cached data from \(timeAgo(from: lastUpdate))")
                        } else {
                            Text("Offline • No cached data")
                        }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .padding(.bottom, 20)
                    .background(Color.orange.opacity(0.9))
                }
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: uvService.isOfflineMode)
        .onAppear {
            setupApp()
            syncPreferencesFromUser()
            // Start timer when view appears
            timerCancellable = timer.autoconnect().sink { _ in
                updateData()
                loadTodaysTotal()
                // Only update gradient if colors actually changed
                let newColors = gradientColors
                if newColors != currentGradientColors {
                    currentGradientColors = newColors
                }
                updateWidgetSharedData()
            }
            updateWidgetSharedData()
        }
        .onChange(of: userPreferences.first) { _ in
            syncPreferencesFromUser()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Reset one-time location alert flag when app becomes active
            locationManager.resetLocationDeniedAlert()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Check for updated skin type and adaptation when app returns to foreground
            vitaminDCalculator.setHealthManager(healthManager)
            // NetworkMonitor will automatically detect when network is restored
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // Resume timer when app becomes active
                timerCancellable = timer.autoconnect().sink { _ in
                    updateData()
                    loadTodaysTotal()
                    // Only update gradient if colors actually changed
                    let newColors = gradientColors
                    if newColors != currentGradientColors {
                        currentGradientColors = newColors
                    }
                }
                // Also update data immediately when returning to foreground
                updateData()
                loadTodaysTotal()
                // Restart location updates when app becomes active
                locationManager.startUpdatingLocation()
            case .inactive, .background:
                // Cancel timer when app goes to background
                timerCancellable?.cancel()
                timerCancellable = nil
            @unknown default:
                break
            }
        }
        .onChange(of: vitaminDCalculator.isInSun) {
            handleSunToggle()
            updateWidgetSharedData()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                uvService.fetchUVData(for: location)
                updateWidgetSharedData()
            }
        }
        .onChange(of: vitaminDCalculator.clothingLevel) {
            // Update rate when clothing changes
            vitaminDCalculator.updateUV(uvService.currentUV)
            updateWidgetSharedData()
        }
        .onChange(of: vitaminDCalculator.skinType) {
            // Update rate when skin type changes
            vitaminDCalculator.updateUV(uvService.currentUV)
            updateWidgetSharedData()
        }
        .onChange(of: uvService.currentUV) { _, newUV in
            // Update rate when UV changes
            vitaminDCalculator.updateUV(newUV)
            updateWidgetSharedData()
        }
        .onChange(of: todaysTotal) { _, _ in
            updateWidgetSharedData()
        }
        .onOpenURL { url in
            handleURL(url)
        }
        .alert("Location access needed",
               isPresented: $locationManager.showLocationDeniedAlert,
               actions: {
                   Button("OK", role: .cancel) { }
               }, message: {
                   Text(locationManager.locationDeniedMessage)
               })
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
            // Night (deep dark blue)
            return [Color(hex: "0f1c3d"), Color(hex: "0a1228")]
        } else if timeProgress < 6 {
            // Pre-dawn (dark blue transitioning)
            return [Color(hex: "1e3a5f"), Color(hex: "2d4a7c")]
        } else if timeProgress < 6.5 {
            // Early dawn (blue to purple)
            return [Color(hex: "3d5a80"), Color(hex: "5c7cae")]
        } else if timeProgress < 7 {
            // Dawn (purple to pink)
            return [Color(hex: "5c7cae"), Color(hex: "ee9b7a")]
        } else if timeProgress < 8 {
            // Sunrise (pink to light blue)
            return [Color(hex: "f4a261"), Color(hex: "87ceeb")]
        } else if timeProgress < 10 {
            // Morning (clear blue sky)
            return [Color(hex: "5ca9d6"), Color(hex: "87ceeb")]
        } else if timeProgress < 16 {
            // Midday (bright blue sky)
            return [Color(hex: "4a90e2"), Color(hex: "7bb7e5")]
        } else if timeProgress < 17 {
            // Late afternoon (slightly warmer blue)
            return [Color(hex: "5ca9d6"), Color(hex: "87b8d4")]
        } else if timeProgress < 18.5 {
            // Golden hour (warm golden)
            return [Color(hex: "f4a261"), Color(hex: "e76f51")]
        } else if timeProgress < 19.5 {
            // Sunset (orange to pink)
            return [Color(hex: "e76f51"), Color(hex: "c44569")]
        } else if timeProgress < 20.5 {
            // Late sunset (pink to purple)
            return [Color(hex: "c44569"), Color(hex: "6a4c93")]
        } else {
            // Dusk (purple to dark blue)
            return [Color(hex: "6a4c93"), Color(hex: "1e3a5f")]
        }
    }
    
    private var headerSection: some View {
        Button(action: { showInfoSheet = true }) {
            Text("DayLight Dose")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .tracking(2)
        }
    }
    
    private var uvSection: some View {
        VStack(spacing: 8) {
            if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                VStack(spacing: 12) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("LOCATION ACCESS REQUIRED")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1.5)
                    
                    Text("Enable location to get accurate UV and vitamin D estimates.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                    
                    Button(action: {
                        locationManager.openSettings()
                    }) {
                        Text("Enable Location")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                    }
                }
            } else {
                Text("UV INDEX")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1.5)
                
                Text(String(format: "%.1f", uvService.currentUV))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 15) {
                VStack(spacing: 3) {
                    Text("BURN LIMIT")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text(uvService.currentUV == 0 ? "---" : formatSafeTime(safeExposureTime))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text(" ")
                        .font(.system(size: 8, weight: .medium))
                        .opacity(0)
                }
                
                VStack(spacing: 3) {
                    Text(uvService.shouldShowTomorrowTimes ? "MAX TMRW" : "MAX UVI")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "%.1f", uvService.displayMaxUV))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text(" ")
                        .font(.system(size: 8, weight: .medium))
                        .opacity(0)
                }
                
                VStack(spacing: 3) {
                    Text("SUNRISE")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text(formatTime(uvService.displaySunrise))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    if uvService.shouldShowTomorrowTimes {
                        Text("TOMORROW")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text(" ")
                            .font(.system(size: 8, weight: .medium))
                            .opacity(0)
                    }
                }
                
                VStack(spacing: 3) {
                    Text("SUNSET")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text(formatTime(uvService.displaySunset))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    if uvService.shouldShowTomorrowTimes {
                        Text("TOMORROW")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text(" ")
                            .font(.system(size: 8, weight: .medium))
                            .opacity(0)
                    }
                }
            }
            
            // Show cloud/altitude/location info
            VStack(spacing: 2) {
                HStack(spacing: 15) {
                    HStack(spacing: 5) {
                        Image(systemName: uvService.currentUV == 0 ?
                                         (uvService.currentCloudCover < 70 ? moonPhaseIcon() : "cloud.fill") :
                                         uvService.currentCloudCover == 0 ? "sun.max" :
                                         uvService.currentCloudCover > 50 ? "cloud.fill" : "cloud")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                        Text("\(Int(uvService.currentCloudCover))% clouds")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    if uvService.currentAltitude > 100 {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up.to.line")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(Int(uvService.currentAltitude))m")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text("(+\(Int((uvService.uvMultiplier - 1) * 100))% UV)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                // Location name
                if !locationManager.locationName.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                        Text(locationManager.locationName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.top, 3)
            
            
            // Vitamin D winter warning
            if uvService.isVitaminDWinter {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vitamin D Winter")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.yellow)
                        Text("Limited UV-B at \(Int(uvService.currentLatitude))°. Consider supplements.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(10)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
        .cornerRadius(20)
    }
    
    private var exposureToggle: some View {
        HStack(spacing: 12) {
            // Main tracking button
            Button(action: {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                if vitaminDCalculator.isInSun,
                   vitaminDCalculator.sessionVitaminD > 0,
                   let startTime = vitaminDCalculator.sessionStartTime {
                    // Defer ending the session until after user confirms in the sheet
                    pendingSessionStartTime = startTime
                    pendingSessionAmount = vitaminDCalculator.sessionVitaminD
                    showSessionCompletionSheet = true
                } else {
                    vitaminDCalculator.toggleSunExposure(uvIndex: uvService.currentUV)
                }
            }) {
                HStack {
                    Image(systemName: vitaminDCalculator.isInSun ? "sun.max.fill" :
                                     uvService.currentUV == 0 ? moonPhaseIcon() : "sun.max")
                        .font(.system(size: 24))
                        .symbolEffect(.pulse, isActive: vitaminDCalculator.isInSun)
                    
                    Text(vitaminDCalculator.isInSun ? "End" :
                         uvService.currentUV == 0 ? "No UV available" : "Begin")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(vitaminDCalculator.isInSun ? Color.yellow.opacity(0.3) : Color.black.opacity(0.2))
                .cornerRadius(15)
                .animation(.easeInOut(duration: 0.3), value: vitaminDCalculator.isInSun)
            }
            .disabled(uvService.currentUV == 0 && !vitaminDCalculator.isInSun)
            .opacity(uvService.currentUV == 0 && !vitaminDCalculator.isInSun ? 0.6 : 1.0)
            
            // Manual entry button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                showManualExposureSheet = true
            }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 60)
                    .padding(.vertical, 20)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(15)
            }
            .disabled(vitaminDCalculator.isInSun) // Can't add manual entry while tracking
            .opacity(vitaminDCalculator.isInSun ? 0.4 : 1.0)
        }
    }
    
    private var clothingSection: some View {
        HStack(spacing: 12) {
            // Clothing picker
            Button(action: { showClothingPicker.toggle() }) {
                VStack(spacing: 10) {
                    Text("CLOTHING")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1.5)
                    
                    HStack {
                        Text(vitaminDCalculator.clothingLevel.description)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.black.opacity(0.2))
                .cornerRadius(15)
            }
            .sheet(isPresented: $showClothingPicker) {
                ClothingPicker(selection: $vitaminDCalculator.clothingLevel)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            
            // Sunscreen picker
            Button(action: { showSunscreenPicker.toggle() }) {
                VStack(spacing: 10) {
                    Text("SUNSCREEN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1.5)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "shield.lefthalf.fill")
                            .font(.system(size: 12))
                        
                        Text(vitaminDCalculator.sunscreenLevel.description)
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.black.opacity(0.2))
                .cornerRadius(15)
            }
            .sheet(isPresented: $showSunscreenPicker) {
                SunscreenPicker(selection: $vitaminDCalculator.sunscreenLevel)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var skinTypeSection: some View {
        Button(action: { showSkinTypePicker.toggle() }) {
            VStack(spacing: 10) {
                Text("SKIN TYPE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1.5)
                
                HStack {
                    if vitaminDCalculator.skinTypeFromHealth {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Text(vitaminDCalculator.skinType.description)
                        .font(.system(size: 16, weight: .medium))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.black.opacity(0.2))
            .cornerRadius(15)
        }
        .sheet(isPresented: $showSkinTypePicker) {
            SkinTypePicker(selection: $vitaminDCalculator.skinType)
        }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet()
        }
        .sheet(isPresented: $showManualExposureSheet) {
            ManualExposureSheet()
        }
        .sheet(isPresented: $showSessionCompletionSheet) {
            if let startTime = pendingSessionStartTime {
                SessionCompletionSheet(
                    sessionStartTime: startTime,
                    sessionAmount: pendingSessionAmount,
                    onSave: {
                        // End the session and let existing logic save to Health + SwiftData
                        vitaminDCalculator.toggleSunExposure(uvIndex: uvService.currentUV)
                        // Reset pending state
                        pendingSessionStartTime = nil
                        pendingSessionAmount = 0
                    },
                    onCancel: {
                        // Keep tracking; just reset pending state
                        pendingSessionStartTime = nil
                        pendingSessionAmount = 0
                    }
                )
                .environmentObject(vitaminDCalculator)
                .environmentObject(healthManager)
                .preferredColorScheme(.dark)
            } else {
                // Fallback placeholder if for some reason we have no pending data
                ProgressView()
                    .tint(.white)
                    .preferredColorScheme(.dark)
            }
        }
    }
    
    private var vitaminDSection: some View {
        VStack(spacing: 15) {
            HStack(alignment: .top, spacing: 15) {
                VStack(spacing: 8) {
                    ZStack {
                        Text("POTENTIAL")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1.2)
                            .opacity(vitaminDCalculator.isInSun ? 0 : 1)
                        
                        Text("RATE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1.2)
                            .opacity(vitaminDCalculator.isInSun ? 1 : 0)
                    }
                    .frame(height: 12)
                    
                    Text(formatVitaminDNumber(vitaminDCalculator.currentVitaminDRate / 60.0))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .frame(minWidth: 80)
                        .frame(height: 34)
                    
                    Text("IU/min")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(height: 16)
                }
                .frame(minWidth: 100)
                
                VStack(spacing: 8) {
                    Text("SESSION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.2)
                        .frame(height: 12)
                    
                    HStack(spacing: 4) {
                        Text(formatVitaminDNumber(vitaminDCalculator.sessionVitaminD))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .frame(minWidth: 80, alignment: .trailing)
                        
                        Text("IU")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 20, alignment: .leading)
                    }
                    .frame(height: 34)
                    
                    ZStack {
                        Text("Not tracking")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                            .opacity(vitaminDCalculator.isInSun ? 0 : 1)
                        
                        if vitaminDCalculator.isInSun, let startTime = vitaminDCalculator.sessionStartTime {
                            Text(sessionDurationString(from: startTime))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .frame(height: 16)
                }
                .frame(minWidth: 100)
                
                VStack(spacing: 8) {
                    Text("TODAY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.2)
                        .frame(height: 12)
                    
                    Text(formatTodaysTotal(todaysTotal + vitaminDCalculator.sessionVitaminD))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .frame(minWidth: 80)
                        .frame(height: 34)
                    
                    Text("IU total")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(height: 16)
                }
                .frame(minWidth: 100)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
        .cornerRadius(20)
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private var safeExposureTime: Int {
        uvService.burnTimeMinutes[vitaminDCalculator.skinType.rawValue] ?? 60
    }
    
    private func setupApp() {
        locationManager.requestPermission()
        healthManager.requestAuthorization()
        loadTodaysTotal()
        currentGradientColors = gradientColors
        
        // Connect services - MUST set modelContext before any UV data fetching
        vitaminDCalculator.setHealthManager(healthManager)
        vitaminDCalculator.setUVService(uvService)
        vitaminDCalculator.setModelContext(modelContext)
        uvService.setModelContext(modelContext)
        uvService.setNetworkMonitor(networkMonitor)
        
        // Fetch UV data on startup
        if let location = locationManager.location {
            uvService.fetchUVData(for: location)
        }
        
        // Initialize vitamin D rate with current UV (even if 0)
        vitaminDCalculator.updateUV(uvService.currentUV)
        
        // Ensure moon phase is available for widget
        if uvService.currentMoonPhaseName.isEmpty {
            let defaultPhase = "Waxing Gibbous"
            uvService.currentMoonPhaseName = defaultPhase
            UserDefaults(suiteName: "group.daylight.mayank")?.set(defaultPhase, forKey: "moonPhaseName")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func updateData() {
        guard let location = locationManager.location else { return }
        
        // Update UV data every 5 minutes if needed
        let now = Date()
        if now.timeIntervalSince(lastUVUpdate) >= 300 {
            uvService.fetchUVData(for: location)
            lastUVUpdate = now
            UserDefaults.standard.set(now, forKey: "lastUVUpdate")
            
            // Stop high-frequency location updates after getting fresh data
            // Switch to significant location changes for battery efficiency
            locationManager.stopUpdatingLocation()
            locationManager.startSignificantLocationChanges()
        }
        
        vitaminDCalculator.updateUV(uvService.currentUV)
    }
    
    private func handleSunToggle() {
        if !vitaminDCalculator.isInSun && vitaminDCalculator.sessionVitaminD > 0 {
            let sessionAmount = vitaminDCalculator.sessionVitaminD
            healthManager.saveVitaminD(amount: sessionAmount)
            // Add the session amount to today's total immediately
            todaysTotal += sessionAmount
            // Reset the session vitamin D after saving
            vitaminDCalculator.sessionVitaminD = 0.0
            // Then reload from HealthKit to ensure accuracy
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadTodaysTotal()
                updateWidgetSharedData()
            }
        }
    }
    
    private func loadTodaysTotal() {
        healthManager.getTodaysVitaminD { total in
            todaysTotal = total ?? 0
            updateWidgetSharedData()
        }
    }
    
    private func formatVitaminD(_ value: Double) -> String {
        if value < 1 {
            return String(format: "%.2f IU", value)
        } else if value < 10 {
            return String(format: "%.1f IU", value)
        } else {
            return "\(Int(value)) IU"
        }
    }
    
    private func formatVitaminDNumber(_ value: Double) -> String {
        if value < 1 {
            return String(format: "%.2f", value)
        } else if value < 10 {
            return String(format: "%.1f", value)
        } else if value < 1000 {
            return "\(Int(value))"
        } else if value < 100000 {
            // Add comma formatting for readability
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        } else {
            // Handle very large numbers with K notation
            return String(format: "%.0fK", value / 1000)
        }
    }
    
    private func formatTodaysTotal(_ value: Double) -> String {
        if value < 1000 {
            return "\(Int(value))"
        } else if value < 100000 {
            // Add comma formatting for readability
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        } else {
            return String(format: "%.0fK", value / 1000)
        }
    }
    
    private func sessionDurationString(from startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration / 60)
        
        if minutes == 0 {
            return "< 1 min"
        } else if minutes == 1 {
            return "1 min"
        } else {
            return "\(minutes) mins"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let duration = Date().timeIntervalSince(date)
        let minutes = Int(duration / 60)
        let hours = Int(duration / 3600)
        
        if minutes < 1 {
            return "just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            return "\(hours / 24)d ago"
        }
    }
    
    private func handleURL(_ url: URL) {
        guard url.scheme == "sunday" else { return }
        
        switch url.host {
        case "toggle":
            // Only toggle if UV > 0, matching the main app behavior
            if uvService.currentUV > 0 {
                vitaminDCalculator.toggleSunExposure(uvIndex: uvService.currentUV)
            }
        default:
            break
        }
    }
    
    private func moonPhaseIcon() -> String {
        // Use the phase name from the API to select the correct icon
        let phaseName = uvService.currentMoonPhaseName.lowercased()
        
        // Map phase names to SF Symbols
        // Note: Farmsense API has typo "Cresent" instead of "Crescent"
        let icon: String
        if phaseName.contains("new") {
            icon = "moonphase.new.moon"
        } else if phaseName.contains("waxing") && phaseName.contains("cres") {
            icon = "moonphase.waxing.crescent"
        } else if phaseName.contains("first quarter") {
            icon = "moonphase.first.quarter"
        } else if phaseName.contains("waxing") && phaseName.contains("gibbous") {
            icon = "moonphase.waxing.gibbous"
        } else if phaseName.contains("full") {
            icon = "moonphase.full.moon"
        } else if phaseName.contains("waning") && phaseName.contains("gibbous") {
            icon = "moonphase.waning.gibbous"
        } else if phaseName.contains("last quarter") || phaseName.contains("third quarter") {
            icon = "moonphase.last.quarter"
        } else if phaseName.contains("waning") && phaseName.contains("cres") {
            icon = "moonphase.waning.crescent"
        } else {
            // Fallback based on illumination if phase name doesn't match
            if uvService.currentMoonPhase > 0.85 {
                icon = "moonphase.full.moon"
            } else {
                icon = "moon"
            }
        }
        
        return icon
    }
    
    private func formatSafeTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
    
    private func contentFitsInScreen(geometry: GeometryProxy) -> Bool {
        // Estimate content height
        let estimatedHeight: CGFloat = 40 + 250 + 140 + 70 + 70 + 70 + 40 + 100 + 40 // header + UV + vitD + button + clothing + skin + padding + summary + padding
        let offlineBarHeight: CGFloat = uvService.isOfflineMode ? 50 : 0
        return estimatedHeight + offlineBarHeight < geometry.size.height
    }

    private func syncPreferencesFromUser() {
        guard let prefs = userPreferences.first else { return }
        if let skinType = SkinType(rawValue: prefs.skinType) {
            vitaminDCalculator.skinType = skinType
        }
        if let clothingLevel = ClothingLevel(rawValue: prefs.clothingLevel) {
            vitaminDCalculator.clothingLevel = clothingLevel
        }
        vitaminDCalculator.userAge = prefs.userAge
    }
    
    // Helper to update widget shared data
    private func updateWidgetSharedData() {
        let sharedDefaults = UserDefaults(suiteName: "group.daylight.mayank")
        sharedDefaults?.set(uvService.currentUV, forKey: "currentUV")
        sharedDefaults?.set(todaysTotal + vitaminDCalculator.sessionVitaminD, forKey: "todaysTotal")
        sharedDefaults?.set(vitaminDCalculator.currentVitaminDRate, forKey: "vitaminDRate")
        sharedDefaults?.set(vitaminDCalculator.isInSun, forKey: "isTracking")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct ClothingPicker: View {
    @Binding var selection: ClothingLevel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ClothingLevel.allCases, id: \.self) { level in
                    Button(action: {
                        selection = level
                        dismiss()
                    }) {
                        HStack {
                            Text(level.description)
                                .foregroundColor(.primary)
                            Spacer()
                            if selection == level {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Clothing Level")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .preferredColorScheme(.dark)
        }
        .presentationBackground(Color(UIColor.systemBackground).opacity(0.99))
    }
}

struct SkinTypePicker: View {
    @Binding var selection: SkinType
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vitaminDCalculator: VitaminDCalculator
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SkinType.allCases, id: \.self) { type in
                    Button(action: {
                        selection = type
                        dismiss()
                    }) {
                        HStack {
                            Circle()
                                .fill(skinColor(for: type))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Type \(type.rawValue)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(type.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(skinTypeDetail(for: type))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 8)
                            
                            Spacer()
                            
                            if selection == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Fitzpatrick Skin Type")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .preferredColorScheme(.dark)
            .safeAreaInset(edge: .bottom) {
                if vitaminDCalculator.skinTypeFromHealth {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                        Text("Synced from Apple Health")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                }
            }
        }
        .presentationBackground(Color(UIColor.systemBackground).opacity(0.99))
    }
    
    private func skinTypeDetail(for type: SkinType) -> String {
        switch type {
        case .type1: return "Always burns, never tans"
        case .type2: return "Usually burns, tans minimally"
        case .type3: return "Sometimes burns, tans uniformly"
        case .type4: return "Burns minimally, tans well"
        case .type5: return "Rarely burns, tans profusely"
        case .type6: return "Never burns, deeply pigmented"
        }
    }
    
    private func skinColor(for type: SkinType) -> Color {
        switch type {
        case .type1: return Color(red: 1.0, green: 0.92, blue: 0.84)      // Very fair
        case .type2: return Color(red: 0.98, green: 0.87, blue: 0.73)     // Fair
        case .type3: return Color(red: 0.94, green: 0.78, blue: 0.63)     // Light brown
        case .type4: return Color(red: 0.82, green: 0.63, blue: 0.48)     // Moderate brown
        case .type5: return Color(red: 0.63, green: 0.47, blue: 0.36)     // Dark brown
        case .type6: return Color(red: 0.4, green: 0.26, blue: 0.18)      // Very dark brown
        }
    }
}

struct ManualExposureSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vitaminDCalculator: VitaminDCalculator
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var uvService: UVService
    @Environment(\.modelContext) private var modelContext
    
    @State private var date = Date()
    @State private var durationMinutes: Double = 20
    @State private var manualUVIndex: Double = 3.0
    @State private var clothingLevel: ClothingLevel = .light
    @State private var sunscreenLevel: SunscreenLevel = .none
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Session details")) {
                    DatePicker("End time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    HStack {
                        Text("Duration")
                        Spacer()
                        Slider(value: $durationMinutes, in: 5...180, step: 5)
                            .frame(width: 180)
                        Text("\(Int(durationMinutes)) min")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("UV Index")
                        Spacer()
                        Slider(value: $manualUVIndex, in: 0...12, step: 0.5)
                            .frame(width: 180)
                        Text(String(format: "%.1f", manualUVIndex))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Exposure")) {
                    Picker("Clothing", selection: $clothingLevel) {
                        ForEach(ClothingLevel.allCases, id: \.self) { level in
                            Text(level.description).tag(level)
                        }
                    }
                    Picker("Sunscreen", selection: $sunscreenLevel) {
                        ForEach(SunscreenLevel.allCases, id: \.self) { level in
                            Text(level.description).tag(level)
                        }
                    }
                }
                
                if let previewAmount = previewVitaminD() {
                    Section(header: Text("Estimated vitamin D")) {
                        Text("\(Int(previewAmount)) IU")
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Add Sun Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        saveSession()
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
    
    private func previewVitaminD() -> Double? {
        guard durationMinutes > 0, manualUVIndex > 0 else { return nil }
        return vitaminDCalculator.calculateVitaminD(
            uvIndex: manualUVIndex,
            exposureMinutes: durationMinutes,
            skinType: vitaminDCalculator.skinType,
            clothingLevel: clothingLevel,
            sunscreenLevel: sunscreenLevel
        )
    }
    
    private func saveSession() {
        guard !isSaving else { return }
        guard let amount = previewVitaminD() else {
            dismiss()
            return
        }
        
        isSaving = true
        
        let endTime = date
        let startTime = endTime.addingTimeInterval(-durationMinutes * 60)
        
        // Save SwiftData session
        let session = VitaminDSession(
            startTime: startTime,
            endTime: endTime,
            totalIU: amount,
            averageUV: manualUVIndex,
            peakUV: manualUVIndex,
            clothingLevel: clothingLevel.rawValue,
            skinType: vitaminDCalculator.skinType.rawValue,
            userAge: vitaminDCalculator.userAge
        )
        
        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            // If save fails, just dismiss without crashing
        }
        
        // Save to Health
        healthManager.saveVitaminD(amount: amount)
        
        // Best-effort widget refresh through shared defaults
        let sharedDefaults = UserDefaults(suiteName: "group.daylight.mayank")
        let existingTotal = sharedDefaults?.double(forKey: "todaysTotal") ?? 0
        sharedDefaults?.set(existingTotal + amount, forKey: "todaysTotal")
        sharedDefaults?.set(uvService.currentUV, forKey: "currentUV")
        sharedDefaults?.set(vitaminDCalculator.currentVitaminDRate, forKey: "vitaminDRate")
        sharedDefaults?.set(vitaminDCalculator.isInSun, forKey: "isTracking")
        WidgetCenter.shared.reloadAllTimelines()
        
        dismiss()
    }
}

struct SessionCompletionSheet: View {
    let sessionStartTime: Date
    let sessionAmount: Double
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }
    
    private var durationText: String {
        let minutes = Int(Date().timeIntervalSince(sessionStartTime) / 60)
        if minutes <= 0 {
            return "< 1 min"
        } else if minutes == 1 {
            return "1 min"
        } else {
            return "\(minutes) mins"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("End this session?")
                        .font(.title3.bold())
                    
                    Text("We'll save this vitamin D session to your history and Apple Health.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Started")
                        Spacer()
                        Text(dateFormatter.string(from: sessionStartTime))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(durationText)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Vitamin D")
                        Spacer()
                        Text("\(Int(sessionAmount)) IU")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Complete Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}
struct SunscreenPicker: View {
    @Binding var selection: SunscreenLevel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SunscreenLevel.allCases, id: \.self) { level in
                    Button(action: {
                        selection = level
                        dismiss()
                    }) {
                        HStack {
                            Text(level.description)
                                .foregroundColor(.primary)
                            Spacer()
                            if selection == level {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sunscreen")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .preferredColorScheme(.dark)
        }
        .presentationBackground(Color(UIColor.systemBackground).opacity(0.99))
    }
}

//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3:
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6:
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8:
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (1, 1, 1, 0)
//        }
//        self.init(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue:  Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
//}

struct InfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vitaminDCalculator: VitaminDCalculator
    @EnvironmentObject var uvService: UVService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // About the calculation
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About")
                            .font(.headline)
                        
                        Text("Daylight Dose uses a scientifically-based multi-factor model to estimate vitamin D synthesis from UV exposure.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("The calculation considers UV intensity, time of day, clothing coverage, skin type, age, and recent exposure history.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Base rate: 21,000 IU/hr (minimal clothing, ~80% exposure)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Link("View detailed methodology", destination: URL(string: "https://github.com/Mayank2026/DayLight-Dose/blob/main/METHODOLOGY.md")!)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    // Current Calculation Factors
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Current Factors")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            FactorRow(
                                label: "UV Factor",
                                value: String(format: "%.2fx", (uvService.currentUV * 2.5) / (3.0 + uvService.currentUV)),
                                detail: "Non-linear response curve"
                            )
                            
                            FactorRow(
                                label: "UV Quality",
                                value: String(format: "%.0f%%", vitaminDCalculator.currentUVQualityFactor * 100),
                                detail: "Time of day effectiveness"
                            )
                            
                            FactorRow(
                                label: "Clothing",
                                value: String(format: "%.0f%%", vitaminDCalculator.clothingLevel.exposureFactor * 100),
                                detail: vitaminDCalculator.clothingLevel.description
                            )
                            
                            FactorRow(
                                label: "Skin Type",
                                value: String(format: "%.0f%%", vitaminDCalculator.skinType.vitaminDFactor * 100),
                                detail: vitaminDCalculator.skinType.description
                            )
                            
                            FactorRow(
                                label: "Age Factor",
                                value: String(format: "%.0f%%", calculateAgeFactor() * 100),
                                detail: "Age \(vitaminDCalculator.userAge)"
                            )
                            
                            FactorRow(
                                label: "Adaptation",
                                value: String(format: "%.1fx", vitaminDCalculator.currentAdaptationFactor),
                                detail: "Based on 7-day history"
                            )
                            
                            if uvService.currentAltitude > 100 {
                                FactorRow(
                                    label: "Altitude",
                                    value: String(format: "+%.0f%%", (uvService.uvMultiplier - 1) * 100),
                                    detail: "\(Int(uvService.currentAltitude))m elevation"
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Data sources
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Data Sources")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.blue)
                            Text("Location from device GPS")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.orange)
                            Text("UV data from Open-Meteo")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Health data from Apple Health")
                                .font(.caption)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .preferredColorScheme(.dark)
        }
        .presentationBackground(Color(UIColor.systemBackground).opacity(0.99))
    }
    
    private func calculateAgeFactor() -> Double {
        let age = vitaminDCalculator.userAge
        if age <= 20 {
            return 1.0
        } else if age >= 70 {
            return 0.25
        } else {
            return max(0.25, 1.0 - Double(age - 20) * 0.015)
        }
    }
}

struct FactorRow: View {
    let label: String
    let value: String
    let detail: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }
}

import UIKit
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

