import Foundation

enum GamePhase: String, Codable {
    case mainMenu
    case playing
    case paused
    case gameOver
    case victory
}

struct Upgrade: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var icon: String
    var fundingCost: Int
    var suppliesCost: Int
    var isUnlocked: Bool
    var effect: String              // human-readable
    var unlocksFloor: Int?

    static let catalog: [Upgrade] = [
        Upgrade(id: UUID(), name: "Community Laundry Room",
                description: "Convert a service closet into a shared laundry space.",
                icon: "washer.fill", fundingCost: 300, suppliesCost: 20,
                isUnlocked: false, effect: "+5 happiness all residents", unlocksFloor: nil),
        Upgrade(id: UUID(), name: "Unlocked: Floor 3 Suites",
                description: "Restore elevator access and clean the locked suites.",
                icon: "3.square.fill", fundingCost: 500, suppliesCost: 40,
                isUnlocked: false, effect: "Opens 2 suite rooms", unlocksFloor: 3),
        Upgrade(id: UUID(), name: "Community Notice Board",
                description: "A corkboard in the lobby for skill-sharing and announcements.",
                icon: "pin.fill", fundingCost: 50, suppliesCost: 5,
                isUnlocked: false, effect: "+3 morale per day", unlocksFloor: nil),
        Upgrade(id: UUID(), name: "Roof Garden",
                description: "Convert the penthouse terrace into shared growing space.",
                icon: "leaf.fill", fundingCost: 800, suppliesCost: 60,
                isUnlocked: false, effect: "+10 morale; supplies regenerate", unlocksFloor: nil),
        Upgrade(id: UUID(), name: "Unlocked: Floor 4 Family Suites",
                description: "Fix the plumbing and furnish the large family suites.",
                icon: "4.square.fill", fundingCost: 700, suppliesCost: 50,
                isUnlocked: false, effect: "Opens 3 family suite rooms", unlocksFloor: 4),
        Upgrade(id: UUID(), name: "Solar Panels",
                description: "Reduce utility costs and keep the lights on.",
                icon: "sun.max.fill", fundingCost: 1200, suppliesCost: 0,
                isUnlocked: false, effect: "-$50 daily upkeep", unlocksFloor: nil),
        Upgrade(id: UUID(), name: "Unlocked: Wellness Floor",
                description: "Open the 5th floor as a rest and recovery space.",
                icon: "5.square.fill", fundingCost: 1000, suppliesCost: 80,
                isUnlocked: false, effect: "Opens 4 wellness rooms", unlocksFloor: 5),
        Upgrade(id: UUID(), name: "Unlocked: Penthouse",
                description: "The legendary top floor, opened for the community's most special needs.",
                icon: "star.fill", fundingCost: 2000, suppliesCost: 100,
                isUnlocked: false, effect: "Opens 2 penthouse suites", unlocksFloor: 6),
    ]
}

struct GameState: Codable {
    var phase: GamePhase
    var day: Int
    var funding: Int
    var supplies: Int
    var morale: Int                 // 0–100 overall staff + community morale
    var maids: [Maid]
    var rooms: [Room]
    var residents: [Resident]
    var waitlist: [Resident]
    var activeEvents: [GameEvent]
    var resolvedEventIDs: [UUID]
    var unlockedUpgrades: [UUID]
    var availableUpgrades: [Upgrade]
    var dailyUpkeep: Int
    var noticeBoard: Bool           // upgrade flag
    var roofGarden: Bool
    var solarPanels: Bool
    var totalHousedEver: Int
    var totalResolutionsThisRun: Int

    var occupiedRooms: Int { rooms.filter { $0.isOccupied }.count }
    var availableRooms: Int { rooms.filter { $0.isAvailable }.count }
    var totalUnlockedRooms: Int { rooms.filter { !$0.isLocked }.count }
    var moralePercent: Double { Double(morale) / 100.0 }
    var isVictoryReached: Bool { totalHousedEver >= 20 && morale >= 70 }

    static func newGame() -> GameState {
        var waitlist: [Resident] = []
        for _ in 0..<4 {
            waitlist.append(Resident.randomWaitlistResident())
        }
        return GameState(
            phase: .playing,
            day: 1,
            funding: 1000,
            supplies: 50,
            morale: 60,
            maids: Maid.roster,
            rooms: Room.buildHotel(),
            residents: [],
            waitlist: waitlist,
            activeEvents: [],
            resolvedEventIDs: [],
            unlockedUpgrades: [],
            availableUpgrades: Upgrade.catalog,
            dailyUpkeep: 100,
            noticeBoard: false,
            roofGarden: false,
            solarPanels: false,
            totalHousedEver: 0,
            totalResolutionsThisRun: 0
        )
    }
}
