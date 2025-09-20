import SwiftUI

struct AddFundsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var gameState: GameState
    @State private var amount: String = ""
    @State private var animateFloating = false
    
    let presetAmounts = [100, 500, 1000, 2000, 5000]
    
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
                    
                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    Text("Quick Add:")
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(presetAmounts, id: \.self) { amount in
                            Button(action: {
                                self.amount = String(amount)
                            }) {
                                Text("$\(amount)")
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: addFunds) {
                        Text("Add Funds")
                            .font(.title3)
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(amount.isEmpty || Double(amount) ?? 0 <= 0)
                    .opacity(amount.isEmpty || Double(amount) ?? 0 <= 0 ? 0.5 : 1)
                }
            }
            .navigationBarItems(trailing: Button("Close") {
                SoundManager.shared.playBackButton()
                presentationMode.wrappedValue.dismiss()
            })
        }
        .onAppear {
            animateFloating = true
        }
    }
    
    private func addFunds() {
        if let amount = Double(amount) {
            gameState.addFunds(amount)
            SoundManager.shared.playBackButton()
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct AddFundsView_Previews: PreviewProvider {
    static var previews: some View {
        AddFundsView()
            .environmentObject(GameState())
    }
} 