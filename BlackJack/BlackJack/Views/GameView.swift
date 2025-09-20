import AVFoundation
import SwiftUI
import Foundation

// MARK: - Split Collapse Transition Overlay
struct SplitCollapseTransitionOverlay: View {
    let splitCollapseProgress: CGFloat
    
    var body: some View {
        VStack(spacing: 20) {
            // Collapse text with animation
            Text(collapseText)
                .font(.title2.bold())
                .foregroundColor(textColor)
                .opacity(textOpacity)
                .scaleEffect(textScale)
                .offset(y: -40)
            
            // Animated collapse effect
            HStack(spacing: 40) {
                // Left collapse line
                collapseLine
                
                // Center collapse indicator
                collapseIndicator
                
                // Right collapse line
                collapseLine
            }
            
            // Progress indicator
            progressText
        }
        .opacity(1.0)
        .animation(.easeInOut(duration: 1.0), value: splitCollapseProgress)
    }
    
    private var collapseText: String {
        splitCollapseProgress < 0.5 ? "COLLAPSING TO SINGLE HAND" : "RETURNING TO SINGLE HAND"
    }
    
    private var textColor: Color {
        splitCollapseProgress < 0.5 ? .cyan : .green
    }
    
    private var textOpacity: Double {
        1.0 - Double(abs(splitCollapseProgress - 0.5) * 2)
    }
    
    private var textScale: CGFloat {
        0.8 + (abs(splitCollapseProgress - 0.5) * 0.4)
    }
    
    private var collapseLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: lineColors),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2, height: 50)
            .scaleEffect(y: lineScale)
            .shadow(color: shadowColor, radius: 4)
    }
    
    private var collapseIndicator: some View {
        Circle()
            .fill(indicatorColor)
            .frame(width: 8, height: 8)
            .scaleEffect(indicatorScale)
            .shadow(color: shadowColor, radius: 4)
    }
    
    private var progressText: some View {
        Group {
            // Removed "Merging split hands..." text
            // Removed "Preparing single hand..." text
        }
    }
    
    private var lineColors: [Color] {
        splitCollapseProgress < 0.5 ? 
            [Color.cyan, Color.blue, Color.cyan] : 
            [Color.green, Color.mint, Color.green]
    }
    
    private var lineScale: CGFloat {
        splitCollapseProgress < 0.5 ? splitCollapseProgress * 2 : (1.0 - splitCollapseProgress) * 2
    }
    
    private var indicatorColor: Color {
        splitCollapseProgress < 0.5 ? Color.cyan : Color.green
    }
    
    private var indicatorScale: CGFloat {
        1.0 - (abs(splitCollapseProgress - 0.5) * 2)
    }
    
    private var shadowColor: Color {
        (splitCollapseProgress < 0.5 ? Color.cyan : Color.green).opacity(0.8)
    }
}

// MARK: - Split Hand Animation Modifier
struct SplitHandAnimationModifier: ViewModifier {
    let displayIndex: Int
    let showPlayerHands: Bool
    let isTransitioningFromSplit: Bool
    let splitCollapseProgress: CGFloat
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scaleValue)
            .opacity(opacityValue)
            .offset(x: offsetX, y: offsetY)
            .rotationEffect(.degrees(rotationValue))
            .animation(animationValue, value: animationTrigger)
    }
    
    private var scaleValue: CGFloat {
        if showPlayerHands {
            return isTransitioningFromSplit ? 0.1 : 1.0
        } else {
            return 0.2
        }
    }
    
    private var opacityValue: Double {
        if showPlayerHands {
            return isTransitioningFromSplit ? 0.0 : 1.0
        } else {
            return 0.0
        }
    }
    
    private var offsetX: CGFloat {
        if showPlayerHands {
            return isTransitioningFromSplit ? 0 : 0
        } else {
            return displayIndex == 0 ? -120 : 120
        }
    }
    
    private var offsetY: CGFloat {
        if showPlayerHands {
            return isTransitioningFromSplit ? -100 : 0
        } else {
            return -80
        }
    }
    
    private var rotationValue: Double {
        if showPlayerHands {
            return isTransitioningFromSplit ? 0 : 0
        } else {
            return displayIndex == 0 ? -25 : 25
        }
    }
    
    private var animationValue: Animation {
        if isTransitioningFromSplit {
            return .easeInOut(duration: 0.8)
        } else {
            return .spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3)
                .delay(Double(displayIndex) * 0.1)
        }
    }
    
    private var animationTrigger: AnyHashable {
        if isTransitioningFromSplit {
            return splitCollapseProgress
        } else {
            return showPlayerHands
        }
    }
}

