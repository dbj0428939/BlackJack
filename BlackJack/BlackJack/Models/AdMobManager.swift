
import Foundation
import UIKit
import GoogleMobileAds
import SwiftUI

class AdMobManager: NSObject, ObservableObject, FullScreenContentDelegate {
    // Computed property to check if ad is available for presentation
    var canShowAd: Bool {
        return isAdLoaded && !isShowingAd
    }
    // ...existing code...

    // MARK: - RewardedAd FullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: RewardedAd) {
        print("🎯 AdMob: Ad did dismiss full screen content")
        DispatchQueue.main.async {
            self.isShowingAd = false
                self.isAdLoaded = true // Force ad available for testing
            self.loadRewardedAd()
        }
    }

    func ad(_ ad: RewardedAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("🎯 AdMob: Ad failed to present: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isShowingAd = false
            self.isAdLoaded = false
            self.loadRewardedAd()
        }
    }
    static let shared = AdMobManager()

    @Published var isAdLoaded = false
    @Published var isShowingAd = false
    @Published var adLoadingElapsed: TimeInterval = 0
    private var adLoadingTimer: Timer?

    private var rewardedAd: RewardedAd?
    private var adLoadTime: Date?

    private let testRewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    private let productionAdUnitID = "ca-app-pub-4504051516226977/8440598650" // Interstitial Ad Unit ID
    private var handsPlayedCount = 0

    // Call this method after each hand is completed
    func incrementHandsPlayedAndShowInterstitialIfNeeded(presentingViewController: UIViewController) {
        handsPlayedCount += 1
        if handsPlayedCount % 15 == 0 {
            showInterstitialAd(presentingViewController: presentingViewController)
        }
    }

    private func showInterstitialAd(presentingViewController: UIViewController) {
        let request = Request()
        InterstitialAd.load(with: productionAdUnitID, request: request) { ad, error in
            if let ad = ad {
                ad.present(from: presentingViewController)
            }
        }
    }

    override init() {
        super.init()
        print("🎯 AdMob: Initializing AdMobManager...")
        print("🎯 AdMob: Production Ad Unit ID: \(productionAdUnitID)")
        print("🎯 AdMob: Test Ad Unit ID: \(testRewardedAdUnitID)")
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["YOUR_TEST_DEVICE_ID"]
        #if DEBUG
        print("🎯 AdMob: Running in DEBUG mode")
        #else
        print("🎯 AdMob: Running in RELEASE mode")
        #endif
        MobileAds.shared.start { status in
            print("🎯 AdMob: MobileAds started with status: \(status)")
            print("🎯 AdMob: Status description: \(String(describing: status))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.loadRewardedAd()
            }
        }
    }

    func loadRewardedAd() {
        let request = Request()
        let adUnitID = testRewardedAdUnitID
        print("🎯 AdMob: Loading test rewarded ad (production app pending approval)")
        print("🎯 AdMob: Ad Unit ID: \(adUnitID)")
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🎯 AdMob: Failed to load test rewarded ad!")
                    print("🎯 AdMob: Error description: \(error.localizedDescription)")
                    self?.isAdLoaded = false
                    return
                }
                guard let ad = ad else {
                    print("🎯 AdMob: Rewarded ad is nil after successful load")
                    self?.isAdLoaded = false
                    return
                }
                self?.rewardedAd = ad
                self?.rewardedAd?.fullScreenContentDelegate = self
                self?.isAdLoaded = true
                self?.adLoadTime = Date()
                print("🎯 AdMob: Test rewarded ad loaded successfully!")
                print("🎯 AdMob: Ad object: \(ad)")
            }
        }
    }

    func showRewardedAd(onReward: @escaping () -> Void) -> Bool {
        print("🎯 AdMob: showRewardedAd called - isAdLoaded: \(isAdLoaded), isShowingAd: \(isShowingAd)")
        guard isAdLoaded,
              let rewardedAd = rewardedAd,
              !isShowingAd else {
            print("🎯 AdMob: Cannot show rewarded ad - isAdLoaded: \(isAdLoaded), rewardedAd: \(rewardedAd != nil), isShowingAd: \(isShowingAd)")
            return false
        }
        guard let rootViewController = Self.topViewController() else {
            print("🎯 AdMob: Cannot find root view controller for rewarded ad")
            return false
        }
        print("🎯 AdMob: Presenting rewarded ad...")
        isShowingAd = true
        rewardedAd.present(from: rootViewController, userDidEarnRewardHandler: {
            let reward = rewardedAd.adReward
            print("🎯 AdMob: User earned reward: \(reward.amount) \(reward.type)")
            onReward()
        })
        return true
    }

    // Helper to get the top-most view controller
    static func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
