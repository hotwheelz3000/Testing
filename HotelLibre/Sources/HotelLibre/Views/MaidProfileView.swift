import SwiftUI

struct MaidsView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(vm.maids) { maid in
                    MaidCardView(maid: maid)
                }
            }
            .padding()
        }
    }
}

struct MaidCardView: View {
    var maid: Maid

    var energyColor: Color {
        maid.energyPercent > 0.6 ? .green : maid.energyPercent > 0.3 ? .orange : .red
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color("HotelTeal").opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: maid.portrait)
                    .font(.system(size: 24))
                    .foregroundStyle(Color("HotelTeal"))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(maid.name)
                        .font(.system(size: 17, weight: .bold))
                    Spacer()
                    if maid.isWorking {
                        Label("Working", systemImage: "figure.walk")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("HotelTeal"))
                            .clipShape(Capsule())
                    }
                }

                Text(maid.title)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    SkillBadge(skill: maid.primarySkill, isPrimary: true)
                    SkillBadge(skill: maid.secondarySkill, isPrimary: false)
                }

                VStack(spacing: 3) {
                    HStack {
                        Text("Energy")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(maid.energy)/\(maid.maxEnergy)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(energyColor)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.2))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(energyColor)
                                .frame(width: geo.size.width * maid.energyPercent)
                        }
                    }
                    .frame(height: 5)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

struct SkillBadge: View {
    var skill: MaidSkill
    var isPrimary: Bool

    var skillIcon: String {
        switch skill {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench.fill"
        case .cooking: return "fork.knife"
        case .socialWork: return "person.2.fill"
        case .admin: return "doc.fill"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: skillIcon)
                .font(.system(size: 9))
            Text(skill.rawValue)
                .font(.system(size: 10, weight: isPrimary ? .bold : .regular))
        }
        .foregroundStyle(isPrimary ? Color("HotelTeal") : .secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isPrimary ? Color("HotelTeal") : Color.gray).opacity(0.1))
        .clipShape(Capsule())
    }
}

struct MaidPickerView: View {
    var filterSkill: MaidSkill?
    var onSelect: (Maid) -> Void

    @EnvironmentObject var vm: GameViewModel
    @Environment(\.dismiss) var dismiss

    var eligibleMaids: [Maid] {
        if let skill = filterSkill {
            return vm.maids.filter {
                ($0.primarySkill == skill || $0.secondarySkill == skill) && $0.energy > 0
            }
        }
        return vm.maids.filter { $0.energy > 0 }
    }

    var body: some View {
        NavigationStack {
            List {
                if eligibleMaids.isEmpty {
                    ContentUnavailableView(
                        "No Maids Available",
                        systemImage: "zzz",
                        description: Text("All maids with the required skill are too tired. Advance the day to let them rest.")
                    )
                } else {
                    ForEach(eligibleMaids) { maid in
                        Button {
                            onSelect(maid)
                        } label: {
                            MaidCardView(maid: maid)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(filterSkill.map { "Pick \($0.rawValue) Expert" } ?? "Pick a Maid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
