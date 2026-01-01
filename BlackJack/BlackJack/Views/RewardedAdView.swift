import SwiftUI

// Lightweight placeholder view used during ad presentation when using the
// real Google Mobile Ads SDK. The actual video is presented by the SDK
// from the native view controller; this view simply provides a neutral
// full-screen overlay while the ad plays.
struct RewardedAdView: View {
    @State private var showingMessage = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("Ad Playing")
                    .font(.title)
                    .foregroundColor(.white)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.6)

                Text("The ad is playing. You'll be returned when it's finished.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
        }
    }
}

struct RewardedAdView_Previews: PreviewProvider {
    static var previews: some View {
        RewardedAdView()
    }
}
