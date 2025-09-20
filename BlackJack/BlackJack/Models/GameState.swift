import Foundation

public class GameState: ObservableObject {
    @Published public var balance: Double = 2000.0
    @Published public var currentBet: Double = 0.0
    @Published public var isGameActive: Bool = false
    @Published public var isLoading: Bool = true
    
    // Game statistics
    @Published public var gamesPlayed: Int = 0
    @Published public var gamesWon: Int = 0
    @Published public var gamesLost: Int = 0
    @Published public var insuranceBet: Double = 0
    
    // UserDefaults keys
    private let balanceKey = "savedBalance"
    private let gamesPlayedKey = "savedGamesPlayed"
    private let gamesWonKey = "savedGamesWon"
    private let gamesLostKey = "savedGamesLost"
    
    public init() {
        loadSavedData()
    }
    
    // MARK: - Data Persistence
    private func loadSavedData() {
        balance = UserDefaults.standard.double(forKey: balanceKey)
        if balance == 0 {
            balance = 2000.0 // Default starting balance
        }
        
        gamesPlayed = UserDefaults.standard.integer(forKey: gamesPlayedKey)
        gamesWon = UserDefaults.standard.integer(forKey: gamesWonKey)
        gamesLost = UserDefaults.standard.integer(forKey: gamesLostKey)
        
        // Reset loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    private func saveData() {
        UserDefaults.standard.set(balance, forKey: balanceKey)
        UserDefaults.standard.set(gamesPlayed, forKey: gamesPlayedKey)
        UserDefaults.standard.set(gamesWon, forKey: gamesWonKey)
        UserDefaults.standard.set(gamesLost, forKey: gamesLostKey)
        
        // Notify that balance has been updated
        NotificationCenter.default.post(name: NSNotification.Name("BalanceUpdated"), object: nil)
    }
    
    public func addFunds(_ amount: Double) {
        balance += amount
        saveData()
    }
    
    public func placeBet(_ amount: Double) {
        guard amount <= balance else { return }
        balance -= amount
        currentBet = amount
        saveData()
    }
    
    public func doubleDown() {
        let additionalBet = currentBet
        guard additionalBet <= balance else { return }
        balance -= additionalBet
        currentBet *= 2
        saveData()
    }
    
    @discardableResult
    public func placeInsuranceBet() -> Bool {
        let amount = currentBet / 2
        guard amount <= balance else { return false }
        balance -= amount
        insuranceBet = amount
        saveData()
        return true
    }
    
    public func clearInsurance() {
        insuranceBet = 0
    }
    
    public func resolveBet(with payout: Double, insuranceResult: Bool?) {
        if payout > 0 {
            balance += payout // Add payout only (bet was already deducted when placed)
        }
        // For losses (payout = 0), no balance change since bet was already deducted
        
        if let won = insuranceResult, won == true {
            // When insurance wins: get original bet back + insurance payout (2:1)
            balance += currentBet // Return the original bet
            let insurancePayout = insuranceBet * 3 // Insurance pays 2:1 (original bet + 2x)
            balance += insurancePayout
        } else if insuranceResult == false {
            // Insurance was lost, the bet was already deducted when placed, so no additional action needed
            // The insurance bet amount is already subtracted from balance when placeInsuranceBet() was called
        }
        insuranceBet = 0
        
        if payout > 0 {
        gamesWon += 1
        } else if payout < 0 {
            gamesLost += 1
    }
    
        gamesPlayed += 1
        currentBet = 0
        saveData()
    }
    
    // MARK: - Reset Functions
    public func resetGameData() {
        balance = 2000.0
        currentBet = 0.0
        isGameActive = false
        gamesPlayed = 0
        gamesWon = 0
        gamesLost = 0
        insuranceBet = 0
        saveData()
    }
}