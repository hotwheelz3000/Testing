# Hotel Libre

**An iOS management game about the maids who won a luxury hotel — and opened it to everyone.**

---

## Premise

The staff of the Grand Aurelius Hotel won the building in a sweepstakes lottery. Instead of selling it or continuing to run it for profit, they voted unanimously to convert it into **free public housing**.

You manage Rosa, Lily, Carmen, Dalia, and Esther — five maids who know every room, every pipe, and every quirk of this building better than anyone. Now they run it on donations, community spirit, and sheer determination.

---

## Gameplay Loop

Each day you:

1. **Walk the floors** — tap rooms to check their cleanliness, condition, and residents
2. **Send maids** — assign maids to clean or repair rooms (each action costs energy and supplies)
3. **House residents** — select people from the waitlist and place them in available rooms
4. **Resolve events** — unexpected events arrive each day (burst pipes, inspections, donations, crises); each has multiple choices gated by maid skills
5. **Invest in upgrades** — spend funding to unlock new floors, add community amenities, and reduce daily upkeep
6. **Advance the day** — maids rest, rooms decay slightly, new residents arrive on the waitlist

### Win Condition
House 20+ residents and maintain morale at or above 70%.

### Lose Condition
Run out of both funding and morale (the team burns out and can't keep the doors open).

---

## The Staff

| Maid | Role | Skills |
|---|---|---|
| **Rosa Delgado** | Head Housekeeper | Administration, Cleaning |
| **Lily Tran** | Senior Maid | Social Work, Cleaning |
| **Carmen Reyes** | Senior Maid | Maintenance, Cleaning |
| **Dalia Osei** | Facilities Maid | Maintenance, Administration |
| **Esther Mwangi** | Kitchen & Housekeeping | Cooking, Social Work |

Each maid has an **energy pool** that depletes when they work and refills overnight. Some events require specific skills — only maids with matching skills can take those options.

---

## Hotel Layout

The Grand Aurelius has 6 floors:

| Floor | Theme | Rooms | Status |
|---|---|---|---|
| 1 | Family Floor | 4 rooms (incl. accessible) | Unlocked |
| 2 | Garden Floor | 6 rooms | Unlocked (one damaged) |
| 3 | Library Floor | 4 suites | 2 unlocked, 2 locked |
| 4 | Family Floor | 3 family suites | Locked |
| 5 | Wellness Floor | 4 rooms | Locked |
| PH | Rooftop Community | 2 penthouses | Locked |

---

## Upgrades

Spend funding and supplies to:
- Unlock new floors
- Build a **Community Laundry Room** (+5 happiness all residents)
- Install a **Community Notice Board** (+3 morale/day)
- Create a **Roof Garden** (passive supply regeneration)
- Add **Solar Panels** (reduced daily upkeep)

---

## Project Structure

```
Sources/HotelLibre/
├── HotelLibreApp.swift          # App entry point
├── Models/
│   ├── Maid.swift               # Maid characters & skills
│   ├── Resident.swift           # Resident profiles & needs
│   ├── Room.swift               # Room types, conditions, floor layout
│   ├── GameEvent.swift          # Event system with branching choices
│   └── GameState.swift          # Full game state & upgrades
├── ViewModels/
│   └── GameViewModel.swift      # All game logic, persistence, day cycle
└── Views/
    ├── MainMenuView.swift        # Title screen
    ├── GameView.swift            # Main game shell (tabs + HUD)
    ├── HUDView.swift             # Resource display
    ├── FloorView.swift           # Hotel floor grid
    ├── RoomDetailView.swift      # Room inspection & actions
    ├── MaidProfileView.swift     # Staff roster & maid picker
    ├── ResidentView.swift        # Housed residents & waitlist
    ├── EventView.swift           # Event overlay with choices
    ├── UpgradesView.swift        # Upgrade shop
    └── GameOverView.swift        # Victory & game over screens
```

---

## Setup (Xcode)

1. Open `HotelLibre/` in Xcode (requires Xcode 15+)
2. Set deployment target to iOS 17+
3. Select a simulator or device
4. Build & Run (`⌘R`)

Game state is persisted automatically via `UserDefaults`.

---

## Design Notes

- **No ads, no microtransactions** — fitting for a game about free housing
- **Residents are people**, not statistics: each has a name, story, needs, and a thank-you note that unlocks when they're thriving
- **Events respect skill gates** — you can't bluff your way through a burst pipe without someone who knows plumbing
- **The hotel decays** — ignore rooms and they'll need repair; the building reflects your attention
