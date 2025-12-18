//
//  MembersCardView.swift
//  UITest
//
//  Created by Avineet Singh on 12/12/25.
//

import SwiftUI
import SwiftData

struct MembersCardView: View {
    @Query(sort: \VitaminDSession.startTime, order: .forward) private var sessions: [VitaminDSession]
    
    @State private var selectedTab = "Vitamin D"
    @State private var selectedMonth: MemberStats? = nil
    let tabs = ["Vitamin D", "Sessions", "UV"]
    
    // Formatter for day labels (e.g. "Mon")
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
    
    // Last 7 calendar days, oldest first, based on session data or today's date.
    private var dayAnchors: [Date] {
        let calendar = Calendar.current
        
        // If we have sessions, anchor around the latest one; otherwise use today.
        let referenceDate = sessions.last?.startTime ?? Date()
        let startOfReferenceDay = calendar.startOfDay(for: referenceDate)
        
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -(6 - offset), to: startOfReferenceDay)
        }
    }
    
    // Build chart data for the active tab from real sessions.
    var currentData: [MemberStats] {
        guard !sessions.isEmpty else {
            // Fallback: simple 0 line so chart layout stays stable
            return dayAnchors.map { date in
                MemberStats(month: dayFormatter.string(from: date), value: 0)
            }
        }
        
        let calendar = Calendar.current
        
        return dayAnchors.map { dayStart in
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let daySessions = sessions.filter { session in
                session.startTime >= dayStart && session.startTime < dayEnd
            }
            
            let value: Double
            switch selectedTab {
            case "Vitamin D":
                value = daySessions.reduce(0) { $0 + $1.totalIU }
            case "Sessions":
                value = Double(daySessions.count)
            case "UV":
                if daySessions.isEmpty {
                    value = 0
                } else {
                    let totalUV = daySessions.reduce(0) { $0 + $1.averageUV }
                    value = totalUV / Double(daySessions.count)
                }
            default:
                value = daySessions.reduce(0) { $0 + $1.totalIU }
            }
            
            return MemberStats(
                month: dayFormatter.string(from: dayStart),
                value: value
            )
        }
    }
    
    // Total value label shown on the right, derived from real data.
    var totalLabel: String {
        switch selectedTab {
        case "Vitamin D":
            let total = sessions.reduce(0) { $0 + $1.totalIU }
            if total < 1_000 {
                return "\(Int(total))"
            } else if total < 100_000 {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 0
                return formatter.string(from: NSNumber(value: total)) ?? "\(Int(total))"
            } else {
                return String(format: "%.0fK", total / 1_000)
            }
        case "Sessions":
            return "\(sessions.count)"
        case "UV":
            guard !sessions.isEmpty else { return "0.0" }
            let avgUV = sessions.reduce(0) { $0 + $1.averageUV } / Double(sessions.count)
            return String(format: "%.1f", avgUV)
        default:
            return "0"
        }
    }
    
    var body: some View {
        // Main card styled to match ContentView cards
        VStack(alignment: .leading, spacing: 0) {
            // Content with padding
            VStack(alignment: .leading, spacing: 0) {
                // Top row: Segmented control (left) and Total count (right)
                HStack(alignment: .top) {
                    // Segmented Control - Step 2 (top-left position)
                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.self) { tab in
                            Text(tab)
                                .foregroundColor(
                                    selectedTab == tab
                                    ? .black // legible on white pill
                                    : .white.opacity(0.7)
                                )
                                .font(.caption.bold())
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    selectedTab == tab ?
                                    Color.white :
                                    Color.clear
                                )
                                .cornerRadius(12)
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        selectedTab = tab
                                    }
                                }
                        }
                    }
                    .padding(3)
                    // Soft white pill to make the selected tab stand out on dark card
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(16)
                    
                    Spacer()
                    
                    // Total Count - Step 4 (top-right position)
                    VStack(alignment: .trailing, spacing: 4) {
                        RollingNumberView(value: totalLabel, font: .title.bold(), textColor: .white)
                        Text(
                            selectedTab == "Vitamin D"
                            ? "Total IU (all time)"
                            : selectedTab == "Sessions"
                              ? "Total Sessions"
                              : "Avg UV"
                        )
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption2)
                    }
                }
                
                // Title and description - Step 3
                VStack(alignment: .leading, spacing: 2) {
                    Text("History")
                        .foregroundColor(.white)
                        .font(.subheadline.bold())
                    
                    Text("Your vitamin D and session trends over recent days")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }
                .padding(.top, 0)
            }
            .padding()
            
            // Chart - Step 5a: Custom line chart (full width, extends to edges)
            CustomLineChart(data: currentData, height: 120, selectedMonth: $selectedMonth)
                .padding(.top, 8)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
        .cornerRadius(20)
    }
}

#Preview {
    MembersCardView()
}

