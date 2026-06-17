import SwiftUI

struct RoomDetailView: View {
    var room: Room
    @EnvironmentObject var vm: GameViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showMaidPicker = false
    @State private var actionMode: ActionMode = .none

    enum ActionMode { case none, clean, repair, house }

    var currentResident: Resident? {
        guard let id = room.residentID else { return nil }
        return vm.resident(for: id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    roomHeader
                    if room.isLocked {
                        lockedBanner
                    } else {
                        statusGrid
                        if let resident = currentResident {
                            residentSection(resident)
                        } else {
                            emptyRoomSection
                        }
                        actionButtons
                    }
                }
                .padding()
            }
            .navigationTitle("Room \(room.number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showMaidPicker) {
            MaidPickerView(
                filterSkill: actionMode == .repair ? .maintenance : nil
            ) { maid in
                showMaidPicker = false
                switch actionMode {
                case .clean:  vm.cleanRoom(roomID: room.id, maidID: maid.id)
                case .repair: vm.repairRoom(roomID: room.id, maidID: maid.id)
                default: break
                }
                actionMode = .none
                dismiss()
            }
            .environmentObject(vm)
        }
        .sheet(isPresented: Binding(
            get: { actionMode == .house },
            set: { if !$0 { actionMode = .none } }
        )) {
            WaitlistPickerView { resident in
                vm.houseResident(resident, in: room)
                actionMode = .none
                dismiss()
            }
            .environmentObject(vm)
        }
    }

    var roomHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("HotelTeal").opacity(0.12))
                    .frame(width: 60, height: 60)
                Image(systemName: room.isOccupied ? "person.fill" : "bed.double.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color("HotelTeal"))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(room.type.rawValue)
                    .font(.system(size: 20, weight: .bold))
                if let theme = room.floorTheme {
                    Label(theme.rawValue, systemImage: theme.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    var lockedBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.gray.opacity(0.5))
            Text("This room is locked.")
                .font(.system(size: 18, weight: .semibold))
            Text("Unlock this floor via the Upgrades panel to open it for residents.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    var statusGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(label: "Cleanliness", value: "\(room.cleanliness)%",
                     icon: "sparkles", color: room.cleanliness > 60 ? .green : .orange)
            StatTile(label: "Comfort", value: "\(room.comfort)%",
                     icon: "bed.double.fill", color: .blue)
            StatTile(label: "Condition", value: room.condition.rawValue,
                     icon: "wrench.fill",
                     color: room.condition == .needsRepair ? .red :
                            room.condition == .needsCleaning ? .orange : .green)
            StatTile(label: "Status", value: room.isOccupied ? "Occupied" : "Vacant",
                     icon: room.isOccupied ? "person.fill" : "moon.fill",
                     color: room.isOccupied ? Color("HotelTeal") : .gray)
        }
    }

    @ViewBuilder
    func residentSection(_ resident: Resident) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current Resident")
                .font(.system(size: 16, weight: .bold))

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color("HotelTeal").opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: resident.portrait)
                        .font(.system(size: 22))
                        .foregroundStyle(Color("HotelTeal"))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(resident.name)
                        .font(.system(size: 17, weight: .semibold))
                    Text("\(resident.daysHoused) days housed")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Label(resident.status.rawValue, systemImage: "circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(resident.status == .thriving ? .green : resident.status == .struggling ? .red : .orange)
                }
            }

            VStack(spacing: 4) {
                HStack {
                    Text("Happiness")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(resident.happiness)%")
                        .font(.system(size: 13, weight: .bold))
                }
                MoraleBarView(percent: resident.happinessPercent)
            }

            if let note = resident.thankYouNote {
                HStack(spacing: 10) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 20))
                        .foregroundStyle(Color("HotelTeal").opacity(0.7))
                    Text(note)
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color("HotelTeal").opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    var emptyRoomSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.gray.opacity(0.4))
            Text("Vacant")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Someone on the waitlist could use this space.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    var actionButtons: some View {
        VStack(spacing: 12) {
            if !room.isOccupied && room.isAvailable {
                ActionButton(label: "House a Resident", icon: "person.badge.plus",
                             color: Color("HotelTeal")) {
                    actionMode = .house
                }
            }
            if room.condition == .needsCleaning || room.cleanliness < 60 {
                ActionButton(label: "Send Maid to Clean", icon: "sparkles",
                             color: .orange) {
                    actionMode = .clean
                    showMaidPicker = true
                }
            }
            if room.pendingRepair || room.condition == .needsRepair {
                ActionButton(label: "Send Maid to Repair", icon: "wrench.and.screwdriver",
                             color: .red) {
                    actionMode = .repair
                    showMaidPicker = true
                }
            }
        }
    }
}

struct StatTile: View {
    var label: String
    var value: String
    var icon: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .bold))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ActionButton: View {
    var label: String
    var icon: String
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
