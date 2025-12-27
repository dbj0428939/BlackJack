// RewardedAdManager removed: no-op placeholder for cleanup
import Foundation
import SwiftUI

class RewardedAdManager: NSObject, ObservableObject {
	static let shared = RewardedAdManager()
	@Published var isRewardedAdReady: Bool = false
	func loadRewardedAd() {}
	func showRewardedAd(onReward: @escaping () -> Void) {}
}
