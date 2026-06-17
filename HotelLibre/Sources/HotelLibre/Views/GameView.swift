import SwiftUI

struct GameView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selectedTab: Tab = .hotel
    @State private var showUpgrades = false
    @State private var showDayConfirm = false

    enum Tab: String, CaseIterable {
        case hotel = "Hotel"
        case residents = "Residents"
        case staff = "Staff"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                // HUD
                HUDView()
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                // Tab content
                Group {
                    switch selectedTab {
                    case .hotel:
                        FloorView()
                    case .residents:
                        ResidentsView()
                    case .staff:
                        MaidsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Tab bar
                tabBar
            }

            // Event overlay
            if let event = vm.activeEvent {
                EventView(event: event)
                    .environmentObject(vm)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: event.id)
                    .zIndex(10)
            }

            // Toast
            if let toast = vm.toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: toast)
                        .padding(.bottom, 90)
                }
                .animation(.spring(response: 0.3), value: toast)
                .zIndex(20)
            }
        }
        .sheet(isPresented: $showUpgrades) {
            UpgradesView()
                .environmentObject(vm)
        }
        .alert("End the Day?", isPresented: $showDayConfirm) {
            Button("Advance Day", role: .destructive) {
                vm.advanceDay()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Maids will rest overnight, rooms will decay slightly, and a new event may arrive.")
        }
    }

    var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hotel Libre")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                Text("\(vm.state.occupiedRooms)/\(vm.state.totalUnlockedRooms) rooms occupied")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Morale indicator
            VStack(spacing: 4) {
                Image(systemName: vm.state.morale > 60 ? "heart.fill" : vm.state.morale > 30 ? "heart.slash" : "heart.slash.fill")
                    .foregroundStyle(vm.state.morale > 60 ? .pink : vm.state.morale > 30 ? .orange : .red)
                Text("Morale")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Button {
                showUpgrades = true
            } label: {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color("HotelTeal"))
                    .padding(10)
                    .background(Color("HotelTeal").opacity(0.1))
                    .clipShape(Circle())
            }

            Button {
                showDayConfirm = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 14))
                    Text("Sleep")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color("HotelTeal"))
                .clipShape(Capsule())
            }
        }
    }

    var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabIcon(tab))
                            .font(.system(size: 20))
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? Color("HotelTeal") : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    func tabIcon(_ tab: Tab) -> String {
        switch tab {
        case .hotel: return "building.columns.fill"
        case .residents: return "person.3.fill"
        case .staff: return "person.badge.shield.checkmark.fill"
        }
    }
}
