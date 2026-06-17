import Foundation

enum MaidSkill: String, CaseIterable, Codable {
    case cleaning = "Cleaning"
    case maintenance = "Maintenance"
    case cooking = "Cooking"
    case socialWork = "Social Work"
    case admin = "Administration"
}

struct Maid: Identifiable, Codable {
    let id: UUID
    var name: String
    var title: String
    var bio: String
    var portrait: String            // SF Symbol name
    var primarySkill: MaidSkill
    var secondarySkill: MaidSkill
    var energy: Int                 // 0–100
    var maxEnergy: Int
    var isWorking: Bool
    var assignedRoomID: UUID?
    var happinessBonus: Int         // bonus added to rooms she tends

    var energyPercent: Double { Double(energy) / Double(maxEnergy) }

    static let roster: [Maid] = [
        Maid(
            id: UUID(),
            name: "Rosa Delgado",
            title: "Head Housekeeper",
            bio: "20-year veteran who kept this hotel spotless. Now she keeps it welcoming.",
            portrait: "person.fill.checkmark",
            primarySkill: .admin,
            secondarySkill: .cleaning,
            energy: 100, maxEnergy: 100,
            isWorking: false, assignedRoomID: nil,
            happinessBonus: 3
        ),
        Maid(
            id: UUID(),
            name: "Lily Tran",
            title: "Senior Maid",
            bio: "Youngest of the crew. Energetic, speaks three languages, great with new residents.",
            portrait: "person.fill.badge.plus",
            primarySkill: .socialWork,
            secondarySkill: .cleaning,
            energy: 100, maxEnergy: 120,
            isWorking: false, assignedRoomID: nil,
            happinessBonus: 5
        ),
        Maid(
            id: UUID(),
            name: "Carmen Reyes",
            title: "Senior Maid",
            bio: "Knows every pipe and secret corridor. Fifteen years on the job.",
            portrait: "wrench.and.screwdriver.fill",
            primarySkill: .maintenance,
            secondarySkill: .cleaning,
            energy: 100, maxEnergy: 100,
            isWorking: false, assignedRoomID: nil,
            happinessBonus: 2
        ),
        Maid(
            id: UUID(),
            name: "Dalia Osei",
            title: "Facilities Maid",
            bio: "Can fix anything with a mop handle and determination.",
            portrait: "hammer.fill",
            primarySkill: .maintenance,
            secondarySkill: .admin,
            energy: 100, maxEnergy: 110,
            isWorking: false, assignedRoomID: nil,
            happinessBonus: 1
        ),
        Maid(
            id: UUID(),
            name: "Esther Mwangi",
            title: "Kitchen & Housekeeping",
            bio: "Runs the communal kitchen with joy. Her stew is legendary on every floor.",
            portrait: "fork.knife",
            primarySkill: .cooking,
            secondarySkill: .socialWork,
            energy: 100, maxEnergy: 100,
            isWorking: false, assignedRoomID: nil,
            happinessBonus: 4
        )
    ]
}
