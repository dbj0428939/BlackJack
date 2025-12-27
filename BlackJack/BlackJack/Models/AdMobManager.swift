import Foundation
import UIKit
import SwiftUI

// AdMobManager removed. Provide minimal no-op stub to satisfy references if any remain during cleanup.
// AdMobManager removed: ad functionality disabled.
// This file kept as a no-op placeholder to avoid compile errors during cleanup.
class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    @Published var isAdLoaded: Bool = false
    @Published var canShowAd: Bool = false
    @Published var adLoadingElapsed: TimeInterval = 0

    func loadRewardedAd() {}
    func showRewardedAd(onReward: @escaping () -> Void) -> Bool { return false }
    func incrementHandsPlayedAndShowInterstitialIfNeeded(presentingViewController: UIViewController) {}
}
