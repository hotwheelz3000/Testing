import SwiftUI

struct FloorView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selectedFloor: Int = 1
    @State private var selectedRoom: Room? = nil
    @State private var selectedMaidForRoom: Maid? = nil

    var body: some View {
        VStack(spacing: 0) {
            floorSelector
                .padding(.horizontal)
                .padding(.top, 8)

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(vm.roomsByFloor(selectedFloor)) { room in
                        RoomCardView(room: room)
                            .onTapGesture {
                                selectedRoom = room
                            }
                    }
                }
                .padding()
            }
        }
        .sheet(item: $selectedRoom) { room in
            RoomDetailView(room: room)
                .environmentObject(vm)
        }
    }

    var floorSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.floors, id: \.self) { floor in
                    let theme = vm.roomsByFloor(floor).first?.floorTheme
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFloor = floor
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: theme?.icon ?? "square.fill")
                                .font(.system(size: 18))
                            Text(floorLabel(floor))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(selectedFloor == floor ? .white : Color("HotelTeal"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            selectedFloor == floor ? Color("HotelTeal") : Color("HotelTeal").opacity(0.12)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    func floorLabel(_ floor: Int) -> String {
        floor == 6 ? "PH" : "Floor \(floor)"
    }
}

struct RoomCardView: View {
    var room: Room

    var conditionColor: Color {
        switch room.condition {
        case .pristine: return .green
        case .good: return .mint
        case .fair: return .yellow
        case .needsCleaning: return .orange
        case .needsRepair: return .red
        case .outOfService: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(room.number)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                Spacer()
                if room.isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                } else if room.pendingRepair {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                } else if room.isOccupied {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Color("HotelTeal"))
                }
            }

            Text(room.type.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            if !room.isLocked {
                VStack(spacing: 4) {
                    HStack {
                        Text("Clean")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(room.cleanliness)%")
                            .font(.system(size: 10, weight: .bold))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(room.cleanliness > 60 ? Color.green : room.cleanliness > 30 ? Color.orange : Color.red)
                                .frame(width: geo.size.width * Double(room.cleanliness) / 100)
                        }
                    }
                    .frame(height: 5)
                }
            }

            HStack {
                Circle()
                    .fill(room.isLocked ? .gray : conditionColor)
                    .frame(width: 8, height: 8)
                Text(room.isLocked ? "Locked" : room.condition.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(room.isLocked ? .secondary : conditionColor)
            }
        }
        .padding(14)
        .background(room.isLocked ? Color.gray.opacity(0.08) : Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(room.isOccupied ? Color("HotelTeal").opacity(0.4) : Color.gray.opacity(0.15), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .opacity(room.isLocked ? 0.6 : 1.0)
    }
}
