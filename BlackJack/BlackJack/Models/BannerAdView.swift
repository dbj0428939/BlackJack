import SwiftUI

struct BannerAdView: View {
    var body: some View {
        // Ads removed; placeholder view takes no space
        Color.clear.frame(height: 0)
    }
}

#Preview {
    VStack(spacing: 12) {
        Text("Content Above Ad")
        BannerAdView().frame(height: 0)
        Text("Content Below Ad")
    }
}
