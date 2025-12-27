// InterstitialAdManager removed as part of ad-related code cleanup.

// InterstitialAdManager removed: no-op placeholder for cleanup
import Foundation
import SwiftUI

class InterstitialAdManager: NSObject, ObservableObject {
    static let shared = InterstitialAdManager()
    @Published var isAdAvailable: Bool = false
    func showAdIfAvailable() {}
}
