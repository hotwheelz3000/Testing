import Foundation
import Combine

@MainActor
final class GameViewModel: ObservableObject {

    @Published var state: GameState
    @Published var activeEvent: GameEvent?
    @Published var toastMessage: String?
    @Published var selectedMaidID: UUID?
    @Published var selectedRoomID: UUID?
    @Published var showUpgrades: Bool = false
    @Published var showWaitlist: Bool = false

    private var toastTimer: Timer?
    private let saveKey = "hotelLibreSave"

    init() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let saved = try? JSONDecoder().decode(GameState.self, from: data) {
            state = saved
        } else {
            state = GameState.newGame()
        }
    }

    // MARK: – Day Advance

    func advanceDay() {
        guard state.phase == .playing else { return }
        state.day += 1

        applyDailyDecay()
        applyDailyUpkeep()
        applyResidentHappinessChanges()
        replenishMaidEnergy()
        maybeSpawnEvent()
        maybeAddWaitlistResident()
        checkVictoryOrDefeat()
        saveGame()
        showToast("Day \(state.day) begins.")
    }

    private func applyDailyDecay() {
        for i in state.rooms.indices {
            guard !state.rooms[i].isLocked else { continue }
            if state.rooms[i].cleanliness > 0 {
                let decay = state.rooms[i].isOccupied ? 8 : 3
                state.rooms[i].cleanliness = max(0, state.rooms[i].cleanliness - decay)
            }
            if state.rooms[i].cleanliness < 30 && state.rooms[i].condition == .good {
                state.rooms[i].condition = .needsCleaning
            }
        }
    }

    private func applyDailyUpkeep() {
        let upkeep = state.solarPanels ? max(50, state.dailyUpkeep - 50) : state.dailyUpkeep
        state.funding -= upkeep
        if state.funding < 0 {
            state.morale = max(0, state.morale - 10)
            state.funding = 0
            showToast("Out of funding! Morale is suffering.")
        }
        if state.noticeBoard {
            state.morale = min(100, state.morale + 3)
        }
        if state.roofGarden {
            state.supplies = min(200, state.supplies + 5)
        }
    }

    private func applyResidentHappinessChanges() {
        for i in state.residents.indices {
            guard let roomID = state.residents[i].roomID,
                  let room = state.rooms.first(where: { $0.id == roomID }) else { continue }

            let cleanBonus = room.cleanliness >= 70 ? 3 : (room.cleanliness >= 40 ? 0 : -3)
            let conditionBonus = room.condition == .needsRepair ? -5 : 0
            state.residents[i].happiness = max(0, min(100, state.residents[i].happiness + cleanBonus + conditionBonus + 1))
            state.residents[i].daysHoused += 1

            if state.residents[i].isThriving && state.residents[i].status != .thriving {
                state.residents[i].status = .thriving
                state.residents[i].thankYouNote = generateThankYouNote(for: state.residents[i])
                state.morale = min(100, state.morale + 5)
                showToast("\(state.residents[i].name) is now thriving!")
                state.totalHousedEver += 0 // already counted at intake
            }

            if state.residents[i].happiness < 20 {
                state.residents[i].status = .struggling
            }
        }
    }

    private func replenishMaidEnergy() {
        for i in state.maids.indices {
            let rest = state.maids[i].isWorking ? 15 : 30
            state.maids[i].energy = min(state.maids[i].maxEnergy, state.maids[i].energy + rest)
            state.maids[i].isWorking = false
            state.maids[i].assignedRoomID = nil
        }
    }

    private func generateThankYouNote(for resident: Resident) -> String {
        let notes = [
            "Thank you for giving me a door I can call mine.",
            "I didn't think anyone would open a door for me. You did.",
            "Every morning I wake up here, I remember what kindness looks like.",
            "My kids sleep soundly now. That means everything.",
            "You didn't just give me a room — you gave me back my dignity.",
        ]
        return notes.randomElement()!
    }

    // MARK: – Events

    private func maybeSpawnEvent() {
        guard state.activeEvents.isEmpty else { return }
        let chance = Double.random(in: 0...1)
        if chance < 0.65 {
            var pool = GameEvent.eventPool.filter { template in
                !state.resolvedEventIDs.contains(template.id)
            }
            if pool.isEmpty {
                state.resolvedEventIDs.removeAll()
                pool = GameEvent.eventPool
            }
            if var event = pool.randomElement() {
                event = GameEvent(
                    id: UUID(), title: event.title, description: event.description,
                    icon: event.icon, category: event.category,
                    choices: event.choices, isResolved: false, dayTriggered: state.day
                )
                state.activeEvents.append(event)
                activeEvent = event
            }
        }
    }

    private func maybeAddWaitlistResident() {
        if state.waitlist.count < 5 && Double.random(in: 0...1) < 0.5 {
            state.waitlist.append(Resident.randomWaitlistResident())
        }
    }

    func resolveEvent(_ event: GameEvent, choiceIndex: Int) {
        guard choiceIndex < event.choices.count else { return }
        let choice = event.choices[choiceIndex]

        // Check if a maid with required skill has enough energy
        if let required = choice.requiredSkill {
            guard let maidIdx = state.maids.firstIndex(where: {
                ($0.primarySkill == required || $0.secondarySkill == required)
                && $0.energy >= choice.energyCost
            }) else {
                showToast("No maid with enough energy for \(required.rawValue)!")
                return
            }
            state.maids[maidIdx].energy -= choice.energyCost
            state.maids[maidIdx].isWorking = true
        } else if choice.energyCost > 0 {
            // Any available maid
            if let maidIdx = state.maids.firstIndex(where: { $0.energy >= choice.energyCost }) {
                state.maids[maidIdx].energy -= choice.energyCost
                state.maids[maidIdx].isWorking = true
            }
        }

        applyOutcomes(choice.outcomes, event: event)

        if let idx = state.activeEvents.firstIndex(where: { $0.id == event.id }) {
            state.activeEvents[idx].isResolved = true
            state.resolvedEventIDs.append(event.id)
            state.activeEvents.remove(at: idx)
        }
        state.totalResolutionsThisRun += 1
        activeEvent = state.activeEvents.first
        saveGame()
    }

    private func applyOutcomes(_ outcomes: [EventOutcome], event: GameEvent) {
        for outcome in outcomes {
            switch outcome {
            case .suppliesGained(let n):
                state.supplies = min(200, state.supplies + n)
                showToast("+\(n) supplies!")
            case .suppliesLost(let n):
                state.supplies = max(0, state.supplies - n)
            case .moraleGained(let n):
                state.morale = min(100, state.morale + n)
                showToast("Morale +\(n)!")
            case .moraleLost(let n):
                state.morale = max(0, state.morale - n)
            case .fundingGained(let n):
                state.funding += n
                showToast("+$\(n) funding!")
            case .fundingLost(let n):
                state.funding = max(0, state.funding - n)
            case .roomDamaged(let id):
                if let idx = state.rooms.firstIndex(where: { $0.id == id }) {
                    state.rooms[idx].condition = .needsRepair
                    state.rooms[idx].pendingRepair = true
                }
            case .roomRepaired(let id):
                if let idx = state.rooms.firstIndex(where: { $0.id == id }) {
                    state.rooms[idx].condition = .good
                    state.rooms[idx].pendingRepair = false
                }
            case .residentJoined:
                break
            case .residentLeft(let id):
                removeResident(id: id)
            case .unlockFloor(let floor):
                unlockFloor(floor)
            }
        }
    }

    // MARK: – Room Actions

    func cleanRoom(roomID: UUID, maidID: UUID) {
        guard let roomIdx = state.rooms.firstIndex(where: { $0.id == roomID }),
              let maidIdx = state.maids.firstIndex(where: { $0.id == maidID }) else { return }

        let maid = state.maids[maidIdx]
        guard maid.energy >= 20 else {
            showToast("\(maid.name) is too tired to clean!")
            return
        }
        guard state.supplies >= 5 else {
            showToast("Not enough supplies to clean!")
            return
        }

        state.maids[maidIdx].energy -= 20
        state.maids[maidIdx].isWorking = true
        state.maids[maidIdx].assignedRoomID = roomID
        state.supplies -= 5

        let bonus = maid.happinessBonus
        state.rooms[roomIdx].cleanliness = min(100, state.rooms[roomIdx].cleanliness + 40 + bonus)
        state.rooms[roomIdx].lastCleaned = Date()

        if state.rooms[roomIdx].condition == .needsCleaning {
            state.rooms[roomIdx].condition = .good
        }
        if let resID = state.rooms[roomIdx].residentID,
           let resIdx = state.residents.firstIndex(where: { $0.id == resID }) {
            state.residents[resIdx].happiness = min(100, state.residents[resIdx].happiness + 10 + bonus)
        }
        showToast("\(maid.name) cleaned room \(state.rooms[roomIdx].number)!")
        saveGame()
    }

    func repairRoom(roomID: UUID, maidID: UUID) {
        guard let roomIdx = state.rooms.firstIndex(where: { $0.id == roomID }),
              let maidIdx = state.maids.firstIndex(where: { $0.id == maidID }) else { return }

        let maid = state.maids[maidIdx]
        let isHandy = maid.primarySkill == .maintenance || maid.secondarySkill == .maintenance
        let energyCost = isHandy ? 25 : 40
        let supplyCost = isHandy ? 10 : 20

        guard maid.energy >= energyCost else {
            showToast("\(maid.name) doesn't have enough energy!")
            return
        }
        guard state.supplies >= supplyCost else {
            showToast("Need \(supplyCost) supplies to repair!")
            return
        }

        state.maids[maidIdx].energy -= energyCost
        state.maids[maidIdx].isWorking = true
        state.supplies -= supplyCost
        state.rooms[roomIdx].condition = .good
        state.rooms[roomIdx].pendingRepair = false
        state.rooms[roomIdx].cleanliness = min(100, state.rooms[roomIdx].cleanliness + 20)

        showToast("\(maid.name) repaired room \(state.rooms[roomIdx].number)!")
        saveGame()
    }

    // MARK: – Resident Intake

    func houseResident(_ resident: Resident, in room: Room) {
        guard room.isAvailable else {
            showToast("Room \(room.number) is not available.")
            return
        }
        guard let roomIdx = state.rooms.firstIndex(where: { $0.id == room.id }),
              let waitIdx = state.waitlist.firstIndex(where: { $0.id == resident.id }) else { return }

        var housed = resident
        housed.status = .housed
        housed.roomID = room.id
        housed.happiness = 60
        state.rooms[roomIdx].residentID = housed.id
        state.residents.append(housed)
        state.waitlist.remove(at: waitIdx)
        state.totalHousedEver += 1
        state.morale = min(100, state.morale + 3)
        showToast("\(housed.name) is now in room \(room.number)!")
        saveGame()
    }

    func removeResident(id: UUID) {
        if let resIdx = state.residents.firstIndex(where: { $0.id == id }) {
            let res = state.residents[resIdx]
            if let roomID = res.roomID,
               let roomIdx = state.rooms.firstIndex(where: { $0.id == roomID }) {
                state.rooms[roomIdx].residentID = nil
            }
            state.residents.remove(at: resIdx)
        }
    }

    // MARK: – Upgrades

    func purchaseUpgrade(_ upgrade: Upgrade) {
        guard state.funding >= upgrade.fundingCost,
              state.supplies >= upgrade.suppliesCost else {
            showToast("Not enough resources for \(upgrade.name).")
            return
        }
        state.funding -= upgrade.fundingCost
        state.supplies -= upgrade.suppliesCost

        if let floor = upgrade.unlocksFloor {
            unlockFloor(floor)
        }

        switch upgrade.name {
        case "Community Notice Board": state.noticeBoard = true
        case "Roof Garden": state.roofGarden = true
        case "Solar Panels": state.solarPanels = true
        default: break
        }

        if let idx = state.availableUpgrades.firstIndex(where: { $0.id == upgrade.id }) {
            state.availableUpgrades[idx].isUnlocked = true
            state.unlockedUpgrades.append(upgrade.id)
        }
        showToast("\(upgrade.name) unlocked!")
        saveGame()
    }

    private func unlockFloor(_ floor: Int) {
        for i in state.rooms.indices {
            if state.rooms[i].floor == floor {
                state.rooms[i].isLocked = false
            }
        }
    }

    // MARK: – Persistence & Utility

    func checkVictoryOrDefeat() {
        if state.isVictoryReached {
            state.phase = .victory
        } else if state.morale <= 0 && state.funding <= 0 {
            state.phase = .gameOver
        }
    }

    func saveGame() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    func resetGame() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        state = GameState.newGame()
        activeEvent = nil
        showToast("New game started!")
    }

    func showToast(_ message: String) {
        toastMessage = message
        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.toastMessage = nil
            }
        }
    }

    // MARK: – Convenience

    var rooms: [Room] { state.rooms }
    var maids: [Maid] { state.maids }
    var residents: [Resident] { state.residents }
    var waitlist: [Resident] { state.waitlist }

    func maid(for id: UUID) -> Maid? { state.maids.first { $0.id == id } }
    func room(for id: UUID) -> Room? { state.rooms.first { $0.id == id } }
    func resident(for id: UUID) -> Resident? { state.residents.first { $0.id == id } }

    func roomsByFloor(_ floor: Int) -> [Room] {
        state.rooms.filter { $0.floor == floor }.sorted { $0.number < $1.number }
    }

    var floors: [Int] { Array(Set(state.rooms.map { $0.floor })).sorted() }
}
