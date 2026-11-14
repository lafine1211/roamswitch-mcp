// Mirrored from RoamSwitchTests/ — RoamSwitch 1.17.36 (build 215). Do not edit here; see SYNC.md.

import Foundation
@testable import roamswitch_mcp

/// A stand-in for the live Tailscale reading, so a test never depends on whether Tailscale runs on the Mac that
/// runs the tests.
struct StubOverlayExposureSource: OverlayExposureSource {
    var state: OverlayExposure.TailscaleState = .notInstalled
    var programs: Set<String>? = []
    func tailscale() -> OverlayExposure.TailscaleState { state }
    func programNames() -> Set<String>? { programs }
}
