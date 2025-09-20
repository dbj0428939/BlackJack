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
    @StateObject private var game = BlackjackGame()
    @State private var betAmount: Int = 0
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
                    .opacity(0.6) // Make it subtle as background element
                    .offset(y: 50) // Position it slightly lower
                    
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
                        .opacity(menuOpacity)
                        .offset(y: menuOffset)
                        
                        // Balance
                        HStack(spacing: 12) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            
                            Text("$\(String(format: "%.0f", gameState.balance))")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            Button(action: { showingAddFunds = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .opacity(menuOpacity)
                        .offset(y: menuOffset)
                        
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
                                        showingGame = true
                                    }
                                }
                            )
                            
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
                        }
                        .opacity(menuOpacity)
                        .offset(y: menuOffset)
                        
                        // Icons8 Attribution
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                            Link("Chip icons by Icons8", destination: URL(string: "https://icons8.com")!)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .opacity(menuOpacity)
                        .offset(y: menuOffset)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
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
        // Start with ace scaling
        withAnimation(.easeOut(duration: 1.5)) {
            aceScale = 1.0
        }
        
        // Start subtle pulsing animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            acePulse = 1.1
        }
        
        // After ace animation, show menu content
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                menuOffset = 0
                menuOpacity = 1.0
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isEnabled ? 
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2),
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1)
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isEnabled ? 
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4) :
                                Color.gray.opacity(0.3),
                                lineWidth: 1
                            )
                    )
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
