import Foundation
import StoreKit

class InAppPurchaseManager: NSObject, ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var purchaseError: String?
    
    // Product IDs - these need to match what you set up in App Store Connect
    private let productIds = [
        "com.spadebet.chips_5000",      // $1.99
        "com.spadebet.chips_30000",     // $4.99
        "com.spadebet.chips_200000",    // $24.99
        "com.spadebet.chips_500000",    // $49.99
        "com.spadebet.chips_1200000",   // $99.99
        "com.spadebet.chips_100000"     // $14.99
    ]
    
    override init() {
        super.init()
        Task {
            await loadProducts()
        }
    }
    
    @MainActor
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIds)
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            purchaseError = "Failed to load products: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func purchase(_ product: Product, gameState: GameState) async {
        isLoading = true
        purchaseError = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the purchase
                switch verification {
                case .verified(let transaction):
                    // Add chips to user's balance
                    await addChipsToBalance(product: product, gameState: gameState)
                    
                    // Finish the transaction
                    await transaction.finish()
                    
                    print("✅ Purchase successful: \(product.displayName)")
                    
                case .unverified:
                    purchaseError = "Purchase could not be verified"
                }
                
            case .userCancelled:
                print("ℹ️ User cancelled purchase")
                
            case .pending:
                print("⏳ Purchase pending")
                purchaseError = "Purchase is pending approval"
                
            @unknown default:
                purchaseError = "Unknown purchase result"
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func addChipsToBalance(product: Product, gameState: GameState) async {
        // Map product IDs to chip amounts
        let chipAmount: Int
        switch product.id {
        case "com.spadebet.chips_5000":
            chipAmount = 5000
        case "com.spadebet.chips_30000":
            chipAmount = 30000
        case "com.spadebet.chips_200000":
            chipAmount = 200000
        case "com.spadebet.chips_500000":
            chipAmount = 500000
        case "com.spadebet.chips_1200000":
            chipAmount = 1200000
        case "com.spadebet.chips_100000":
            chipAmount = 100000
        default:
            chipAmount = 0
        }
        
        // Add chips to balance
        gameState.addFunds(Double(chipAmount))
        
        // Show success message
        DispatchQueue.main.async {
            print("✅ Added \(chipAmount) chips to balance")
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        purchaseError = nil
        
        do {
            try await AppStore.sync()
            print("✅ Purchases restored")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
            purchaseError = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
