import Foundation
import AVFoundation

class SoundManager: ObservableObject {
    static let shared = SoundManager() // Singleton instance
    
    private var players: [String: AVAudioPlayer] = [:]
    
    private init() {
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error.localizedDescription)")
        }
    }
    
    func playSound(named name: String) {
        // Check if sound is enabled before playing
        guard SettingsManager.shared.soundEnabled else {
            return
        }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("Could not find sound file: \(name).wav")
            return
        }
        
        if let player = players[name] {
            // If player already exists, stop and prepare to play again
            player.stop()
            player.currentTime = 0
            player.play()
        } else {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
                players[name] = player
            } catch {
                print("Could not load or play sound file: \(error.localizedDescription)")
            }
        }
    }
    
    // Optional: Preload sounds if needed for faster playback
    func preloadSound(named name: String) {
        // Check if sound is enabled before preloading
        guard SettingsManager.shared.soundEnabled else {
            return
        }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            print("Could not find sound file for preloading: \(name).wav")
            return
        }
        
        if players[name] == nil {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[name] = player
            } catch {
                print("Could not preload sound file: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Specific Sound Effects for BlackJack Game
    
    func playCardDeal() {
        playSound(named: "mixkit-poker-card-flick-2002")
    }
    
    func playChipPlace() {
        playSound(named: "chip")
    }
    
    func playWin() {
        playSound(named: "mixkit-gold-coin-prize-1999")
    }
    
    func playLose() {
        playSound(named: "mixkit-click-error-1110")
    }
    
    func playBlackjack() {
        playSound(named: "blackjack")
    }
    
    func playBust() {
        playSound(named: "bust")
    }
    
    func playStand() {
        playSound(named: "stand")
    }
    
    func playHit() {
        playSound(named: "hit")
    }
    
    func playDoubleDown() {
        playSound(named: "double")
    }
    
    func playSplit() {
        playSound(named: "split")
    }
    
    func playShuffle() {
        playSound(named: "shuffle")
    }
    
    func playInsurance() {
        playSound(named: "insurance")
    }
    
    func playButtonTap() {
        playSound(named: "mixkit-modern-technology-select-3124")
    }
    
    func playPush() {
        playSound(named: "mixkit-coins-sound-2003")
    }
    
    func playDeal() {
        playSound(named: "mixkit-poker-card-placement-2001")
    }
    
    func playHitButton() {
        playSound(named: "mixkit-on-or-off-light-switch-tap-2585")
    }
    
    func playSplitButton() {
        playSound(named: "mixkit-paper-slide-1530")
    }
    
    func playChipSelect() {
        playSound(named: "mixkit-coins-sound-2003")
    }
    
    func playDoubleButton() {
        playSound(named: "mixkit-money-bag-drop-1989")
    }
    
    func playStandButton() {
        playSound(named: "mixkit-light-button-2580")
    }
    
    func playBackButton() {
        playSound(named: "mixkit-hard-pop-click-2364")
    }
} 