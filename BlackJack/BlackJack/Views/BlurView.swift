import SwiftUI
import UIKit

public struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    public func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    public func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // No update needed
    }
}