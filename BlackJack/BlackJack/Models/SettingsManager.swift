import Foundation
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var soundEnabled: Bool = true
    @Published var dealerSpeed: Double = 1.0
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Settings Management
    
    func updateDealerSpeed(_ speed: Double) {
        dealerSpeed = speed
        saveSettings()
    }
    
    func updateSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
        saveSettings()
    }
    
    // MARK: - Computed Properties
    
    var dealerSpeedMultiplier: Double {
        // Convert slider value (0.5-2.0) to timing multiplier
        // 0.5 = 2x slower, 1.0 = normal, 2.0 = 2x faster
        return 2.0 - dealerSpeed
    }
    
    var cardDealDelay: Double {
        // Base delay of 0.35 seconds, modified by speed multiplier
        return 0.35 * dealerSpeedMultiplier
    }
    
    var dealerDrawDelay: Double {
        // Base delay of 1.0 seconds, modified by speed multiplier
        return 1.0 * dealerSpeedMultiplier
    }
    
    var animationDuration: Double {
        // Base animation duration of 0.5 seconds, modified by speed multiplier
        return 0.5 * dealerSpeedMultiplier
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(dealerSpeed, forKey: "dealerSpeed")
    }
    
    private func loadSettings() {
        soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        dealerSpeed = UserDefaults.standard.double(forKey: "dealerSpeed")
        
        // Set default values if not previously saved
        if UserDefaults.standard.object(forKey: "soundEnabled") == nil {
            soundEnabled = true
        }
        if UserDefaults.standard.object(forKey: "dealerSpeed") == nil {
            dealerSpeed = 1.0
        }
    }
}
