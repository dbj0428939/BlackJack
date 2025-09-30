import SwiftUI
import Foundation
import GoogleMobileAds

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
    @State private var showBalance: Bool = false
    @State private var showButtons: Bool = false
    @State private var showAttribution: Bool = false
    @State private var showSpade: Bool = false
    @StateObject private var game = BlackjackGame()
    @State private var betAmount: Int = 0
    
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
                    Spacer()
                    
                    
                    // Big Gold Spade (from loading screen)
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 150
                                )
                            )
                            .frame(width: 300, height: 300)
                            .scaleEffect(acePulse)
                        
                        // Gold spade
                        Image(systemName: "suit.spade.fill")
                            .font(.system(size: 120))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.84, blue: 0.0), // Gold
                                        Color(red: 0.9, green: 0.7, blue: 0.0),  // Darker gold
                                        Color(red: 1.0, green: 0.84, blue: 0.0)  // Gold
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6), radius: 12, x: 0, y: 6)
                            .scaleEffect(acePulse)
                    }
                    .opacity(showSpade ? 0.6 : 0) // Make it subtle as background element
                    .scaleEffect(showSpade ? 1.0 : 0.96)
                    .offset(y: 50) // Position it slightly lower
                    .animation(.spring(response: 0.7, dampingFraction: 0.9), value: showSpade)
                    
                    Spacer()
                    
                    // Menu Content
                    VStack(spacing: 24) {
                        // Title
                        VStack(spacing: 8) {
                            Text("SpadeBet")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.84, blue: 0.0),
                                            Color(red: 1.0, green: 0.9, blue: 0.3),
                                            Color(red: 1.0, green: 0.84, blue: 0.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6), radius: 8, x: 0, y: 4)
                                .overlay(
                                    Text("SpadeBet")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.8),
                                                    Color.white.opacity(0.3),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .blendMode(.overlay)
                                )
                            
                            Text("Blackjack")
                                .font(.system(size: 32, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.9), value: showTitle)
                        
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
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
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
                                        InterstitialAdManager.shared.showAdIfAvailable()
                                        
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
                    
                    // Banner Ad
                    BannerAdView()
                        .frame(width: 320, height: 50)
                        .padding(.bottom, 20)
                }
            }
        }
        .overlay(
            Group {
                if showPlayTransition {
                    ZStack {
                        // Dimmed backdrop
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                        
                        // Subtle glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.20),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 140
                                )
                            )
                            .frame(width: 260, height: 260)
                            .scaleEffect(playZoom ? 1.15 : 0.9)
                            .animation(.easeInOut(duration: 0.65), value: playZoom)
                        
                        // Gold spade zoom
                        Image(systemName: "suit.spade.fill")
                            .font(.system(size: 110))
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
                            .shadow(color: .yellow.opacity(0.25), radius: 10)
                            .scaleEffect(playZoom ? 5.8 : 0.92)
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
        // Start subtle pulsing animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            acePulse = 1.1
        }
        
        // Staggered entrances for smoother feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                showSpade = true
            }
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
