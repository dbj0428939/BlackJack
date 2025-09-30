
import Foundation
#if canImport(UIKit)
import UIKit
#endif


import GoogleMobileAds

class RewardedAdManager: NSObject, FullScreenContentDelegate {
	static let shared = RewardedAdManager()
	private override init() {
		super.init()
	}

	private let adUnitID = "ca-app-pub-4504051516226977/8991489305" // Production Rewarded Ad Unit ID (50 chips)
    private var rewardedAd: RewardedAd?
	private(set) var isAdLoaded: Bool = false
	private var adLoadCompletion: (() -> Void)?

	func preloadAd(completion: (() -> Void)? = nil) {
        let request = Request()
		isAdLoaded = false
		adLoadCompletion = completion
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
			guard let self = self else { return }
			if let error = error {
				print("Failed to load rewarded ad: \(error.localizedDescription)")
				self.rewardedAd = nil
				self.isAdLoaded = false
			} else {
				self.rewardedAd = ad
				self.rewardedAd?.fullScreenContentDelegate = self
				self.isAdLoaded = true
			}
			self.adLoadCompletion?()
			self.adLoadCompletion = nil
		}
	}

	func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
		guard let ad = rewardedAd, isAdLoaded else {
			print("Rewarded ad not ready to show.")
			completion(false)
			return
		}
        ad.present(from: viewController) { [weak self] in
			// User earned reward
			completion(true)
			self?.isAdLoaded = false
			self?.preloadAd()
		}
		// If the ad is dismissed without reward, handle in delegate
	}

	// MARK: - GADFullScreenContentDelegate
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
		print("Rewarded ad failed to present: \(error.localizedDescription)")
		isAdLoaded = false
		preloadAd()
	}

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
		print("Rewarded ad dismissed.")
		isAdLoaded = false
		preloadAd()
	}
}
