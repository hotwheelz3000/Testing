import SwiftUI

struct ResidentsView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var tab: Tab = .housed

    enum Tab: String, CaseIterable {
        case housed = "Housed"
        case waitlist = "Waitlist"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                LazyVStack(spacing: 14) {
                    switch tab {
                    case .housed:
                        if vm.residents.isEmpty {
                            emptyState(
                                icon: "moon.fill",
                                title: "No Residents Yet",
                                message: "Check the waitlist to house someone."
                            )
                        } else {
                            ForEach(vm.residents) { resident in
                                ResidentCardView(resident: resident, mode: .housed)
                            }
                        }
                    case .waitlist:
                        if vm.waitlist.isEmpty {
                            emptyState(
                                icon: "person.badge.clock.fill",
                                title: "Waitlist is Clear",
                                message: "New applicants arrive each day."
                            )
                        } else {
                            ForEach(vm.waitlist) { resident in
                                ResidentCardView(resident: resident, mode: .waitlist)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    @ViewBuilder
    func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))
                .padding(.top, 40)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct ResidentCardView: View {
    var resident: Resident
    var mode: Mode

    enum Mode { case housed, waitlist }

    @EnvironmentObject var vm: GameViewModel
    @State private var showDetail = false

    var statusColor: Color {
        switch resident.status {
        case .thriving: return .green
        case .housed: return Color("HotelTeal")
        case .struggling: return .red
        case .waitlisted: return .orange
        case .departed: return .gray
        }
    }

    var body: some View {
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.15))
                            .frame(width: 50, height: 50)
                        Image(systemName: resident.portrait)
                            .font(.system(size: 20))
                            .foregroundStyle(statusColor)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(resident.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(resident.story)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                if mode == .housed {
                    VStack(spacing: 3) {
                        HStack {
                            Text("Happiness")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(resident.happiness)%")
                                .font(.system(size: 11, weight: .bold))
                        }
                        MoraleBarView(percent: resident.happinessPercent)
                    }
                }

                HStack(spacing: 6) {
                    ForEach(resident.needs.prefix(3), id: \.self) { need in
                        Text(need.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Label(resident.status.rawValue, systemImage: "circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            ResidentDetailView(resident: resident, mode: mode)
                .environmentObject(vm)
        }
    }
}

struct ResidentDetailView: View {
    var resident: Resident
    var mode: ResidentCardView.Mode
    @EnvironmentObject var vm: GameViewModel
    @Environment(\.dismiss) var dismiss

    var assignedRoom: Room? {
        guard let id = resident.roomID else { return nil }
        return vm.room(for: id)
    }

    var availableRooms: [Room] {
        vm.rooms.filter { $0.isAvailable }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color("HotelTeal").opacity(0.12))
                                .frame(width: 70, height: 70)
                            Image(systemName: resident.portrait)
                                .font(.system(size: 30))
                                .foregroundStyle(Color("HotelTeal"))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(resident.name)
                                .font(.system(size: 22, weight: .bold))
                            Text("Age \(resident.age)")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            if let room = assignedRoom {
                                Label("Room \(room.number)", systemImage: "bed.double.fill")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color("HotelTeal"))
                            }
                        }
                    }

                    // Story
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Their Story")
                            .font(.system(size: 15, weight: .bold))
                        Text(resident.story)
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(.secondary)
                    }

                    // Contribution
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Community Contribution")
                            .font(.system(size: 15, weight: .bold))
                        Label(resident.skillContribution, systemImage: "hands.sparkles.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }

                    // Needs
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Needs")
                            .font(.system(size: 15, weight: .bold))
                        FlowLayout(items: resident.needs.map { $0.rawValue })
                    }

                    // Thank you note
                    if let note = resident.thankYouNote {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("A Note from \(resident.name.components(separatedBy: " ").first ?? resident.name)",
                                  systemImage: "envelope.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color("HotelTeal"))
                            Text(note)
                                .font(.system(size: 15, design: .serif))
                                .italic()
                                .padding(14)
                                .background(Color("HotelTeal").opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    // Actions
                    if mode == .waitlist && !availableRooms.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Assign to a Room")
                                .font(.system(size: 15, weight: .bold))
                            ForEach(availableRooms.prefix(4)) { room in
                                Button {
                                    vm.houseResident(resident, in: room)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "bed.double.fill")
                                            .foregroundStyle(Color("HotelTeal"))
                                        Text("Room \(room.number) — \(room.type.rawValue)")
                                            .font(.system(size: 14, weight: .medium))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(14)
                                    .background(Color("HotelTeal").opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else if mode == .waitlist {
                        Label("No available rooms right now. Clean or repair rooms to make space.", systemImage: "exclamationmark.triangle")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
            }
            .navigationTitle(resident.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct WaitlistPickerView: View {
    var onSelect: (Resident) -> Void
    @EnvironmentObject var vm: GameViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.waitlist) { resident in
                    Button {
                        onSelect(resident)
                    } label: {
                        ResidentCardView(resident: resident, mode: .waitlist)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Waitlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .environmentObject(vm)
    }
}

// Simple flow layout for tags
struct FlowLayout: View {
    var items: [String]

    var body: some View {
        var width: CGFloat = 0
        var rows: [[String]] = [[]]

        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                        .alignmentGuide(.leading) { d in
                            if abs(width - d.width) > geo.size.width {
                                width = 0
                            }
                            let result = width
                            if item == items.last {
                                width = 0
                            } else {
                                width -= d.width + 6
                            }
                            return result
                        }
                }
            }
        }
        .frame(height: CGFloat(items.count / 3 + 1) * 32)
    }
}
