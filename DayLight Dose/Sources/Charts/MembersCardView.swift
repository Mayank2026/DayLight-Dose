//
//  MembersCardView.swift
//  UITest
//
//  Created by Avineet Singh on 12/12/25.
//

import SwiftUI

struct MembersCardView: View {
    @State private var selectedTab = "Enrolled"
    @State private var selectedMonth: MemberStats? = nil
    let tabs = ["All", "Active", "Enrolled"]
    
    // Get current data based on selected tab
    var currentData: [MemberStats] {
        SampleData.data(for: selectedTab)
    }
    
    // Get total members count based on selected tab
    var totalMembers: String {
        SampleData.totalMembers(for: selectedTab)
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
                        RollingNumberView(value: totalMembers, font: .title.bold(), textColor: .white)
                        Text("Total Members")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption2)
                    }
                }
                
                // Title and description - Step 3
                VStack(alignment: .leading, spacing: 2) {
                    Text("Members")
                        .foregroundColor(.white)
                        .font(.subheadline.bold())
                    
                    Text("Manage, total course members\nand their progress")
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

