import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        LoadingView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(GameState())
    }
}

