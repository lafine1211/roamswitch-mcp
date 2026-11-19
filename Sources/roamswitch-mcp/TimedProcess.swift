// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 2.2.0 (build 224).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import Darwin

/// Running a program, reading what it prints, with a time limit and a limit on what is kept.
///
/// Before this, most of the 79 `Process()` calls read with `readDataToEndOfFile()` and then waited with
/// `waitUntilExit()` (on the main thread `waitUntilExitWithoutRunLoop()`, a 10 ms poll): a `lsof`, a `brew`, a `docker`
/// that does not answer held the caller for as long as it ran, and a `Pipe()` given to stderr and never read could fill
/// and stop the program (see the Mac cross-check, section 7).
///
/// Here the program, and everything it started, is ended when time is up (`ChildProcessTree`: SIGTERM, a short grace,
/// SIGKILL, grandchildren included). stdout and stderr are read at the same time. What is kept of stdout is limited
/// (`outputLimit`); a program that prints more is ended too. The caller is blocked on a semaphore, not a poll, for at
/// most `timeout` plus the grace.
enum TimedProcess {
    struct Result: Equatable {
        /// The exit status; -1 when the program was ended by a signal, including the end made here.
        var status: Int32
        var stdout: Data
        var stderr: Data
        /// Time ran out and the program was ended.
        var timedOut: Bool
        /// stdout went past `outputLimit`; the program was ended and `stdout` holds the first `outputLimit` bytes.
        var truncated: Bool

        var stdoutText: String { String(decoding: stdout, as: UTF8.self) }
        var stderrText: String { String(decoding: stderr, as: UTF8.self) }
        /// It ran to its end by itself and exited with 0.
        var succeeded: Bool { status == 0 && !timedOut && !truncated }
    }

    /// What is kept of stderr by default (it is read to its end either way, so the program never blocks on it).
    static let stderrKeep = 64 * 1024

    /// nil when the program could not be started.
    ///
    /// - `input`: written to the program's stdin from another thread, then stdin is closed (a program that does not read
    ///   it, or is ended, never blocks the caller or raises SIGPIPE here). Without it stdin is `/dev/null`.
    /// - `mergeStderr`: stderr goes into the same pipe as stdout, in the order the program wrote them (what a caller that
    ///   used one `Pipe()` for both got before); `stderr` in the result is then empty.
    static func run(_ path: String, _ arguments: [String], environment: [String: String]? = nil,
                    input: Data? = nil, mergeStderr: Bool = false,
                    timeout: TimeInterval, outputLimit: Int = 8 << 20, stderrLimit: Int = TimedProcess.stderrKeep,
                    grace: TimeInterval = 1.0) -> Result? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = arguments
        if let environment { p.environment = environment }
        let inPipe: Pipe? = input == nil ? nil : Pipe()
        if let inPipe { p.standardInput = inPipe } else { p.standardInput = FileHandle.nullDevice }
        let outPipe = Pipe(), errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = mergeStderr ? outPipe : errPipe

        let capture = Capture(outputLimit: outputLimit, stderrLimit: stderrLimit)
        let finished = DispatchSemaphore(value: 0)     // the program ended, or printed too much
        let outEOF = DispatchSemaphore(value: 0)
        let errEOF = DispatchSemaphore(value: 0)
        outPipe.fileHandleForReading.readabilityHandler = { h in
            let chunk = h.availableData
            guard !chunk.isEmpty else { h.readabilityHandler = nil; outEOF.signal(); return }
            if capture.appendOut(chunk) { finished.signal() }
        }
        if mergeStderr {
            errEOF.signal()
        } else {
            errPipe.fileHandleForReading.readabilityHandler = { h in
                let chunk = h.availableData
                guard !chunk.isEmpty else { h.readabilityHandler = nil; errEOF.signal(); return }
                capture.appendErr(chunk)
            }
        }
        p.terminationHandler = { _ in finished.signal() }

        do {
            try p.run()
        } catch {
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
            closeQuietly(outPipe); closeQuietly(errPipe)
            if let inPipe { closeQuietly(inPipe) }
            return nil
        }
        if let inPipe, let input { feed(input, to: inPipe) }
        let root = ChildProcessTree.entry(of: p.processIdentifier)?.identity
        var timedOut = false

