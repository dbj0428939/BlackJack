import SwiftUI

struct SmoothEntrance: ViewModifier {
    let isVisible: Bool
    let offset: CGFloat
    let scale: CGFloat
    let delay: Double
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : offset)
            .scaleEffect(isVisible ? 1 : scale)
            .animation(animation.delay(delay), value: isVisible)
    }
}

extension View {
    func smoothEntrance(visible: Bool,
                        offset: CGFloat = 12,
                        scale: CGFloat = 0.98,
                        delay: Double = 0,
                        animation: Animation = .spring(response: 0.6, dampingFraction: 0.9)) -> some View {
        modifier(SmoothEntrance(isVisible: visible, offset: offset, scale: scale, delay: delay, animation: animation))
    }
}
