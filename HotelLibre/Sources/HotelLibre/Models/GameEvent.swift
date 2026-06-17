import Foundation

enum EventCategory: String, Codable {
    case maintenance = "Maintenance"
    case community = "Community"
    case external = "External"
    case donation = "Donation"
    case crisis = "Crisis"
}

enum EventOutcome: Codable {
    case suppliesGained(Int)
    case suppliesLost(Int)
    case moraleGained(Int)
    case moraleLost(Int)
    case roomDamaged(UUID)
    case roomRepaired(UUID)
    case residentJoined
    case residentLeft(UUID)
    case fundingGained(Int)
    case fundingLost(Int)
    case unlockFloor(Int)
}

struct GameEventChoice: Identifiable, Codable {
    let id: UUID
    var label: String
    var description: String
    var requiredSkill: MaidSkill?
    var outcomes: [EventOutcome]
    var energyCost: Int
}

struct GameEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var icon: String                // SF Symbol
    var category: EventCategory
    var choices: [GameEventChoice]
    var isResolved: Bool
    var dayTriggered: Int

    static let eventPool: [GameEvent] = [
        // Maintenance
        GameEvent(
            id: UUID(),
            title: "Burst Pipe on Floor 2",
            description: "Water is leaking into room 220. Residents are scrambling.",
            icon: "drop.fill",
            category: .maintenance,
            choices: [
                GameEventChoice(id: UUID(),
                    label: "Fix it ourselves",
                    description: "Carmen or Dalia patches the pipe. Costs supplies but saves the room.",
                    requiredSkill: .maintenance,
                    outcomes: [.suppliesLost(10), .moraleGained(5)],
                    energyCost: 25),
                GameEventChoice(id: UUID(),
                    label: "Call a plumber",
                    description: "Professional fix. Costs funding.",
                    requiredSkill: nil,
                    outcomes: [.fundingLost(150), .moraleGained(2)],
                    energyCost: 5)
            ],
            isResolved: false, dayTriggered: 0
        ),
        // Community
        GameEvent(
            id: UUID(),
            title: "Residents Want a Community Garden",
            description: "Three residents are asking to turn the rooftop terrace into a vegetable garden.",
            icon: "leaf.fill",
            category: .community,
            choices: [
                GameEventChoice(id: UUID(),
                    label: "Yes — let's grow together",
                    description: "Spend supplies to build raised beds. Big morale boost.",
                    requiredSkill: nil,
                    outcomes: [.suppliesLost(20), .moraleGained(15)],
                    energyCost: 10),
                GameEventChoice(id: UUID(),
                    label: "Not yet — too much work",
                    description: "Decline for now. Small morale dip.",
                    requiredSkill: nil,
                    outcomes: [.moraleLost(5)],
                    energyCost: 0)
            ],
            isResolved: false, dayTriggered: 0
        ),
        // External
        GameEvent(
            id: UUID(),
            title: "City Inspector Visit",
            description: "An official is coming to assess the building's use as housing. She looks skeptical.",
            icon: "building.2.fill",
            category: .external,
            choices: [
                GameEventChoice(id: UUID(),
                    label: "Show her around proudly",
                    description: "Rosa leads a confident tour. High cleanliness required.",
                    requiredSkill: .admin,
                    outcomes: [.moraleGained(20), .fundingGained(500)],
                    energyCost: 30),
                GameEventChoice(id: UUID(),
                    label: "Panic-clean everything",
                    description: "Rush to tidy up. Uses lots of supplies and energy.",
                    requiredSkill: .cleaning,
                    outcomes: [.suppliesLost(30), .moraleGained(8)],
                    energyCost: 40)
            ],
            isResolved: false, dayTriggered: 0
        ),
        // Donation
        GameEvent(
            id: UUID(),
            title: "Anonymous Donation Arrives",
            description: "A crate of cleaning supplies and a note: 'Keep doing what you're doing.'",
            icon: "gift.fill",
            category: .donation,
            choices: [
                GameEventChoice(id: UUID(),
                    label: "Accept gratefully",
                    description: "Free supplies and a morale lift.",
                    requiredSkill: nil,
                    outcomes: [.suppliesGained(40), .moraleGained(10)],
                    energyCost: 0)
            ],
            isResolved: false, dayTriggered: 0
        ),
        // Crisis
        GameEvent(
            id: UUID(),
            title: "Former Owner Demands the Hotel Back",
            description: "The previous owner's lawyer is in the lobby with papers. Residents are watching nervously.",
            icon: "exclamationmark.triangle.fill",
            category: .crisis,
            choices: [
                GameEventChoice(id: UUID(),
                    label: "Stand firm with our deed",
                    description: "Rosa presents the lottery paperwork. Legal and effective.",
                    requiredSkill: .admin,
                    outcomes: [.moraleGained(25)],
                    energyCost: 20),
                GameEventChoice(id: UUID(),
                    label: "Call community supporters",
                    description: "Lily rallies residents and press. Takes time but generates goodwill.",
                    requiredSkill: .socialWork,
                    outcomes: [.moraleGained(15), .fundingGained(200)],
                    energyCost: 35)
            ],
            isResolved: false, dayTriggered: 0
        ),
        // Community dinner
        GameEvent(
            id: UUID(),
            title: "Community Potluck Night",
            description: "Esther is organizing a big dinner. She needs ingredients and a space cleared.",
            icon: "fork.knife.circle.fill",
            category: .community,
            choices: [
                GameEventChoice(id: UUID(),
                    label: "Make it a big event",
                    description: "Spend supplies, gain huge morale and resident happiness.",
                    requiredSkill: .cooking,
                    outcomes: [.suppliesLost(15), .moraleGained(20)],
                    energyCost: 20),
                GameEventChoice(id: UUID(),
                    label: "Keep it small and simple",
                    description: "Lower cost, modest morale gain.",
                    requiredSkill: nil,
                    outcomes: [.suppliesLost(5), .moraleGained(8)],
                    energyCost: 10)
            ],
            isResolved: false, dayTriggered: 0
        ),
        // Media
        GameEvent(
            id: UUID(),
            title: "Journalist Wants to Write a Story",
            description: "A local reporter heard about the hotel. She wants to interview the staff.",
            icon: "newspaper.fill",
            category: .external,
            choices: [
                GameEventChoice(id: UUID(),
                    label: "Welcome her warmly",
                    description: "Positive press brings donations.",
                    requiredSkill: .socialWork,
                    outcomes: [.fundingGained(400), .moraleGained(15)],
                    energyCost: 15),
                GameEventChoice(id: UUID(),
                    label: "Politely decline",
                    description: "Keep a low profile.",
                    requiredSkill: nil,
                    outcomes: [],
                    energyCost: 0)
            ],
            isResolved: false, dayTriggered: 0
        ),
        // Power outage
        GameEvent(
            id: UUID(),
            title: "Power Outage on Floor 3",
            description: "A tripped breaker has knocked out lights and heat on the entire floor.",
            icon: "bolt.slash.fill",
            category: .maintenance,
            choices: [
                GameEventChoice(id: UUID(),
                    label: "Reset the breaker",
                    description: "Dalia knows where it is. Quick fix.",
                    requiredSkill: .maintenance,
                    outcomes: [.moraleGained(5)],
                    energyCost: 10),
                GameEventChoice(id: UUID(),
                    label: "Move residents temporarily",
                    description: "Shuffle people to communal spaces until morning.",
                    requiredSkill: .socialWork,
                    outcomes: [.moraleLost(5)],
                    energyCost: 20)
            ],
            isResolved: false, dayTriggered: 0
        )
    ]
}
