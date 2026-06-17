import Foundation

enum ResidentNeed: String, CaseIterable, Codable {
    case quiet = "Quiet Space"
    case community = "Community"
    case accessibility = "Accessibility"
    case petFriendly = "Pet-Friendly"
    case childcare = "Childcare Access"
    case medical = "Medical Proximity"
}

enum ResidentStatus: String, Codable {
    case waitlisted = "Waitlisted"
    case housed = "Housed"
    case thriving = "Thriving"
    case struggling = "Struggling"
    case departed = "Departed"
}

struct Resident: Identifiable, Codable {
    let id: UUID
    var name: String
    var age: Int
    var story: String
    var portrait: String            // SF Symbol name
    var needs: [ResidentNeed]
    var happiness: Int              // 0–100
    var daysHoused: Int
    var status: ResidentStatus
    var roomID: UUID?
    var skillContribution: String   // what they contribute to the community
    var thankYouNote: String?       // unlocked when thriving

    var happinessPercent: Double { Double(happiness) / 100.0 }
    var isThriving: Bool { happiness >= 80 && daysHoused >= 7 }

    static func randomWaitlistResident() -> Resident {
        let pool: [(name: String, age: Int, story: String, portrait: String,
                    needs: [ResidentNeed], skill: String)] = [
            ("Marcus Webb", 34,
             "Lost his apartment after a medical crisis. Volunteers at the library on weekends.",
             "person.fill", [.medical, .quiet], "Fixes donated computers"),
            ("Priya Sharma", 28,
             "Graduate student priced out of campus housing. Studying urban planning.",
             "graduationcap.fill", [.quiet, .community], "Tutors residents' kids"),
            ("The Kowalski Family", 42,
             "Parents and two kids displaced after factory closure. Looking for stability.",
             "person.3.fill", [.childcare, .petFriendly], "Cooking for community dinners"),
            ("Dot Hargrove", 71,
             "Retired nurse. Her pension barely covers groceries.",
             "figure.walk", [.medical, .accessibility], "First-aid knowledge for all"),
            ("Andre & Biscuit", 29,
             "Andre and his rescue dog need somewhere safe. Will help with deliveries.",
             "dog.fill", [.petFriendly, .community], "Handles package deliveries"),
            ("Yuki Nakamura", 19,
             "Aged out of foster care last month. Nervous but hopeful.",
             "figure.stand", [.community, .childcare], "Helps with social media outreach"),
            ("Reverend Gaines", 58,
             "His congregation's building burned down. He still holds Sunday services in the lobby.",
             "building.columns.fill", [.community, .quiet], "Leads community mediation"),
            ("Elena Vasquez", 45,
             "Domestic violence survivor starting over with her daughter.",
             "person.2.fill", [.quiet, .childcare], "Organizes the community garden"),
        ]
        let pick = pool.randomElement()!
        return Resident(
            id: UUID(),
            name: pick.name,
            age: pick.age,
            story: pick.story,
            portrait: pick.portrait,
            needs: pick.needs,
            happiness: 50,
            daysHoused: 0,
            status: .waitlisted,
            roomID: nil,
            skillContribution: pick.skill,
            thankYouNote: nil
        )
    }
}