struct GameView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var game: BlackjackGame
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var storeManager = StoreManager()
    let initialBetAmount: Int
    @State private var betAmount: Int
    @State private var dealt = false
    @State private var uiRefreshTrigger = false
    @State private var showBustMessage = false
    @State private var bustMessage = ""
    @State private var bustMessageTimer: Timer?
    @State private var isSplitTransitioning = false
    @State private var splitTransitionProgress: Double = 0.0
    @State private var showPlayerHands = true
    @State private var showingAddFunds = false
    @State private var showDealerCards = true
    @State private var dealerCardsOffset: CGFloat = 0
    @State private var showFirstSplitCards = false
    @State private var showSecondSplitCards = false
    @State private var splitDealingStep = 0 // 0: initial, 1: first cards shown, 2: second cards dealt
    @State private var playerDealtCount = 0
    @State private var dealerDealtCount = 0
    @State private var splitHandResults: [Int: (result: String, payout: Double)] = [:] // Track results for each split hand
    @State private var splitChipAnimations: [Int: Bool] = [:] // Track chip animations for each hand
    @State private var splitChipPositions: [Int: CGPoint] = [:] // Track chip positions for transfer animation
    @State private var splitHandMessages: [Int: String] = [:] // Track per-hand result messages
    @State private var splitMessageTimers: [Int: Timer] = [:] // Track message timers
    @State private var currentResolvingHand = 0 // Track which hand is currently being resolved
    @State private var isResolvingSplitHands = false // Track if we're in the process of resolving split hands
    @State private var isDoubleDown = false
    @State private var showGameResultText = false
    @State private var animateBalance = false
    @State private var lastCardFlyIn = false
    @State private var lastCardRotation: Double = 90
    @State private var splitHandCardFlyIn: [Bool] = [false, false] // Per-hand fly-in state for split hands
    @State private var splitHandCardRotation: [Double] = [90, 90] // Per-hand rotation state for split hands
    @State private var dealerDrawingOffset: CGFloat = 0 // Offset for dealer drawing phase in split hands
    @State private var isDealingCards = false // Track when cards are being dealt
    @State private var playerCardFlyIn: [Bool] = [false, false]
    @State private var playerCardRotation: [Double] = [90, 90]
    @State private var dealerCardFlyIn: [Bool] = [false, false]
    @State private var dealerCardRotation: [Double] = [90, 90]
    @State private var showSplitDialog = false
    @State private var splitDealtCount = 0
    @State private var splitCardFlyIn: [Bool] = [false, false, false, false]
    @State private var splitCardRotation: [Double] = [90, 90, 90, 90]
    // Removed complex split prompt states for simplicity
    @State private var hasDeclinedSplit = false
    @State private var showCustomSplitPrompt = false
    @State private var isTransitioningFromSplit = false
    @State private var splitCollapseProgress: CGFloat = 0.0
    @State private var showNormalGameplay = true
    @State private var showHandIcon = false
    @State private var handIconType: String = "idle"
    @State private var handIconOpacity: Double = 1
    @State private var isPulsing = true  // New state for stable pulsing animation
    @State private var handIconPosition = CGSize.zero  // Add back the missing state variable
    @State private var handIconRotation: Double = 0
    @State private var animatedBalance: Double = 0
    @State private var showBalanceChange: Bool = false
    @State private var balanceChangeAmount: Double = 0
    @State private var showHomeConfirm = false
    @State private var dealerPeeking = false
    @State private var dealerHoleCardFlipped = false
    @State private var bettingCirclesVisible = true
    @State private var holeCardPeekOffset: CGFloat = 0
    @State private var chipAnimations: [Int: Bool] = [:] // Track chip animations by value
    @State private var animatingChips: [AnimatingChip] = [] // Track flying chips
    @State private var navigateToStats = false // Track navigation to stats screen
    @State private var navigateToSettings = false // Track navigation to settings screen
    @State private var showInsuranceMessage = true // Control insurance message visibility
    @State private var insuranceMessageTimer: Timer? = nil // Timer for auto-hiding insurance message
    @State private var insuranceChipPosition = CGPoint(x: 0, y: 0) // Insurance chip animation position
    @State private var showInsuranceChip = false // Control insurance chip visibility
    @State private var insuranceChipScale: CGFloat = 1.0 // Insurance chip scale animation
    @State private var showChipInCircle = true // Control whether chip shows in betting circle
    @State private var chipAnimationOffset = CGSize.zero // Chip animation offset
    @State private var chipScale: CGFloat = 1.0 // Chip scale animation
    @State private var chipRotation: Double = 0.0 // Chip rotation animation
    @State private var chipOpacity: Double = 1.0 // Chip opacity animation
    @State private var showGameOverButtons = false // Control game over buttons visibility
    let handIconSize: CGFloat = 44
    let standCircleSize: CGFloat = 44
    let standCircleOffset: CGFloat = 70

    let chipValues = [1, 10, 25, 50, 100, 1000]
    
    // Helper function to convert numbers to ordinal strings
    func ordinalNumber(_ number: Int) -> String {
        let suffix: String
        switch number % 10 {
        case 1 where number % 100 != 11:
            suffix = "st"
        case 2 where number % 100 != 12:
            suffix = "nd"
        case 3 where number % 100 != 13:
            suffix = "rd"
        default:
            suffix = "th"
        }
        return "\(number)\(suffix)"
    }
    
    func animateInsuranceChip() {
        // Start position (betting area)
        let startPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 200)
        
        // End position (next to player cards)
        let endPosition = CGPoint(x: UIScreen.main.bounds.width / 2 + 80, y: UIScreen.main.bounds.height - 350)
        
        // Set initial position and show chip
        insuranceChipPosition = startPosition
        showInsuranceChip = true
        insuranceChipScale = 0.8
        
        // Animate to final position
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            insuranceChipPosition = endPosition
            insuranceChipScale = 1.0
        }
    }
    
    func animateInsuranceChipBackToDealer() {
        // Dealer position (top center)
        let dealerPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: 150)
        
        // Animate chip back to dealer
        withAnimation(.easeInOut(duration: 1.0)) {
            insuranceChipPosition = dealerPosition
            insuranceChipScale = 0.3
        }
        
        // Hide chip after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showInsuranceChip = false
            }
        }
    }
    
    struct AnimatingChip: Identifiable {
        let id = UUID()
        let value: Int
        var position: CGPoint
        var isAnimating: Bool = false
    }

    init(game: BlackjackGame, initialBetAmount: Int) {
        self.game = game
        self.initialBetAmount = initialBetAmount
        _betAmount = State(initialValue: initialBetAmount)
    }

    var canDoubleDown: Bool {
        return game.gameState == BlackjackGameState.playerTurn && game.playerHand.cards.count == 2
            && gameState.balance >= gameState.currentBet
    }
    
    var playerHandValueText: String {
        let playerValue = game.playerHand.value
        if game.playerHand.isSoft && playerValue != 21 {
            // Calculate the low value (all aces as 1)
            var lowValue = 0
            for card in game.playerHand.cards {
                if card.rank == .ace {
                    lowValue += 1
                } else {
                    lowValue += card.value
                }
            }
            return "\(lowValue)/\(playerValue)"
        } else {
            return "\(playerValue)"
        }
    }
    
    var resultColor: Color {
        if game.payout > 0 {
            return .green
        } else if game.payout < 0 {
            return .red
        } else {
            return .white
        }
    }
    
    @ViewBuilder
    var insuranceChipView: some View {
        if game.gameState == BlackjackGameState.offeringInsurance && gameState.insuranceBet > 0 && !dealerPeeking {
            insuranceChipIndicator
            
            // Total risk indicator
            VStack(spacing: 4) {
                Text("Total at Risk")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("$\(Int(gameState.currentBet + gameState.insuranceBet))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange.opacity(0.5), lineWidth: 1)
            )
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: gameState.insuranceBet > 0)
        }
    }
    
    @ViewBuilder
    var animatedInsuranceChip: some View {
        if showInsuranceChip {
            // Calculate chip image name based on bet amount
            let chipImageName: String = {
                let insuranceBet = Int(gameState.insuranceBet)
                if insuranceBet >= 1000 {
                    return "Chip1000"
                } else if insuranceBet >= 500 {
                    return "Chip500"
                } else if insuranceBet >= 100 {
                    return "Chip100"
                } else if insuranceBet >= 25 {
                    return "Chip25"
                } else if insuranceBet >= 5 {
                    return "Chip5"
                } else {
                    return "Chip1"
                }
            }()
            
            ZStack {
                Image(chipImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                    .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.85)
                            ]),
                            center: .center,
                            startRadius: 5,
                            endRadius: 16
                        )
                    )
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Show half the main bet amount if no insurance bet placed, otherwise show insurance bet
                let displayAmount = gameState.insuranceBet > 0 ? Int(gameState.insuranceBet) : Int(gameState.currentBet / 2)
                Text("\(displayAmount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .shadow(color: .white.opacity(0.8), radius: 1, x: 0, y: 1)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .shadow(color: .white.opacity(0.8), radius: 1, x: 0, y: 1)
            }
            .scaleEffect(insuranceChipScale)
            .position(insuranceChipPosition)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: insuranceChipPosition)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: insuranceChipScale)
        }
    }
    
    @ViewBuilder
    var insuranceResultView: some View {
        if game.gameState == BlackjackGameState.gameOver && gameState.insuranceBet > 0 && !game.insuranceMessage.isEmpty && showInsuranceMessage {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: game.insuranceMessage.contains("won") ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(game.insuranceMessage.contains("won") ? .green : .red)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(game.insuranceMessage.contains("won") ? "Insurance Won!" : "Insurance Lost")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(game.insuranceMessage.contains("won") ? .green : .red)
                        
                        Text(game.insuranceMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(game.insuranceMessage.contains("won") ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(game.insuranceMessage.contains("won") ? Color.green.opacity(0.4) : Color.red.opacity(0.4), lineWidth: 1.5)
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: game.insuranceMessage)
            }
        }
    }
    
    @ViewBuilder
    var dealerPeekingView: some View {
        if dealerPeeking {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 8, height: 8)
                        .scaleEffect(dealerPeeking ? 1.2 : 0.8)
                        .animation(
                            game.gameState == .gameOver ? nil : .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: dealerPeeking
                        )
                }
            }
            .transition(.scale.combined(with: .opacity))
            .animation(game.gameState == .gameOver ? nil : .spring(response: 0.6, dampingFraction: 0.8), value: dealerPeeking)
        }
    }
    
    // Removed enhancedSplitHandsView - using simplified split display in playerAreaView

    var body: some View {
        NavigationStack {
            ZStack {
                BlueTableBackground(showTableDesigns: true)
                    .ignoresSafeArea(.all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)  // Ensure background fills entire screen

            VStack(spacing: 0) {  // This VStack contains top elements and the main game flow area
                // Top buttons (exit and stats) - Only show at top when NOT game over, NOT dealer peeking, NOT dealer drawing, and NOT during initial dealing
                if game.gameState != .gameOver && game.gameState != .dealerTurn && (dealt || game.gameState == .betting) {
                    topButtonsView
                        .padding(.top, game.gameState == .betting ? -80 : 30)  // Move buttons up more on betting screen
                        .opacity(game.gameState == BlackjackGameState.offeringInsurance ? 0.3 : 1.0)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .onAppear {
                            print("DEBUG: Showing top buttons - isDealingCards: \(isDealingCards), gameState: \(game.gameState), dealerPeeking: \(dealerPeeking)")
                        }
                }

                // Dealer area with buttons above it when game over
                if game.gameState == .gameOver {
                    VStack(spacing: 8) {
                        // Top row - back and stats buttons (only show when not dealer peeking, not dealer drawing, and not during initial dealing)
                        if game.gameState != .dealerTurn && (dealt || game.gameState == .betting) {
                            HStack {
                                // Back button
                                Button(action: {
                                    showHomeConfirm = true
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.title3.bold())
                                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                                        .frame(width: 28, height: 28)
                                        .background(Color.black.opacity(0.5))
                                        .clipShape(Circle())
                                        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), radius: 3, y: 2)
                                }
                                .alert("Leave Current Game?", isPresented: $showHomeConfirm) {
                                    Button("Stay & Continue Playing", role: .cancel) {}
                                    Button("Leave Game", role: .destructive) {
                                        SoundManager.shared.playBackButton()
                                        SoundManager.shared.playBackButton()
                                        forfeitCurrentBetAndLeave()
                                    }
                                } message: {
                                    Text(game.gameState == .betting && !dealt ? 
                                         "Your current bet of $\(Int(gameState.currentBet)) will be returned to your balance. Are you sure you want to return to the main menu?" :
                                         "Your current game progress will be lost and you will forfeit your current bet of $\(Int(gameState.currentBet)). Are you sure you want to return to the main menu?")
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                }
                                
                                Spacer()
                                
                                // Settings button
                                SettingsIconView {
                                    print("DEBUG: Settings button tapped")
                                    navigateToSettings = true
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 100)  // Increased from 60 to move buttons much lower
                        }
                        
                        // Dealer cards below the buttons
                        dealerAreaViewNoLabel
                            .padding(.top, 20)  // Add space above dealer cards
                            .opacity(isSplitTransitioning ? (showDealerCards ? 1.0 : 0.0) : 1.0)
                            .offset(y: isSplitTransitioning ? dealerCardsOffset : 0)
                            .scaleEffect(isSplitTransitioning ? (showDealerCards ? 1.0 : 0.8) : 1.0)
                    }
                } else {
                    // Dealer area (without 'Dealer' label) - Keep highlighted during insurance/split
                    dealerAreaViewNoLabel
                        .padding(.top, 20)  // Add space above dealer cards for consistency
                        .opacity(isSplitTransitioning ? (showDealerCards ? 1.0 : 0.0) : 1.0)
                        .offset(y: isSplitTransitioning ? dealerCardsOffset : (game.hasSplit && game.gameState == .dealerTurn ? dealerDrawingOffset : 0))
                        .scaleEffect(isSplitTransitioning ? (showDealerCards ? 1.0 : 0.8) : 1.0)
                }

                // Engraved rules banner (no result message popup - result shows in betting circle)
                if !(game.hasSplit && game.gameState == .dealerTurn) {
                EngravedRulesBanner(
                        resultMessage: nil,  // No result message popup - result shows in betting circle
                    resultColor: resultColor,
                    isGameOver: game.gameState == BlackjackGameState.gameOver,
                        insuranceMessage: (showInsuranceMessage && !dealerPeeking) ? game.insuranceMessage : "",
                        hideInsuranceText: dealerPeeking,
                        gameState: game.gameState
                )
                    .padding(.top, game.gameState == .betting ? -50 : 0)  // Only adjust for betting screen
                .opacity(game.gameState == BlackjackGameState.offeringInsurance ? 0.3 : 1.0)
                }
                
                // Insurance chip indicator when insurance bet is placed
                insuranceChipView
                
                // Insurance result display when game is over
                insuranceResultView
                
                // Dealer checking for blackjack animation (dots only) - REMOVED
                // dealerPeekingView
                
                // Player area and Total Bet Display
                playerAreaView

                // Spacer to push controls to bottom of VStack
                Spacer()
                    .frame(maxHeight: 20)  // Reduced height to match active game state

                // Betting and controls
                if game.gameState == BlackjackGameState.offeringInsurance {
                    insuranceControlsView
                } else if game.gameState != BlackjackGameState.betting && game.gameState != .dealerTurn {
                    gameControlsView
                        .opacity(showNormalGameplay ? 1.0 : 0.0)
                }
                
                // Split prompt overlay
                // Simplified: removed separate split controls view
            }  // End of main content VStack
            .padding(.horizontal, 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)  // Ensure this VStack fills all available space
            
            // Animated insurance chip overlay
            animatedInsuranceChip

            }  // End of ZStack
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // Ensure the ZStack fills the entire screen
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea()
        .navigationDestination(isPresented: $navigateToStats) {
            StatsPopupView(gameStats: game.gameStats, isPresented: $navigateToStats)
        }
        .fullScreenCover(isPresented: $navigateToSettings) {
            SettingsView()
                .environmentObject(gameState)
        }
        .sheet(isPresented: $showingAddFunds) {
            EnhancedAddFundsView()
                .environmentObject(gameState)
                .environmentObject(storeManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BalanceUpdated"))) { _ in
            // Update animated balance immediately when balance changes
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedBalance = gameState.balance
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChipsPurchased"))) { notification in
            // Handle chip purchases from in-app purchases
            if let amount = notification.userInfo?["amount"] as? Int {
                gameState.addFunds(Double(amount))
                withAnimation(.easeInOut(duration: 0.5)) {
                    animatedBalance = gameState.balance
                }
            }
        }
        .onAppear {
            // Initialize animatedBalance to current balance when view appears
            animatedBalance = gameState.balance
            
            // Reset UI state when returning to the game (for both new games and continuing games)
            // Reset positioning states to ensure proper layout
            dealerDrawingOffset = 0
            holeCardPeekOffset = 0
            bettingCirclesVisible = true
            showGameOverButtons = false
            showGameResultText = false
            isDealingCards = false
            dealerPeeking = false
            dealerHoleCardFlipped = false
            
            // Reset card animation states
            playerDealtCount = 0
            dealerDealtCount = 0
            playerCardFlyIn = [false, false]
            playerCardRotation = [90, 90]
            dealerCardFlyIn = [false, false]
            dealerCardRotation = [90, 90]
            
            // If continuing a game in progress, set proper card counts
            if !game.playerHand.cards.isEmpty && !game.dealerHand.cards.isEmpty {
                playerDealtCount = game.playerHand.cards.count
                dealerDealtCount = game.dealerHand.cards.count
                dealt = true  // Set dealt to true when continuing a game
                // Set cards as already dealt (no animation)
                for i in 0..<min(playerDealtCount, playerCardFlyIn.count) {
                    playerCardFlyIn[i] = true
                    playerCardRotation[i] = 0
                }
                for i in 0..<min(dealerDealtCount, dealerCardFlyIn.count) {
                    dealerCardFlyIn[i] = true
                    dealerCardRotation[i] = 0
                }
                // Ensure hole card is flipped if game is over
                if game.gameState == .gameOver {
                    dealerHoleCardFlipped = true
                }
            } else {
                dealt = false  // Set dealt to false for new games
            }
            
            // Reset split states
            isSplitTransitioning = false
            splitTransitionProgress = 0.0
            showPlayerHands = true
            showDealerCards = true
            showFirstSplitCards = false
            showSecondSplitCards = false
            splitDealingStep = 0
            isResolvingSplitHands = false
            currentResolvingHand = 0
            splitHandResults.removeAll()
            splitChipAnimations.removeAll()
            splitChipPositions.removeAll()
            splitHandMessages.removeAll()
            splitMessageTimers.removeAll()
            
            // Reset insurance states
            showInsuranceMessage = true
            showInsuranceChip = false
            insuranceChipPosition = CGPoint(x: 0, y: 0)
            insuranceChipScale = 1.0
            
            // Reset chip animation states
            showChipInCircle = true
            chipAnimationOffset = .zero
            chipScale = 1.0
            chipRotation = 0.0
            chipOpacity = 1.0
            chipAnimations.removeAll()
            animatingChips.removeAll()
            
            // Reset other UI states
            showBustMessage = false
            bustMessage = ""
            isDoubleDown = false
            showSplitDialog = false
            splitDealtCount = 0
            hasDeclinedSplit = false
            showCustomSplitPrompt = false
            isTransitioningFromSplit = false
            splitCollapseProgress = 0.0
            showNormalGameplay = true
            showHandIcon = false
            handIconType = "idle"
            handIconOpacity = 1
            isPulsing = true
            handIconPosition = .zero
            handIconRotation = 0
            showBalanceChange = false
            balanceChangeAmount = 0
            showHomeConfirm = false
            navigateToStats = false
            navigateToSettings = false
            showBustMessage = false
            showPlayerHands = true
            showDealerCards = true
            showFirstSplitCards = false
            showSecondSplitCards = false
            showGameResultText = false
            showSplitDialog = false
            showCustomSplitPrompt = false
            showHandIcon = false
            showInsuranceMessage = true
            showInsuranceChip = false
            showChipInCircle = true
            showGameOverButtons = false
            
            // Force layout refresh to ensure proper positioning
            DispatchQueue.main.async {
                self.uiRefreshTrigger.toggle()
            }
        }
        .onChange(of: game.gameState) { _, newGameState in
            // Reset insurance message and chip visibility when starting a new game
            if newGameState == BlackjackGameState.playerTurn || newGameState == BlackjackGameState.offeringInsurance {
                showInsuranceMessage = true
                showInsuranceChip = false
            }
            
            // Animate cards down during dealer turn for split hands
            if newGameState == .dealerTurn && game.hasSplit {
                withAnimation(.easeInOut(duration: 0.5)) {
                    dealerDrawingOffset = 100 // Move cards down by 100 points
                    // Keep betting circles visible but they'll be greyed out
                }
            } else if newGameState == .gameOver && game.hasSplit {
                withAnimation(.easeInOut(duration: 0.5)) {
                    dealerDrawingOffset = 0 // Move cards back to normal position
                }
                // Re-appear betting circles with animation after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        bettingCirclesVisible = true
                    }
                }
            }
            
            // Handle dealer turn animation
            if newGameState == BlackjackGameState.dealerTurn {
                animateDealerTurn()
            }
            
            if newGameState == BlackjackGameState.gameOver {
                // Ensure all dealer cards are visible when game is over
                dealerDealtCount = game.dealerHand.cards.count
                
                // If player has blackjack, ensure dealer cards are immediately visible
                if game.playerHand.isBlackjack {
                    // Force all dealer cards to be visible and face up
                    for i in 0..<game.dealerHand.cards.count {
                        if i < dealerCardFlyIn.count {
                            dealerCardFlyIn[i] = true
                        }
                        if i < dealerCardRotation.count {
                            dealerCardRotation[i] = 0
                        }
                    }
                    dealerHoleCardFlipped = true
                }
                
                // For split hands, hide chip immediately
                if game.hasSplit {
                    showChipInCircle = false
                } else {
                    // Animate chip from betting circle for normal games
                animateChipFromCircle()
                }
                
                // Start split hand resolution if needed
                if game.hasSplit && !isResolvingSplitHands {
                    startSequentialSplitResolution()
                }
                
                // Show the game over buttons after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showGameOverButtons = true
                    }
                }
                
                let oldBalance = gameState.balance
                let payout = game.payout
                // Don't calculate newBalance here - let resolveBet handle the actual balance update
                // This prevents double application of the payout
                
                // Show insurance message initially
                func handleInsuranceResult(_ didWin: Bool) {
                    if didWin {
                        let message = "Insurance paid 2:1 - You won $\(Int(gameState.insuranceBet * 2))!"
                        game.updateInsuranceMessage(message)
                        showInsuranceMessage = true
                    } else {
                        // No message for insurance loss, just show balance change
                        game.updateInsuranceMessage("")
                        showInsuranceMessage = false
                        
                        // Show balance change for insurance loss
                        showBalanceChange = true
                        balanceChangeAmount = -gameState.insuranceBet
                        
                        // Hide balance change after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showBalanceChange = false
                        }
                        
                        // Animate chip back to dealer if insurance is lost
                        animateInsuranceChipBackToDealer()
                    }
                }
                
                // Handle insurance result if there was an insurance bet
                if gameState.insuranceBet > 0 {
                    handleInsuranceResult(game.insuranceResult ?? false)
                }
                
                // Resolve the bet to update the actual balance (only for normal games, not split hands)
                if !game.hasSplit {
                    print("DEBUG: Resolving bet - payout: \(game.payout), current balance: \(gameState.balance)")
                    gameState.resolveBet(with: game.payout, insuranceResult: game.insuranceResult)
                    print("DEBUG: After resolve bet - new balance: \(gameState.balance)")
                }
                let finalBalance = gameState.balance
                
                // Animate the balance change
                if payout != 0 {
                    showBalanceChange = true
                    balanceChangeAmount = payout
                    let steps = 40
                    let stepAmount = payout / Double(steps)
                    let duration: Double = 1.2
                    let stepDuration = duration / Double(steps)
                    var currentStep = 0
                    Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
                        currentStep += 1
                        animatedBalance = oldBalance + stepAmount * Double(currentStep)
                        if currentStep >= steps {
                            animatedBalance = finalBalance
                            timer.invalidate()
                        }
                    }
                    // Hide the balance change after a few seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showBalanceChange = false
                    }
                } else {
                    animatedBalance = finalBalance
                    showBalanceChange = false
                }
                
                // Show result text immediately for blackjack, with delay for other results
                if game.resultMessage == "Blackjack!" {
                    // Show blackjack message immediately
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                        showGameResultText = true
                    }
                } else {
                    // Show other result messages with a delay
                    let delay = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                            showGameResultText = true
                        }
                    }
                }
            }
        }
        .onChange(of: game.shouldAutoDeal) { _, shouldDeal in
            if shouldDeal {
                // Reset insurance message visibility for new game
                showInsuranceMessage = true
            }
        }
        .onAppear {
            // If hands are not empty, it means we are returning to a game in progress or just started a new game from the main menu.
            if !game.playerHand.cards.isEmpty && !game.dealerHand.cards.isEmpty {
                // If not in betting state, show existing cards without animation
                if game.gameState != .betting {
                    playerDealtCount = game.playerHand.cards.count
                    dealerDealtCount = game.dealerHand.cards.count
                    
                    // Set animation states to show existing cards
                    for i in 0..<min(playerDealtCount, playerCardFlyIn.count) {
                        playerCardFlyIn[i] = true
                        playerCardRotation[i] = 0
                    }
                    for i in 0..<min(dealerDealtCount, dealerCardFlyIn.count) {
                        dealerCardFlyIn[i] = true
                        dealerCardRotation[i] = 0
                    }
                } else {
                    // If in betting state, this is a new game - cards will be dealt with animation
                    playerDealtCount = 0
                    dealerDealtCount = 0
                    dealerHoleCardFlipped = false
                    bettingCirclesVisible = true
                }
            }
            // Simplified: no automatic split prompts
            // We should NOT automatically deal cards on appear if hands are empty.
            animatedBalance = gameState.balance
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SplitHandIndexChanged"))) { _ in
            // Force UI refresh when split hand index changes
            uiRefreshTrigger.toggle()
        }
        // Simplified: removed automatic split prompt logic
    }

    // MARK: - Initial Deal Animation
    func forfeitCurrentBetAndLeave() {
        // Check if we're in betting phase (no cards dealt yet)
        if game.gameState == .betting && !dealt {
            // Return the bet to balance since no game has started
            gameState.balance += Double(betAmount)
            animatedBalance = gameState.balance
        }
        // Otherwise, forfeit the current bet - don't return it to balance
        
        game.reset()
        betAmount = 0
        gameState.currentBet = 0
        gameState.isGameActive = false
        
        // Reset all UI states
        dealt = false
        playerDealtCount = 0
        dealerDealtCount = 0
        dealerHoleCardFlipped = false
        isDealingCards = false
        bettingCirclesVisible = true
        isDoubleDown = false
        showGameResultText = false
        showGameOverButtons = false
        dealerPeeking = false
        
        // Reset animation states
        playerCardFlyIn = [false, false]
        playerCardRotation = [90, 90]
        dealerCardFlyIn = [false, false]
        dealerCardRotation = [90, 90]
        
        // Reset split states
        splitHandResults.removeAll()
        isSplitTransitioning = false
        splitTransitionProgress = 0.0
        showPlayerHands = true
        showDealerCards = true
        showFirstSplitCards = false
        showSecondSplitCards = false
        splitDealingStep = 0
        isResolvingSplitHands = false
        currentResolvingHand = 0
        hasDeclinedSplit = false
        showCustomSplitPrompt = false
        isTransitioningFromSplit = false
        showNormalGameplay = true
        showHandIcon = false
        handIconType = "idle"
        handIconOpacity = 1
        isPulsing = true
        handIconPosition = .zero
        handIconRotation = 0
        showBalanceChange = false
        balanceChangeAmount = 0
        showBustMessage = false
        showSplitDialog = false
        showInsuranceMessage = true
        showInsuranceChip = false
        showChipInCircle = true
        
        // Reset offsets
        dealerDrawingOffset = 0
        holeCardPeekOffset = 0
        dealerCardsOffset = 0
        chipAnimationOffset = .zero
        chipScale = 1.0
        chipRotation = 0.0
        chipOpacity = 1.0
        
        // Dismiss the view
        dismiss()
    }

    func dealInitialCards() {
        // Always reset counts and animation states for new games
        playerDealtCount = 0
        dealerDealtCount = 0
        dealerHoleCardFlipped = false
        
        // Reset animation state arrays for new game
        playerCardFlyIn = [false, false]
        playerCardRotation = [90, 90]
        dealerCardFlyIn = [false, false]
        dealerCardRotation = [90, 90]
        
        dealt = true
        isDealingCards = true  // Start dealing animation
        // Keep betting circles visible but they'll be greyed out during dealing
        isDoubleDown = false
        showGameResultText = false  // Reset result text for a new hand
        showGameOverButtons = false  // Hide buttons at start of new game
        
        // Reset split hand results and animations
        splitHandResults.removeAll()
        
        // Reset per-hand animation states
        splitHandCardFlyIn = [false, false]
        splitHandCardRotation = [90, 90]
        dealerDrawingOffset = 0
        // REMOVED: isDealingCards = false (keep it true during dealing)
        splitChipAnimations.removeAll()
        splitChipPositions.removeAll()
        splitHandMessages.removeAll()
        splitMessageTimers.values.forEach { $0.invalidate() }
        splitMessageTimers.removeAll()
        currentResolvingHand = 0
        isResolvingSplitHands = false
        // Split decline flag removed for simplified split functionality
        
        // Reset chip animation state
        showChipInCircle = true
        chipAnimationOffset = .zero
        chipScale = 1.0
        chipRotation = 0.0
        chipOpacity = 1.0

        // Set the bet amount in game (balance already deducted when chips were selected)
        game.placeBet(Double(betAmount))       // Set bet amount in game
        gameState.currentBet = Double(betAmount)  // Set current bet without deducting balance again
        animatedBalance = gameState.balance    // Update animated balance immediately
        game.dealCards()

        // Always animate dealing for new games
        // Animate dealing: alternate player, dealer, player, dealer
        let dealOrder: [(isPlayer: Bool, index: Int)] = [
            (true, 0), (false, 0), (true, 1), (false, 1),
        ]
        for i in 0..<dealOrder.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * settingsManager.cardDealDelay) {
                if dealOrder[i].isPlayer {
                    if self.playerDealtCount < self.game.playerHand.cards.count {
                        self.playerDealtCount += 1
                        // Play card deal sound
                        SoundManager.shared.playCardDeal()
                        // Animate fly-in and flip for this card
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                self.playerCardFlyIn[dealOrder[i].index] = true
                                self.playerCardRotation[dealOrder[i].index] = 0
                            }
                        }
                    }
                } else {
                    if self.dealerDealtCount < self.game.dealerHand.cards.count {
                        self.dealerDealtCount += 1
                        // Play card deal sound
                        SoundManager.shared.playCardDeal()
                        // Animate fly-in and flip for this card
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                self.dealerCardFlyIn[dealOrder[i].index] = true
                                self.dealerCardRotation[dealOrder[i].index] = 0
                            }
                        }
                        
                        // If this is the dealer's first card and it's a 10, start peek animation immediately
                        if dealOrder[i].index == 0 && self.game.dealerHand.cards.first?.value == 10 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { // Wait for card flip animation
                                self.animateDealerPeek()
                            }
                        }
                    }
                }
                // After the last card is dealt, check for dealer peek and blackjack
                if i == dealOrder.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * settingsManager.cardDealDelay) {
                        // Cards dealing animation is complete (wait for card flip animation)
                        self.isDealingCards = false
                        self.bettingCirclesVisible = true  // Show betting circles after dealing
                        
                        // Check if dealer should peek for blackjack (only for player blackjack)
                        if self.game.playerHand.isBlackjack && self.game.gameState != .offeringInsurance {
                            self.animateDealerPeek()
                        }
                        
                        // Blackjack check is now handled by the delayed check in startNewRound()
                        // This ensures consistent behavior regardless of dealer's first card
                    }
                }
            }
        }
        
        // Check for immediate blackjack after dealing (for all cases)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Check for blackjack regardless of game state
            if self.game.playerHand.isBlackjack {
                // Force the game to check for blackjack immediately
                self.game.checkForBlackjackImmediately()
                
                // Ensure dealer cards are visible for blackjack
                self.dealerDealtCount = self.game.dealerHand.cards.count
                for i in 0..<self.game.dealerHand.cards.count {
                    if i < self.dealerCardFlyIn.count {
                        self.dealerCardFlyIn[i] = true
                    }
                    if i < self.dealerCardRotation.count {
                        self.dealerCardRotation[i] = 0
                    }
                }
                self.dealerHoleCardFlipped = true
                
                self.showGameResultText = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.showGameOverButtons = true
                }
            }
        }
    }

    // MARK: - Dealer Peek Animation
    func animateDealerPeek() {
        print("DEBUG: animateDealerPeek called - bettingCirclesVisible: \(bettingCirclesVisible), gameState: \(game.gameState)")
        dealerPeeking = true
        
        // Animate the hole card moving closer to dealer
        withAnimation(.easeInOut(duration: 0.8)) {
            holeCardPeekOffset = -25 // Move card closer to dealer
        }
        
        // Hold the peek position briefly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // Move card back to original position
            withAnimation(.easeInOut(duration: 0.8)) {
                holeCardPeekOffset = 0
            }
            
            // Reset peeking state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dealerPeeking = false
                
                // If player has blackjack, show dealer cards and resolve game
                if self.game.playerHand.isBlackjack {
                    // Ensure dealer cards are visible for blackjack
                    self.dealerDealtCount = self.game.dealerHand.cards.count
                    for i in 0..<self.game.dealerHand.cards.count {
                        if i < self.dealerCardFlyIn.count {
                            self.dealerCardFlyIn[i] = true
                        }
                        if i < self.dealerCardRotation.count {
                            self.dealerCardRotation[i] = 0
                        }
                    }
                    self.dealerHoleCardFlipped = true
                    
                    self.showGameResultText = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.showGameOverButtons = true
                    }
                }
            }
        }
    }
    
    // MARK: - Insurance Card Check Animation
    func animateInsuranceCardCheck(completion: @escaping () -> Void) {
        dealerPeeking = true
        
        // Animate the hole card moving closer to dealer
        withAnimation(.easeInOut(duration: 0.8)) {
            holeCardPeekOffset = -25 // Move card closer to dealer
        }
        
        // Hold the peek position briefly
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // Move card back to original position
            withAnimation(.easeInOut(duration: 0.8)) {
                holeCardPeekOffset = 0
            }
            
            // Reset peeking state and execute completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dealerPeeking = false
                completion()
            }
        }
    }

    // MARK: - Player Actions
    func playerHit() {
        game.hit()
        // Play card deal sound
        SoundManager.shared.playCardDeal()
        // Animate the new card being dealt to the player
        let newCount = game.playerHand.cards.count
        lastCardFlyIn = false
        lastCardRotation = 90
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.5)) {
                self.playerDealtCount = newCount
            }
            // Animate fly-in and flip
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.lastCardFlyIn = true
                    self.lastCardRotation = 0
                }
            }
            // SoundManager.shared.playSound(named: "deal")
        }
    }

    func playerStand() {
        game.gameState = .dealerTurn
        animateDealerTurn()
    }

    /// Animates the dealer's turn, dealing cards one by one with fly-in animation and updating the total as each card is drawn.
    func animateDealerTurn() {
        dealerDealtCount = 2
        
        // First, flip the hole card with animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.6)) {
                self.dealerHoleCardFlipped = true
            }
            // Play card flip sound
            SoundManager.shared.playCardDeal()
        }
        
        // Ensure dealerCardRotation and dealerCardFlyIn arrays are large enough
        while dealerCardRotation.count < game.dealerHand.cards.count + 1 {
            dealerCardRotation.append(90)
            dealerCardFlyIn.append(false)
        }
        func dealNextCard() {
            let done = game.dealerDrawOneCard()
            let newCount = game.dealerHand.cards.count
            if dealerDealtCount < newCount {
                // Play card deal sound
                SoundManager.shared.playCardDeal()
                // Animate the new card
                // Ensure arrays are large enough
                while dealerCardRotation.count < newCount {
                    dealerCardRotation.append(90)
                    dealerCardFlyIn.append(false)
                }
                dealerCardRotation[newCount - 1] = 90
                dealerCardFlyIn[newCount - 1] = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        dealerDealtCount = newCount
                    }
                    // Animate flip
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeOut(duration: 0.8)) {
                            dealerCardRotation[newCount - 1] = 0
                            dealerCardFlyIn[newCount - 1] = true
                        }
                    }
                    SoundManager.shared.playCardDeal()
                    // Wait for the animation, then check if more cards are needed
                    DispatchQueue.main.asyncAfter(deadline: .now() + settingsManager.dealerDrawDelay) {
                        if !done {
                            dealNextCard()
                        } else {
                            // Ensure all dealer cards are visible when done
                            dealerDealtCount = game.dealerHand.cards.count
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if game.hasSplit {
                                    game.determineWinnerEnhanced()
                                } else {
                                game.determineWinner()
                                }
                                // Show buttons after a 1-second delay to let animations finish
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    showGameOverButtons = true
                                }
                            }
                        }
                    }
                }
            } else {
                if !done {
                    DispatchQueue.main.asyncAfter(deadline: .now() + settingsManager.dealerDrawDelay) {
                        dealNextCard()
                    }
                } else {
                    // Ensure all dealer cards are visible when done
                    dealerDealtCount = game.dealerHand.cards.count
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if game.hasSplit {
                            game.determineWinnerEnhanced()
                        } else {
                        game.determineWinner()
                        }
                        // Show buttons after a 1-second delay to let animations finish
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showGameOverButtons = true
                        }
                    }
                }
            }
        }
        // Start dealing cards after hole card flip animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if game.dealerHand.value < 17 || (game.dealerHand.value == 17 && game.dealerHand.isSoft)
            {
                dealNextCard()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if game.hasSplit {
                        game.determineWinnerEnhanced()
                    } else {
                    game.determineWinner()
                    }
                }
            }
        }
    }

    func doubleDown() {
        guard canDoubleDown else { return }
        isDoubleDown = true
        // Double the bet if possible
        let betToDouble = gameState.currentBet
        if gameState.balance >= betToDouble {
            gameState.doubleDown()
            game.doubleDownBet()
            // Player gets one card, then stands
            game.hit()
            lastCardFlyIn = false
            lastCardRotation = 90
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.playerDealtCount = self.game.playerHand.cards.count
                }
                // Animate fly-in and flip
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        self.lastCardFlyIn = true
                        self.lastCardRotation = 0
                    }
                }
                // SoundManager.shared.playSound(named: "deal")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dealerDealtCount = game.dealerHand.cards.count
                playerStand()
            }
        }
    }

    func hitOnActiveHand() {
        guard game.gameState == BlackjackGameState.playerTurn else { return }
        if game.hasSplit {
            let activeHandIndex = game.splitManager.activeHandIndex
            
            // REMOVED: Auto-stand logic for split aces
            // Split aces should allow normal hit/stand/double actions
            
            // Call the model method
            print("Hitting on active hand \(activeHandIndex + 1), cards before: \(game.splitManager.hands[activeHandIndex].cards.count)")
            game.hitOnActiveHand()
            print("Cards after hit: \(game.splitManager.hands[activeHandIndex].cards.count)")
            
            // Play card deal sound
            SoundManager.shared.playCardDeal()
            
            // Animate the new card being dealt to the split hand (same as regular game)
            let newCount = game.splitManager.hands[activeHandIndex].cards.count
            
            // Reset animation state
            splitHandCardFlyIn[activeHandIndex] = false
            splitHandCardRotation[activeHandIndex] = 90
            
            // Small delay to ensure state is reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.playerDealtCount = newCount
                }
                // Animate fly-in and flip
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        self.splitHandCardFlyIn[activeHandIndex] = true
                        self.splitHandCardRotation[activeHandIndex] = 0
                    }
                }
            }
            
            // Force UI refresh without affecting layout
            DispatchQueue.main.async {
                self.uiRefreshTrigger.toggle()
            }
            
            // Check if hand is complete after the hit
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let updatedHand = self.game.splitManager.hands[activeHandIndex]
                if updatedHand.isBust || (updatedHand.cards.count == 2 && updatedHand.cards[0].rank == Rank.ace) {
                    // Handle immediate loss for busted hand
                    if updatedHand.isBust {
                        // Casino style: balance already deducted when bet was placed
                        // No additional balance change needed - just take the chip away
                        self.animatedBalance = self.gameState.balance
                    }
                    
                    // Don't call standOnActiveHand() here - it's already called in the model
                    // Just force UI refresh
                    DispatchQueue.main.async {
                        self.uiRefreshTrigger.toggle()
                    }
                }
            }
        } else {
            playerHit()
        }
    }

    // MARK: - Helper Views
    private var bettingInterfaceView: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text("PLACE YOUR BET")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2.0)
                    .shadow(color: Color.black.opacity(0.8), radius: 4, x: 0, y: 2)
                
                Text("Select your chip amount below")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.5)
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
            
            Spacer()
            
            if bettingCirclesVisible {
                balanceDisplayView
                    .padding(.horizontal, -20)  // Make balance bar wider on betting screen
                    .padding(.top, 10)  // Move balance bar up
                    .opacity((game.gameState == .dealerTurn || dealerPeeking || isDealingCards) ? 0.4 : 1.0)
                    .onAppear {
                        print("DEBUG: balanceDisplayView appeared - bettingCirclesVisible: \(bettingCirclesVisible), dealerPeeking: \(dealerPeeking), gameState: \(game.gameState)")
                    }
                    .animation(.easeInOut(duration: 0.3), value: game.gameState)
                    .animation(.easeInOut(duration: 0.3), value: dealerPeeking)
                    .animation(.easeInOut(duration: 0.3), value: isDealingCards)
                
                Spacer()
                
                bettingCircleView
                    .opacity((game.gameState == .dealerTurn || dealerPeeking || isDealingCards) ? 0.4 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: game.gameState)
                    .animation(.easeInOut(duration: 0.3), value: dealerPeeking)
                    .animation(.easeInOut(duration: 0.3), value: isDealingCards)
                
                Spacer()
                
                chipSelectionView
                    .opacity((game.gameState == .dealerTurn || dealerPeeking || isDealingCards) ? 0.4 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: game.gameState)
                    .animation(.easeInOut(duration: 0.3), value: dealerPeeking)
                    .animation(.easeInOut(duration: 0.3), value: isDealingCards)
                
                HStack(spacing: 16) {
                    // Add Funds button
                    Button(action: {
                        showingAddFunds = true
                        SoundManager.shared.playButtonTap()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.green)
                            
                            Text("ADD FUNDS")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundColor(.green)
                                .tracking(1.2)
                        }
                        .frame(width: 120, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.green.opacity(0.2),
                                            Color.green.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                        )
                        .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
                    }
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: gameState.balance)
                    
                    dealButtonView
                        .offset(y: 6)
                }
                .padding(.bottom, 20)  // Fixed bottom padding - never changes
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var bettingCircleView: some View {
        ZStack {
            // Outer glow ring with animation
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8),
                            Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3),
                            Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 120, height: 120)
                .scaleEffect(betAmount > 0 ? 1.0 : 0.95)
                .animation(.easeInOut(duration: 0.3), value: betAmount)
                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8), radius: 15, x: 0, y: 0)
            
            // Main betting circle with glassmorphism
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05),
                            Color.black.opacity(0.4)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.9),
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Betting circle content
            VStack(spacing: 6) {
                if betAmount > 0 {
                    // Show chip representation of current bet
                    SingleBetChipView(
                        denomination: chipDenominationForBet(amount: Double(betAmount)),
                        totalAmount: betAmount
                    )
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: betAmount)
                    
                    Button("Clear") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            // Restore the bet amount to balance before clearing
                            gameState.balance += Double(betAmount)
                            animatedBalance = gameState.balance
                            betAmount = 0
                        }
                        SoundManager.shared.playChipPlace()
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5), lineWidth: 1)
                            )
                    )
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: betAmount)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "suit.spade.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.3), value: betAmount)
                        
                        Text("PLACE BET")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1.0)
                    }
                }
            }
            
            // Pulsing ring effect when bet is placed
            if betAmount > 0 {
                Circle()
                    .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), lineWidth: 1)
                    .frame(width: 110, height: 110)
                    .scaleEffect(1.1)
                    .opacity(0.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: betAmount)
            }
            
            // Animated chips overlay
            ForEach(animatingChips) { chip in
                ChipView(value: chip.value, action: {})
                    .position(chip.position)
                    .opacity(chip.isAnimating ? 0 : 1)
                    .scaleEffect(chip.isAnimating ? 0.3 : 1.0)
                    .animation(.easeInOut(duration: 0.6), value: chip.isAnimating)
            }
        }
    }
    
    private var chipSelectionView: some View {
        HStack(spacing: 4) {
            ForEach(chipValues, id: \.self) { value in
                ChipView(value: value) {
                    if gameState.balance >= Double(value) {
                        SoundManager.shared.playChipSelect()
                        animateChipToCircle(chipValue: value)
                        betAmount += value
                        gameState.balance -= Double(value)
                        animatedBalance = gameState.balance
                    }
                }
                .opacity(gameState.balance >= Double(value) ? 1 : 0.4)
                .disabled(gameState.balance < Double(value))
                .scaleEffect(chipAnimations[value] == true ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: chipAnimations[value])
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var dealButtonView: some View {
        Button(action: {
            if betAmount > 0 && Double(betAmount) <= gameState.balance {
                SoundManager.shared.playButtonTap()
                SoundManager.shared.playDeal()
                dealInitialCards()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(betAmount > 0 ? Color(red: 1.0, green: 0.84, blue: 0.0) : Color.gray)
                
                Text("DEAL")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(betAmount > 0 ? Color(red: 1.0, green: 0.84, blue: 0.0) : Color.gray)
                    .tracking(1.2)
            }
            .frame(width: 120, height: 50)
            .background(dealButtonBackground)
        }
        .disabled(betAmount == 0 || Double(betAmount) > gameState.balance)
        .opacity(betAmount == 0 ? 0.4 : (Double(betAmount) > gameState.balance ? 0.5 : 1))
        .scaleEffect(betAmount == 0 ? 0.95 : (Double(betAmount) > gameState.balance ? 0.95 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: betAmount)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: Double(betAmount) > gameState.balance)
        .padding(.bottom, 15)  // Add space between deal button and balance bar
    }
    
    private var dealButtonBackground: some View {
        ZStack {
            // Glassmorphism background
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(betAmount > 0 ? 0.2 : 0.1),
                            Color.white.opacity(betAmount > 0 ? 0.05 : 0.02),
                            Color.black.opacity(betAmount > 0 ? 0.4 : 0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.black.opacity(0.3))
                )
            
            // Animated border
            RoundedRectangle(cornerRadius: 25)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            betAmount > 0 ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.9) : Color.gray.opacity(0.5),
                            betAmount > 0 ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6) : Color.gray.opacity(0.3),
                            betAmount > 0 ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.9) : Color.gray.opacity(0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .shadow(
                    color: betAmount > 0 ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6) : Color.clear, 
                    radius: betAmount > 0 ? 12 : 0, 
                    x: 0, 
                    y: 0
                )
            
            // Inner highlight
            RoundedRectangle(cornerRadius: 23)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            betAmount > 0 ? Color.white.opacity(0.3) : Color.gray.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.3), value: betAmount)
    }
    
    private var splitHandsView: some View {
        ZStack {
            VStack(spacing: 0) {
                // Fixed top spacing - never changes
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 80)
                
                // Split hands with enhanced transition animation
                ZStack {
                    HStack(spacing: 20) {
                        // Always show the first two hands (no rotation)
                        ForEach(0..<min(2, game.splitManager.hands.count), id: \.self) { displayIndex in
                            splitHandView(handIndex: displayIndex, isActive: game.splitManager.activeHandIndex == displayIndex && game.gameState == .playerTurn)
                                .modifier(SplitHandAnimationModifier(
                                    displayIndex: displayIndex,
                                    showPlayerHands: showPlayerHands,
                                    isTransitioningFromSplit: isTransitioningFromSplit,
                                    splitCollapseProgress: splitCollapseProgress
                                ))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Enhanced split transition overlay
                    if isSplitTransitioning {
                        VStack(spacing: 20) {
                            // Main split text with better animation
                            Text("SPLITTING CARDS")
                                .font(.title.bold())
                                .foregroundColor(.orange)
                                .opacity(1.0 - (splitTransitionProgress * 1.5))
                                .scaleEffect(0.5 + (splitTransitionProgress * 0.5))
                                .offset(y: -40)
                            
                            // Animated splitting effect
                            HStack(spacing: 80) {
                                // Left splitting line
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.yellow, Color.orange]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 3, height: 60)
                                    .scaleEffect(y: 1.0 - splitTransitionProgress)
                                    .shadow(color: .orange.opacity(0.8), radius: 4)
                                
                                // Center split indicator
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 12, height: 12)
                                    .scaleEffect(1.0 - splitTransitionProgress)
                                    .shadow(color: .orange.opacity(0.8), radius: 6)
                                
                                // Right splitting line
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.orange, Color.yellow, Color.orange]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 3, height: 60)
                                    .scaleEffect(y: 1.0 - splitTransitionProgress)
                                    .shadow(color: .orange.opacity(0.8), radius: 4)
                            }
                            .offset(y: 10)
                            
                            // Progress indicator
                            if splitTransitionProgress < 0.7 {
                                Text("Creating split hands...")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .offset(y: 30)
                            }
                        }
                        .animation(.easeInOut(duration: 0.4), value: splitTransitionProgress)
                    }
                    
                    // Cool collapse transition overlay
                    if isTransitioningFromSplit {
                        SplitCollapseTransitionOverlay(splitCollapseProgress: splitCollapseProgress)
                    }
                    
                    // Chip transfer animations (same as normal gameplay)
                    ForEach(0..<game.splitManager.hands.count, id: \.self) { handIndex in
                        if let position = splitChipPositions[handIndex], splitChipAnimations[handIndex] == true {
                            let hand = game.splitManager.hands[handIndex]
                            let chipDenomination = chipDenominationForBet(amount: hand.bet)
                            
                            SingleBetChipView(
                                denomination: chipDenomination, 
                                totalAmount: Int(hand.bet)
                            )
                            .frame(width: 30, height: 30)
                            .position(position)
                            .scaleEffect(0.9)
                            .opacity(0.8)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                
                // Fixed spacing between cards and buttons - never changes
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 40)
                
                // Bust message display - hide during dealer turn
                if showBustMessage && game.gameState != .dealerTurn {
                    Text(bustMessage)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showBustMessage)
                }
                
                // Action buttons for split hands
                splitActionButtonsView
                
                // Fixed spacing between buttons and balance - never changes
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 40)
                
                // Balance display for split view - grey out during dealer turn
                balanceDisplayView
                    .padding(.bottom, 20)
                    .opacity((game.gameState == .dealerTurn || dealerPeeking || isDealingCards) ? 0.4 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: game.gameState)
                    .animation(.easeInOut(duration: 0.3), value: dealerPeeking)
                    .animation(.easeInOut(duration: 0.3), value: isDealingCards)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: game.hasSplit && game.gameState == .dealerTurn ? dealerDrawingOffset : 0)
        .id(uiRefreshTrigger) // Force refresh when uiRefreshTrigger changes
    }
    
    private func splitHandView(handIndex: Int, isActive: Bool) -> some View {
        let hand = game.splitManager.hands[handIndex]
        let isBust = hand.isBust
        _ = hand.isComplete
        
        // Determine how many cards to show based on dealing step
        let cardsToShow: Int
        if splitDealingStep == 0 {
            cardsToShow = 0
        } else if splitDealingStep == 1 {
            cardsToShow = 1 // Only show first card
        } else {
            cardsToShow = hand.cards.count // Show all cards
        }
        
        return VStack(spacing: 12) {
            // Cards
            HStack(spacing: -8) {
                ForEach(0..<cardsToShow, id: \.self) { i in
                    let isLastCard = i == cardsToShow - 1
                    let shouldAnimate = isLastCard && isActive && hand.cards.count > 2
                    
                    CardView(card: hand.cards[i])
                        .shadow(radius: 4)
                        .scaleEffect(0.8)
                        .rotationEffect(.degrees(shouldAnimate ? splitHandCardRotation[handIndex] : 0))
                        .offset(y: shouldAnimate ? (splitHandCardFlyIn[handIndex] ? 0 : 200) : 0)
                        .animation(shouldAnimate ? .easeOut(duration: settingsManager.animationDuration) : nil, value: splitHandCardFlyIn[handIndex])
                }
            }
            .background(activeHandGlow(isActive: isActive))
            .overlay(activeHandBorder(isActive: isActive))
            .opacity(isBust ? 0.4 : 1.0) // Darken busted hands
            
            // Hand value
            if hand.cards.count > 0 {
                splitHandValueView(hand: hand)
            }
            
            // Status text removed - no bust text display
            
            // Betting circle
            bettingCircleForHand(handIndex: handIndex)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func activeHandGlow(isActive: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                isActive ? 
                AnyShapeStyle(RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3),
                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 20,
                    endRadius: 80
                )) : 
                AnyShapeStyle(Color.clear)
            )
            .shadow(
                color: isActive ? 
                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8) : 
                Color.clear, 
                radius: isActive ? 15 : 0
            )
            .padding(-8)
    }
    
    private func activeHandBorder(isActive: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isActive ? 
                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8) : 
                Color.clear, 
                lineWidth: 2
            )
            .padding(-8)
    }
    
    private func handValueView(hand: Hand) -> some View {
        let handValue = hand.value
        let handIsBust = handValue > 21
        let handIs21 = handValue == 21
        
        // Calculate hard value (all aces as 1)
        let hardValue = calculateHardValue(hand: hand)
        
        // Display format: show "hard/soft" for soft hands, just value for hard hands
        let displayText: String
        if hand.isSoft && hardValue != handValue {
            displayText = "\(hardValue)/\(handValue)"
        } else {
            displayText = "\(handValue)"
        }
        
        return Text(displayText)
            .font(.title3.bold())
            .foregroundColor(
                handIsBust ? .red : (handIs21 ? .green : .white)
            )
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.4))
            .cornerRadius(8)
    }
    
    private func splitHandValueView(hand: SplitHand) -> some View {
        let handValue = hand.value
        let handIsBust = handValue > 21
        let handIs21 = handValue == 21
        
        // Calculate hard value (all aces as 1)
        let hardValue = calculateSplitHandHardValue(hand: hand)
        
        // Display format: show "hard/soft" for soft hands, just value for hard hands
        let displayText: String
        if hand.isSoft && hardValue != handValue {
            displayText = "\(hardValue)/\(handValue)"
        } else {
            displayText = "\(handValue)"
        }
        
        return Text(displayText)
            .font(.title3.bold())
            .foregroundColor(
                handIsBust ? .red : (handIs21 ? .green : .white)
            )
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.4))
            .cornerRadius(8)
    }
    
    private func calculateHardValue(hand: Hand) -> Int {
        var value = 0
        
        for card in hand.cards {
            if card.rank == Rank.ace {
                value += 1 // All aces count as 1 for hard value
            } else {
                value += card.value
            }
        }
        
        return value
    }
    
    private func calculateSplitHandHardValue(hand: SplitHand) -> Int {
        var value = 0
        
        for card in hand.cards {
            if card.rank == Rank.ace {
                value += 1 // All aces count as 1 for hard value
            } else {
                value += card.value
            }
        }
        
        return value
    }
    
    private func bettingCircleForHand(handIndex: Int) -> some View {
        let hand = game.splitManager.hands[handIndex]
        let isBust = hand.isBust
        _ = game.gameState == .gameOver
        _ = splitHandResults[handIndex] != nil
        let chipAnimated = splitChipAnimations[handIndex] == true
        let hasMessage = splitHandMessages[handIndex] != nil
        
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.9)
                        ]),
                        center: .center,
                        startRadius: 15,
                        endRadius: 35
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.9),
                                    Color(red: 1.0, green: 0.84, blue: 0.0),
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                )
                .frame(width: 60, height: 60)
                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6), radius: 8, x: 0, y: 2)
                .opacity(isBust ? 0.3 : (bettingCirclesVisible ? 1.0 : 0.0)) // Dim the circle when bust
                .scaleEffect(bettingCirclesVisible ? 1.0 : 0.8) // Scale effect
            
            // Show per-hand message or chip
            if hasMessage {
                // Show per-hand result message
                if let message = splitHandMessages[handIndex] {
                    Text(message)
                        .font(.caption.bold())
                        .foregroundColor(message == "You Win" ? .green : (message == "Dealer Wins" ? .red : .yellow))
                        .multilineTextAlignment(.center)
                        .transition(.scale.combined(with: .opacity))
                }
            } else if !isBust && !chipAnimated && game.gameState != .gameOver && game.gameState != .dealerTurn {
                // Show chip when not bust and not animated and game not over and not dealer turn
                let chipDenomination = chipDenominationForBet(amount: hand.bet)
                SingleBetChipView(
                    denomination: chipDenomination, 
                    totalAmount: Int(hand.bet)
                )
                .frame(width: 30, height: 30)
                .scaleEffect(chipAnimated ? 0.1 : 1.0)
                .opacity(chipAnimated ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 1.0), value: chipAnimated)
            }
        }
    }
    
    private var splitActionButtonsView: some View {
        Group {
            // Show buttons during split hands, but hide during dealer turn
            if game.hasSplit && game.gameState != .dealerTurn {
                if game.gameState == .gameOver {
                    // Game over buttons
                    HStack(spacing: 20) {
                        // Edit Bet button (left side)
                        RoundedButton(
                            title: "Edit Bet",
                            background: Color.black.opacity(0.13),
                            foreground: Color.white.opacity(0.72),
                            action: {
                                // Return the current bet to the balance before resetting
                                if gameState.currentBet > 0 {
                                    gameState.addFunds(gameState.currentBet)
                                }
                                // Reset the game state
                                game.reset()
                                betAmount = 0
                                // Reset any animation states
                                dealt = false
                                playerDealtCount = 0
                                dealerDealtCount = 0
                                showGameResultText = false
                            }
                        )
                        .frame(width: 90, height: 40)
                        
                        // Play Again button (right side)
                        RoundedButton(
                            title: "Play Again",
                            background: Color.green.opacity(0.2),
                            foreground: Color.green,
                            action: {
                                if game.originalBet > 0 && game.originalBet <= gameState.balance {
                                    // Set the view's bet amount for the new round from the original bet
                                    betAmount = Int(game.originalBet)
                                    // Deduct the bet amount from balance (since dealInitialCards expects it to be already deducted)
                                    gameState.placeBet(Double(betAmount))
                                    animatedBalance = gameState.balance
                                    // Use the cool transition instead of direct deal
                                    performSplitToNormalTransition()
                                }
                            }
                        )
                        .frame(width: 100, height: 40)
                    }
                    .padding(.bottom, 20)
                } else {
                    // Regular action buttons during gameplay
                    let activeHand = game.splitManager.activeHand
                    
                    HStack(spacing: 20) {
                        // Stand button
                        RoundedButton(
                            title: "Stand",
                            background: Color.black.opacity(0.13),
                            foreground: Color.white.opacity(0.72),
                            action: {
                                print("DEBUG UI: Standing on hand \(game.splitManager.activeHandIndex + 1)")
                                SoundManager.shared.playStandButton()
                                game.standOnActiveHand()
                                // Force UI refresh
                                DispatchQueue.main.async {
                                    self.uiRefreshTrigger.toggle()
                                }
                            }
                        )
                        .frame(width: 70, height: 40)
                        
                        // Hit button - only enabled if hand is not complete/bust
                        RoundedButton(
                            title: "Hit",
                            background: Color.green.opacity(0.2),
                            foreground: Color.green,
                            action: {
                                print("DEBUG UI: Hitting on hand \(game.splitManager.activeHandIndex + 1)")
                                SoundManager.shared.playHitButton()
                                hitOnActiveHand()
                            }
                        )
                        .frame(width: 70, height: 40)
                        .opacity((activeHand?.isComplete == true || activeHand?.isBust == true) ? 0.3 : 1.0)
                        .disabled(activeHand?.isComplete == true || activeHand?.isBust == true)
                        .onAppear {
                            if let hand = activeHand {
                                print("DEBUG UI: Hit button - hand value: \(hand.value), isComplete: \(hand.isComplete), isBust: \(hand.isBust)")
                            }
                        }
                        
                        // Double button - only enabled if hand is not complete/bust and has exactly 2 cards
                        RoundedButton(
                            title: "Double",
                            background: Color.black.opacity(0.13),
                            foreground: Color.white.opacity(0.72),
                            action: {
                                print("🎯 Double down button pressed for split hand")
                                print("🎯 Can double down: \(game.canDoubleDownOnActiveHand(balance: gameState.balance))")
                                print("🎯 Active hand index: \(game.splitManager.activeHandIndex)")
                                print("🎯 Hand cards count: \(game.splitManager.hands[game.splitManager.activeHandIndex].cards.count)")
                                print("🎯 Hand value: \(game.splitManager.hands[game.splitManager.activeHandIndex].value)")
                                print("🎯 Hand bet: \(game.splitManager.hands[game.splitManager.activeHandIndex].bet)")
                                print("🎯 Current balance: \(gameState.balance)")
                                
                                SoundManager.shared.playDoubleButton()
                                let additionalBet = game.doubleDownOnActiveHand(balance: gameState.balance)
                                print("🎯 Additional bet returned: \(additionalBet)")
                                
                                if additionalBet > 0 {
                                    // Deduct the additional bet from balance immediately
                                    gameState.balance -= additionalBet
                                    animatedBalance = gameState.balance
                                    
                                    print("🎯 New balance after double down: \(gameState.balance)")
                                    
                                    // Animate additional chip to betting circle
                                    animateDoubleDownChip(amount: additionalBet)
                                    
                                    // Ensure all cards are visible after double down
                                    splitDealingStep = 2
                                    
                                    // Animate the double down card for the active hand
                                    let activeHandIndex = game.splitManager.activeHandIndex
                                    splitHandCardFlyIn[activeHandIndex] = false
                                    splitHandCardRotation[activeHandIndex] = 90
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            self.splitHandCardFlyIn[activeHandIndex] = true
                                            self.splitHandCardRotation[activeHandIndex] = 0
                                        }
                                    }
                                } else {
                                    print("🎯 Double down failed - no additional bet returned")
                                }
                            }
                        )
                        .frame(width: 70, height: 40)
                        .opacity(game.canDoubleDownOnActiveHand(balance: gameState.balance) ? 1.0 : 0.3)
                        .disabled(!game.canDoubleDownOnActiveHand(balance: gameState.balance))
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private var bettingControlsView: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Use custom button positioning for betting state
                // Hide buttons during dealer peeking and dealer drawing
                if game.gameState != .dealerTurn {
                    bettingTopButtonsView
                }
                
                Spacer()
                
                VStack(spacing: 10) {
                    // Bet display
                    HStack(spacing: 8) {
                        Image(systemName: "circle.grid.cross")
                            .foregroundColor(.yellow)
                        Text("Bet: $\(betAmount)")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        Button("Clear") { 
                            // Restore the bet amount to balance before clearing
                            gameState.balance += Double(betAmount)
                            betAmount = 0 
                        }
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 4)

                    balanceDisplayView

                    // Chips bar - Minimal spacing between chips
                    HStack(spacing: 2) {
                        ForEach(chipValues, id: \.self) { value in
                            ChipView(value: value) {
                                SoundManager.shared.playChipSelect()
                                betAmount += value
                            }
                            .opacity(gameState.balance >= Double(betAmount + value) ? 1 : 0.4)
                            .disabled(gameState.balance < Double(betAmount + value))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .padding(.bottom, 40)
                
                // Deal button
                Button(action: {
                    if betAmount > 0 && Double(betAmount) <= gameState.balance {
                        SoundManager.shared.playButtonTap()
                        SoundManager.shared.playDeal()
                        dealInitialCards()
                    }
                }) {
                    Text("Deal")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(width: 160, height: 48)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .cyan]), 
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                }
                .disabled(betAmount == 0 || Double(betAmount) > gameState.balance)
                .opacity(betAmount == 0 || Double(betAmount) > gameState.balance ? 0.5 : 1)
                .padding(.bottom, 60)
            }
        }
    }

    private var insuranceControlsView: some View {
        VStack(spacing: 12) {
            Text("Insurance?")
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(.top, 8)  // Reduced padding to bring Insurance? text closer to balance bar
            
            // Show insurance bet amount if placed
            if gameState.insuranceBet > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                    
                    Text("Insurance Bet: $\(Int(gameState.insuranceBet))")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: gameState.insuranceBet > 0)
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    SoundManager.shared.playButtonTap()
                    animateInsuranceCardCheck {
                        game.playerRespondedToInsurance(insuranceTaken: false)
                    }
                }) {
                    Text("No")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(width: 70, height: 30)
                        .background(Color.red)
                        .cornerRadius(12)
                }
                Button(action: {
                    SoundManager.shared.playChipSelect()
                    // First animate the insurance chip
                    animateInsuranceChip()
                    
                    animateInsuranceCardCheck {
                        gameState.placeInsuranceBet()
                        animatedBalance = gameState.balance  // Update animated balance immediately when insurance is placed
                        game.playerRespondedToInsurance(insuranceTaken: true)
                    }
                }) {
                    Text("Yes")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(width: 70, height: 30)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .disabled(gameState.balance < (gameState.currentBet / 2))
            }
        }
        .padding(.bottom, 80)  // Increased bottom padding to prevent buttons from touching bottom of phone
    }

    // Simplified split functionality - no separate split controls view needed

    private var gameControlsView: some View {
        VStack(spacing: 0) {
            if false { // Game over buttons moved to main action buttons area
                // Show buttons only after animations finish
                HStack(alignment: .center, spacing: 40) {
                    // Edit Bet button
                    Button(action: {
                        // Return the current bet to the balance before resetting
                        if gameState.currentBet > 0 {
                            gameState.addFunds(gameState.currentBet)
                        }
                        // Reset game to betting state
                        game.reset()
                        betAmount = 0
                        // Reset any animation states
                        dealt = false
                        playerDealtCount = 0
                        dealerDealtCount = 0
                        showGameResultText = false
                    }) {
                        Text("Edit Bet")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 90, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 25, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.black.opacity(0.13).opacity(0.9),
                                                Color.black.opacity(0.13).opacity(0.6),
                                                Color.black.opacity(0.13).opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8),
                                                        Color(red: 1.0, green: 0.84, blue: 0.0)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2.5
                                            )
                                    )
                                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), radius: 8, x: 0, y: 4)
                                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.2),
                                                        Color.clear
                                                    ]),
                                                    startPoint: .top,
                                                    endPoint: .center
                                                )
                                            )
                                    )
                            )
                    }
                    
                    // Play Again button
                    Button(action: {
                        if game.originalBet > 0 && game.originalBet <= gameState.balance {
                            // Set the view's bet amount for the new round from the original bet
                            betAmount = Int(game.originalBet)
                            // Deduct the bet amount from balance (since dealInitialCards expects it to be already deducted)
                            gameState.balance -= game.originalBet
                            animatedBalance = gameState.balance
                            // Use the cool transition instead of direct deal
                            performSplitToNormalTransition()
                        }
                    }) {
                        Text("Play Again")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 90, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 25, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.black.opacity(0.13).opacity(0.9),
                                                Color.black.opacity(0.13).opacity(0.6),
                                                Color.black.opacity(0.13).opacity(0.8)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8),
                                                        Color(red: 1.0, green: 0.84, blue: 0.0)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2.5
                                            )
                                    )
                                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), radius: 8, x: 0, y: 4)
                                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.2),
                                                        Color.clear
                                                    ]),
                                                    startPoint: .top,
                                                    endPoint: .center
                                                )
                                            )
                                    )
                            )
                    }
                    .disabled(game.originalBet == 0 || game.originalBet > gameState.balance)
                    .opacity(game.originalBet == 0 || game.originalBet > gameState.balance ? 0.5 : 1)
                    .scaleEffect(game.originalBet == 0 || game.originalBet > gameState.balance ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: game.originalBet == 0 || game.originalBet > gameState.balance)
                }
            }
        }
        .padding(.bottom, 80)  // Fixed bottom padding - never changes
    }
    
    private var dealerCardCount: Int {
        let count = if game.gameState == .gameOver {
            // When game is over, always show all dealer cards
            game.dealerHand.cards.count
        } else {
            // During play, use the animated count
            dealerDealtCount
        }
        
        // Debug logging
        print("🔍 Dealer card count: \(count), game state: \(game.gameState), actual cards: \(game.dealerHand.cards.count), dealerDealtCount: \(dealerDealtCount)")
        
        return count
    }
    
    private func dealerCardFaceUp(at i: Int) -> Bool {
        // First card is always face up
        if i == 0 { return true }
        
        // Second card (hole card) is face up if:
        // - Game is over (all cards revealed)
        // - Hole card has been flipped (for both normal and split games)
        return game.gameState == .gameOver || dealerHoleCardFlipped
    }
    
    private func dealerCardOffset(at i: Int, cardCount: Int, flyIn: Bool) -> CGSize {
        let x = CGFloat(i - cardCount / 2) * 12 + (i == 1 ? holeCardPeekOffset : 0)
        let y = abs(CGFloat(i - cardCount / 2)) * 2 + (flyIn ? 0 : 200) + (i == 1 ? holeCardPeekOffset * 0.3 : 0)
        return CGSize(width: x, height: y)
    }

    private var dealerAreaViewNoLabel: some View {
        VStack(spacing: 6) {
            HStack(spacing: -8) {
                ForEach(0..<dealerCardCount, id: \.self) { i in
                    if i < game.dealerHand.cards.count {
                        let cardCount = dealerCardCount
                        let angle = Double(i - cardCount / 2) * 6
                        let flyIn = dealerCardFlyIn.indices.contains(i) ? dealerCardFlyIn[i] : true
                        let rotation =
                            dealerCardRotation.indices.contains(i) ? dealerCardRotation[i] : 0.0
                        
                        // Debug logging for each card
                        let _ = {
                            let card = game.dealerHand.cards[i]
                            print("🔍 Displaying dealer card \(i): \(card.rank.stringValue)\(card.suit.rawValue) (\(card.value)), faceUp: \(dealerCardFaceUp(at: i))")
                        }()
                        
                        CardView(
                            card: game.dealerHand.cards[i],
                            faceUp: dealerCardFaceUp(at: i),
                            rotationAngle: rotation
                        )
                        .shadow(radius: 4)
                        .rotationEffect(.degrees(angle))
                        .offset(dealerCardOffset(at: i, cardCount: cardCount, flyIn: flyIn))
                        .scaleEffect(i == 1 && dealerPeeking ? 1.1 : 1.0)
                        .shadow(
                            radius: i == 1 && dealerPeeking ? 12 : 4,
                            x: 0,
                            y: i == 1 && dealerPeeking ? 8 : 0
                        )
                        .shadow(
                            color: i == 1 && dealerPeeking ? Color.yellow.opacity(0.6) : Color.clear,
                            radius: i == 1 && dealerPeeking ? 8 : 0,
                            x: 0,
                            y: 0
                        )
                        .animation(game.gameState == .gameOver ? nil : .easeInOut(duration: 0.8), value: holeCardPeekOffset)
                        .animation(game.gameState == .gameOver ? nil : .easeInOut(duration: 0.8), value: dealerPeeking)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(game.gameState == .gameOver ? nil : .easeOut(duration: 0.5), value: flyIn)
                        .zIndex(Double(cardCount - i))
                    }
                }
            }
            .id(game.dealerHand.cards.count)
            .frame(height: 75)
            if game.dealerHand.cards.count > 0 && game.gameState != .offeringInsurance {
                let dealerValue = game.dealerHand.dealerValue(
                    isDealerTurn: game.gameState == .dealerTurn || game.gameState == .gameOver)  // Hide hole card during insurance
                let dealerIsBust = dealerValue > 21
                let dealerIs21 = dealerValue == 21
                
                // Debug logging for dealer value
                let _ = {
                    if game.dealerHand.cards.count >= 2 {
                        let card1 = game.dealerHand.cards[0]
                        let card2 = game.dealerHand.cards[1]
                        print("🔍 Dealer cards: \(card1.rank.stringValue)\(card1.suit.rawValue) (\(card1.value)) + \(card2.rank.stringValue)\(card2.suit.rawValue) (\(card2.value)) = \(dealerValue)")
                    }
                }()
                
                Text("\(dealerValue)")
                    .font(.title3.bold())
                    .foregroundColor(dealerIsBust ? .red : (dealerIs21 ? .green : .white))
                    .padding(.top, 2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(6)
            }
        }
        .padding(.bottom, 0)  // Fixed bottom padding - never changes
    }

    private var playerAreaView: some View {
        VStack(spacing: 6) {
            // Add minimal top padding when game is over to prevent covering the "Insurance pays 2 to 1" text
            if game.gameState == .gameOver {
                Spacer()
                    .frame(height: 5)  // Minimal spacing to prevent spread out layout
            }
            
            // Only show betting interface when in the initial betting state
            if game.gameState == .betting && game.playerHand.cards.isEmpty {
                bettingInterfaceView
            }
            else if game.hasSplit {
                splitHandsView
            } else {
                ZStack {
                    // Hand icon (only visible during tap)
                    if showHandIcon {
                        Image(
                            systemName: handIconType == "tap"
                                ? "hand.point.up.left.fill" : "hand.point.up.left.fill"
                        )
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: handIconSize, height: handIconSize)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        .offset(handIconPosition)
                        .rotationEffect(.degrees(handIconRotation))
                        .opacity(handIconOpacity)
                        .zIndex(2)
                    }
                    // Only show regular player cards when NOT in split mode
                    if !game.hasSplit {
                        VStack(spacing: 0) {
                            HStack(spacing: -12) {
                                ForEach(0..<playerDealtCount, id: \.self) { i in
                                    if i < game.playerHand.cards.count {
                                    let angle = Double(i - playerDealtCount / 2) * 6
                                    if i < 2 {
                                        CardView(
                                            card: game.playerHand.cards[i],
                                            rotationAngle: playerCardRotation[i]
                                        )
                                        .shadow(radius: 4)
                                        .rotationEffect(.degrees(angle))
                                        .offset(
                                            x: CGFloat(i - playerDealtCount / 2) * 12,
                                            y: abs(CGFloat(i - playerDealtCount / 2)) * 2
                                                + (playerCardFlyIn[i] ? 0 : 200)
                                        )
                                        .transition(
                                            .move(edge: .bottom).combined(with: .opacity)
                                        )
                                        .animation(
                                            game.gameState == .gameOver ? nil : .easeOut(duration: 0.5), value: playerCardFlyIn[i])
                                    } else if i == playerDealtCount - 1
                                        && game.playerHand.cards.count == playerDealtCount
                                        && game.playerHand.cards.count > 2
                                    {
                                        CardView(
                                            card: game.playerHand.cards[i],
                                            rotationAngle: lastCardRotation
                                        )
                                        .shadow(radius: 4)
                                        .rotationEffect(.degrees(angle))
                                        .offset(
                                            x: CGFloat(i - playerDealtCount / 2) * 12,
                                            y: abs(CGFloat(i - playerDealtCount / 2)) * 2
                                                + (lastCardFlyIn ? 0 : 200)
                                        )
                                        .transition(
                                            .move(edge: .bottom).combined(with: .opacity)
                                        )
                                        .animation(
                                            game.gameState == .gameOver ? nil : .easeOut(duration: 0.5), value: lastCardFlyIn)
                                    } else {
                                        CardView(card: game.playerHand.cards[i])
                                            .shadow(radius: 4)
                                            .rotationEffect(.degrees(angle))
                                            .offset(
                                                x: CGFloat(i - playerDealtCount / 2) * 12,
                                                y: abs(CGFloat(i - playerDealtCount / 2)) * 2
                                            )
                                            .transition(
                                                .move(edge: .bottom).combined(with: .opacity)
                                            )
                                            .animation(
                                                game.gameState == .gameOver ? nil : .easeOut(duration: 0.4).delay(Double(i) * 0.2),
                                                value: playerDealtCount)
                                    }
                                }
                            }
                        }
                        .id(game.playerHand.cards.count)
                        .frame(height: 100)
                        .padding(.top, game.gameState == .gameOver ? 100 : 0)  // Move down more when game over
                        if game.playerHand.cards.count > 0 {
                            let playerValue = game.playerHand.value
                            let playerIsBust = playerValue > 21
                            let playerIs21 = playerValue == 21
                            VStack(spacing: 15) {
                                Text(playerHandValueText)
                                    .font(.title3.bold())
                                    .foregroundColor(
                                        playerIsBust ? .red : (playerIs21 ? .green : .white)
                                    )
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(8)
                                    .padding(.top, -10)  // Fixed padding - never changes
                                Spacer().frame(height: 15)  // Fixed spacing - never changes
                                if (game.gameState != .betting && !game.hasSplit) || dealerPeeking || isDealingCards {
                                    circularBetDisplayView
                                        .opacity((game.gameState == .dealerTurn || dealerPeeking || isDealingCards) ? 0.4 : 1.0)
                                        .animation(.easeInOut(duration: 0.3), value: game.gameState)
                                        .animation(.easeInOut(duration: 0.3), value: dealerPeeking)
                                        .animation(.easeInOut(duration: 0.3), value: isDealingCards)
                                }
                            }
                            .padding(.top, 20)
                            // Animation disabled to prevent layout shifting
                        }
                    }
                    .zIndex(1)
                    .allowsHitTesting(game.gameState != .offeringInsurance)
                    }
                }
            }
        }
        .padding(.top, 0)  // Fixed top padding - never changes
        .opacity(showNormalGameplay ? 1.0 : 0.0)
        // Animation disabled to prevent layout shifting
    }

    private var topButtonsView: some View {
        HStack(spacing: 20) {  // Close spacing between buttons
            // Exit button (left) - hidden during dealer drawing
            if game.gameState != .dealerTurn && (dealt || game.gameState == .betting) {
                Button(action: {
                    showHomeConfirm = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2.bold())
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), radius: 4, y: 2)
                }
                .padding(.leading, 40)  // Position from left edge
                .padding(.top, 110)  // Even lower positioning
                .alert("Leave Current Game?", isPresented: $showHomeConfirm) {
                    Button("Stay & Continue Playing", role: .cancel) {}
                    Button("Leave Game", role: .destructive) {
                        SoundManager.shared.playBackButton()
                        forfeitCurrentBetAndLeave()
                    }
                } message: {
                    Text(game.gameState == .betting && !dealt ? 
                         "Your current bet of $\(Int(gameState.currentBet)) will be returned to your balance. Are you sure you want to return to the main menu?" :
                         "Your current game progress will be lost and you will forfeit your current bet of $\(Int(gameState.currentBet)). Are you sure you want to return to the main menu?")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            // Settings button (right) - hidden during dealer drawing
            if game.gameState != .dealerTurn && (dealt || game.gameState == .betting) {
                SettingsIconView {
                    print("DEBUG: Settings button tapped (main game)")
                    navigateToSettings = true
                }
                .padding(.trailing, 40)  // Position from right edge
                .padding(.top, 110)  // Even lower positioning
            }
        }
    }

    private var bettingTopButtonsView: some View {
        HStack(spacing: 20) {  // Close spacing between buttons
            // Exit button (left) - positioned higher for betting view
            if game.gameState != .dealerTurn {
                Button(action: {
                    showHomeConfirm = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2.bold())
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), radius: 4, y: 2)
                }
                .padding(.leading, 40)  // Position from left edge
                .padding(.top, -20)  // Move buttons up much more for betting view
                .alert("Leave Current Game?", isPresented: $showHomeConfirm) {
                    Button("Stay & Continue Playing", role: .cancel) {}
                    Button("Leave Game", role: .destructive) {
                        SoundManager.shared.playBackButton()
                        forfeitCurrentBetAndLeave()
                    }
                } message: {
                    Text(game.gameState == .betting && !dealt ? 
                         "Your current bet of $\(Int(gameState.currentBet)) will be returned to your balance. Are you sure you want to return to the main menu?" :
                         "Your current game progress will be lost and you will forfeit your current bet of $\(Int(gameState.currentBet)). Are you sure you want to return to the main menu?")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            // Settings button (right) - positioned higher for betting view
            if game.gameState != .dealerTurn {
                SettingsIconView {
                    print("DEBUG: Settings button tapped (betting view)")
                    navigateToSettings = true
                }
                .padding(.trailing, 40)  // Position from right edge
                .padding(.top, -20)  // Move buttons up much more for betting view
            }
        }
    }

    private var circularBetDisplayView: some View {
        VStack(spacing: 4) {  // Minimal spacing to match active game state exactly
            // Spacer to separate betting circle and player's card number
            VStack(spacing: 8) {
                Spacer()
                    .frame(height: 10)
                
                // Bet circle (moved above the buttons)
                ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.8),
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.9)
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.9),
                                        Color(red: 1.0, green: 0.84, blue: 0.0),
                                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3.5
                            )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6), radius: 12, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
                
                // Show result message when game is over, otherwise show chip
                if game.gameState == .gameOver && showGameResultText {
                    Text(game.resultMessage)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(resultColor)
                        .multilineTextAlignment(.center)
                        .shadow(color: resultColor.opacity(0.3), radius: 2, x: 1, y: 1)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: -1, y: -1)
                } else if showChipInCircle {
                    let chipDenomination = chipDenominationForBet(amount: game.currentBet)
                    SingleBetChipView(
                        denomination: chipDenomination, totalAmount: Int(game.currentBet)
                    )
                    .frame(width: 35, height: 35)
                }
            }
            }
            
            // Action buttons row - centered with equal spacing
            HStack(alignment: .center, spacing: 20) {
                // Game over buttons
                if game.gameState == .gameOver && showGameOverButtons {
                    // Edit Bet button (left side)
                    RoundedButton(
                        title: "Edit Bet",
                        background: Color.black.opacity(0.13),
                        foreground: Color.white.opacity(0.72),
                        action: {
                            // Return the current bet to the balance before resetting
                            if gameState.currentBet > 0 {
                                gameState.addFunds(gameState.currentBet)
                            }
                            // Reset to betting state
                            game.reset()
                            gameState.currentBet = 0
                            betAmount = 0
                            // Reset any animation states
                            dealt = false
                            playerDealtCount = 0
                            dealerDealtCount = 0
                            showGameResultText = false
                        }
                    )
                    .frame(width: 90, height: 40)
                    
                    // Play Again button (right side)
                    RoundedButton(
                        title: "Play Again",
                        background: Color.green.opacity(0.2),
                        foreground: Color.green,
                        action: {
                            if game.originalBet > 0 && game.originalBet <= gameState.balance {
                                // Set the view's bet amount for the new round from the original bet
                                betAmount = Int(game.originalBet)
                                // Deduct the bet amount from balance (since dealInitialCards expects it to be already deducted)
                                gameState.balance -= game.originalBet
                                animatedBalance = gameState.balance
                                // Reuse the main deal function to start the next round
                                dealInitialCards()
                            }
                        }
                    )
                    .frame(width: 100, height: 40)
                    .opacity((game.originalBet > 0 && game.originalBet <= gameState.balance) ? 1.0 : 0.3)
                    .disabled(!(game.originalBet > 0 && game.originalBet <= gameState.balance))
                } else if game.gameState == .playerTurn && game.gameState != .offeringInsurance {
                    // Regular game buttons
                    // Stand button
                    RoundedButton(
                        title: "Stand",
                        background: Color.black.opacity(0.13),
                        foreground: Color.white.opacity(0.72),
                        action: {
                            SoundManager.shared.playStandButton()
                            if game.hasSplit {
                                game.standOnActiveHand()
                            } else {
                                playerStand()
                            }
                        }
                    )
                    .frame(width: 70, height: 40)
                    
                    // Split button (only when split is available)
                    if shouldShowSplitPrompt {
                        RoundedButton(
                            title: "Split",
                            background: Color.orange.opacity(0.2),
                            foreground: Color.orange,
                            action: {
                                // Add haptic feedback for split action
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                // Play split button sound
                                SoundManager.shared.playSplitButton()
                                
                                // Start the enhanced split transition sequence
                                startSplitTransitionSequence()
                            }
                        )
                        .frame(width: 70, height: 40)
                    }
                    
                    // Hit button (always centered)
                    RoundedButton(
                        title: "Hit",
                        background: Color.green.opacity(0.2),
                        foreground: Color.green,
                        action: {
                            SoundManager.shared.playHitButton()
                            if game.hasSplit {
                                hitOnActiveHand()
                            } else {
                                playerHit()
                            }
                        }
                    )
                    .frame(width: 70, height: 40)
                    
                    // Double button - always visible but faded when not available
                    RoundedButton(
                        title: "Double",
                        background: Color.black.opacity(0.13),
                        foreground: Color.white.opacity(0.72),
                        action: {
                            SoundManager.shared.playDoubleButton()
                            if game.hasSplit {
                                let additionalBet = game.doubleDownOnActiveHand(balance: gameState.balance)
                                if additionalBet > 0 {
                                    // Deduct the additional bet from balance immediately
                                    gameState.balance -= additionalBet
                                    animatedBalance = gameState.balance
                                    
                                    // Animate additional chip to betting circle
                                    animateDoubleDownChip(amount: additionalBet)
                                    
                                    // Ensure all cards are visible after double down
                                    splitDealingStep = 2
                                    
                                    // Animate the double down card for the active hand
                                    let activeHandIndex = game.splitManager.activeHandIndex
                                    splitHandCardFlyIn[activeHandIndex] = false
                                    splitHandCardRotation[activeHandIndex] = 90
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            self.splitHandCardFlyIn[activeHandIndex] = true
                                            self.splitHandCardRotation[activeHandIndex] = 0
                                        }
                                    }
                                }
                            } else {
                                doubleDown()
                            }
                        }
                    )
                    .frame(width: 70, height: 40)
                    .opacity((game.hasSplit ? game.canDoubleDownOnActiveHand(balance: gameState.balance) : canDoubleDown) ? 1.0 : 0.3)
                    .disabled(!(game.hasSplit ? game.canDoubleDownOnActiveHand(balance: gameState.balance) : canDoubleDown))
                }
            }
            .padding(.top, 15)  // Add space between buttons and betting circle

            // Balance display always visible
            balanceDisplayView
                .scaleEffect(animateBalance ? 1.2 : 1)
                .opacity(game.gameState == .dealerTurn ? 0.4 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: game.gameState)
                .shadow(
                    color: animateBalance && game.payout > 0 ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8) : .clear,  // Gold glow
                    radius: 15
                )
                .overlay(
                    // Sparkle effect when balance changes
                    Group {
                        if animateBalance && game.payout > 0 {
                            ForEach(0..<6, id: \.self) { i in
                                Image(systemName: "sparkle")
                                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                                    .font(.system(size: 12))
                                    .offset(
                                        x: CGFloat.random(in: -50...50),
                                        y: CGFloat.random(in: -30...30)
                                    )
                                    .opacity(animateBalance ? 1 : 0)
                                    .animation(.easeOut(duration: 2.0).delay(Double(i) * 0.2), value: animateBalance)
                            }
                        }
                    }
                )
                .padding(.top, 12)
                .padding(.bottom, 5)  // Minimal bottom padding to match active game state exactly
        }
        .padding(.top, 20)  // Fixed top padding - never changes
        .scaleEffect(1.0)  // Fixed scale - never changes
        .offset(y: 0) // Fixed offset - never changes
        // No animations - elements stay in fixed position
    }

    private var balanceDisplayView: some View {
        HStack(spacing: 12) {
            // Balance content
            VStack(spacing: 2) {
                Text("BALANCE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1.2)
                
                HStack(spacing: 6) {
                    // Add funds button - only show when not in betting state
                    if game.gameState != .betting {
                        Button(action: {
                            showingAddFunds = true
                            SoundManager.shared.playButtonTap()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .shadow(color: Color.green.opacity(0.3), radius: 3, x: 0, y: 1)
                        )
                        .offset(y: -2) // Move up slightly
                    }
                    
                    Text("$\(String(format: "%.0f", animatedBalance))")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.5), value: animatedBalance)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(x: game.gameState != .betting ? -10 : 0) // Shift left
                    
                    // Add spacer to balance the + icon on the left for perfect centering
                    if game.gameState != .betting {
                        Spacer()
                            .frame(width: 20) // Match the width of the + icon
                    }
                    
                    if showBalanceChange && balanceChangeAmount != 0 {
                        HStack(spacing: 3) {
                            Image(systemName: balanceChangeAmount > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(balanceChangeAmount > 0 ? .green : .red)
                            
                            Text(
                                String(
                                    format: "%@%.0f", balanceChangeAmount > 0 ? "+$" : "-$",
                                    abs(balanceChangeAmount))
                            )
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(balanceChangeAmount > 0 ? .green : .red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(balanceChangeAmount > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(balanceChangeAmount > 0 ? Color.green.opacity(0.5) : Color.red.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.6, dampingFraction: 0.8)),
                            removal: .opacity.animation(.easeOut(duration: 0.3))
                        ))
                    }
                }
            }
            .frame(maxWidth: .infinity) // Allow full width for balance display
        }
        .padding(.horizontal, 60)  // Give more space for balance content
        .padding(.vertical, 16)
        .background(
            ZStack {
                // Glassmorphism background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.3))
                    )
                
                // Animated border
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8),
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4),
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6), radius: 8, x: 0, y: 0)
                
                // Subtle inner glow
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2), radius: 20, x: 0, y: 0)
        .padding(.horizontal, 0)
        .padding(.bottom, 4)
        .overlay(
            // Animated chip that flies to player/dealer
            Group {
                if !showChipInCircle && game.gameState == .gameOver && !game.hasSplit {
                    animatedChipView
                }
            }
        )
    }
    
    // MARK: - Animated Chip View
    private var animatedChipView: some View {
        let chipDenomination = chipDenominationForBet(amount: game.currentBet)
        let totalAmount = Int(game.currentBet)
        
        return SingleBetChipView(
            denomination: chipDenomination, 
            totalAmount: totalAmount
        )
        .frame(width: 50, height: 50)
        .offset(chipAnimationOffset)
        .scaleEffect(chipScale)
        .rotationEffect(.degrees(chipRotation))
        .opacity(chipOpacity)
        .shadow(
            color: Color.black.opacity(0.3), 
            radius: chipScale > 1.0 ? 8 : 4, 
            x: 0, 
            y: chipScale > 1.0 ? 4 : 2
        )
        .animation(.easeInOut(duration: 1.0), value: chipAnimationOffset)
        .animation(.easeInOut(duration: 1.0), value: chipScale)
        .animation(.easeInOut(duration: 1.0), value: chipRotation)
        .animation(.easeInOut(duration: 1.0), value: chipOpacity)
    }

    // MARK: - Animation Functions
    private func animateDoubleDownChip(amount: Double) {
        // Create a flying chip animation for the additional bet
        let chipValue = Int(amount)
        
        // Start position (from balance area)
        let startPosition = CGPoint(
            x: UIScreen.main.bounds.width / 2,
            y: UIScreen.main.bounds.height - 100
        )
        
        // End position (betting circle of active hand)
        let activeHandIndex = game.splitManager.activeHandIndex
        let endPosition = CGPoint(
            x: UIScreen.main.bounds.width / 2 + (activeHandIndex == 0 ? -100 : 100),
            y: UIScreen.main.bounds.height - 200
        )
        
        // Create animated chip using existing structure
        var animatedChip = AnimatingChip(
            value: chipValue,
            position: startPosition
        )
        animatedChip.isAnimating = true
        
        animatingChips.append(animatedChip)
        
        // Animate chip to end position
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 1.0)) {
                if let index = self.animatingChips.firstIndex(where: { $0.value == chipValue }) {
                    self.animatingChips[index].position = endPosition
                }
            }
        }
        
        // Remove chip after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.animatingChips.removeAll { $0.value == chipValue }
        }
    }
    
    private func animateChipFromCircle() {
        let isWin = game.payout > 0
        
        // Determine target position based on win/loss
        let targetOffset: CGSize
        if isWin {
            // Move to player area (bottom of screen) - more natural path
            targetOffset = CGSize(width: 0, height: 180)
        } else {
            // Move all the way to dealer's cards area (much higher up - to the very top)
            targetOffset = CGSize(width: 0, height: -400)
        }
        
        // Hide chip from circle
        withAnimation(.easeInOut(duration: 0.3)) {
            showChipInCircle = false
        }
        
        // Animate chip flying to target
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // First phase: slight lift and tilt (like being picked up)
            withAnimation(.easeOut(duration: 0.3)) {
                chipAnimationOffset = CGSize(width: 0, height: isWin ? 20 : -20)
                chipScale = 1.1
                chipRotation = isWin ? 15 : -15
            }
            
            // Second phase: move to destination with smooth curve
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Much longer duration for losses since they travel much further
                let moveDuration = isWin ? 0.8 : 1.4
                withAnimation(.easeInOut(duration: moveDuration)) {
                    chipAnimationOffset = targetOffset
                    chipScale = 0.9
                    chipRotation = isWin ? 5 : -5
                }
                
                // Third phase: settle and fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + moveDuration) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        chipScale = 0.7
                        chipOpacity = 0
                    }
                }
            }
        }
    }
    
    private func animateChipToCircle(chipValue: Int) {
        // Create animated chip at chip's position
        let startPosition = CGPoint(x: 0, y: 100) // Approximate chip row position
        let endPosition = CGPoint(x: 0, y: -50) // Betting circle position
        
        let animatingChip = AnimatingChip(
            value: chipValue,
            position: startPosition,
            isAnimating: false
        )
        
        animatingChips.append(animatingChip)
        
        // Start animation
        withAnimation(.easeInOut(duration: 0.6)) {
            if let index = animatingChips.firstIndex(where: { $0.id == animatingChip.id }) {
                animatingChips[index].position = endPosition
                animatingChips[index].isAnimating = true
            }
        }
        
        // Remove animated chip after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            animatingChips.removeAll { $0.id == animatingChip.id }
        }
        
        SoundManager.shared.playChipPlace()
    }
    
    // Helper function to determine chips for a given amount
    func chipsForBet(amount: Double) -> [Int] {
        var remainingAmount = Int(amount)
        var chips: [Int] = []
        let sortedChipValues = chipValues.sorted(by: >)

        for chipValue in sortedChipValues {
            while remainingAmount >= chipValue {
                chips.append(chipValue)
                remainingAmount -= chipValue
            }
        }
        return chips
    }

    // Helper function to determine the best chip denomination for display
    func chipDenominationForBet(amount: Double) -> Int {
        let betAmount = Int(amount)
        let sortedChipValues = chipValues.sorted(by: >)

        // Find the highest denomination that the bet amount is divisible by or closest to
        for chipValue in sortedChipValues {
            if betAmount >= chipValue {
                return chipValue
            }
        }
        return chipValues.first ?? 10
    }

    // Check if split prompt should be shown
    var shouldShowSplitPrompt: Bool {
        // Never allow splitting during split hands - only on the original hand before splitting
        if game.hasSplit {
            return false
        } else {
            // For regular hands, check the main player hand
        return game.gameState == .playerTurn && 
               game.canSplitCurrentHand() && 
               game.playerHand.cards.count == 2 && 
               !isDoubleDown
        }
    }

    // MARK: - Split Transition Sequence
    private func startSplitTransitionSequence() {
        // Reset all animation states
        isSplitTransitioning = true
        splitTransitionProgress = 0.0
        showPlayerHands = false
        showDealerCards = false
        dealerCardsOffset = 100
        splitDealtCount = 0
        showFirstSplitCards = false
        showSecondSplitCards = false
        splitDealingStep = 0
        
        // Stage 1: Initial split animation (0.3s - faster)
        withAnimation(.easeInOut(duration: 0.3)) {
            splitTransitionProgress = 0.3
        }
        
        // Stage 2: Perform the initial split with only first cards (0.2s delay - faster)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("DEBUG: Before performInitialSplit - Balance: \(self.gameState.balance)")
            self.performInitialSplit()
            print("DEBUG: After performInitialSplit - Balance: \(self.gameState.balance)")
            
            // Stage 3: Show first cards of each split hand with enhanced animation (0.4s - faster)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3)) {
                self.splitTransitionProgress = 0.7
                self.showPlayerHands = true
                self.showFirstSplitCards = true
                self.splitDealingStep = 1
            }
            
            // Stage 4: Show dealer cards with smooth slide-in (0.3s delay - faster)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    self.splitTransitionProgress = 1.0
                    self.showDealerCards = true
                    self.dealerCardsOffset = 0
                }
                
        // Stage 5: Deal second cards to each split hand (dynamic delay based on settings)
        DispatchQueue.main.asyncAfter(deadline: .now() + settingsManager.cardDealDelay) {
            self.dealSecondCardsToSplitHands()
        }
            }
        }
    }
    
    private func performInitialSplit() {
        // Set dealing flag during split hand dealing
        isDealingCards = true
        // Keep betting circles visible but they'll be greyed out during split dealing
        
        // Create split hands with only the first card from each original card
        let originalHand = game.splitManager.hands[0]
        guard originalHand.cards.count == 2 else { return }
        
        let firstCard = originalHand.cards[0]
        let secondCard = originalHand.cards[1]
        
        // Create two new hands with just the first card each
        let hand1 = SplitHand(initialCard: firstCard, bet: originalHand.bet)
        let hand2 = SplitHand(initialCard: secondCard, bet: originalHand.bet)
        
        // Replace the original hand with the two new hands
        game.splitManager.hands.removeAll()
        game.splitManager.hands.append(hand1)
        game.splitManager.hands.append(hand2)
        game.splitManager.activeHandIndex = 0
        game.splitManager.totalBet = originalHand.bet * 2
        
        // Update betAmount to reflect total bet for split hands
        betAmount = Int(game.splitManager.totalBet)
        
        // Update game state
        game.updateCurrentBet(game.splitManager.totalBet)
        game.splitManager.splitPhase = .playing
        
        // Deduct the additional bet for the second hand from balance AFTER everything else
        print("DEBUG: Before split - Balance: \(gameState.balance), Bet: \(originalHand.bet)")
        gameState.balance -= originalHand.bet
        print("DEBUG: After split - Balance: \(gameState.balance)")
        
        // Update the game's currentBet to match the actual total bet (2x original)
        game.updateCurrentBet(game.splitManager.totalBet)
        
        // Force UI update immediately and repeatedly to ensure it sticks
        DispatchQueue.main.async {
            self.animatedBalance = self.gameState.balance
            print("DEBUG: Forced UI update - animatedBalance: \(self.animatedBalance)")
        }
        
        // Also update after a short delay to ensure it sticks
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.animatedBalance = self.gameState.balance
            print("DEBUG: Delayed UI update - animatedBalance: \(self.animatedBalance)")
        }
    }
    
    private func dealSecondCardsToSplitHands() {
        // Deal second card to each split hand with enhanced animation
        guard game.splitManager.hands.count == 2 else { 
            isDealingCards = false
            return 
        }
        
        // Deal to first hand with spring animation (avoid 20-value hands)
        if let card1 = game.drawCardForSplitHand(for: game.splitManager.hands[0]) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
                game.splitManager.hands[0].addCard(card1)
                self.splitDealtCount = game.splitManager.hands[0].cards.count
            }
        }
        
        // Deal to second hand after a shorter delay (avoid 20-value hands)
        DispatchQueue.main.asyncAfter(deadline: .now() + settingsManager.cardDealDelay * 0.6) {
            if let card2 = self.game.drawCardForSplitHand(for: self.game.splitManager.hands[1]) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
                    self.game.splitManager.hands[1].addCard(card2)
                    self.showSecondSplitCards = true
                    self.splitDealingStep = 2
                }
            }
            
            // REMOVED: Auto-stand logic for split aces
            // Split aces should allow normal hit/stand/double actions
            
            // Set to player turn for all split hands
            self.game.gameState = .playerTurn
            
            // Mark dealing as complete
            self.isDealingCards = false
            self.bettingCirclesVisible = true  // Show betting circles after split dealing
            
            // Complete the transition faster
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("DEBUG: Split transition complete - Balance: \(self.gameState.balance)")
                
                // Final balance update to ensure it sticks
                // Note: Balance already deducted in performInitialSplit(), no need to deduct again
                self.animatedBalance = self.gameState.balance
                print("DEBUG: Final balance update - Balance: \(self.gameState.balance)")
                
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isSplitTransitioning = false
                }
            }
        }
    }
    
    // MARK: - Split Result Message
    private func getSplitResultMessage() -> String {
        // If no split hands, return normal result
        if !game.hasSplit {
            return game.resultMessage
        }
        
        // For split hands, don't show banner message - use per-hand messages instead
        return ""
    }
    
    private func startSequentialSplitResolution() {
        print("DEBUG: Starting sequential split resolution")
        isResolvingSplitHands = true
        currentResolvingHand = 0
        resolveNextSplitHand()
    }
    
    private func performSplitToNormalTransition() {
        print("DEBUG: Starting split to normal transition")
        isTransitioningFromSplit = true
        splitCollapseProgress = 0.0
        
        // Stage 1: Collapse split hands with a cool animation
        withAnimation(.easeInOut(duration: 0.8)) {
            splitCollapseProgress = 1.0
        }
        
        // Stage 2: After collapse animation, show transition to single hand
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Reset all split-related states but keep transition active
            self.isSplitTransitioning = false
            self.showFirstSplitCards = false
            self.showSecondSplitCards = false
            self.isResolvingSplitHands = false
            self.currentResolvingHand = 0
            self.splitHandResults.removeAll()
            self.splitHandMessages.removeAll()
            self.splitChipAnimations.removeAll()
            self.splitChipPositions.removeAll()
            self.splitDealtCount = 0
            self.splitCardFlyIn = [false, false, false, false]
            self.splitCardRotation = [90, 90, 90, 90]
            self.splitTransitionProgress = 0.0
            self.showDealerCards = false
            self.dealerCardsOffset = 200
            
            // Reset specific states without changing game state to avoid showing betting interface
            self.game.playerHand.clear()
            self.game.dealerHand.clear()
            // Note: currentBet, payout, resultMessage, and insuranceResult are private(set), so we can't reset them directly
            self.game.splitManager.reset()
            self.game.gameState = .playerTurn // Set to playerTurn to avoid showing betting interface
            self.dealt = false
            self.playerDealtCount = 0
            self.dealerDealtCount = 0
            self.showGameResultText = false
            
            // Stage 3: Show "RETURNING TO SINGLE HAND" message and fade in normal gameplay
            withAnimation(.easeInOut(duration: 0.5)) {
                self.splitCollapseProgress = 0.0
                self.showNormalGameplay = true
            }
            
            // Stage 4: After message, start new game with smooth transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isTransitioningFromSplit = false
                self.splitCollapseProgress = 0.0
                
                // Start new game directly without showing betting interface
                self.dealInitialCards()
            }
        }
    }
    
    private func resolveNextSplitHand() {
        print("DEBUG: Resolving hand \(currentResolvingHand)")
        guard currentResolvingHand < game.splitManager.hands.count else {
            // All hands resolved
            print("DEBUG: All hands resolved")
            isResolvingSplitHands = false
            return
        }
        
        let hand = game.splitManager.hands[currentResolvingHand]
        let dealerValue = game.dealerHand.value
        
        // Calculate result and payout for this hand
        let result: String
        let payout: Double
        
        if hand.isBust {
            result = "Dealer Wins"
            payout = -hand.bet
        } else if dealerValue > 21 {
            result = "You Win"
            payout = hand.bet * 2
        } else if dealerValue > hand.value {
            result = "Dealer Wins"
            payout = -hand.bet
        } else if dealerValue < hand.value {
            result = "You Win"
            payout = hand.bet * 2
        } else {
            result = "Push!"
            payout = 0
        }
        
        // Store result for this hand
        splitHandResults[currentResolvingHand] = (result: result, payout: payout)
        print("DEBUG: Hand \(currentResolvingHand) result: \(result), payout: \(payout)")
        print("DEBUG: Balance before resolveBet: \(gameState.balance)")
        
        // Play sound for this hand's result immediately when it's displayed
        if result == "You Win" {
            SoundManager.shared.playWin()
        } else if result == "Dealer Wins" {
            SoundManager.shared.playLose()
        } else if result == "Push!" {
            SoundManager.shared.playPush()
        }
        
        // Animate chip and update balance for this hand
        animateSplitHandResult(handIndex: currentResolvingHand, result: result, payout: payout)
        
        // Move to next hand after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.currentResolvingHand += 1
            self.resolveNextSplitHand()
        }
    }
    
    private func animateSplitHandResult(handIndex: Int, result: String, payout: Double) {
        print("DEBUG: Animating hand \(handIndex) result: \(result)")
        // Show per-hand message
        splitHandMessages[handIndex] = result
        
        // Set up message auto-dismiss timer
        splitMessageTimers[handIndex]?.invalidate()
        splitMessageTimers[handIndex] = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            DispatchQueue.main.async {
                self.splitHandMessages[handIndex] = nil
            }
        }
        
        // Use same chip animation logic as normal gameplay
        let isWin = result == "You Win"
        
        // Determine target position based on win/loss (same as normal gameplay)
        let targetOffset: CGSize
        if isWin {
            // Move to player area (bottom of screen) - more natural path
            targetOffset = CGSize(width: 0, height: 180)
        } else {
            // Move all the way to dealer's cards area (much higher up - to the very top)
            targetOffset = CGSize(width: 0, height: -400)
        }
        
        // Hide chip from circle (same as normal gameplay)
        withAnimation(.easeInOut(duration: 0.3)) {
            splitChipAnimations[handIndex] = true
        }
        
        // Animate chip flying to target (same as normal gameplay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // First phase: slight lift and tilt (like being picked up)
            withAnimation(.easeOut(duration: 0.3)) {
                splitChipPositions[handIndex] = CGPoint(
                    x: UIScreen.main.bounds.width / 2 + (handIndex == 0 ? -100 : 100),
                    y: UIScreen.main.bounds.height - 200 + (isWin ? 20 : -20)
                )
            }
            
            // Second phase: move to destination with smooth curve
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Much longer duration for losses since they travel much further
                let moveDuration = isWin ? 0.8 : 1.4
                withAnimation(.easeInOut(duration: moveDuration)) {
                    splitChipPositions[handIndex] = CGPoint(
                        x: UIScreen.main.bounds.width / 2,
                        y: UIScreen.main.bounds.height - 200 + targetOffset.height
                    )
                }
                
                // Casino style: manually update balance for split hands
                DispatchQueue.main.asyncAfter(deadline: .now() + moveDuration) {
                    // Clear the chip position so it disappears
                    self.splitChipPositions[handIndex] = nil
                    
                    // For split hands, manually update balance
                    print("DEBUG: About to update balance with payout: \(payout), current balance: \(self.gameState.balance)")
                    if payout > 0 {
                        // Wins: add payout to balance
                        self.gameState.balance += payout
                    } else if payout == 0 {
                        // Push: return the original bet to balance
                        let hand = self.game.splitManager.hands[handIndex]
                        self.gameState.balance += hand.bet
                    }
                    // Losses don't change balance (already deducted when bet was placed)
                    print("DEBUG: After balance update, balance: \(self.gameState.balance)")
                    self.animatedBalance = self.gameState.balance
                    
                    // Show balance change
                    self.showBalanceChange = true
                    self.balanceChangeAmount = payout
                    
                    // Hide balance change after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.showBalanceChange = false
                    }
                }
            }
        }
    }

    // MARK: - Insurance Chip Indicator
    private var insuranceChipIndicator: some View {
        VStack(spacing: 8) {
            // Insurance chip
            ZStack {
                Circle()
                    .stroke(Color.red, lineWidth: 4)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.red.opacity(0.6), radius: 8, y: 4)
                
                Circle()
                    .fill(Color.red.opacity(0.9))
                    .frame(width: 70, height: 70)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
                
                VStack(spacing: 2) {
                    Text("INSURANCE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("$\(Int(gameState.insuranceBet))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            // Insurance bet label
            Text("Insurance Bet")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: gameState.insuranceBet > 0)
    }
    
    // MARK: - Betting Elements Animation
    private var bettingElementsOffset: CGFloat {
        if game.gameState == .offeringInsurance {
            return -30 // Move betting elements up by 30 points when prompts appear
        }
        return 0 // Normal position
    }
}

struct PayoutView: View {
    let payout: Double
    @State private var animate = false

    var body: some View {
        Text(String(format: "%@$%.0f", payout > 0 ? "+" : "", abs(payout)))
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(payout > 0 ? .green : .red)
            .opacity(animate ? 0 : 1)
            .offset(y: animate ? 25 : 0)
            .scaleEffect(animate ? 1.5 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 4.0)) {
                    animate = true
                }
            }
    }
}

