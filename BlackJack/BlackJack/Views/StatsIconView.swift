//
//  StatsIconView.swift
//  BlackJack
//
//  Created by Trae AI on 1/14/25.
//

import SwiftUI

struct StatsIconView: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Bar chart icon using SF Symbols
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(Color(white: 0.7))
            }
            .padding(10)
            .background(Color.black.opacity(0.5))
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// Custom bar chart icon for more detailed visualization
struct CustomBarChartIcon: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Custom bar chart design
                HStack(spacing: 2) {
                    // Bar 1 (shortest)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: 0.7))
                        .frame(width: 3, height: 8)
                    
                    // Bar 2 (medium)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: 0.7))
                        .frame(width: 3, height: 12)
                    
                    // Bar 3 (tallest)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: 0.7))
                        .frame(width: 3, height: 16)
                    
                    // Bar 4 (medium-high)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: 0.7))
                        .frame(width: 3, height: 14)
                }
                .frame(width: 20, height: 20)
            }
            .padding(10)
            .background(Color.black.opacity(0.5))
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.18), radius: 6, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    HStack(spacing: 20) {
        StatsIconView {
            print("Stats tapped")
        }
        
        CustomBarChartIcon {
            print("Custom stats tapped")
        }
    }
    .padding()
    .background(Color.blue)
}