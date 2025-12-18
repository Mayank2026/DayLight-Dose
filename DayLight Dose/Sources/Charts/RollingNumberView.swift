//
//  RollingNumberView.swift
//  UITest
//
//  Created by Avineet Singh on 12/12/25.
//

import SwiftUI

// Animated Rolling Number View
struct RollingNumberView: View {
    let value: String
    var font: Font = .title
    // Default to white so it matches the cards in ContentView
    var textColor: Color = .white
    @State private var displayedValue: Double = 0
    @State private var animationTask: Task<Void, Never>?
    @State private var hasAppeared: Bool = false
    
    private var numericValue: Double {
        // Remove commas and convert to number
        let cleaned = value.replacingOccurrences(of: ",", with: "")
        return Double(cleaned) ?? 0
    }
    
    var body: some View {
        Text(formatNumber(displayedValue))
            .font(font)
            .foregroundColor(textColor)
            .contentTransition(.numericText())
            .animation(nil, value: displayedValue) // Disable automatic animation, we handle it manually
            .onChange(of: value) { _, newValue in
                // Calculate target value from the new string value
                let cleaned = newValue.replacingOccurrences(of: ",", with: "")
                let targetValue = Double(cleaned) ?? 0
                let startValue = displayedValue
                let difference = targetValue - startValue
                
                // Only animate if there's a meaningful difference and view has appeared
                guard abs(difference) > 0.1 && hasAppeared else {
                    displayedValue = targetValue
                    return
                }
                
                // Cancel any existing animation
                animationTask?.cancel()
                
                // Animate the number rolling
                animationTask = Task {
                    let duration: Double = 0.8
                    let steps: Int = 30
                    let stepDuration = duration / Double(steps)
                    
                    for step in 0...steps {
                        guard !Task.isCancelled else { return }
                        
                        let progress = Double(step) / Double(steps)
                        // Use easing function for smooth animation
                        let easedProgress = easeOutCubic(progress)
                        displayedValue = startValue + (difference * easedProgress)
                        
                        try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                    }
                    
                    // Ensure we end at the exact target value
                    displayedValue = targetValue
                }
            }
            .onAppear {
                // Initialize immediately without animation on first appear
                if !hasAppeared {
                    displayedValue = numericValue
                    hasAppeared = true
                } else {
                    // If view reappears with a different value, animate to it
                    let currentTarget = numericValue
                    if abs(displayedValue - currentTarget) > 0.1 {
                        let startValue = displayedValue
                        let difference = currentTarget - startValue
                        
                        animationTask?.cancel()
                        animationTask = Task {
                            let duration: Double = 0.8
                            let steps: Int = 30
                            let stepDuration = duration / Double(steps)
                            
                            for step in 0...steps {
                                guard !Task.isCancelled else { return }
                                
                                let progress = Double(step) / Double(steps)
                                let easedProgress = easeOutCubic(progress)
                                displayedValue = startValue + (difference * easedProgress)
                                
                                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                            }
                            
                            displayedValue = currentTarget
                        }
                    }
                }
            }
            .onDisappear {
                animationTask?.cancel()
            }
    }
    
    // Easing function for smooth animation
    private func easeOutCubic(_ t: Double) -> Double {
        let oneMinusT = 1.0 - t
        return 1.0 - (oneMinusT * oneMinusT * oneMinusT)
    }
    
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