struct SingleBetChipView: View {
    let denomination: Int
    let totalAmount: Int

    var body: some View {
        ZStack {
            Image(chipImageName(for: denomination))
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
                .shadow(radius: 2)
            Circle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
            Text("\(totalAmount)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .shadow(color: .white.opacity(0.5), radius: 1, y: 1)
        }
    }

    private func chipImageName(for value: Int) -> String {
        switch value {
        case 1: return "Chip1"
        case 10: return "Chip10"
        case 25: return "Chip25"
        case 50: return "Chip50"
        case 100: return "Chip100"
        case 1000: return "Chip1000"
        default: return "chip_red"
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView(game: BlackjackGame(), initialBetAmount: 100)
            .environmentObject(GameState())
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct EngravedRulesBanner: View {
    var resultMessage: String?
    var resultColor: Color = .white
    var isGameOver: Bool = false
    var insuranceMessage: String = ""
    var hideInsuranceText: Bool = false
    var gameState: BlackjackGameState = .betting
    @State private var animateWin = false
    @State private var animateLose = false
    @State private var animateBlackjack = false
    @State private var lastMessage: String? = nil
    
    var body: some View {
        // Only show the VStack when there's actually content to display
        if (!isGameOver && gameState != .betting) || resultMessage != nil {
            VStack(spacing: isGameOver ? 0 : 6) {  // No spacing at all for game over messages to bring cards closer
                // Only show rules when game is not over and not in betting phase
                if !isGameOver && gameState != .betting {
                    Text("BLACKJACK PAYS 3 TO 2")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.black.opacity(0.32))
                        .shadow(color: Color.white.opacity(0.10), radius: 0, x: 0, y: 2)
                        .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 2)
                        .padding(.bottom, isGameOver ? 6 : 0)  // Reduced from 10 to 6 for better balance
                }
                if let message = resultMessage {
                Group {
                    if message == "Blackjack!" {
                        Text(message)
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.9), radius: 18)
                            .overlay(
                                Text(message)
                                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white.opacity(0.2))
                                    .blur(radius: 2)
                            )
                            .scaleEffect(animateBlackjack ? 1.18 : 0.8)
                            .opacity(animateBlackjack ? 1 : 0)
                            .animation(
                                .interpolatingSpring(stiffness: 180, damping: 10).delay(0.1),
                                value: animateBlackjack
                            )
                            .onAppear { 
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    animateBlackjack = true
                                }
                            }
                            .onChange(of: resultMessage) { _, newMessage in
                                if newMessage == "Blackjack!" && lastMessage != newMessage {
                                    lastMessage = newMessage
                                    animateBlackjack = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        animateBlackjack = true
                                        // Play celebration sound for blackjack
                                        // SoundManager.shared.playSound(named: "deal")
                                    }
                                }
                            }
                            .overlay(
                                // Sparkle effect for blackjack
                                Group {
                                    if animateBlackjack && message == "Blackjack!" {
                                        ForEach(0..<8, id: \.self) { i in
                                            Image(systemName: "sparkle")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 16))
                                                .offset(
                                                    x: CGFloat.random(in: -80...80),
                                                    y: CGFloat.random(in: -40...40)
                                                )
                                                .opacity(animateBlackjack ? 1 : 0)
                                                .scaleEffect(animateBlackjack ? 1.5 : 0.5)
                                                .animation(
                                                    .easeOut(duration: 2.0).delay(Double(i) * 0.15),
                                                    value: animateBlackjack
                                                )
                                        }
                                    }
                                }
                            )
                    } else if resultColor == .green {
                        Text(message)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(resultColor)
                            .shadow(color: resultColor.opacity(0.22), radius: 2, x: 1, y: 1)
                            .shadow(color: Color.black.opacity(0.18), radius: 2, x: -1, y: -1)
                            .scaleEffect(animateWin ? 1.25 : 0.8)
                            .opacity(animateWin ? 1 : 0)
                            .animation(
                                .spring(response: 0.7, dampingFraction: 0.5).delay(0.1),
                                value: animateWin
                            )
                            .onAppear { animateWin = true }
                    } else if resultColor == .red {
                        Text(message)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(resultColor)
                            .shadow(color: resultColor.opacity(0.22), radius: 2, x: 1, y: 1)
                            .shadow(color: Color.black.opacity(0.18), radius: 2, x: -1, y: -1)
                            .modifier(ShakeEffect(animating: animateLose))
                            .onAppear {
                                animateLose = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    animateLose = true
                                }
                            }
                    } else {
                        Text(message)
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(resultColor)
                            .shadow(color: resultColor.opacity(0.22), radius: 2, x: 1, y: 1)
                            .shadow(color: Color.black.opacity(0.18), radius: 2, x: -1, y: -1)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, isGameOver ? 0 : 0)  // No padding at all for game over messages
            } else if !isGameOver && gameState != .betting {
                // Only show dealer rules when game is not over and not in betting phase
                Text("Dealer must stand on a 17 and draw to 16")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.28))
                    .shadow(color: Color.white.opacity(0.10), radius: 0, x: 0, y: 1)
                    .padding(.bottom, isGameOver ? 8 : 0)  // Reduced from 15 to 8 for better balance
            }
            }
            .padding(.vertical, isGameOver ? 0 : 10)  // No vertical padding at all for game over messages
            .frame(maxWidth: 340)
        }
    }
}

