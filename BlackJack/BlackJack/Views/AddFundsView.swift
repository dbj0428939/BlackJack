import SwiftUI

struct AddFundsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var gameState: GameState
    @StateObject var iapManager = InAppPurchaseManager()
    @StateObject var rewardedAdManager = RewardedAdManager.shared
    @State private var animateFloating = false
    @State private var displayBalance: Double = 0
    @State private var lastBalance: Double = 0
    @State private var showAwardToast: Bool = false
    @State private var awardAmount: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                BlueTableBackground()
                    .edgesIgnoringSafeArea(.all)
                // Floating card suits animation
                ForEach(0..<4, id: \.self) { i in
                    let suits = ["suit.heart.fill", "suit.diamond.fill", "suit.club.fill", "suit.spade.fill"]
                    Image(systemName: suits[i])
                        .font(.system(size: CGFloat.random(in: 12...18)))
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.12))
                        .offset(
                            x: CGFloat.random(in: -120...120),
                            y: CGFloat.random(in: -200...200)
                        )
                        .rotationEffect(.degrees(animateFloating ? 360 : 0))
                        .animation(
                            .linear(duration: Double.random(in: 12...18))
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 1.2),
                            value: animateFloating
                        )
                }
                VStack(spacing: 20) {
                    // Current balance header with animated value
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current Balance:")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text("$\(Int(displayBalance))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }

                    if iapManager.isLoading {
                        ProgressView()
                    } else {
                        ForEach(iapManager.products, id: \.id) { product in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.displayName)
                                        .foregroundColor(.white)
                                    Text(product.displayPrice)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Button(action: {
                                    Task {
                                        await iapManager.purchase(product, gameState: gameState)
                                    }
                                }) {
                                    Text("Buy")
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                }
                                .disabled(iapManager.isLoading)
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                    }
                    // Watch ad for chips
                    VStack {
                        Button(action: {
                            SoundManager.shared.playChipPlace()
                            let played = rewardedAdManager.showRewardedAd {
                                // Award 50 chips when ad completes
                                    DispatchQueue.main.async {
                                        let amount = 50
                                        gameState.addFunds(Double(amount))
                                        // local UI feedback
                                        awardAmount = amount
                                        showAwardToast = true
                                        lastBalance = displayBalance
                                        // Animate numeric increase
                                        Task {
                                            await animateBalanceIncrease(from: lastBalance, to: gameState.balance)
                                        }
                                        // hide toast after 1.8s
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                            showAwardToast = false
                                        }
                                    }
                            }
                            if !played {
                                // If ad not ready, attempt to (re)load with the provided test unit ID
                                rewardedAdManager.loadRewardedAd(testUnitID: "ca-app-pub-4504051516226977/8991489305")
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text(rewardedAdManager.isRewardedAdReady ? "Watch Ad for 50 Chips" : "Loading Ad...")
                                    .foregroundColor(.black)
                                    .padding(.vertical, 10)
                                Spacer()
                            }
                            .background(Color.yellow)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        .disabled(!rewardedAdManager.isRewardedAdReady)
                    }
                }
            }
            .navigationBarItems(trailing: Button("Close") {
                SoundManager.shared.playBackButton()
                presentationMode.wrappedValue.dismiss()
            })
        }
        .onAppear {
            animateFloating = true
            Task {
                await iapManager.loadProducts()
            }
            // Start loading the simulated rewarded ad with provided test unit ID
            rewardedAdManager.loadRewardedAd(testUnitID: "ca-app-pub-4504051516226977/8991489305")
            // initialize displayed balance
            displayBalance = gameState.balance
            lastBalance = gameState.balance
        }
        .onChange(of: gameState.balance) { oldValue, newValue in
            // If balance increased (award), animate the numeric change and show toast
            if newValue > lastBalance {
                awardAmount = Int(newValue - lastBalance)
                showAwardToast = true
                Task {
                    await animateBalanceIncrease(from: lastBalance, to: newValue)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    showAwardToast = false
                }
                lastBalance = newValue
            } else {
                // update without animation for non-incremental changes
                displayBalance = newValue
                lastBalance = newValue
            }
        }

        // Toast overlay when award is received
        .overlay(
            Group {
                if showAwardToast {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("+\(awardAmount) chips — Added!")
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.85))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            Spacer()
                        }
                        .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeOut(duration: 0.35), value: showAwardToast)
                }
            }
        )
        
    }

    // Animate displayed balance from `from` to `to` over ~0.6s
    private func animateBalanceIncrease(from: Double, to: Double) async {
        let steps = 20
        let total: Double = to - from
        guard total > 0 else {
            await MainActor.run { displayBalance = to }
            return
        }
        for i in 1...steps {
            let progress = Double(i) / Double(steps)
            let value = from + total * progress
            await MainActor.run { displayBalance = value }
            try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
        }
        await MainActor.run { displayBalance = to }
}
    }
