//
//  WelcomeView.swift
//  DayLight Dose
//
//  Created by Mayank Verma on 15/07/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var isAnimating = false
    @State private var showingOnboarding = false
    @State private var currentGradientColors: [Color] = []
    
    var body: some View {
        ZStack {
            backgroundGradient
            VStack(spacing: 40) {
                Spacer()
                // App icon and title
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: isAnimating)
                    }
                    VStack(spacing: 8) {
                        Text("DayLight Dose")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Your Vitamin D Companion")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                // Features preview
                VStack(spacing: 16) {
                    FeatureRow(icon: "location.fill", text: "Real-time UV tracking")
                    FeatureRow(icon: "person.fill", text: "Personalized recommendations")
                    FeatureRow(icon: "heart.fill", text: "Health insights")
                }
                .padding(.horizontal, 40)
                Spacer()
                // Get started button
                Button(action: {
                    showingOnboarding = true
                }) {
                    HStack {
                        Text("Get Started")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(30)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                Spacer()
            }
        }
        .onAppear {
            isAnimating = true
            currentGradientColors = gradientColors
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
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

struct FeatureRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            Text(text)
                .font(.body)
                .foregroundColor(.white)
            Spacer()
        }
    }
}

#Preview {
    WelcomeView()
}