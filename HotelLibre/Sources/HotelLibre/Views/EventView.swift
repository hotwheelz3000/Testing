import SwiftUI

struct EventView: View {
    var event: GameEvent
    @EnvironmentObject var vm: GameViewModel

    var categoryColor: Color {
        switch event.category {
        case .maintenance: return .orange
        case .community: return .green
        case .external: return .blue
        case .donation: return Color("HotelTeal")
        case .crisis: return .red
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    // Icon & category
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(categoryColor.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: event.icon)
                                .font(.system(size: 32))
                                .foregroundStyle(categoryColor)
                        }

                        VStack(spacing: 6) {
                            Text(event.category.rawValue.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(categoryColor)
                                .tracking(2)
                            Text(event.title)
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .multilineTextAlignment(.center)
                        }
                    }

                    Text(event.description)
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)

                    Divider()

                    // Choices
                    VStack(spacing: 12) {
                        Text("How do you respond?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)

                        ForEach(Array(event.choices.enumerated()), id: \.element.id) { index, choice in
                            EventChoiceButton(
                                choice: choice,
                                isAvailable: isChoiceAvailable(choice)
                            ) {
                                vm.resolveEvent(event, choiceIndex: index)
                            }
                        }
                    }
                }
                .padding(28)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    func isChoiceAvailable(_ choice: GameEventChoice) -> Bool {
        guard let required = choice.requiredSkill else { return true }
        return vm.maids.contains {
            ($0.primarySkill == required || $0.secondarySkill == required)
            && $0.energy >= choice.energyCost
        }
    }
}

struct EventChoiceButton: View {
    var choice: GameEventChoice
    var isAvailable: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(choice.label)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isAvailable ? .primary : .secondary)
                    Spacer()
                    if choice.energyCost > 0 {
                        Label("\(choice.energyCost) energy", systemImage: "bolt.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isAvailable ? .orange : .secondary)
                    }
                }
                Text(choice.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)

                if let skill = choice.requiredSkill {
                    Label("Needs \(skill.rawValue)", systemImage: "star.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isAvailable ? .blue : .red)
                }
            }
            .padding(14)
            .background(isAvailable ? Color(.secondarySystemBackground) : Color.gray.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isAvailable ? Color.clear : Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable && choice.requiredSkill != nil)
    }
}
