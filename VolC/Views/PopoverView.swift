import AppKit
import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: VolumeMixerViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 9)

            masterVolume
                .padding(.horizontal, 10)
                .padding(.bottom, 10)

            appList
                .padding(.horizontal, 10)

            footer
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        .frame(width: 368)
        .frame(minHeight: 388)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color(nsColor: .windowBackgroundColor).opacity(0.34))
            }
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            VolCLogoView()
                .frame(width: 42, height: 42)
                .accessibilityLabel("VolC logo")

            VStack(alignment: .leading, spacing: 1) {
                Text("VolC")
                    .font(.system(size: 15, weight: .semibold))

                Text(activeSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Quit VolC")
        }
    }

    private var masterVolume: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)

            Text("Master")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 48, alignment: .leading)

            Slider(
                value: Binding(
                    get: { viewModel.masterVolume },
                    set: { viewModel.setMasterVolume($0) }
                ),
                in: 0...1
            )

            Text(percent(viewModel.masterVolume))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private var appList: some View {
        if viewModel.apps.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "waveform.slash")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(.secondary)

                Text("No active audio apps")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 190)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.38), lineWidth: 0.5)
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 5) {
                        ForEach(viewModel.apps) { app in
                            AppVolumeRowView(app: app, volume: viewModel.volumeBinding(for: app.id))
                        }
                    }
                }
                .frame(maxHeight: 250)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Toggle(
                isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { viewModel.setLaunchAtLogin($0) }
                ),
                label: {
                    Label("Launch at login", systemImage: "power")
                        .font(.system(size: 12, weight: .medium))
                }
            )
            .toggleStyle(.switch)

            Spacer()
        }
    }

    private var activeSummary: String {
        let count = viewModel.apps.count
        return count == 1 ? "1 active app" : "\(count) active apps"
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

private struct VolCLogoView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let lineWidth = side * 0.14

            ZStack {
                RoundedRectangle(cornerRadius: side * 0.2, style: .continuous)
                    .fill(backgroundStyle)

                RoundedRectangle(cornerRadius: side * 0.2, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 0.5)

                ZStack {
                    VolCVShape()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.27, green: 0.78, blue: 1.0),
                                    Color(red: 0.0, green: 0.46, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: blueGlow, radius: glowRadius, x: 0, y: 1)

                    VolCCShape()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.43, green: 0.63, blue: 1.0),
                                    Color(red: 0.55, green: 0.25, blue: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: purpleGlow, radius: glowRadius, x: 0, y: 1)
                }
                .padding(side * 0.08)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var backgroundStyle: some ShapeStyle {
        colorScheme == .dark
            ? LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.045, blue: 0.06),
                    Color(red: 0.08, green: 0.075, blue: 0.105)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            : LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 0.96, green: 0.965, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    private var blueGlow: Color {
        colorScheme == .dark ? Color.blue.opacity(0.55) : Color.black.opacity(0.16)
    }

    private var purpleGlow: Color {
        colorScheme == .dark ? Color.purple.opacity(0.5) : Color.black.opacity(0.12)
    }

    private var glowRadius: CGFloat {
        colorScheme == .dark ? 4 : 2
    }
}

private struct VolCVShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.30))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.43, y: rect.minY + rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.55, y: rect.minY + rect.height * 0.51))
        return path
    }
}

private struct VolCCShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.minX + rect.width * 0.68, y: rect.minY + rect.height * 0.52)
        let radius = rect.width * 0.24
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-35),
            endAngle: .degrees(38),
            clockwise: true
        )
        return path
    }
}
