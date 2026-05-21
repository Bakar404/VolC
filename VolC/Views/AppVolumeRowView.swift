import SwiftUI

struct AppVolumeRowView: View {
    let app: AppVolume
    let volume: Binding<Double>
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            icon

            VStack(alignment: .leading, spacing: 2) {
                Text(app.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                if let status = app.status {
                    HStack(spacing: 4) {
                        Image(systemName: app.supportsVolumeControl ? "checkmark.circle.fill" : "lock.fill")
                            .font(.system(size: 8, weight: .semibold))

                        Text(status)
                            .lineLimit(1)
                    }
                    .font(.caption2)
                    .foregroundStyle(app.supportsVolumeControl ? .secondary : .tertiary)
                }
            }
            .frame(width: 92, alignment: .leading)

            Slider(value: volume, in: 0...1)
                .disabled(!app.supportsVolumeControl)
                .opacity(app.supportsVolumeControl ? 1 : 0.45)

            Text(percent)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(rowFill)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(isHovering ? 0.52 : 0.3), lineWidth: 0.5)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onHover { isHovering = $0 }
    }

    @ViewBuilder
    private var icon: some View {
        if let appIcon = app.icon {
            Image(nsImage: appIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
        }
    }

    private var percent: String {
        "\(Int((app.volume * 100).rounded()))%"
    }

    private var rowFill: Color {
        if isHovering {
            return Color(nsColor: .controlAccentColor).opacity(0.12)
        }

        return Color(nsColor: .controlBackgroundColor).opacity(0.62)
    }
}
