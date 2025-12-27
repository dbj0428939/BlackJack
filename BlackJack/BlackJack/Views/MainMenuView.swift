import SwiftUI
import Foundation

struct MainMenuView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showingAddFunds = false
    @StateObject private var storeManager = StoreManager()
    @State private var showingGame = false
    @State private var showingStats = false
    @State private var showingSettings = false
    @State private var isLoaded = false
    @State private var showContent = false
    @State private var acePulse: CGFloat = 1.0
    @State private var aceScale: CGFloat = 0.1
    @State private var menuOffset: CGFloat = 100
    @State private var menuOpacity: Double = 0
    @State private var showTitle: Bool = false
    @State private var shinePhase: CGFloat = -1.0
    @State private var shineGlow: CGFloat = 1.0
    @State private var showBalance: Bool = false
    @State private var showButtons: Bool = false
    @State private var showAttribution: Bool = false
    @State private var showSpade: Bool = false
    @State private var aceAnimate: Bool = false
    @State private var aceOffset: CGFloat = 0
    @StateObject private var game = BlackjackGame()
    @State private var betAmount: Int = 0
    @State private var showBlackjack: Bool = false
    @State private var blackjackPulse: Bool = false
    
    // Play Game transition state
    @State private var showPlayTransition: Bool = false
    @State private var playZoom: Bool = false
    
    let chipValues = [10, 25, 50, 100]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                BlueTableBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top-aligned title + ace strip — uses GeometryReader
                    // to apply padding that respects the device safe area.
                    GeometryReader { topGeo in
                        VStack(spacing: 10) {
                            VStack(spacing: 8) {
                                // Title with shimmer/shine overlay
                                Text("SpadeBet")
                                    .font(Font.custom("AvenirNext-Bold", size: 34))
                                    .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.30))
                                    .shadow(color: Color.yellow.opacity(0.22 * Double(shineGlow)), radius: 6 * shineGlow, x: 0, y: 0)
                                    .overlay(
                                        // stronger, wider moving highlight masked to the text
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: Color.white.opacity(0.0), location: 0.0),
                                                .init(color: Color.white.opacity(0.98), location: 0.5),
                                                .init(color: Color.white.opacity(0.0), location: 1.0)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        .rotationEffect(.degrees(20))
                                        .frame(width: 420, height: 56)
                                        .offset(x: shinePhase * 420)
                                        .blendMode(.screen)
                                        .mask(
                                            Text("SpadeBet")
                                                .font(Font.custom("AvenirNext-Bold", size: 34))
                                        )
                                    )
                                .opacity(showTitle ? 1 : 0)
                                .offset(y: showTitle ? 0 : 10)
                                .animation(.spring(response: 0.6, dampingFraction: 0.9), value: showTitle)
                                
                                // Blackjack appears last with a custom entrance animation
                                Text("Blackjack")
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.98))
                                    .scaleEffect(showBlackjack ? (blackjackPulse ? 1.04 : 1.0) : 0.8)
                                    .rotation3DEffect(.degrees(showBlackjack ? 0 : 20), axis: (x: 1, y: 0, z: 0))
                                    .offset(y: showBlackjack ? 0 : 30)
                                    .opacity(showBlackjack ? 1 : 0)
                                    .shadow(color: Color.black.opacity(showBlackjack ? 0.25 : 0.0), radius: 8, x: 0, y: 6)
                                    .animation(.interpolatingSpring(stiffness: 220, damping: 18), value: showBlackjack)
                                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: blackjackPulse)
                            }
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.9), value: showTitle)

                            // (ace strip relocated below, above balance box)
                        }
                        // Slightly larger safe-area offset so the title sits a bit lower
                        // and is visually centered between the notch and the ace strip.
                        .padding(.top, topGeo.safeAreaInsets.top + 94)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .onAppear {
                            // start a continuous left->right shine sweep
                            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                                shinePhase = 1.0
                            }
                            // subtle pulsing glow to emphasize the shine
                            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                                shineGlow = 1.25
                            }
                            // ensure Golden title shows early
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                                showTitle = true
                            }
                        }
                    }
                    .frame(height: 240)

                    Spacer()

                    // Menu Content
                    VStack(spacing: 24) {
                        // Title moved to top; menu content begins here
                        
                        // Ace strip placed directly above the balance box
                        GeometryReader { geo in
                            let aceWidth: CGFloat = 28
                            let aceSpacing: CGFloat = 36
                            let count = Int(ceil(geo.size.width / (aceWidth + aceSpacing))) + 6
                            let oneSetWidth = (aceWidth + aceSpacing) * CGFloat(count)

                            HStack(spacing: aceSpacing) {
                                ForEach(0..<(count * 2), id: \.self) { _ in
                                    Image(systemName: "suit.spade.fill")
                                        .font(.system(size: aceWidth))
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
                                        .shadow(color: .yellow.opacity(0.12), radius: 2)
                                }
                            }
                            .frame(width: geo.size.width * 1.0, height: 32, alignment: .leading)
                            .offset(x: aceOffset)
                            .clipped()
                            .onAppear {
                                aceOffset = 0
                                let duration = Double(oneSetWidth) / 30.0
                                withAnimation(Animation.linear(duration: duration).repeatForever(autoreverses: false)) {
                                    aceOffset = -oneSetWidth
                                }
                            }
                        }
                        .frame(height: 32)
                        .padding(.bottom, 8)

                        // Balance
                        HStack(spacing: 12) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.green)
                            
                            Text("$\(String(format: "%.0f", gameState.balance))")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            Button(action: { showingAddFunds = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.black.opacity(0.22))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.green.opacity(0.28), lineWidth: 1.2)
                                )
                        )
                        .frame(minWidth: 220)
                        .opacity(showBalance ? 1 : 0)
                        .offset(y: showBalance ? 0 : 10)
                        .scaleEffect(showBalance ? 1 : 0.98)
                        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: showBalance)
                        
                        // Menu Buttons
                        VStack(spacing: 16) {
                            // Play Game
                            ModernButton(
                                title: "Play Game",
                                icon: "play.fill",
                                isEnabled: gameState.balance > 0,
                                action: {
                                    if gameState.balance > 0 {
                                        SoundManager.shared.playButtonTap()
                                        // Interstitials disabled
                                        
                                        // Animate a quick branded transition before presenting the game
                                        showPlayTransition = true
                                        playZoom = false
                                        
                                        // Kick off zoom animation
                                        DispatchQueue.main.async {
                                            withAnimation(.easeInOut(duration: 0.65)) {
                                                playZoom = true
                                            }
                                        }
                                        
                                        // Present game after the transition completes
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) {
                                            showingGame = true
                                            // Reset transition state
                                            showPlayTransition = false
                                            playZoom = false
                                        }
                                    }
                                }
                            )
                            .opacity(showButtons ? 1 : 0)
                            .offset(y: showButtons ? 0 : 16)
                            .animation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.05), value: showButtons)
                            
                            // Statistics
                            ModernButton(
                                title: "Statistics",
                                icon: "chart.bar.fill",
                                isEnabled: true,
                                action: {
                                    SoundManager.shared.playButtonTap()
                                    showingStats = true
                                }
                            )
                            .opacity(showButtons ? 1 : 0)
                            .offset(y: showButtons ? 0 : 16)
                            .animation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.12), value: showButtons)
                            
                            // Settings
                            ModernButton(
                                title: "Settings",
                                icon: "gearshape.fill",
                                isEnabled: true,
                                action: {
                                    SoundManager.shared.playButtonTap()
                                    showingSettings = true
                                }
                            )
                            .opacity(showButtons ? 1 : 0)
                            .offset(y: showButtons ? 0 : 16)
                            .animation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.19), value: showButtons)
                        }
                        
                        // Icons8 Attribution
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                            Link("Chip icons by Icons8", destination: URL(string: "https://icons8.com")!)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .opacity(showAttribution ? 1 : 0)
                        .offset(y: showAttribution ? 0 : 8)
                        .animation(.easeOut(duration: 0.5), value: showAttribution)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    
                    // Banner area removed (ads disabled)
                }
            }
        }
        .overlay(
            Group {
                if showPlayTransition {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea()
                        Image(systemName: "suit.spade.fill")
                            .font(.system(size: 96))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.95, green: 0.82, blue: 0.30),
                                        Color(red: 0.80, green: 0.60, blue: 0.20)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .yellow.opacity(0.12), radius: 6)
                            .scaleEffect(playZoom ? 5.6 : 0.92)
                            .opacity(playZoom ? 0.0 : 1.0)
                            .animation(.easeInOut(duration: 0.65), value: playZoom)
                    }
                    .transition(.opacity)
                    .allowsHitTesting(false)
                }
            }
        )
        .sheet(isPresented: $showingAddFunds) {
            EnhancedAddFundsView()
                .environmentObject(gameState)
                .environmentObject(storeManager)
        }
        .fullScreenCover(isPresented: $showingGame) {
            GameView(game: game, initialBetAmount: betAmount).environmentObject(gameState)
        }
        .fullScreenCover(isPresented: $showingStats) {
            StatsView()
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            startLoadingAnimation()
        }
    }
    
    private func startLoadingAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            acePulse = 1.0 // keep minimal pulsing or remove
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                showTitle = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                showBalance = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) {
                showButtons = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
            withAnimation(.easeOut(duration: 0.5)) {
                showAttribution = true
            }
        }
        // Show the `Blackjack` title last with its entrance animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 18)) {
                showBlackjack = true
            }
            // start subtle repeating zoom/pulse after entrance completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    blackjackPulse = true
                }
            }
        }
    }
}

// MARK: - Modern Button Component
struct ModernButton: View {
    let title: String
    let icon: String
    let isEnabled: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if isEnabled {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    action()
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(isEnabled ? .white : .white.opacity(0.5))
            .frame(maxWidth: 280)
            .frame(height: 50)
            .background(
                ZStack {
                    // Main button background with deeper gold gradient
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isEnabled ?
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.25),
                                    Color(red: 0.8, green: 0.6, blue: 0.0).opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.2),
                                    Color.gray.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Outer gold border with shimmer effect
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isEnabled ?
                            Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8) :
                            Color.gray.opacity(0.3),
                            lineWidth: 1.5
                        )
                        .shadow(color: isEnabled ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
                }
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .disabled(!isEnabled)
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
            .environmentObject(GameState())
    }
}
