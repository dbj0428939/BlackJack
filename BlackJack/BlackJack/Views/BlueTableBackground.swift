import SwiftUI

public struct BlueTableBackground: View {
    let showTableDesigns: Bool
    @State private var animateParticles = false
    @State private var animateWave = false
    @State private var animateTableElements = false
    
    public init(showTableDesigns: Bool = false) {
        self.showTableDesigns = showTableDesigns
    }
    
    public var body: some View {
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
            
            // Borders removed
            
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
            
            // Blackjack table design elements (only during gameplay)
            if showTableDesigns {
                BlackjackTableDesign(animate: animateTableElements)
            }
            
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

struct BlackjackTableDesign: View {
    let animate: Bool
    @State private var rotateChips = false
    @State private var pulseElements = false
    
    var body: some View {
        ZStack {
            // Casino table corner decorations
            ForEach(0..<4, id: \.self) { corner in
                VStack {
                    HStack {
                        // Top-left corner
                        if corner == 0 {
                            CasinoCornerDecoration()
                                .offset(x: -150, y: -200)
                        }
                        Spacer()
                        // Top-right corner
                        if corner == 1 {
                            CasinoCornerDecoration()
                                .offset(x: 150, y: -200)
                        }
                    }
                    Spacer()
                    HStack {
                        // Bottom-left corner
                        if corner == 2 {
                            CasinoCornerDecoration()
                                .offset(x: -150, y: 200)
                        }
                        Spacer()
                        // Bottom-right corner
                        if corner == 3 {
                            CasinoCornerDecoration()
                                .offset(x: 150, y: 200)
                        }
                    }
                }
            }
            
            // Table center design
            VStack {
                // "BLACKJACK" text at top
                Text("BLACKJACK")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3))
                    .tracking(3)
                    .offset(y: -300)
                    .scaleEffect(pulseElements ? 1.02 : 0.98)
                    .animation(
                        .easeInOut(duration: 4.0)
                        .repeatForever(autoreverses: true),
                        value: pulseElements
                    )
                
                Spacer()
                
                // "PAYS 3 TO 2" text at bottom
                Text("PAYS 3 TO 2")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2))
                    .tracking(2)
                    .offset(y: 300)
                    .scaleEffect(pulseElements ? 1.01 : 0.99)
                    .animation(
                        .easeInOut(duration: 3.5)
                        .repeatForever(autoreverses: true),
                        value: pulseElements
                    )
            }
            
            // Subtle betting circles in background
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1),
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                    .offset(
                        x: CGFloat([-80, 0, 80][i]),
                        y: CGFloat([200, 250, 200][i])
                    )
                    .scaleEffect(pulseElements ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.5),
                        value: pulseElements
                    )
            }
            
            // Card suit decorations around the table
            ForEach([0, 1, 2, 3, 4, 5, 6, 7], id: \.self) { i in
                let suits = ["suit.heart.fill", "suit.diamond.fill", "suit.club.fill", "suit.spade.fill"]
                let suit = suits[i % 4]
                let angles: [CGFloat] = [0, 45, 90, 135, 180, 225, 270, 315]
                let radius: CGFloat = 250
                
                Image(systemName: suit)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.15))
                    .offset(
                        x: cos(angles[i] * .pi / 180) * radius,
                        y: sin(angles[i] * .pi / 180) * radius
                    )
                    .rotationEffect(.degrees(angles[i]))
                    .scaleEffect(pulseElements ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 2.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.2),
                        value: pulseElements
                    )
            }

        }
        .onAppear {
            if animate {
                rotateChips = true
                pulseElements = true
            }
        }
    }
}

struct CasinoCornerDecoration: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Outer gold ring
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0),
                            Color(red: 0.8, green: 0.6, blue: 0.0),
                            Color(red: 1.0, green: 0.84, blue: 0.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 60, height: 60)
                .scaleEffect(animate ? 1.1 : 0.9)
                .opacity(0.6)
            
            // Inner diamond
            TableDiamond()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8),
                            Color(red: 0.8, green: 0.6, blue: 0.0).opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(animate ? 360 : 0))
            
            // Center dot
            Circle()
                .fill(Color(red: 1.0, green: 0.84, blue: 0.0))
                .frame(width: 8, height: 8)
                .scaleEffect(animate ? 1.3 : 0.7)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

struct TableDiamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: width, y: height * 0.5))
        path.addLine(to: CGPoint(x: width * 0.5, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 0.5))
        path.closeSubpath()
        
        return path
    }
}



struct FeltTexturePattern: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Horizontal lines
                ForEach(0..<Int(height / 20), id: \.self) { i in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.05),
                                    Color.clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .offset(y: CGFloat(i * 20) - height / 2)
                }
                
                // Vertical lines
                ForEach(0..<Int(width / 20), id: \.self) { i in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.03),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1)
                        .offset(x: CGFloat(i * 20) - width / 2)
                }
            }
        }
    }
}

struct AnimatedParticle: View {
    let index: Int
    let animate: Bool
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    @State private var size: CGFloat = 3
    
    var body: some View {
        Circle()
            .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1))
            .frame(width: size, height: size)
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                // Set initial random values
                size = CGFloat.random(in: 2...6)
                xOffset = CGFloat.random(in: -100...100)
                yOffset = CGFloat.random(in: -200...200)
                
                // Start animation
                withAnimation(
                    .easeInOut(duration: Double.random(in: 4...8))
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.3)
                ) {
                    xOffset = CGFloat.random(in: -200...200)
                    yOffset = CGFloat.random(in: -400...400)
                }
            }
    }
}
