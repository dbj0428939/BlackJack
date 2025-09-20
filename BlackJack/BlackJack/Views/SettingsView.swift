import SwiftUI
import Foundation

struct SettingsView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var storeManager = StoreManager()
    @State private var showingAddFunds = false
    
    var body: some View {
        ZStack {
            // Background matching the game theme
            BlueTableBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    // Settings sections
                    VStack(spacing: 20) {
                        // Audio Settings
                        settingsSection(title: "Audio", icon: "speaker.wave.2.fill") {
                            VStack(spacing: 16) {
                                settingsToggle(
                                    title: "Sound Effects",
                                    subtitle: "Card dealing, chip sounds, etc.",
                                    isOn: $settingsManager.soundEnabled
                                )
                            }
                        }
                        
                        // Gameplay Settings
                        settingsSection(title: "Gameplay", icon: "gamecontroller.fill") {
                            VStack(spacing: 16) {
                                // Dealer Speed Slider
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Dealer Speed")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text(dealerSpeedText)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                                    }
                                    
                                    Slider(value: $settingsManager.dealerSpeed, in: 0.5...2.0, step: 0.25)
                                        .accentColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                                    
                                    Text("How fast the dealer reveals cards")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        
                        // Account Settings
                        settingsSection(title: "Account", icon: "person.circle.fill") {
                            VStack(spacing: 16) {
                                // Current Balance Display
                                HStack {
                                    Text("Current Balance")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("$\(String(format: "%.0f", gameState.balance))")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.green)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                
                                // Add Funds Button
                                Button(action: {
                                    showingAddFunds = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Add Funds")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(.green)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.green.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                        
                        // App Info
                        settingsSection(title: "About", icon: "info.circle.fill") {
                            VStack(spacing: 12) {
                                infoRow(label: "Version", value: "1.0.0")
                                infoRow(label: "Developer", value: "David Johnson")
                                
                                // Attribution
                                VStack(spacing: 4) {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                        Link("Chip icons by Icons8", destination: URL(string: "https://icons8.com")!)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                        Spacer()
                                    }
                                }
                            }
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
        .sheet(isPresented: $showingAddFunds) {
            EnhancedAddFundsView()
                .environmentObject(gameState)
                .environmentObject(storeManager)
        }
    }
    
    private var dealerSpeedText: String {
        switch settingsManager.dealerSpeed {
        case 0.5: return "Slow"
        case 0.75: return "Relaxed"
        case 1.0: return "Normal"
        case 1.25: return "Fast"
        case 1.5: return "Quick"
        case 1.75: return "Rapid"
        case 2.0: return "Lightning"
        default: return "Normal"
        }
    }
    
    @ViewBuilder
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
            }
            
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
    
    private func settingsToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 1.0, green: 0.84, blue: 0.0)))
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
                .environmentObject(GameState())
        }
    }
}