import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var showCredits = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("HotelGold").opacity(0.9), Color("HotelTeal")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                VStack(spacing: 8) {
                    Text("HOTEL")
                        .font(.system(size: 20, weight: .medium, design: .serif))
                        .foregroundStyle(.white.opacity(0.8))
                        .tracking(12)
                    Text("LIBRE")
                        .font(.system(size: 72, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .tracking(8)
                    Text("Free housing for all — managed by those who know it best.")
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 4)
                }

                Image(systemName: "building.columns.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                Spacer()

                VStack(spacing: 16) {
                    MenuButton(label: "Start New Game", icon: "star.fill") {
                        vm.resetGame()
                        vm.state.phase = .playing
                    }
                    if UserDefaults.standard.data(forKey: "hotelLibreSave") != nil {
                        MenuButton(label: "Continue", icon: "arrow.clockwise") {
                            vm.state.phase = .playing
                        }
                    }
                    MenuButton(label: "Credits", icon: "person.3.fill") {
                        showCredits = true
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
    }
}

struct MenuButton: View {
    var label: String
    var icon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
            }
            .foregroundStyle(Color("HotelTeal"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        }
    }
}

struct CreditsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Hotel Libre is a story about what happens when the people who serve a place inherit it — and choose to share it.")
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)

                    creditSection(title: "The Maids", items: [
                        "Rosa Delgado — Head Housekeeper",
                        "Lily Tran — Senior Maid & Translator",
                        "Carmen Reyes — Senior Maid",
                        "Dalia Osei — Facilities Maid",
                        "Esther Mwangi — Kitchen & Housekeeping"
                    ])

                    creditSection(title: "Inspired by", items: [
                        "Every hotel worker who ever made a bed",
                        "Communities that build from what they have",
                        "The stubborn belief that shelter is a right"
                    ])
                }
                .padding(28)
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    func creditSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .serif))
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