        if finished.wait(timeout: .now() + timeout) == .timedOut { timedOut = true }
        if timedOut || capture.isTruncated {
            // Ended with everything it started; the termination handler then signals `finished` once more.
            if let root { _ = ChildProcessTree.stop(root, grace: grace, killWait: 1) } else { p.terminate() }
            _ = finished.wait(timeout: .now() + 2)
        }
        // The program is gone. What it printed is in the pipe; a grandchild that still holds the pipe open would keep
        // it from ever reaching its end, so the wait is short.
        _ = outEOF.wait(timeout: .now() + 0.5)
        _ = errEOF.wait(timeout: .now() + 0.5)
        outPipe.fileHandleForReading.readabilityHandler = nil
        errPipe.fileHandleForReading.readabilityHandler = nil
        closeQuietly(outPipe); closeQuietly(errPipe)

        let snapshot = capture.snapshot()
        let status: Int32 = (p.isRunning || timedOut || snapshot.truncated || p.terminationReason == .uncaughtSignal) ? -1 : p.terminationStatus
        return Result(status: status, stdout: snapshot.out, stderr: snapshot.err, timedOut: timedOut, truncated: snapshot.truncated)
    }

    /// Writes `data` to the program's stdin on its own thread and closes it. The read end held here is closed first, so
    /// that the write fails (EPIPE, with SIGPIPE turned off for this descriptor) when the program ends without reading.
    private static func feed(_ data: Data, to pipe: Pipe) {
        try? pipe.fileHandleForReading.close()
        let writer = pipe.fileHandleForWriting
        _ = fcntl(writer.fileDescriptor, F_SETNOSIGPIPE, 1)
        DispatchQueue.global(qos: .utility).async {
            let fd = writer.fileDescriptor
            data.withUnsafeBytes { raw in
                var offset = 0
                while offset < raw.count {
                    let n = write(fd, raw.baseAddress!.advanced(by: offset), raw.count - offset)
                    if n < 0 { if errno == EINTR { continue }; break }
                    offset += n
                }
            }
            try? writer.close()
        }
    }

    private static func closeQuietly(_ pipe: Pipe) {
        try? pipe.fileHandleForReading.close()
        try? pipe.fileHandleForWriting.close()
    }

    private final class Capture {
        private let lock = NSLock()
        private let limit: Int
        private var out = Data()
        private var err = Data()
        private(set) var truncated = false

        private let errLimit: Int

        init(outputLimit: Int, stderrLimit: Int) {
            limit = max(outputLimit, 0)
            errLimit = max(stderrLimit, 0)
        }

        /// True when this chunk took stdout past the limit.
        func appendOut(_ chunk: Data) -> Bool {
            lock.lock(); defer { lock.unlock() }
            guard !truncated else { return false }
            let room = limit - out.count
            if chunk.count > room {
                out.append(chunk.prefix(max(room, 0)))
                truncated = true
                return true
            }
            out.append(chunk)
            return false
        }

        func appendErr(_ chunk: Data) {
            lock.lock(); defer { lock.unlock() }
            if err.count < errLimit { err.append(chunk.prefix(errLimit - err.count)) }
        }

        func snapshot() -> (out: Data, err: Data, truncated: Bool) {
            lock.lock(); defer { lock.unlock() }
            return (out, err, truncated)
        }

        var isTruncated: Bool { lock.lock(); defer { lock.unlock() }; return truncated }
    }
}

extension TimedProcess {
    /// What the helper's command runner and others that used one `Pipe()` for stdout and stderr gave: one text, the exit status.
    /// - `status` is -1 when the program could not be started, was ended by a signal, ran past `timeout` and was ended, or
    ///   printed more than `outputLimit` and was ended. A time-out or a failed start is never a success.
    /// - `text` is what the program printed (stdout and stderr together, in order); a time-out or a failed start adds one line at
    ///   the end that says so, so a caller that shows the text shows why.
    struct MergedResult: Equatable {
        var text: String
        var status: Int32
        var timedOut: Bool
        var truncated: Bool
        var couldNotStart: Bool
    }

    static func runMerged(_ path: String, _ arguments: [String], environment: [String: String]? = nil,
                          timeout: TimeInterval, outputLimit: Int = 4 << 20) -> MergedResult {
        guard let r = run(path, arguments, environment: environment, mergeStderr: true, timeout: timeout, outputLimit: outputLimit) else {
            return MergedResult(text: "could not start \(path)", status: -1, timedOut: false, truncated: false, couldNotStart: true)
        }
        if r.timedOut {
            let name = (path as NSString).lastPathComponent
            return MergedResult(text: r.stdoutText + "\n\(name) did not finish in \(Int(timeout)) s and was ended", status: -1,
                                timedOut: true, truncated: r.truncated, couldNotStart: false)
        }
        return MergedResult(text: r.stdoutText, status: r.status, timedOut: false, truncated: r.truncated, couldNotStart: false)
    }
}
