// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.17.16 (build 195).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation

extension Process {
    /// `Process.waitUntilExit()` spins the calling thread's run loop. On the main thread that
    /// runs any pending main-queue block while a caller is still in the middle of its work.
    /// When that caller is a `static let shared` initialiser (AppState.init calls
    /// `which clamscan` this way), a pending block that touches the same `.shared` re-enters
    /// the `dispatch_once` on the same thread and the app traps at launch
    /// (EXC_BREAKPOINT in `_dispatch_once_wait`, seen 2026-10-24 on 1.17.5).
    /// On the main thread this polls instead, so nothing else runs until the process is gone.
    /// Other threads keep the plain call.
    func waitUntilExitWithoutRunLoop() {
        guard Thread.isMainThread else {
            waitUntilExit()
            return
        }
        while isRunning { Thread.sleep(forTimeInterval: 0.01) }
    }
}
