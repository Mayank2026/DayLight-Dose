//
//  CustomLineChart.swift
//  UITest
//
//  Created by Avineet Singh on 12/12/25.
//

import SwiftUI

// Custom Line Chart View
struct CustomLineChart: View {
    let data: [MemberStats]
    let height: CGFloat
    @Binding var selectedMonth: MemberStats?
    
    // Animation state
    @State private var animatedData: [MemberStats] = []
    @State private var animationProgress: Double = 1.0 // 0 = at zero, 1 = at target
    @State private var animationPhase: AnimationPhase = .idle
    @State private var previousData: [MemberStats] = []
    @State private var targetData: [MemberStats] = [] // Store target data for Phase 2 without updating animatedData immediately
    @State private var isInitialized: Bool = false
    @State private var animationTask: Task<Void, Never>?
    @State private var isAnimating: Bool = false // Flag to prevent duplicate animations
    @State private var lastAnimatedValues: [Double] = [] // Track last animated values to prevent duplicates
    @State private var pendingAnimationTask: Task<Void, Never>? // Debounce task
    
    enum AnimationPhase {
        case idle
        case goingToZero
        case goingToTarget
    }
    
    // Easing function for smooth animation
    private func easeInOutCubic(_ t: Double) -> Double {
        return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
    
    // Helper to create mask gradient stops
    private func createMaskGradientStops(chartHeight: CGFloat, height: CGFloat) -> [Gradient.Stop] {
        return [
            .init(color: .white.opacity(0.7), location: 0.0),
            .init(color: .white.opacity(0.68), location: (chartHeight * 0.1) / height),
            .init(color: .white.opacity(0.65), location: (chartHeight * 0.2) / height),
            .init(color: .white.opacity(0.62), location: (chartHeight * 0.25) / height),
            .init(color: .white.opacity(0.58), location: (chartHeight * 0.3) / height),
            .init(color: .white.opacity(0.55), location: (chartHeight * 0.4) / height),
            .init(color: .white.opacity(0.52), location: (chartHeight * 0.5) / height),
            .init(color: .white.opacity(0.48), location: (chartHeight * 0.6) / height),
            .init(color: .white.opacity(0.45), location: (chartHeight - 10) / height),
            .init(color: .white.opacity(0.42), location: (chartHeight - 7.5) / height),
            .init(color: .white.opacity(0.38), location: (chartHeight - 5) / height),
            .init(color: .white.opacity(0.35), location: (chartHeight - 2.5) / height),
            .init(color: .white.opacity(0.30), location: chartHeight / height),
            .init(color: .white.opacity(0.28), location: (chartHeight + 2) / height),
            .init(color: .white.opacity(0.25), location: (chartHeight + 4) / height),
            .init(color: .white.opacity(0.23), location: (chartHeight + 6) / height),
            .init(color: .white.opacity(0.20), location: (chartHeight + 8) / height),
            .init(color: .white.opacity(0.18), location: (chartHeight + 10) / height),
            .init(color: .white.opacity(0.15), location: (chartHeight + 12) / height),
            .init(color: .white.opacity(0.13), location: (height - 10) / height),
            .init(color: .white.opacity(0.10), location: (height - 8) / height),
            .init(color: .white.opacity(0.09), location: (height - 6) / height),
            .init(color: .white.opacity(0.08), location: (height - 4) / height),
            .init(color: .white.opacity(0.06), location: (height - 2) / height),
            .init(color: .white.opacity(0.05), location: 1.0)
        ]
    }
    
    // Helper to create chart gradient stops
    private func createChartGradientStops() -> [Gradient.Stop] {
        return [
            // Soft grey gradient for the area fill under the line
            .init(color: Color.white.opacity(0.22), location: 0.0),
            .init(color: Color.white.opacity(0.10), location: 0.5),
            .init(color: Color.white.opacity(0.04), location: 1.0)
        ]
    }
    
    // Generate interpolated points for smoother line using animated data
    private var interpolatedPoints: [(x: Double, y: Double)] {
        let dataSource = animationPhase == .goingToZero ? previousData : animatedData
        guard dataSource.count > 1 else { return [] }
        
        var points: [(x: Double, y: Double)] = []
        let interpolationSteps = 10 // Number of points between each month
        
        for i in 0..<dataSource.count - 1 {
            let startValue = dataSource[i].value
            let endValue = dataSource[i + 1].value
            let startX = Double(i)
            let endX = Double(i + 1)
            
            // Add the start point
            if i == 0 {
                points.append((x: startX, y: startValue))
            }
            
            // Interpolate between start and end
            for step in 1...interpolationSteps {
                let t = Double(step) / Double(interpolationSteps)
                let x = startX + (endX - startX) * t
                // Use smooth interpolation (ease-in-out)
                let smoothT = t * t * (3.0 - 2.0 * t)
                let y = startValue + (endValue - startValue) * smoothT
                points.append((x: x, y: y))
            }
        }
        
        return points
    }
    
    private var minValue: Double {
        0 // Always use 0 as minimum
    }
    
    private var maxValue: Double {
        let dataSource = animationPhase == .goingToZero ? previousData : animatedData
        return (dataSource.isEmpty ? data : dataSource).map { $0.value }.max() ?? 1
    }
    
    private var valueRange: Double {
        maxValue - minValue // Will be maxValue since minValue is 0
    }
    
    private func linePath(width: CGFloat, chartHeight: CGFloat) -> Path {
        // Use the appropriate data source based on animation phase
        let dataSource: [MemberStats]
        let valuesToAnimate: [Double]
        
        if animationPhase == .goingToZero {
            dataSource = previousData.isEmpty ? animatedData : previousData
            valuesToAnimate = dataSource.map { $0.value }
        } else if animationPhase == .goingToTarget {
            // During Phase 2, use targetData for the target values, but keep previousData structure
            // We'll interpolate between 0 (from previousData) and targetData values
            dataSource = targetData.isEmpty ? (animatedData.isEmpty ? data : animatedData) : targetData
            valuesToAnimate = dataSource.map { $0.value }
        } else {
            dataSource = animatedData.isEmpty ? data : animatedData
            valuesToAnimate = dataSource.map { $0.value }
        }
        
        guard dataSource.count > 1 else { return Path() }
        
        let totalRange = Double(dataSource.count - 1)
        guard totalRange > 0 else { return Path() }
        let stepX = width / CGFloat(totalRange)
        
        var pathPoints: [CGPoint] = []
        let interpolationSteps = 10
        
        // Generate points with animation applied
        for i in 0..<dataSource.count - 1 {
            let startValue = valuesToAnimate[i]
            let endValue = valuesToAnimate[i + 1]
            let startX = Double(i)
            let endX = Double(i + 1)
            
                // Add the start point
                if i == 0 {
                    let animatedStartValue: Double
                    if animationPhase == .goingToZero {
                        // animationProgress: 0.0 = old values, 1.0 = zero
                        animatedStartValue = startValue * (1.0 - animationProgress)
                    } else if animationPhase == .goingToTarget {
                        // animationProgress: 0.0 = zero, 1.0 = target values
                        animatedStartValue = startValue * animationProgress
                    } else {
                        animatedStartValue = startValue
                    }
                
                let currentMaxValue = valuesToAnimate.max() ?? 1
                let normalizedValue = currentMaxValue > 0 ? animatedStartValue / currentMaxValue : 0
                let y = chartHeight - (normalizedValue * chartHeight)
                pathPoints.append(CGPoint(x: CGFloat(startX) * stepX, y: y))
            }
            
            // Interpolate between start and end
            for step in 1...interpolationSteps {
                let t = Double(step) / Double(interpolationSteps)
                let x = startX + (endX - startX) * t
                let smoothT = t * t * (3.0 - 2.0 * t)
                let baseValue = startValue + (endValue - startValue) * smoothT
                
                // Apply animation progress
                let animatedValue: Double
                if animationPhase == .goingToZero {
                    // animationProgress: 0.0 = old values (baseValue), 1.0 = zero (0)
                    animatedValue = baseValue * (1.0 - animationProgress)
                } else if animationPhase == .goingToTarget {
                    // animationProgress: 0.0 = zero (0), 1.0 = target values (baseValue)
                    animatedValue = baseValue * animationProgress
                } else {
                    animatedValue = baseValue
                }
                
                let currentMaxValue = valuesToAnimate.max() ?? 1
                let normalizedValue = currentMaxValue > 0 ? animatedValue / currentMaxValue : 0
                let y = chartHeight - (normalizedValue * chartHeight)
                pathPoints.append(CGPoint(x: CGFloat(x) * stepX, y: y))
            }
        }
        
        var pathResult = Path()
        pathResult.move(to: pathPoints[0])
        
        // Create smooth curve using Catmull-Rom style interpolation
        for i in 1..<pathPoints.count {
            let previousPoint = pathPoints[i - 1]
            let currentPoint = pathPoints[i]
            
            if i == 1 {
                // First segment: use simple curve
                let controlPoint = CGPoint(
                    x: (previousPoint.x + currentPoint.x) / 2,
                    y: (previousPoint.y + currentPoint.y) / 2
                )
                pathResult.addQuadCurve(to: currentPoint, control: controlPoint)
            } else if i < pathPoints.count - 1 {
                // Middle segments: use smoother curves
                let nextPoint = pathPoints[i + 1]
                let controlPoint1 = CGPoint(
                    x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.5,
                    y: previousPoint.y + (currentPoint.y - previousPoint.y) * 0.5
                )
                let controlPoint2 = CGPoint(
                    x: currentPoint.x - (nextPoint.x - currentPoint.x) * 0.5,
                    y: currentPoint.y - (nextPoint.y - currentPoint.y) * 0.5
                )
                pathResult.addCurve(to: currentPoint, control1: controlPoint1, control2: controlPoint2)
            } else {
                // Last segment
                let controlPoint = CGPoint(
                    x: (previousPoint.x + currentPoint.x) / 2,
                    y: (previousPoint.y + currentPoint.y) / 2
                )
                pathResult.addQuadCurve(to: currentPoint, control: controlPoint)
            }
        }
        
        return pathResult
    }
    
    private func areaPath(width: CGFloat, chartHeight: CGFloat) -> Path {
        var path = linePath(width: width, chartHeight: chartHeight)
        
        // Close the path to create area
        path.addLine(to: CGPoint(x: width, y: chartHeight))
        path.addLine(to: CGPoint(x: 0, y: chartHeight))
        path.closeSubpath()
        
        return path
    }
    
    private func createExtendedAreaPath(width: CGFloat, fullHeight: CGFloat, chartHeight: CGFloat) -> Path {
        // Extend the area path from chartHeight to fullHeight
        var path = linePath(width: width, chartHeight: chartHeight)
        
        // Extend down to full height
        path.addLine(to: CGPoint(x: width, y: fullHeight))
        path.addLine(to: CGPoint(x: 0, y: fullHeight))
        path.closeSubpath()
        
        return path
    }
    
    
    // Get position of selected month point
    private func getSelectedPointPosition(width: CGFloat, chartHeight: CGFloat, month: MemberStats) -> CGPoint? {
        let dataSource: [MemberStats]
        if animationPhase == .goingToZero {
            dataSource = previousData.isEmpty ? animatedData : previousData
        } else if animationPhase == .goingToTarget {
            dataSource = targetData.isEmpty ? animatedData : targetData
        } else {
            dataSource = animatedData.isEmpty ? data : animatedData
        }
        guard let index = dataSource.firstIndex(where: { $0.month == month.month }) else { return nil }
        
        // Match the month label positioning: each month gets equal space
        let stepX = width / CGFloat(dataSource.count)
        // Center the point in the month's space
        let x = (CGFloat(index) + 0.5) * stepX
        
        // Apply animation to the selected month's value
        let animatedValue: Double
        if animationPhase == .goingToZero {
            animatedValue = month.value * (1.0 - animationProgress)
        } else if animationPhase == .goingToTarget {
            animatedValue = month.value * animationProgress
        } else {
            animatedValue = month.value
        }
        
        let currentMaxValue = dataSource.map { $0.value }.max() ?? 1
        let currentValueRange = currentMaxValue - minValue
        let normalizedValue = currentValueRange > 0 ? (animatedValue - minValue) / currentValueRange : 0
        let y = chartHeight - (normalizedValue * chartHeight)
        
        return CGPoint(x: x, y: y)
    }
    
    // Helper function to create extended area path
    private func createExtendedAreaPath(from linePath: Path, width: CGFloat, height: CGFloat) -> Path {
        var extendedPath = linePath
        extendedPath.addLine(to: CGPoint(x: width, y: height))
        extendedPath.addLine(to: CGPoint(x: 0, y: height))
        extendedPath.closeSubpath()
        return extendedPath
    }
    
    // Helper view for the area fill
    @ViewBuilder
    private func areaFillView(cachedLinePath: Path, width: CGFloat, chartHeight: CGFloat) -> some View {
        let extendedAreaPath = createExtendedAreaPath(from: cachedLinePath, width: width, height: height)
        let chartGradientStops = createChartGradientStops()
        let maskGradientStops = createMaskGradientStops(chartHeight: chartHeight, height: height)
        
        extendedAreaPath
            .fill(
                LinearGradient(
                    stops: chartGradientStops,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
            .transaction { transaction in
                transaction.animation = nil
            }
            .mask(
                ChartMaskShape(
                    linePath: cachedLinePath,
                    fullHeight: height,
                    cornerRadius: 12
                )
                .fill(
                    LinearGradient(
                        stops: maskGradientStops,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
    }
    
    // Helper view for the line stroke
    @ViewBuilder
    private func lineStrokeView(cachedLinePath: Path, chartHeight: CGFloat) -> some View {
        cachedLinePath
            .stroke(
                Color.white,
                style: StrokeStyle(lineWidth: 3, lineJoin: .round)
            )
            .frame(height: chartHeight)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
    
    // Helper view for tooltip and lines
    @ViewBuilder
    private func tooltipView(width: CGFloat, chartHeight: CGFloat) -> some View {
        if let selected = selectedMonth,
           let pointPos = getSelectedPointPosition(width: width, chartHeight: chartHeight, month: selected) {
            // Line 1: Above tooltip with gradient (white to transparent white)
            let lineStartY = pointPos.y - 25
            let lineAboveHeight = pointPos.y - lineStartY
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: lineAboveHeight))
            }
            .stroke(
                LinearGradient(
                    stops: [
                        .init(color: Color.white, location: 0.0),
                        .init(color: Color.white.opacity(0.1), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
            .frame(width: 1, height: lineAboveHeight)
            .position(x: pointPos.x, y: pointPos.y - lineAboveHeight / 2)
            .frame(height: chartHeight)
            
            // Line 2: Below tooltip (solid soft white)
            Path { path in
                path.move(to: CGPoint(x: pointPos.x, y: pointPos.y))
                path.addLine(to: CGPoint(x: pointPos.x, y: chartHeight))
            }
            .stroke(Color.white.opacity(0.6), lineWidth: 1)
            .frame(height: chartHeight)
            
            // Tooltip (white capsule with dark text) positioned at the line
            RollingNumberView(
                value: "\(Int(selected.value))",
                font: .caption.bold(),
                textColor: .black
            )
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(Color.white)
                )
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                .position(x: pointPos.x, y: pointPos.y)
        }
    }
    
    // Helper view for month labels
    @ViewBuilder
    private func monthLabelsView(monthLabelsDataSource: [MemberStats], stepX: CGFloat) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                ForEach(monthLabelsDataSource.isEmpty ? data : monthLabelsDataSource) { item in
                    let isSelected = selectedMonth?.month == item.month
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                .frame(width: stepX - 12, height: 20)
                        }
                        Text(item.month)
                            .font(isSelected ? .system(size: 11, weight: .bold) : .system(size: 11))
                            // Selected month stays black on white pill, others use soft white like other labels
                            .foregroundColor(isSelected ? .black : .white.opacity(0.6))
                    }
                    .frame(width: stepX, alignment: .center)
                }
            }
            .frame(height: 24)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let chartHeight = height - 30
            let stepX = width / CGFloat(data.count)
            
            // Force view updates during animation by including animation state
            let _ = animationProgress
            let _ = animationPhase
            
            // Compute data source for month labels
            let monthLabelsDataSource: [MemberStats] = {
                if animationPhase == .goingToZero {
                    return previousData.isEmpty ? animatedData : previousData
                } else if animationPhase == .goingToTarget {
                    return targetData.isEmpty ? animatedData : targetData
                } else {
                    return animatedData.isEmpty ? data : animatedData
                }
            }()
            
            // Compute path once per frame and reuse it
            let cachedLinePath = linePath(width: width, chartHeight: chartHeight)
            
            ZStack(alignment: .topLeading) {
                areaFillView(cachedLinePath: cachedLinePath, width: width, chartHeight: chartHeight)
                lineStrokeView(cachedLinePath: cachedLinePath, chartHeight: chartHeight)
                tooltipView(width: width, chartHeight: chartHeight)
                monthLabelsView(monthLabelsDataSource: monthLabelsDataSource, stepX: stepX)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Match the month label positioning: each month gets equal space
                        let stepX = width / CGFloat(data.count)
                        
                        // Find which month was tapped
                        let tappedIndex = Int(value.location.x / stepX)
                        if tappedIndex >= 0 && tappedIndex < data.count {
                            // Only update if the month actually changed to avoid unnecessary redraws
                            if selectedMonth?.month != data[tappedIndex].month {
                                // Update immediately without animation for responsive dragging
                                selectedMonth = data[tappedIndex]
                            }
                        }
                    }
            )
        }
        .frame(height: height)
        .onAppear {
            // Initialize animated data
            if !isInitialized {
                animatedData = data
                previousData = data
                lastAnimatedValues = data.map { $0.value } // Initialize with current data
                isInitialized = true
                
                // Default to June (index 5) as shown in reference image only if no month is selected
                if selectedMonth == nil && data.count > 5 {
                    selectedMonth = data[5] // June
                } else if selectedMonth == nil {
                    selectedMonth = data.last
                } else {
                    // Update selectedMonth to match the new data when tab changes, preserving the month name
                    if let currentMonth = selectedMonth?.month,
                       let matchingMonth = data.first(where: { $0.month == currentMonth }) {
                        selectedMonth = matchingMonth
                    }
                }
            }
        }
        .onChange(of: data) { oldData, newData in
            let oldValues = oldData.map { $0.value }
            let newValues = newData.map { $0.value }
            
            // Skip animation on initial setup
            guard isInitialized else {
                animatedData = newData
                previousData = newData
                lastAnimatedValues = newData.map { $0.value }
                return
            }
            
            // Check if data actually changed by comparing values
            guard oldValues != newValues else {
                // Data values are the same, just update references
                animatedData = newData
                previousData = newData
                lastAnimatedValues = newValues
                return
            }
            
            // CRITICAL: Prevent duplicate animations - check multiple conditions
            // 1. Not currently animating
            // 2. Not in the middle of an animation phase
            // 3. New values are different from what we're currently animating to
            guard !isAnimating,
                  animationPhase == .idle,
                  newValues != lastAnimatedValues else {
                // Already animating or same data, skip completely
                return
            }
            
            // Cancel any pending animation tasks
            pendingAnimationTask?.cancel()
            animationTask?.cancel()
            
            // Use a debounced task to handle rapid onChange calls
            pendingAnimationTask = Task { @MainActor in
                // Small delay to catch any duplicate onChange calls
                try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
                
                // Double-check conditions after delay
                guard !isAnimating,
                      animationPhase == .idle,
                      newData.map({ $0.value }) != lastAnimatedValues else {
                    return
                }
                
                // IMMEDIATELY mark that we're starting an animation (before any async work)
                isAnimating = true
                // Don't update lastAnimatedValues here - wait until animation completes
                // This prevents blocking if onChange is called again during animation
                
                // Phase 1: Animate to zero
                previousData = animatedData
                animationPhase = .goingToZero
                animationProgress = 0.0 // Start at 0.0 = show old values, will go to 1.0 = show zero
                
                // Use Task to handle async animation with manual progress updates
                animationTask = Task { @MainActor in
                // Double-check we're not cancelled before starting
                guard !Task.isCancelled else {
                    isAnimating = false
                    return
                }
                
                // Phase 1: Animate to zero (0.28 seconds - 30% faster than original 0.4s)
                // animationProgress goes from 0.0 (show old values) to 1.0 (show zero)
                let phase1Duration: Double = 0.28
                let phase1Steps = 28
                let phase1StepDuration = phase1Duration / Double(phase1Steps)
                
                for step in 0...phase1Steps {
                    guard !Task.isCancelled else {
                        isAnimating = false
                        return
                    }
                    let progress = Double(step) / Double(phase1Steps)
                    let easedProgress = easeInOutCubic(progress)
                    // animationProgress: 0.0 = old values, 1.0 = zero
                    animationProgress = easedProgress
                    
                    try? await Task.sleep(nanoseconds: UInt64(phase1StepDuration * 1_000_000_000))
                }
                
                guard !Task.isCancelled else {
                    isAnimating = false
                    return
                }
                
                animationProgress = 1.0 // At zero
                
                // Phase 2: Animate to new values
                
                // CRITICAL: Store target data WITHOUT updating animatedData yet
                // This prevents the view from recomputing with new data before we start animating
                await MainActor.run {
                    targetData = newData
                    animationPhase = .goingToTarget
                    // animationProgress stays at 1.0 (zero) - Phase 2 will animate from 0.0 to 1.0
                    // Keep animatedData as is (still has old values at zero) until animation completes
                }
                
                guard !Task.isCancelled else {
                    isAnimating = false
                    return
                }
                
                // Phase 2: Animate to target (0.42 seconds - 30% faster than original 0.6s)
                // animationProgress goes from 0.0 (zero) to 1.0 (target values)
                let phase2Duration: Double = 0.42
                let phase2Steps = 42
                let phase2StepDuration = phase2Duration / Double(phase2Steps)
                
                for step in 0...phase2Steps {
                    guard !Task.isCancelled else {
                        isAnimating = false
                        return
                    }
                    let progress = Double(step) / Double(phase2Steps)
                    let easedProgress = easeInOutCubic(progress)
                    // animationProgress: 0.0 = zero, 1.0 = target values
                    animationProgress = easedProgress
                    
                    try? await Task.sleep(nanoseconds: UInt64(phase2StepDuration * 1_000_000_000))
                }
                
                guard !Task.isCancelled else {
                    isAnimating = false
                    return
                }
                
                animationProgress = 1.0
                
                // NOW update animatedData to the final values after animation completes
                await MainActor.run {
                    animatedData = targetData
                    animationPhase = .idle
                    isAnimating = false // Mark animation as complete
                    lastAnimatedValues = targetData.map { $0.value }
                }
                }
            }
            
            // Update selectedMonth AFTER animation starts to avoid triggering another onChange
            // Use a small delay to ensure it doesn't interfere with the animation
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds delay
                if let currentMonth = selectedMonth?.month,
                   let matchingMonth = newData.first(where: { $0.month == currentMonth }) {
                    // Keep the same month if it exists in new data
                    selectedMonth = matchingMonth
                } else if selectedMonth == nil {
                    // Only set to last month if no month was previously selected
                    selectedMonth = newData.last
                }
            }
        }
        .onDisappear {
            pendingAnimationTask?.cancel()
            animationTask?.cancel()
            isAnimating = false
        }
    }
}

