import SwiftUI

struct GameBackground: View {
    @State private var animateParticles = false
    @State private var animateWave = false
    @State private var animateTableElements = false
    
    var body: some View {
        ZStack {
            // Base purple gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.6),  // Rich purple
                    Color(red: 0.2, green: 0.1, blue: 0.4),  // Deep purple
                    Color(red: 0.1, green: 0.05, blue: 0.2)  // Very dark purple
                ]), 
                center: .center, 
                startRadius: 100, 
                endRadius: 600
            )
            
            // Gold table border
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0),  // Gold
                            Color(red: 0.8, green: 0.6, blue: 0.0),   // Darker gold
                            Color(red: 1.0, green: 0.84, blue: 0.0)   // Gold
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 8
                )
                .padding(20)
                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5), radius: 10, x: 0, y: 0)
            
            // Inner gold border
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6),
                    lineWidth: 2
                )
                .padding(35)
            
            // Table felt texture overlay
            Rectangle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 0.3, blue: 0.1).opacity(0.3),
                            Color(red: 0.0, green: 0.2, blue: 0.05).opacity(0.2)
                        ]),
                        center: .center,
                        startRadius: 200,
                        endRadius: 800
                    )
                )
                .blendMode(.overlay)
            
            // Subtle felt texture pattern
            FeltTexturePattern()
                .opacity(0.1)
                .blendMode(.overlay)
            
            // Blackjack table design elements
            BlackjackTableDesign(animate: animateTableElements)
            
            // Floating particles animation
            ForEach(0..<15, id: \.self) { i in
                AnimatedParticle(index: i, animate: animateParticles)
            }
            
            // Subtle wave overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color(red: 0.5, green: 0.3, blue: 0.7).opacity(0.05),  // Light purple wave
                    Color.clear
                ]),
                startPoint: animateWave ? .topLeading : .bottomTrailing,
                endPoint: animateWave ? .bottomTrailing : .topLeading
            )
            .animation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true), value: animateWave)
        }
        .ignoresSafeArea()
        .onAppear {
            animateParticles = true
            animateWave = true
            animateTableElements = true
        }
    }
}