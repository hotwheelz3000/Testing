import SwiftUI

struct UpgradesView: View {
    @EnvironmentObject var vm: GameViewModel
    @Environment(\.dismiss) var dismiss

    var available: [Upgrade] { vm.state.availableUpgrades.filter { !$0.isUnlocked } }
    var unlocked: [Upgrade] { vm.state.availableUpgrades.filter { $0.isUnlocked } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Resources summary
                    HStack(spacing: 0) {
                        ResourcePill(icon: "dollarsign.circle.fill", value: "$\(vm.state.funding)", color: .green)
                        Divider().frame(height: 28).padding(.horizontal, 8)
                        ResourcePill(icon: "shippingbox.fill", value: "\(vm.state.supplies) supplies", color: .orange)
                    }
                    .padding(.horizontal)

                    if !available.isEmpty {
                        sectionHeader("Available Upgrades")
                        LazyVStack(spacing: 12) {
                            ForEach(available) { upgrade in
                                UpgradeCard(upgrade: upgrade) {
                                    vm.purchaseUpgrade(upgrade)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    if !unlocked.isEmpty {
                        sectionHeader("Already Unlocked")
                        LazyVStack(spacing: 12) {
                            ForEach(unlocked) { upgrade in
                                UpgradeCard(upgrade: upgrade, purchased: true) { }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Upgrades")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold))
            .padding(.horizontal)
    }
}

struct UpgradeCard: View {
    var upgrade: Upgrade
    var purchased: Bool = false
    var onPurchase: () -> Void

    @EnvironmentObject var vm: GameViewModel

    var canAfford: Bool {
        vm.state.funding >= upgrade.fundingCost && vm.state.supplies >= upgrade.suppliesCost
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(purchased ? Color.green.opacity(0.1) : Color("HotelTeal").opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: upgrade.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(purchased ? .green : Color("HotelTeal"))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(upgrade.name)
                        .font(.system(size: 16, weight: .bold))
                    Text(upgrade.description)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                Label("\(upgrade.effect)", systemImage: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(purchased ? .green : Color("HotelTeal"))
                Spacer()
            }

            if !purchased {
                HStack(spacing: 16) {
                    if upgrade.fundingCost > 0 {
                        costPill(icon: "dollarsign.circle.fill", amount: "$\(upgrade.fundingCost)",
                                 affordable: vm.state.funding >= upgrade.fundingCost)
                    }
                    if upgrade.suppliesCost > 0 {
                        costPill(icon: "shippingbox.fill", amount: "\(upgrade.suppliesCost) supplies",
                                 affordable: vm.state.supplies >= upgrade.suppliesCost)
                    }
                    Spacer()
                    Button(action: onPurchase) {
                        Text("Unlock")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(canAfford ? Color("HotelTeal") : Color.gray.opacity(0.4))
                            .clipShape(Capsule())
                    }
                    .disabled(!canAfford)
                }
            } else {
                Label("Unlocked", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    @ViewBuilder
    func costPill(icon: String, amount: String, affordable: Bool) -> some View {
        Label(amount, systemImage: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(affordable ? .primary : .red)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background((affordable ? Color.gray : Color.red).opacity(0.1))
            .clipShape(Capsule())
    }
}

struct ResourcePill: View {
    var icon: String
    var value: String
    var color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 14, weight: .bold))
        }
        .frame(maxWidth: .infinity)
    }
}