struct ShakeEffect: GeometryEffect {
    var animating: Bool
    var amount: CGFloat = 12
    var shakesPerUnit = 3
    var animatableData: CGFloat {
        animating ? 1 : 0
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation =
            animating ? sin(.pi * 2 * CGFloat(shakesPerUnit) * animatableData) * amount : 0
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

struct RoundedButton: View {
    let title: String
    let background: Color
    let foreground: Color
    let action: () -> Void
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(foreground)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            background.opacity(0.9),
                            background.opacity(0.6),
                            background.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8),
                                    Color(red: 1.0, green: 0.84, blue: 0.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                )
                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), radius: 8, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                )
        )
        .scaleEffect(isPressed ? 0.92 : (isHovered ? 1.05 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovered)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Enhanced Add Funds View
struct EnhancedAddFundsView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: AddFundsOption = .watchAd
    @State private var isWatchingAd = false
    @State private var adRewardAmount = 50
    @State private var showPurchaseSuccess = false
    @State private var purchaseSuccessMessage = ""
    
    enum AddFundsOption: CaseIterable {
        case watchAd
        case purchase5000
        case purchase30000
        case purchase200000
        case purchase500000
        case purchase1200000
        case purchase100000
        
        var title: String {
            switch self {
            case .watchAd: return "Watch Ad for Chips"
            case .purchase5000: return "Starter Pack"
            case .purchase30000: return "Value Pack"
            case .purchase200000: return "Premium Pack"
            case .purchase500000: return "Elite Pack"
            case .purchase1200000: return "Ultimate Pack"
            case .purchase100000: return "Deluxe Pack"
            }
        }
        
        var description: String {
            switch self {
            case .watchAd: return "Watch a 30-second ad"
            case .purchase5000: return "5,000 chips"
            case .purchase30000: return "30,000 chips"
            case .purchase200000: return "200,000 chips"
            case .purchase500000: return "500,000 chips"
            case .purchase1200000: return "1,200,000 chips"
            case .purchase100000: return "100,000 chips"
            }
        }
        
        var chipAmount: Int {
            switch self {
            case .watchAd: return 50
            case .purchase5000: return 5000
            case .purchase30000: return 30000
            case .purchase200000: return 200000
            case .purchase500000: return 500000
            case .purchase1200000: return 1200000
            case .purchase100000: return 100000
            }
        }
        
        var productId: String? {
            switch self {
            case .watchAd: return nil
            case .purchase5000: return "com.spadebet.blackjack.chips.5000"
            case .purchase30000: return "com.spadebet.blackjack.chips.30000"
            case .purchase200000: return "com.spadebet.blackjack.chips.200000"
            case .purchase500000: return "com.spadebet.blackjack.chips.500000"
            case .purchase1200000: return "com.spadebet.blackjack.chips.1200000"
            case .purchase100000: return "com.spadebet.blackjack.chips.100000"
            }
        }
        
        var price: String {
            switch self {
            case .watchAd: return "FREE"
            case .purchase5000: return "$1.99"
            case .purchase30000: return "$4.99"
            case .purchase200000: return "$24.99"
            case .purchase500000: return "$49.99"
            case .purchase1200000: return "$99.99"
            case .purchase100000: return "$14.99"
            }
        }
        
        var color: Color {
            switch self {
            case .watchAd: return .green
            case .purchase5000: return .blue
            case .purchase30000: return .cyan
            case .purchase200000: return .orange
            case .purchase500000: return .purple
            case .purchase1200000: return .red
            case .purchase100000: return .mint
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Add Chips")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
                        Text("Choose how you'd like to get more chips")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 20)
                    
                    // Current Balance
                    HStack {
                        Text("Current Balance:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("$\(Int(gameState.balance))")
                            .font(.title.bold())
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color(red: 1.0, green: 0.84, blue: 0.0), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    
                    // Options
                    VStack(spacing: 15) {
                        ForEach(AddFundsOption.allCases, id: \.self) { option in
                            AddFundsOptionView(
                                option: option,
                                isSelected: selectedOption == option,
                                onTap: { selectedOption = option },
                                onWatchAd: option == .watchAd ? watchAdForChips : nil
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Action Button (only for purchase options)
                    if selectedOption != .watchAd {
                        Button(action: handleSelectedOption) {
                            HStack {
                                if storeManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "creditcard.fill")
                                        .font(.title2)
                                }
                                
                                Text("Purchase")
                                    .font(.headline.bold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(selectedOption.color)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(selectedOption.color.opacity(0.3), lineWidth: 2)
                                    )
                            )
                            .shadow(color: selectedOption.color.opacity(0.3), radius: 10, y: 5)
                        }
                        .disabled(storeManager.isLoading)
                        .padding(.horizontal, 20)
                    }
                    
                    // Restore Purchases Button
                    Button(action: {
                        Task {
                            await storeManager.restorePurchases()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                            Text("Restore Purchases")
                                .font(.subheadline.bold())
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .disabled(storeManager.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Success!", isPresented: $showPurchaseSuccess) {
            Button("OK") { }
        } message: {
            Text(purchaseSuccessMessage)
        }
    }
    
    private func handleSelectedOption() {
        if selectedOption == .watchAd {
            watchAdForChips()
        } else {
            purchaseChips()
        }
    }
    
    private func watchAdForChips() {
        isWatchingAd = true
        
        // Simulate ad watching
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            gameState.addFunds(Double(selectedOption.chipAmount))
            isWatchingAd = false
            purchaseSuccessMessage = "You received \(selectedOption.chipAmount) chips!"
            showPurchaseSuccess = true
        }
    }
    
    private func purchaseChips() {
        guard let productId = selectedOption.productId,
              let product = storeManager.products.first(where: { $0.id == productId }) else {
            return
        }
        
        Task {
            let result = await storeManager.purchase(product)
            
            await MainActor.run {
                switch result {
                case .success:
                    purchaseSuccessMessage = "You received \(selectedOption.chipAmount) chips!"
                    showPurchaseSuccess = true
                case .cancelled:
                    // User cancelled, no action needed
                    break
                case .failure(let error):
                    // Handle error - could show an alert
                    print("Purchase failed: \(error)")
                }
            }
        }
    }
}

struct AddFundsOptionView: View {
    let option: EnhancedAddFundsView.AddFundsOption
    let isSelected: Bool
    let onTap: () -> Void
    let onWatchAd: (() -> Void)?
    @EnvironmentObject var storeManager: StoreManager
    
    init(option: EnhancedAddFundsView.AddFundsOption, isSelected: Bool, onTap: @escaping () -> Void, onWatchAd: (() -> Void)? = nil) {
        self.option = option
        self.isSelected = isSelected
        self.onTap = onTap
        self.onWatchAd = onWatchAd
    }
    
    var body: some View {
        Button(action: {
            if option == .watchAd {
                onWatchAd?()
            } else {
                onTap()
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(option.title)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Text(option.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text("+\(option.chipAmount.formatted())")
                        .font(.title2.bold())
                        .foregroundColor(option.color)
                    
                    Text(displayPrice)
                        .font(.subheadline.bold())
                        .foregroundColor(option.color)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? option.color.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? option.color : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var displayPrice: String {
        if option == .watchAd {
            return "FREE"
        }
        
        // Try to get real price from StoreKit product
        if let productId = option.productId,
           let product = storeManager.products.first(where: { $0.id == productId }) {
            return product.displayPrice
        }
        
        // Fallback to hardcoded price
        return option.price
    }
}

