import SwiftUI

struct VictoryView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ZStack {
            LinearGradient(colors: [.green.opacity(0.8), Color("HotelTeal")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .shadow(radius: 10)

                    Text("Hotel Libre Lives")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("You housed \(vm.state.totalHousedEver) people and proved that a hotel can be a home for everyone.")
                        .font(.system(size: 17, design: .serif))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    statRow(label: "Days Running", value: "\(vm.state.day)")
                    statRow(label: "Residents Housed", value: "\(vm.state.totalHousedEver)")
                    statRow(label: "Events Resolved", value: "\(vm.state.totalResolutionsThisRun)")
                    statRow(label: "Final Morale", value: "\(vm.state.morale)%")
                }
                .padding(24)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    vm.resetGame()
                } label: {
                    Text("Play Again")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color("HotelTeal"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

struct GameOverView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ZStack {
            LinearGradient(colors: [.gray.opacity(0.8), .black.opacity(0.9)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.orange)

                    Text("The Hotel Went Dark")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Without funding or morale, the staff couldn't keep the doors open. The residents had to leave.")
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Text("Day \(vm.state.day) — \(vm.state.totalHousedEver) people housed during your run.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Button {
                    vm.resetGame()
                } label: {
                    Text("Try Again")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
    }
}
