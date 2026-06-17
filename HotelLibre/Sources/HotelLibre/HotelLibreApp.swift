import SwiftUI

@main
struct HotelLibreApp: App {
    @StateObject private var vm = GameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
                .preferredColorScheme(.none)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        Group {
            switch vm.state.phase {
            case .mainMenu:
                MainMenuView()
            case .playing, .paused:
                GameView()
            case .victory:
                VictoryView()
            case .gameOver:
                GameOverView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: vm.state.phase)
    }
}
