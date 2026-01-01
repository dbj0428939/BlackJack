//
//  ATTConsent.swift
//  BlackJack
//
//  Created by David Johnson on 12/30/25.
//

import Foundation
import AppTrackingTransparency
import AdSupport

enum ATTAuthorization {
    static func requestIfNeeded(){
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ATTrackingManager.requestTrackingAuthorization() {
                _ in
            }
        }
    }
}
