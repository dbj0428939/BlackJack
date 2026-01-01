import SwiftUI
import GoogleMobileAds
import Combine
import Foundation

// Manages the lifecycle of a Google Mobile Ads interstitial: loading, presenting, and handling callbacks.
// Exposed as an ObservableObject so SwiftUI views can hold and trigger it.
final class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = InterstitialAdManager()
    // Track hands played to throttle interstitial frequency
    @Published private(set) var handsPlayedCounter: Int = 0
    private let interstitialFrequency: Int = 10
    private let userDefaultsKey = "interstitialHandsPlayed"
    private let firstGameShownKey = "interstitialShownOnFirstGameStart"
    // If we requested presentation but the ad wasn't loaded yet, remember to show after load
    private var presentAfterLoadRequested: Bool = false
    // Optional completion to call after a presented interstitial is dismissed
    private var pendingCompletion: (() -> Void)? = nil

    // Use Google's official test interstitial unit ID during development. Replace with your real unit ID for production.
    /// Google test interstitial ad unit
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910"

    // Keep a strong reference to the loaded interstitial until it's shown or fails.
    private var interstitial: InterstitialAd?

    override init() {
        super.init()
        // Load persisted hands counter so frequency continues across launches
        handsPlayedCounter = UserDefaults.standard.integer(forKey: userDefaultsKey)
    }

    // Call this when a hand completes. Presents an interstitial every `interstitialFrequency` hands if loaded.
    func recordHandCompletedAndMaybeShow() {
        handsPlayedCounter += 1
        // persist updated counter
        UserDefaults.standard.set(handsPlayedCounter, forKey: userDefaultsKey)
        print("InterstitialAdManager: hand completed count = \(handsPlayedCounter), interstitial ready = \(interstitial != nil)")
        // Only show at multiples of the configured frequency
        guard handsPlayedCounter % interstitialFrequency == 0 else { return }
        // Try to present if ready, otherwise start loading for next time
        if interstitial != nil {
            present()
        } else {
            print("Interstitial not ready at threshold — preloading")
            load()
        }
    }

    // Request a new interstitial. Should be called initially and again after presentation/dismissal.
    func load() {
        if interstitial != nil { return }
        let request = Request()
        InterstitialAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            if let error {
                print("InterstitialAdManager: Interstitial failed to load: \(error)")
                // If a show was requested after load, but load failed, call pending completion so UI continues
                if self.presentAfterLoadRequested {
                    self.presentAfterLoadRequested = false
                    if let completion = self.pendingCompletion {
                        self.pendingCompletion = nil
                        DispatchQueue.main.async { completion() }
                    }
                }
                return
            }
            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
            print("InterstitialAdManager: Interstitial loaded: \(String(describing: ad))")
            // If a presentation was requested while loading (e.g. first-game show), present now
            if self.presentAfterLoadRequested {
                self.presentAfterLoadRequested = false
                self.present()
            }
        }
    }

    // Present the interstitial if available; otherwise kick off a load.
    func present() {
        // Find the top-most view controller for presentation to avoid interfering with SwiftUI transitions
        guard var top = UIApplication.shared.firstKeyWindowRootViewController() else { return }
        while let presented = top.presentedViewController {
            top = presented
        }
        print("InterstitialAdManager: presenting from top VC: \(type(of: top))")
        guard let interstitial else {
            print("InterstitialAdManager: Interstitial not ready — loading now") ; load() ; return // If not ready, trigger load and exit; UI can try again later
        }
        // Tentatively mark the one-time first-game flag when starting presentation. If presentation fails,
        // we'll revert the flag in the failure delegate so we don't incorrectly suppress future attempts.
        if pendingCompletion != nil {
            UserDefaults.standard.set(true, forKey: firstGameShownKey)
        }
        interstitial.present(from: top) // Show the ad from the top-most controller
        // When presented, the SDK will call delegate callbacks; keep reference until dismissal
    }

    // MARK: - GADFullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Interstitial dismissed — loading next") // After dismissal, clear reference and load the next ad
        self.interstitial = nil
        // Reset persisted counter so we count a fresh block of hands after showing
        handsPlayedCounter = 0
        UserDefaults.standard.set(handsPlayedCounter, forKey: userDefaultsKey)
        // If there was a pending completion (e.g. first-game flow), call it now
        if let completion = pendingCompletion {
            pendingCompletion = nil
            DispatchQueue.main.async { completion() }
        }
        self.load()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("InterstitialAdManager: Interstitial failed to present: \(error)") // If presentation fails, clear and attempt to load again
        self.interstitial = nil
        // If a first-game show was pending, call its completion so UI can continue
        if let completion = pendingCompletion {
            pendingCompletion = nil
            DispatchQueue.main.async { completion() }
        }
        presentAfterLoadRequested = false
        // Revert first-game shown flag because presentation failed
        UserDefaults.standard.set(false, forKey: firstGameShownKey)
        self.load()
    }
}

extension InterstitialAdManager {
    /// Call this to attempt to show an interstitial the first time the player opens a game.
    /// This will only show once (persisted) and will present immediately if loaded, or after load completes.
    /// Attempt to show an interstitial the first time the player opens a game.
    /// If `completion` is provided it will be invoked after the ad is dismissed (or immediately if no ad is shown).
    func showOnFirstGameStartIfNeeded(completion: (() -> Void)? = nil) {
        let alreadyShown = UserDefaults.standard.bool(forKey: firstGameShownKey)
        guard !alreadyShown else {
            // Nothing to show — run completion immediately
            DispatchQueue.main.async { completion?() }
            return
        }

        // Store completion to call after dismissal
        pendingCompletion = completion

        if interstitial != nil {
            // Present now and mark as shown
            present()
            UserDefaults.standard.set(true, forKey: firstGameShownKey)
            // Also reset hands counter so the next block begins fresh
            handsPlayedCounter = 0
            UserDefaults.standard.set(handsPlayedCounter, forKey: userDefaultsKey)
        } else {
            // Request load and present after it finishes
            presentAfterLoadRequested = true
            load()
            // Mark as shown so we don't try repeatedly
            UserDefaults.standard.set(true, forKey: firstGameShownKey)
        }
    }
}

// Helper to locate a root view controller for presentation in multi-scene apps.
private extension UIApplication {
    func firstKeyWindowRootViewController() -> UIViewController? {
        connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow } // Iterate active scenes and find the key window
            .first?
            .rootViewController
    }
}

// Convenience to fetch the key window for a scene
private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first(where: { $0.isKeyWindow }) }
}
