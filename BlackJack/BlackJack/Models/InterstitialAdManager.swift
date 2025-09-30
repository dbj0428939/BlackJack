import Foundation
import GoogleMobileAds
import SwiftUI
import UIKit

class InterstitialAdManager: NSObject, ObservableObject {
    @Published var interstitialAd: InterstitialAd?
    @Published var isAdLoaded = false
    static let shared = InterstitialAdManager()

    override init() {
        super.init()
        loadAd()
    }

    func loadAd() {
        let request = Request()
        InterstitialAd.load(with: "ca-app-pub-3940256099942544/4411468910", request: request) { [weak self] ad, error in
            if let ad = ad {
                self?.interstitialAd = ad
                self?.isAdLoaded = true
                ad.fullScreenContentDelegate = self
            } else {
                print("Failed to load interstitial ad: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func showAdIfAvailable() {
        guard let ad = interstitialAd,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("Interstitial ad not ready or no root view controller.")
            return
        }
        ad.present(from: rootVC)
        isAdLoaded = false
        interstitialAd = nil
        loadAd() // Preload next ad
    }
}

extension InterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Interstitial ad dismissed.")
        loadAd()
    }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Interstitial ad failed to present: \(error.localizedDescription)")
        loadAd()
    }
}
