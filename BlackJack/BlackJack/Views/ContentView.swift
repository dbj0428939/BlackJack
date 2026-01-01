import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        if gameState.isLoading {
            // Loading screen without banner
            LoadingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.keyboard)
        } else {
            // Main menu with banner at bottom
            VStack(spacing: 0) {
                // Replace this with your actual MainMenu view if different
                LoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 0)
                        GADBannerAdView(width: proxy.size.width)
                            .frame(width: proxy.size.width)
                            .background(Color(UIColor.systemBackground))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .frame(height: 50)
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GameState())
    }
}
