import SwiftUI

@main
struct CremaApp: App {
    @StateObject private var brewer = Brewer()

    var body: some Scene {
        MenuBarExtra {
            BrewPanel()
                .environmentObject(brewer)
        } label: {
            Image(nsImage: PortafilterIcon.image(brewing: brewer.isBrewing))
                .accessibilityLabel(brewer.isBrewing ? "Crema: brewing" : "Crema: idle")
        }
        .menuBarExtraStyle(.window)
    }
}

/// Fill for solid surfaces with white text on top.
private let espresso = Color(red: 0x2A / 255, green: 0x1A / 255, blue: 0x10 / 255)
/// Accent for icons, text and controls; lighter in dark mode so it stays readable.
private let coffee = Color(nsColor: NSColor(name: nil) { appearance in
    appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        ? NSColor(srgbRed: 0.78, green: 0.56, blue: 0.38, alpha: 1)
        : NSColor(srgbRed: 0x2A / 255, green: 0x1A / 255, blue: 0x10 / 255, alpha: 1)
})

struct BrewPanel: View {
    @EnvironmentObject private var brewer: Brewer

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            statusCard
            if brewer.isBrewing {
                Button(action: brewer.stopShot) {
                    Label("Stop shot", systemImage: "stop.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(.white)
                        .background(espresso, in: RoundedRectangle(cornerRadius: 8))
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(".", modifiers: .command)
                .help("Stop keeping your Mac awake (⌘.)")
            }
            shotGrid
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Cup warmer")
                    Text("Keep the display on too")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("Cup warmer", isOn: $brewer.keepDisplayOn)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .tint(coffee)
            }

            Divider()

            HStack {
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .keyboardShortcut("q", modifiers: .command)
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private var statusCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 12) {
                Image(nsImage: PortafilterIcon.image(brewing: brewer.isBrewing, size: 30))
                    .renderingMode(.template)
                    .foregroundStyle(brewer.isBrewing ? coffee : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    if let shot = brewer.shot {
                        Text("Extracting · \(shot.name)")
                            .font(.headline)
                            .foregroundStyle(coffee)
                        if let remaining = brewer.remainingSeconds(now: context.date),
                           let minutes = shot.minutes {
                            Text("\(format(remaining)) left")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.secondary)
                            ProgressView(value: Double(minutes * 60 - remaining), total: Double(minutes * 60))
                                .tint(coffee)
                        } else {
                            Text("Runs until you stop the shot")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Group head is cold")
                            .font(.headline)
                        Text("Your Mac may sleep as usual")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(brewer.isBrewing ? AnyShapeStyle(coffee.opacity(0.14)) : AnyShapeStyle(.quaternary.opacity(0.5)),
                        in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var shotGrid: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PULL A SHOT")
                .font(.caption2.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(Shot.menu) { shot in
                    ShotButton(shot: shot, isActive: brewer.shot == shot) {
                        brewer.pull(shot)
                    }
                }
            }
        }
    }

    private func format(_ seconds: Int) -> String {
        let h = seconds / 3600, m = seconds / 60 % 60, s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
}

private struct ShotButton: View {
    let shot: Shot
    let isActive: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(shot.name)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(shot.durationLabel)
                    .font(.system(size: 10))
                    .foregroundStyle(isActive ? .white.opacity(0.85) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .foregroundStyle(isActive ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? AnyShapeStyle(espresso) : AnyShapeStyle(.quaternary.opacity(hovering ? 1 : 0.5)))
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(shot.minutes == nil ? "Stay awake until stopped" : "Stay awake for \(shot.durationLabel)")
    }
}
