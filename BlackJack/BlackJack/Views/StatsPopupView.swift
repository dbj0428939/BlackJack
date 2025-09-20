//
//  StatsPopupView.swift
//  BlackJack
//
//  Created by Trae AI on 1/14/25.
//

import SwiftUI
import Foundation

struct StatsPopupView: View {
    @ObservedObject var gameStats: GameStats
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            
            // Stats popup card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Game Statistics")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Stats content
                ScrollView {
                    VStack(spacing: 16) {
                        // Overall stats
                        statsSection(title: "Overall Performance") {
                            VStack(spacing: 12) {
                                statRow(label: "Total Games", value: "\(gameStats.totalGames)", color: .white)
                                statRow(label: "Win Rate", value: String(format: "%.1f%%", gameStats.winPercentage), color: .green)
                            }
                        }
                        
                        // Detailed breakdown
                        statsSection(title: "Game Outcomes") {
                            VStack(spacing: 12) {
                                statRow(label: "Wins", value: "\(gameStats.playerWins)", color: .green)
                                statRow(label: "Losses", value: "\(gameStats.playerLosses)", color: .red)
                                statRow(label: "Pushes", value: "\(gameStats.pushes)", color: .yellow)
                            }
                        }
                        
                        // Special outcomes
                        statsSection(title: "Special Outcomes") {
                            VStack(spacing: 12) {
                                statRow(label: "Player Blackjacks", value: "\(gameStats.playerBlackjacks)", color: .orange)
                                statRow(label: "Player Busts", value: "\(gameStats.playerBusts)", color: .red)
                                statRow(label: "Dealer Blackjacks", value: "\(gameStats.dealerBlackjacks)", color: .purple)
                            }
                        }
                        
                        // Visual chart representation
                        if gameStats.totalGames > 0 {
                            statsSection(title: "Win/Loss Chart") {
                                VStack(spacing: 8) {
                                    HStack(spacing: 8) {
                                        // Wins bar
                                        barChart(
                                            label: "Wins",
                                            value: gameStats.playerWins,
                                            total: gameStats.totalGames,
                                            color: .green
                                        )
                                        
                                        // Losses bar
                                        barChart(
                                            label: "Losses",
                                            value: gameStats.playerLosses,
                                            total: gameStats.totalGames,
                                            color: .red
                                        )
                                        
                                        // Pushes bar
                                        barChart(
                                            label: "Pushes",
                                            value: gameStats.pushes,
                                            total: gameStats.totalGames,
                                            color: .yellow
                                        )
                                    }
                                    .frame(height: 120)
                                }
                            }
                        }
                        
                        // Reset button
                        Button(action: {
                            gameStats.resetStats()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset Statistics")
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.red.opacity(0.8),
                                        Color.red.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.1, green: 0.1, blue: 0.2),
                                Color(red: 0.05, green: 0.05, blue: 0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
            )
            .frame(maxWidth: 350, maxHeight: 500)
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .opacity(isPresented ? 1.0 : 0.0)
        }
    }
    
    @ViewBuilder
    private func statsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
            
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
    
    private func barChart(label: String, value: Int, total: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            // Bar
            VStack {
                Spacer()
                
                if value > 0 {
                    RoundedRectangle(cornerRadius: 4)
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
                        .frame(height: CGFloat(value) / CGFloat(total) * 80)
                        .shadow(color: color.opacity(0.3), radius: 2, y: 1)
                }
            }
            .frame(width: 30, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            
            // Label
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            // Value
            Text("\(value)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    StatsPopupView(
        gameStats: GameStats(),
        isPresented: $isPresented
    )
}
