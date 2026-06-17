import Foundation

enum RoomType: String, CaseIterable, Codable {
    case standard = "Standard"
    case suite = "Suite"
    case penthouse = "Penthouse"
    case accessible = "Accessible"
    case familySuite = "Family Suite"
    case communal = "Communal Space"
}

enum RoomCondition: String, Codable {
    case pristine = "Pristine"
    case good = "Good"
    case fair = "Fair"
    case needsCleaning = "Needs Cleaning"
    case needsRepair = "Needs Repair"
    case outOfService = "Out of Service"

    var colorName: String {
        switch self {
        case .pristine: return "green"
        case .good: return "mint"
        case .fair: return "yellow"
        case .needsCleaning: return "orange"
        case .needsRepair: return "red"
        case .outOfService: return "gray"
        }
    }

    var decayScore: Int {
        switch self {
        case .pristine: return 5
        case .good: return 4
        case .fair: return 3
        case .needsCleaning: return 2
        case .needsRepair: return 1
        case .outOfService: return 0
        }
    }
}

enum FloorTheme: String, CaseIterable, Codable {
    case garden = "Garden Floor"
    case art = "Art Floor"
    case library = "Library Floor"
    case family = "Family Floor"
    case wellness = "Wellness Floor"
    case rooftop = "Rooftop Community"

    var icon: String {
        switch self {
        case .garden: return "leaf.fill"
        case .art: return "paintpalette.fill"
        case .library: return "books.vertical.fill"
        case .family: return "house.fill"
        case .wellness: return "heart.fill"
        case .rooftop: return "sun.max.fill"
        }
    }
}

struct Room: Identifiable, Codable {
    let id: UUID
    var number: String
    var floor: Int
    var type: RoomType
    var condition: RoomCondition
    var residentID: UUID?
    var floorTheme: FloorTheme?
    var cleanliness: Int            // 0–100
    var comfort: Int                // 0–100, increases with upgrades
    var isLocked: Bool              // locked until unlocked via upgrades
    var pendingRepair: Bool
    var lastCleaned: Date?

    var isOccupied: Bool { residentID != nil }
    var isAvailable: Bool { !isOccupied && !isLocked && condition != .outOfService }

    var overallScore: Int { (cleanliness + comfort) / 2 }

    static func buildHotel() -> [Room] {
        var rooms: [Room] = []
        let now = Date()

        // Floor 1 – Lobby & Accessible (4 rooms, always unlocked)
        let floor1Types: [RoomType] = [.accessible, .standard, .standard, .communal]
        for (i, type) in floor1Types.enumerated() {
            rooms.append(Room(
                id: UUID(), number: "1\(i+1)0", floor: 1, type: type,
                condition: .good, residentID: nil,
                floorTheme: .family,
                cleanliness: 80, comfort: 60,
                isLocked: false, pendingRepair: false, lastCleaned: now
            ))
        }

        // Floor 2 – Standard rooms (6 rooms, unlocked)
        for i in 0..<6 {
            rooms.append(Room(
                id: UUID(), number: "2\(i+1)0", floor: 2, type: .standard,
                condition: i == 3 ? .needsRepair : .fair,
                residentID: nil, floorTheme: .garden,
                cleanliness: 60, comfort: 50,
                isLocked: false, pendingRepair: i == 3, lastCleaned: now
            ))
        }

        // Floor 3 – Suites (4 rooms, 2 locked)
        for i in 0..<4 {
            rooms.append(Room(
                id: UUID(), number: "3\(i+1)0", floor: 3, type: .suite,
                condition: .fair, residentID: nil,
                floorTheme: .library,
                cleanliness: 50, comfort: 70,
                isLocked: i >= 2, pendingRepair: false, lastCleaned: now
            ))
        }

        // Floor 4 – Family Suites (3 rooms, locked)
        for i in 0..<3 {
            rooms.append(Room(
                id: UUID(), number: "4\(i+1)0", floor: 4, type: .familySuite,
                condition: .fair, residentID: nil,
                floorTheme: .family,
                cleanliness: 45, comfort: 65,
                isLocked: true, pendingRepair: false, lastCleaned: now
            ))
        }

        // Floor 5 – Wellness floor (3 rooms + communal, locked)
        for i in 0..<4 {
            rooms.append(Room(
                id: UUID(), number: "5\(i+1)0", floor: 5,
                type: i == 3 ? .communal : .standard,
                condition: .needsCleaning, residentID: nil,
                floorTheme: .wellness,
                cleanliness: 30, comfort: 80,
                isLocked: true, pendingRepair: false, lastCleaned: now
            ))
        }

        // Penthouse – 2 rooms, heavily locked
        for i in 0..<2 {
            rooms.append(Room(
                id: UUID(), number: "PH\(i+1)", floor: 6, type: .penthouse,
                condition: .pristine, residentID: nil,
                floorTheme: .rooftop,
                cleanliness: 100, comfort: 100,
                isLocked: true, pendingRepair: false, lastCleaned: now
            ))
        }

        return rooms
    }
}
