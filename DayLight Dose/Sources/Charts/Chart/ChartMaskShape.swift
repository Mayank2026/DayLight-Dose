//
//  ChartMaskShape.swift
//  UITest
//
//  Created by Avineet Singh on 12/12/25.
//

import SwiftUI

// Custom Shape for mask with rounded bottom corners only
struct ChartMaskShape: Shape {
    let linePath: Path
    let fullHeight: CGFloat
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = linePath
        
        // Add rounded corners only at the bottom
        let width = rect.width
        
        // Bottom right corner
        path.addLine(to: CGPoint(x: width, y: fullHeight - cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: width - cornerRadius, y: fullHeight),
            control: CGPoint(x: width, y: fullHeight)
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: cornerRadius, y: fullHeight))
        
        // Bottom left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: fullHeight - cornerRadius),
            control: CGPoint(x: 0, y: fullHeight)
        )
        
        // Close back to the start
        path.closeSubpath()
        
        return path
    }
}

