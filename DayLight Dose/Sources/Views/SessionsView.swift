//
//  SessionsView.swift
//  DayLight Dose
//
//  Created by Mayank Verma on 15/07/25.
//

import SwiftUI
import SwiftData

struct SessionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VitaminDSession.startTime, order: .reverse) private var sessions: [VitaminDSession]
    
    @State private var currentGradientColors: [Color] = []
    @State private var showStats = false
    @State private var selectedSession: VitaminDSession? = nil
    // Removed: @State private var showAnalyzeSheet = false
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            if sessions.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 0) {
                    // Header with stats button
                    HStack {
                        Text("Sessions")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { showStats.toggle() }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Stats view
                    if showStats {
                        statsView
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                    }
                    
                    // Sessions list
                    sessionsList
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
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sun.max")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            
            Text("No Sessions Yet")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Start tracking your vitamin D exposure to see your sessions here")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    

    
    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sessions) { session in
                    SessionCard(session: session)
                        .onTapGesture {
                            selectedSession = session
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteSession(session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .sheet(item: $selectedSession) { session in
            AnalyzeSessionView(session: session)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func deleteSession(_ session: VitaminDSession) {
        modelContext.delete(session)
        try? modelContext.save()
    }
    
    private var statsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatCard(
                    title: "Total Sessions",
                    value: "\(sessions.count)",
                    icon: "clock.fill"
                )
                
                StatCard(
                    title: "Total IU",
                    value: formatVitaminD(totalIU),
                    icon: "sun.max.fill"
                )
            }
            
            HStack(spacing: 20) {
                StatCard(
                    title: "Avg Duration",
                    value: averageDuration,
                    icon: "timer"
                )
                
                StatCard(
                    title: "Avg UV",
                    value: String(format: "%.1f", averageUV),
                    icon: "sun.max"
                )
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
    }
    
    private var totalIU: Double {
        sessions.reduce(0) { $0 + $1.totalIU }
    }
    
    private var averageDuration: String {
        guard !sessions.isEmpty else { return "0m" }
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        let avgSeconds = totalSeconds / Double(sessions.count)
        let minutes = Int(avgSeconds / 60)
        return "\(minutes)m"
    }
    
    private var averageUV: Double {
        guard !sessions.isEmpty else { return 0 }
        let totalUV = sessions.reduce(0) { $0 + $1.averageUV }
        return totalUV / Double(sessions.count)
    }
    
    private func formatVitaminD(_ value: Double) -> String {
        if value < 1000 {
            return "\(Int(value))"
        } else if value < 10000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        } else {
            return String(format: "%.0fK", value / 1000)
        }
    }
}

@available(iOS 26, *)
struct AnalyzeSessionView: View {
    let session: VitaminDSession
    @StateObject private var viewModel = TextGenerationViewModel()
    @State private var isGenerating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) { // Reduced spacing between title and card
                // Title above the card
                Text("Session Details")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 32)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Session details card
                VStack(alignment: .leading, spacing: 12) {
                    // Header with date and time
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatDate(session.startTime))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            // No time range in analysis card
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(formatVitaminD(session.totalIU))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Text("IU")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    // Session details
                    HStack(spacing: 20) {
                        DetailItem(
                            icon: "clock",
                            title: "Duration",
                            value: session.durationString
                        )
                        DetailItem(
                            icon: "sun.max",
                            title: "UV Index",
                            value: String(format: "%.1f", session.averageUV)
                        )
                        DetailItem(
                            icon: "person",
                            title: "Skin Type",
                            value: session.skinTypeDescription
                        )
                    }
                    // Clothing level and extra info
                    HStack {
                        Image(systemName: "tshirt")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Clothing: \(session.clothingLevelDescription)")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                    // Add peak UV and age row for extra info
                    HStack(spacing: 20) {
                        DetailItem(
                            icon: "flame",
                            title: "Peak UV",
                            value: String(format: "%.1f", session.peakUV)
                        )
                        DetailItem(
                            icon: "figure.walk",
                            title: "Age",
                            value: String(session.userAge)
                        )
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.2))
                .cornerRadius(16)
                .frame(maxWidth: 500)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)

                // Analysis button (not inside a card)
                Button(action: {
                    isGenerating = true
                    viewModel.generateText()
                }) {
                    HStack(spacing: 8) {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isGenerating ? "Analyzing..." : "Generate Analysis")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .padding(.vertical, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.glass)
                .disabled(isGenerating)
                .padding(.horizontal, 8)

                // Analysis output or shimmer
                Group {
                    if isGenerating {
                        MultilineShimmerView(lineCount: 3, lineHeight: 16, spacing: 12)
                            .frame(height: 60)
                            .padding(.top, 4)
                    } else if !viewModel.output.isEmpty {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "apple.intelligence")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("AI-generated analysis")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            Text(viewModel.output)
                                .padding()
                                .background(Color.white.opacity(0.10))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)
                                .transition(.opacity)
                        }
                        .padding(.horizontal, 8)
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color.black.opacity(0.18).ignoresSafeArea())
        .onAppear {
            viewModel.input = """
Analyze this vitamin D session for the user in 2-3 sentences, using clear and friendly language:

- Date: \(session.startTime.formatted())
- Duration: \(session.durationString)
- Total Vitamin D: \(Int(session.totalIU)) IU
- Average UV: \(String(format: "%.1f", session.averageUV))
- Peak UV: \(String(format: "%.1f", session.peakUV))
- Clothing: \(session.clothingLevelDescription)
- Skin Type: \(session.skinTypeDescription)
- Age: \(session.userAge)
"""
        }
        .onChange(of: viewModel.output) { _, newValue in
            if isGenerating && !newValue.isEmpty {
                isGenerating = false
            }
        }
    }
}

struct SessionCard: View {
    let session: VitaminDSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(session.startTime))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(formatTime(session.startTime)) - \(formatTime(session.endTime ?? session.startTime))")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatVitaminD(session.totalIU))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("IU")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Session details
            HStack(spacing: 20) {
                DetailItem(
                    icon: "clock",
                    title: "Duration",
                    value: session.durationString
                )
                
                DetailItem(
                    icon: "sun.max",
                    title: "UV Index",
                    value: String(format: "%.1f", session.averageUV)
                )
                
                DetailItem(
                    icon: "person",
                    title: "Skin Type",
                    value: session.skinTypeDescription
                )
            }
            
            // Clothing level
            HStack {
                Image(systemName: "tshirt")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("Clothing: \(session.clothingLevelDescription)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
    }
}

fileprivate func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}

fileprivate func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

fileprivate func formatVitaminD(_ value: Double) -> String {
    if value < 1000 {
        return "\(Int(value))"
    } else if value < 10000 {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    } else {
        return String(format: "%.0fK", value / 1000)
    }
}

struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    SessionsView()
        .modelContainer(for: VitaminDSession.self, inMemory: true)
} 

