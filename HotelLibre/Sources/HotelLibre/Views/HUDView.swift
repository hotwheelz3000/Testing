import SwiftUI

struct HUDView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        HStack(spacing: 0) {
            HUDStat(icon: "dollarsign.circle.fill", value: "$\(vm.state.funding)",
                    label: "Funding", color: .green)
            Divider().frame(height: 32)
            HUDStat(icon: "shippingbox.fill", value: "\(vm.state.supplies)",
                    label: "Supplies", color: .orange)
            Divider().frame(height: 32)
            HUDStat(icon: "heart.fill", value: "\(vm.state.morale)%",
                    label: "Morale", color: .pink)
            Divider().frame(height: 32)
            HUDStat(icon: "calendar", value: "Day \(vm.state.day)",
                    label: "Current", color: .blue)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

struct HUDStat: View {
    var icon: String
    var value: String
    var label: String
    var color: Color

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MoraleBarView: View {
    var percent: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                RoundedRectangle(cornerRadius: 4)
                    .fill(percent > 0.6 ? Color.green : percent > 0.3 ? Color.orange : Color.red)
                    .frame(width: geo.size.width * percent)
            }
        }
        .frame(height: 6)
    }
}

struct ToastView: View {
    var message: String
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.78))
            .clipShape(Capsule())
            .shadow(radius: 6)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
