// Mirrored from RoamSwitchTests/ — RoamSwitch 2.0.2 (build 218). Do not edit here; see SYNC.md.

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
