import SwiftUI

struct LoadingView: View {
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowIntensity: CGFloat = 0.5 // Reduced baseline intensity
    @State private var backgroundOpacity: Double = 1.0
    @State private var isActive = false
    @State private var showTransition = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Base purple gradient matching BlueTableBackground
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
                .ignoresSafeArea()
                
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
                    .ignoresSafeArea()
                
                // Floating card suits in background
                ForEach(0..<12, id: \.self) { i in
                    let suits = ["suit.spade", "suit.heart", "suit.diamond", "suit.club"]
                    let suit = suits[i % suits.count]
                    let size = CGFloat.random(in: 20...50)
                    let xOffset = CGFloat.random(in: -200...200)
                    let yOffset = CGFloat.random(in: -400...400)
                    let delay = Double(i) * 0.2
                    let duration = Double.random(in: 8...12)
                    
                    Image(systemName: suit)
                        .font(.system(size: size))
                        .foregroundColor(Color.white.opacity(0.1))
                        .offset(x: xOffset, y: yOffset)
                        .rotationEffect(.degrees(rotation * 2))
                        .animation(
                            Animation.linear(duration: duration)
                                .repeatForever(autoreverses: false)
                                .delay(delay),
                            value: rotation
                        )
                }
                
                // Spade will be added as a centered overlay below (keeps backgrounds/layout separate)
                
                NavigationLink(
                    destination: MainMenuView().navigationBarHidden(true),
                    isActive: $isActive,
                    label: { EmptyView() }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .overlay(
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.yellow.opacity(0.12 * glowIntensity),
                                    Color.orange.opacity(0.06 * glowIntensity),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)

                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: 96))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0),
                                    Color(red: 0.8, green: 0.5, blue: 0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .yellow.opacity(0.15), radius: 4, x: 0, y: 0)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(showTransition ? 6.0 : 1.0)
                        .opacity(showTransition ? 0 : 1.0)
                        .animation(Animation.linear(duration: 8).repeatForever(autoreverses: false), value: rotation)
                        .animation(.easeInOut(duration: 0.9), value: showTransition)
                }
                .frame(width: 140, height: 140)
                .opacity(backgroundOpacity)
                .onAppear(perform: startLoadingAnimation),
                alignment: .center
            )
            .navigationBarHidden(true)
        }
        .statusBar(hidden: true)
        .edgesIgnoringSafeArea(.all)
    }
    
    private func startLoadingAnimation() {
        // Start rotation after layout is settled to avoid initial top-left placement
        DispatchQueue.main.async {
            withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        
        // Simulate loading time (slightly longer), then perform zoom transition before navigating
        let loadingDelay: TimeInterval = 3.2
        let transitionDuration: TimeInterval = 0.9
        
        DispatchQueue.main.asyncAfter(deadline: .now() + loadingDelay) {
            // Zoom and fade the spade + background
            withAnimation(.easeInOut(duration: transitionDuration)) {
                showTransition = true
                backgroundOpacity = 0.0
            }
            // Navigate after the transition completes
            DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) {
                isActive = true
            }
        }
    }
}

#Preview {
    LoadingView()
}
