import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            if gameState.isLoading {
                LoadingView()
            } else {
                NavigationStack {
                    MainMenuView()
                }
            }
        }
        .onAppear {
            // Simulate loading time
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    gameState.isLoading = false
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GameState())
    }
} 

