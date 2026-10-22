import Foundation

/// A preset brew length. `minutes == nil` means "until stopped".
struct Shot: Identifiable, Hashable {
    let id: String
    let name: String
    let minutes: Int?

    var durationLabel: String {
        guard let minutes else { return "∞" }
        return minutes < 60 ? "\(minutes) min" : "\(minutes / 60) h"
    }

    static let menu: [Shot] = [
        Shot(id: "ristretto", name: "Ristretto", minutes: 15),
        Shot(id: "espresso", name: "Espresso", minutes: 30),
        Shot(id: "doppio", name: "Doppio", minutes: 60),
        Shot(id: "lungo", name: "Lungo", minutes: 120),
        Shot(id: "americano", name: "Americano", minutes: 240),
        Shot(id: "bottomless", name: "Bottomless", minutes: nil),
    ]
}

/// Owns the /usr/bin/caffeinate child process.
@MainActor
final class Brewer: ObservableObject {
    @Published private(set) var shot: Shot?
    @Published private(set) var startedAt: Date?
    @Published var keepDisplayOn: Bool {
        didSet {
            UserDefaults.standard.set(keepDisplayOn, forKey: "keepDisplayOn")
            // Re-pull the current shot so the new flag takes effect, keeping the remaining time.
            guard let shot else { return }
            let remaining = remainingSeconds()
            if remaining == 0 { return stopShot() }
            launch(shot: shot, seconds: remaining, startedAt: startedAt)
        }
    }

    private var process: Process?

    init() {
        keepDisplayOn = UserDefaults.standard.object(forKey: "keepDisplayOn") as? Bool ?? true
    }

    var isBrewing: Bool { shot != nil }

    var endsAt: Date? {
        guard let shot, let minutes = shot.minutes, let startedAt else { return nil }
        return startedAt.addingTimeInterval(TimeInterval(minutes * 60))
    }

    func remainingSeconds(now: Date = .now) -> Int? {
        guard let endsAt else { return nil }
        return max(0, Int(endsAt.timeIntervalSince(now).rounded(.up)))
    }

    func pull(_ shot: Shot) {
        launch(shot: shot, seconds: shot.minutes.map { $0 * 60 }, startedAt: .now)
    }

    func stopShot() {
        terminate()
        shot = nil
        startedAt = nil
    }

    private func launch(shot: Shot, seconds: Int?, startedAt: Date?) {
        terminate()

        var args = ["-i", "-m"]
        if keepDisplayOn { args.append("-d") }
        if let seconds { args += ["-t", String(seconds)] }
        // caffeinate exits by itself if this app dies, so no orphaned assertion is left behind.
        args += ["-w", String(ProcessInfo.processInfo.processIdentifier)]

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        p.arguments = args
        p.terminationHandler = { [weak self] finished in
            Task { @MainActor in
                guard let self, self.process === finished else { return }
                self.process = nil
                self.shot = nil
                self.startedAt = nil
            }
        }

        do {
            try p.run()
            process = p
            self.shot = shot
            self.startedAt = startedAt
        } catch {
            NSLog("Crema: failed to start caffeinate: \(error)")
            self.shot = nil
            self.startedAt = nil
        }
    }

    private func terminate() {
        guard let p = process else { return }
        process = nil
        if p.isRunning { p.terminate() }
    }
}
