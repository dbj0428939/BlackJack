import SwiftUI
import Foundation

struct StatsView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background matching the game theme
            BlueTableBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        
                        Text("Game Statistics")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    // Stats content
                    VStack(spacing: 20) {
                        // Overall stats
                        statsSection(title: "Overall Performance") {
                            VStack(spacing: 12) {
                                statRow(label: "Total Games", value: "\(gameState.gamesPlayed)", color: .white)
                                let winRate = gameState.gamesPlayed > 0 ? (Double(gameState.gamesWon) / Double(gameState.gamesPlayed)) * 100 : 0.0
                                statRow(label: "Win Rate", value: "\(String(format: "%.1f", winRate))%", color: .green)
                            }
                        }
                        
                        // Detailed breakdown
                        statsSection(title: "Game Outcomes") {
                            VStack(spacing: 12) {
                                statRow(label: "Wins", value: "\(gameState.gamesWon)", color: .green)
                                statRow(label: "Losses", value: "\(gameState.gamesLost)", color: .red)
                                let pushes = gameState.gamesPlayed - gameState.gamesWon - gameState.gamesLost
                                statRow(label: "Pushes", value: "\(pushes)", color: .yellow)
                            }
                        }
                        
                        // Special outcomes
                        statsSection(title: "Special Outcomes") {
                            VStack(spacing: 12) {
                                statRow(label: "Player Blackjacks", value: "0", color: .orange)
                                statRow(label: "Player Busts", value: "0", color: .red)
                                statRow(label: "Dealer Blackjacks", value: "0", color: .purple)
                            }
                        }
                        
                        // Visual chart representation
                        if gameState.gamesPlayed > 0 {
                            statsSection(title: "Win/Loss Chart") {
                                VStack(spacing: 8) {
                                    HStack(spacing: 16) {
                                        // Wins bar
                                        barChart(
                                            label: "Wins",
                                            value: gameState.gamesWon,
                                            total: gameState.gamesPlayed,
                                            color: .green
                                        )
                                        
                                        // Losses bar
                                        barChart(
                                            label: "Losses",
                                            value: gameState.gamesLost,
                                            total: gameState.gamesPlayed,
                                            color: .red
                                        )
                                        
                                        // Pushes bar
                                        let pushes = gameState.gamesPlayed - gameState.gamesWon - gameState.gamesLost
                                        barChart(
                                            label: "Pushes",
                                            value: pushes,
                                            total: gameState.gamesPlayed,
                                            color: .yellow
                                        )
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        } else {
                            // No games played yet - show pair of aces held in hand
                            VStack(spacing: 16) {
                                HStack(spacing: -8) {
                                    // Ace of Spades - held in hand
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                            .frame(width: 50, height: 70)
                                            .rotationEffect(.degrees(-15))
                                        
                                        VStack(spacing: 3) {
                                            Text("A")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white.opacity(0.3))
                                            Image(systemName: "suit.spade")
                                                .font(.system(size: 18))
                                                .foregroundColor(.white.opacity(0.3))
                                        }
                                        .rotationEffect(.degrees(-15))
                                    }
                                    
                                    // Ace of Hearts - held in hand
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                            .frame(width: 50, height: 70)
                                            .rotationEffect(.degrees(15))
                                        
                                        VStack(spacing: 3) {
                                            Text("A")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white.opacity(0.3))
                                            Image(systemName: "suit.heart")
                                                .font(.system(size: 18))
                                                .foregroundColor(.white.opacity(0.3))
                                        }
                                        .rotationEffect(.degrees(15))
                                    }
                                }
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .overlay(
            // Custom back button overlay
            VStack {
                HStack {
                    Button(action: {
                        SoundManager.shared.playBackButton()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 1.0, green: 0.84, blue: 0.0), lineWidth: 2)
                                )
                        )
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    }
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.leading, 20)
                Spacer()
            }
        )
    }
    
    @ViewBuilder
    private func statsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
            
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
    
    private func barChart(label: String, value: Int, total: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            // Bar
            VStack {
                Spacer()
                
                if value > 0 {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.8),
                                    color
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: CGFloat(value) / CGFloat(total) * 100)
                        .shadow(color: color.opacity(0.3), radius: 3, y: 2)
                }
            }
            .frame(width: 40, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            
            // Label
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            // Value
            Text("\(value)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StatsView()
                .environmentObject(GameState())
        }
    }
}
