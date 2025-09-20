import Foundation
import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var productIdentifiers: Set<String> = [
        "com.spadebet.blackjack.chips.5000",
        "com.spadebet.blackjack.chips.30000", 
        "com.spadebet.blackjack.chips.200000",
        "com.spadebet.blackjack.chips.500000",
        "com.spadebet.blackjack.chips.1200000",
        "com.spadebet.blackjack.chips.100000"
    ]
    
    init() {
        Task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await Product.products(for: productIdentifiers)
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            errorMessage = "Failed to load products. Please try again."
        }
        
        isLoading = false
    }
    
    func purchase(_ product: Product) async -> PurchaseResult {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the purchase
                switch verification {
                case .verified(let transaction):
                    // Complete the transaction
                    await transaction.finish()
                    
                    // Add chips to user's balance
                    let chipAmount = getChipAmount(for: product.id)
                    await addChipsToBalance(chipAmount)
                    
                    purchasedProducts.insert(product.id)
                    isLoading = false
                    return .success
                    
                case .unverified:
                    errorMessage = "Purchase verification failed"
                    isLoading = false
                    return .failure("Purchase verification failed")
                }
                
            case .userCancelled:
                isLoading = false
                return .cancelled
                
            case .pending:
                errorMessage = "Purchase is pending approval"
                isLoading = false
                return .failure("Purchase is pending approval")
                
            @unknown default:
                errorMessage = "Unknown purchase result"
                isLoading = false
                return .failure("Unknown purchase result")
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            isLoading = false
            return .failure(error.localizedDescription)
        }
    }
    
    private func getChipAmount(for productId: String) -> Int {
        switch productId {
        case "com.spadebet.blackjack.chips.5000":
            return 5000
        case "com.spadebet.blackjack.chips.30000":
            return 30000
        case "com.spadebet.blackjack.chips.200000":
            return 200000
        case "com.spadebet.blackjack.chips.500000":
            return 500000
        case "com.spadebet.blackjack.chips.1200000":
            return 1200000
        case "com.spadebet.blackjack.chips.100000":
            return 100000
        default:
            return 0
        }
    }
    
    private func addChipsToBalance(_ amount: Int) async {
        // This will be called from the GameView to update the balance
        NotificationCenter.default.post(
            name: NSNotification.Name("ChipsPurchased"), 
            object: nil, 
            userInfo: ["amount": amount]
        )
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            print("✅ Purchases restored successfully")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

enum PurchaseResult {
    case success
    case cancelled
    case failure(String)
}
