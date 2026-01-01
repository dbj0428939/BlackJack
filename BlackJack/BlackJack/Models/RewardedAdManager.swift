// RewardedAdManager: Google Mobile Ads backed rewarded ad controller
import Foundation
import SwiftUI
import UIKit
import GoogleMobileAds

class RewardedAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
	static let shared = RewardedAdManager()

	@Published var isRewardedAdReady: Bool = false
	@Published var isShowingAd: Bool = false

    private var rewardedAd: RewardedAd? = nil
	private var adUnitID: String = ""
	private var onReward: (() -> Void)? = nil
	private var pendingReward: Bool = false

	// Non-async wrapper: set ad unit (optional) and start async load
	func loadRewardedAd(testUnitID: String? = nil) {
		if let unit = testUnitID, !unit.isEmpty {
			adUnitID = unit
		}
		Task { [weak self] in
			await self?.loadRewardedAd()
		}
	}

	// Async/await loader using the newer Google Mobile Ads API
	func loadRewardedAd() async {
		guard !adUnitID.isEmpty else { return }
		await MainActor.run { self.isRewardedAdReady = false }

		do {
			rewardedAd = try await RewardedAd.load(with: adUnitID, request: Request())
			// Assign delegate and update published state on the main actor.
			await MainActor.run {
				self.rewardedAd?.fullScreenContentDelegate = self
				self.isRewardedAdReady = true
			}
			print("Rewarded ad loaded for unit: \(adUnitID)")
		} catch {
			print("Rewarded ad failed to load with error: \(error) -- \(error.localizedDescription)")
			await MainActor.run { self.isRewardedAdReady = false }
		}
	}

	// Show the rewarded ad if ready. Returns true if presentation started.
	func showRewardedAd(onReward: @escaping () -> Void) -> Bool {
		guard isRewardedAdReady, !isShowingAd, let ad = rewardedAd else { return false }
		guard let root = topViewController() else {
			print("No root view controller to present ad from")
			return false
		}

		self.onReward = onReward
		DispatchQueue.main.async { self.isShowingAd = true }

		// Ensure presentation happens on the main thread and avoid strong self captures.
		DispatchQueue.main.async { [weak self] in
			guard let strongSelf = self else { return }
			ad.present(from: root) { [weak strongSelf] in
				guard let strongSelf = strongSelf else { return }
				// Reward callback is delivered here by the SDK — mark pending reward
				let reward = ad.adReward
				print("User earned reward (pending): \(reward.amount) \(reward.type)")
				Task { @MainActor in
					strongSelf.pendingReward = true
				}
			}
		}

		// Begin loading the next ad immediately so the user can replay after dismissal
		Task { [weak self] in
			await self?.loadRewardedAd()
		}

		return true
	}

	// MARK: - FullScreenContentDelegate

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
		print("Rewarded ad failed to present: \(error) -- \(error.localizedDescription)")
		DispatchQueue.main.async {
			self.isShowingAd = false
			self.isRewardedAdReady = false
			self.rewardedAd = nil
		}
	}

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
		print("Rewarded ad was dismissed")
		Task { @MainActor in
			// If a reward was earned earlier, deliver it now so the UI can animate on dismissal
			if self.pendingReward {
				print("Delivering pending reward now")
				self.onReward?()
				self.onReward = nil
				self.pendingReward = false
			}

			self.isShowingAd = false
			self.isRewardedAdReady = false
			self.rewardedAd = nil
		}
	}

	private func topViewController(base: UIViewController? = nil) -> UIViewController? {
		// Robust method to find the top-most view controller for presentation.
		let baseVC: UIViewController? = {
			if let explicit = base { return explicit }
			if #available(iOS 13.0, *) {
				return UIApplication.shared.connectedScenes
					.compactMap { $0 as? UIWindowScene }
					.flatMap { $0.windows }
					.first { $0.isKeyWindow }?.rootViewController
			} else {
				return UIApplication.shared.windows.first { $0.isKeyWindow }?.rootViewController
			}
		}()

		if let nav = baseVC as? UINavigationController {
			return topViewController(base: nav.visibleViewController)
		}

		if let tab = baseVC as? UITabBarController {
			if let selected = tab.selectedViewController {
				return topViewController(base: selected)
			}
			return topViewController(base: tab)
		}

		if let presented = baseVC?.presentedViewController {
			return topViewController(base: presented)
		}

		return baseVC
	}
}

// Note: Full screen content delegate handling is done via the present completion
// to avoid SDK delegate availability issues in different versions.
