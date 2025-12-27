import SwiftUI

struct AddFundsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var gameState: GameState
    @StateObject var iapManager = InAppPurchaseManager()
    @State private var animateFloating = false

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
                    Text("Add Funds")
                        .font(.title)
                        .foregroundColor(.white)

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
        }
    }
}
