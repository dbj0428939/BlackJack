//
//  SettingsIconView.swift
//  BlackJack
//
//  Created by Trae AI on 1/14/25.
//

import SwiftUI

struct SettingsIconView: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Settings gear icon using SF Symbols
                Image(systemName: "gearshape.fill")
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

#Preview {
    HStack(spacing: 20) {
        SettingsIconView {
            print("Settings tapped")
        }
    }
    .padding()
    .background(Color.blue)
}
