// Mirrored from RoamSwitchTests/ — RoamSwitch 1.9.44 (build 101). Do not edit here; see SYNC.md.

import XCTest
@testable import roamswitch_mcp

final class CryptoSecretDetectionTests: XCTestCase {

    private func tokens(_ s: String) -> [String] {
        CryptoSecretDetection.tokenizeWords(s)
    }

    func testWordlistHas2048UniqueEntriesMatchingUpstream() {
        XCTAssertEqual(CryptoSecretDetection.bip39EnglishWords.count, 2048)
        XCTAssertEqual(Set(CryptoSecretDetection.bip39EnglishWords).count, 2048, "duplicate word in list")
        XCTAssertEqual(CryptoSecretDetection.bip39EnglishWords.first, "abandon")
        XCTAssertEqual(CryptoSecretDetection.bip39EnglishWords.last, "zoo")
    }

    /// Independently verified (2026-09-14) against the BIP39 reference
    /// algorithm: SHA-256(16 zero bytes) checksum -> mnemonic ends "about".
    /// Same test vector used by the Linux edition's `crypto_secrets.rs`.
    func testDetectsTheCanonicalAllZeroEntropy12WordTestVector() {
        let t = tokens("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about")
        let spans = CryptoSecretDetection.findMnemonicSpans(t)
        XCTAssertEqual(spans.count, 1)
        XCTAssertEqual(spans.first?.start, 0)
        XCTAssertEqual(spans.first?.end, 12)
    }

    func testDetectsTheCanonicalAllZeroEntropy24WordTestVector() {
        let t = tokens("abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art")
        let spans = CryptoSecretDetection.findMnemonicSpans(t)
        XCTAssertEqual(spans.count, 1)
        XCTAssertEqual(spans.first?.end, 24)
    }

    func testDetectsTheAllFfEntropy24WordTestVector() {
        let t = tokens("zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote")
        let spans = CryptoSecretDetection.findMnemonicSpans(t)
        XCTAssertEqual(spans.count, 1)
        XCTAssertEqual(spans.first?.end, 24)
    }

    func testRejects12Bip39WordsInARowWithNoValidChecksum() {
        // All 12 words are real BIP39 words, but strung together with no
        // relation to a real checksum — must NOT be reported.
        let t = tokens("abandon ability able about above absent absorb abstract absurd abuse access accident")
        XCTAssertTrue(CryptoSecretDetection.findMnemonicSpans(t).isEmpty)
    }

    func testIgnoresOrdinaryProseEvenWhenItContainsBip39Words() {
        let t = tokens("the quick brown fox jumps over the lazy dog near the river bank today")
        XCTAssertTrue(CryptoSecretDetection.findMnemonicSpans(t).isEmpty)
    }

    func testFindsAValidMnemonicEmbeddedInSurroundingProse() {
        let s = "here is my wallet backup abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about please keep it safe"
        let t = tokens(s)
        let spans = CryptoSecretDetection.findMnemonicSpans(t)
        XCTAssertEqual(spans.count, 1)
        guard let span = spans.first else { return }
        XCTAssertEqual(t[span.start..<span.end].joined(separator: " "),
                        "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about")
    }

    // MARK: - WIF / BIP32 extended key

    /// Base58Check(version=0x80, payload=32 bytes of 0x01) — independently
    /// verified (2026-09-14) to start with '5', the well-known WIF
    /// uncompressed-mainnet leading character. Cross-checked against the
    /// same fixture the Linux edition's tests use.
    private let uncompressedWIFFixture = "5HpjE2Hs7vjU4SN3YyPQCdhzCu92WoEeuE6PWNuiPyTu3ESGnzn"

    func testWifUncompressedMainnetClassifies() {
        XCTAssertTrue(uncompressedWIFFixture.hasPrefix("5"))
        XCTAssertEqual(CryptoSecretDetection.classifyCryptoKeyCandidate(uncompressedWIFFixture), .wif)
    }

    func testCorruptedChecksumIsRejected() {
        var corrupted = uncompressedWIFFixture
        let last = corrupted.removeLast()
        corrupted.append(last == "1" ? "2" : "1")
        XCTAssertNil(CryptoSecretDetection.classifyCryptoKeyCandidate(corrupted))
    }

    func testCandidatePatternsMatchTheFixtureKey() throws {
        let re = try NSRegularExpression(pattern: CryptoSecretDetection.wifCandidatePattern)
        let range = NSRange(uncompressedWIFFixture.startIndex..., in: uncompressedWIFFixture)
        XCTAssertNotNil(re.firstMatch(in: uncompressedWIFFixture, range: range))
    }

    func testRandomBase58LookingStringWithoutAValidChecksumIsNotClassified() {
        // Right shape (leading '5', right length), but not a real
        // Base58Check-encoded key — must not classify as anything.
        XCTAssertNil(CryptoSecretDetection.classifyCryptoKeyCandidate("5" + String(repeating: "z", count: 50)))
    }

    // MARK: - Integration with the existing scanner

    func testAuditTextDetectsASeedPhraseAndNeverShowsItInTheMask() {
        let text = "my wallet backup: abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        let findings = SecretLeakScanning.auditText(text)
        XCTAssertEqual(findings.count, 1)
        guard let finding = findings.first else { return }
        XCTAssertEqual(finding.type, .cryptoSeedPhrase)
        XCTAssertFalse(finding.masked.contains("abandon"))
        XCTAssertFalse(finding.masked.contains("about"))
    }

    func testAuditTextIgnoresBip39WordsInOrdinaryProseWithNoValidChecksum() {
        let text = "abandon ability able about above absent absorb abstract absurd abuse access accident is not a real seed phrase"
        let findings = SecretLeakScanning.auditText(text)
        XCTAssertFalse(findings.contains { $0.type == .cryptoSeedPhrase })
    }

    func testAuditTextDetectsAChecksumValidWifKey() {
        let text = "leaked key: \(uncompressedWIFFixture)"
        let findings = SecretLeakScanning.auditText(text)
        XCTAssertTrue(findings.contains { $0.type == .cryptoBitcoinWIF })
        XCTAssertFalse(findings.contains { $0.masked.contains("5HpjE2Hs") })
    }

    func testRedactMasksASeedPhraseAndAWifKeyFully() {
        let text = "seed: abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about\nkey: \(uncompressedWIFFixture)"
        let redacted = SecretLeakScanning.redact(text)
        XCTAssertFalse(redacted.contains("abandon"))
        XCTAssertFalse(redacted.contains("5HpjE2Hs"))
        XCTAssertTrue(redacted.contains("seed:"))
        XCTAssertTrue(redacted.contains("key:"))
    }

    func testScanTextForSecretsMapsTheNewCryptoTypes() {
        let text = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
        let items = SecretLeakScanning.scanTextForSecrets(text)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.type, .cryptoSeedPhrase)
    }
}
