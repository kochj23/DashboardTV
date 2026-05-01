//
//  DashboardTVTests.swift
//  DashboardTVTests
//
//  Unit tests for DashboardTV models, configuration, and managers
//  Created by Jordan Koch
//

import XCTest
@testable import DashboardTV

// MARK: - TVConfiguration Tests

final class TVConfigurationTests: XCTestCase {

    func testCodableRoundTrip() throws {
        let config = TVConfiguration(
            urls: ["https://grafana.example.com", "https://kibana.example.com"],
            rotationInterval: 45,
            enableDarkMode: true,
            enableAIDetection: false,
            alertThreshold: 7.5
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(TVConfiguration.self, from: data)

        XCTAssertEqual(decoded.urls, config.urls)
        XCTAssertEqual(decoded.rotationInterval, config.rotationInterval, accuracy: 0.01)
        XCTAssertEqual(decoded.enableDarkMode, config.enableDarkMode)
        XCTAssertEqual(decoded.enableAIDetection, config.enableAIDetection)
        XCTAssertEqual(decoded.alertThreshold, config.alertThreshold, accuracy: 0.01)
    }

    func testEmptyURLs() throws {
        let config = TVConfiguration(
            urls: [],
            rotationInterval: 30,
            enableDarkMode: true,
            enableAIDetection: false,
            alertThreshold: 5.0
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(TVConfiguration.self, from: data)

        XCTAssertTrue(decoded.urls.isEmpty)
    }

    func testLargeURLList() throws {
        let urls = (0..<100).map { "https://dashboard-\($0).example.com" }
        let config = TVConfiguration(
            urls: urls,
            rotationInterval: 10,
            enableDarkMode: false,
            enableAIDetection: true,
            alertThreshold: 3.0
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(TVConfiguration.self, from: data)

        XCTAssertEqual(decoded.urls.count, 100)
    }

    func testMinimalConfiguration() throws {
        let config = TVConfiguration(
            urls: ["https://example.com"],
            rotationInterval: 1,
            enableDarkMode: false,
            enableAIDetection: false,
            alertThreshold: 0
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(TVConfiguration.self, from: data)

        XCTAssertEqual(decoded.urls.count, 1)
        XCTAssertEqual(decoded.rotationInterval, 1, accuracy: 0.01)
        XCTAssertEqual(decoded.alertThreshold, 0, accuracy: 0.01)
    }
}

// MARK: - TVSettings Tests

final class TVSettingsTests: XCTestCase {

    func testDefaultValues() {
        let settings = TVSettings()

        XCTAssertEqual(settings.rotationInterval, 30)
        XCTAssertTrue(settings.enableDarkMode)
        XCTAssertFalse(settings.enableAIDetection)
        XCTAssertEqual(settings.alertThreshold, 5.0)
    }

    func testCodableRoundTrip() throws {
        var settings = TVSettings()
        settings.rotationInterval = 60
        settings.enableDarkMode = false
        settings.enableAIDetection = true
        settings.alertThreshold = 10.0

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(TVSettings.self, from: data)

        XCTAssertEqual(decoded.rotationInterval, 60, accuracy: 0.01)
        XCTAssertFalse(decoded.enableDarkMode)
        XCTAssertTrue(decoded.enableAIDetection)
        XCTAssertEqual(decoded.alertThreshold, 10.0, accuracy: 0.01)
    }

    func testSettingsModification() throws {
        var settings = TVSettings()
        settings.rotationInterval = 120
        settings.enableDarkMode = false
        settings.enableAIDetection = true
        settings.alertThreshold = 2.5

        XCTAssertEqual(settings.rotationInterval, 120)
        XCTAssertFalse(settings.enableDarkMode)
        XCTAssertTrue(settings.enableAIDetection)
        XCTAssertEqual(settings.alertThreshold, 2.5, accuracy: 0.01)
    }
}

// MARK: - AIBackend Tests

final class AIBackendTests: XCTestCase {

    func testAllCases() {
        XCTAssertEqual(AIBackend.allCases.count, 4)
    }

    func testRawValues() {
        XCTAssertEqual(AIBackend.ollama.rawValue, "Ollama")
        XCTAssertEqual(AIBackend.tinyLLM.rawValue, "TinyLLM")
        XCTAssertEqual(AIBackend.tinyChat.rawValue, "TinyChat")
        XCTAssertEqual(AIBackend.auto.rawValue, "Auto (Prefer Local)")
    }

    func testIcons() {
        XCTAssertFalse(AIBackend.ollama.icon.isEmpty)
        XCTAssertFalse(AIBackend.tinyLLM.icon.isEmpty)
        XCTAssertFalse(AIBackend.tinyChat.icon.isEmpty)
        XCTAssertFalse(AIBackend.auto.icon.isEmpty)
    }

    func testDescriptions() {
        for backend in AIBackend.allCases {
            XCTAssertFalse(backend.description.isEmpty, "\(backend.rawValue) should have a description")
        }
    }

    func testAttribution() {
        XCTAssertNotNil(AIBackend.tinyLLM.attribution, "TinyLLM should have attribution")
        XCTAssertNotNil(AIBackend.tinyChat.attribution, "TinyChat should have attribution")
        XCTAssertNil(AIBackend.ollama.attribution, "Ollama should not need attribution")
        XCTAssertNil(AIBackend.auto.attribution, "Auto should not need attribution")
    }

    func testCodableRoundTrip() throws {
        for backend in AIBackend.allCases {
            let data = try JSONEncoder().encode(backend)
            let decoded = try JSONDecoder().decode(AIBackend.self, from: data)
            XCTAssertEqual(decoded, backend)
        }
    }
}

// MARK: - AIBackendError Tests

final class AIBackendErrorTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertNotNil(AIBackendError.noBackendAvailable.errorDescription)
        XCTAssertNotNil(AIBackendError.invalidConfiguration.errorDescription)
        XCTAssertNotNil(AIBackendError.invalidState.errorDescription)
    }

    func testErrorDescriptionsNotEmpty() {
        XCTAssertFalse(AIBackendError.noBackendAvailable.errorDescription!.isEmpty)
        XCTAssertFalse(AIBackendError.invalidConfiguration.errorDescription!.isEmpty)
        XCTAssertFalse(AIBackendError.invalidState.errorDescription!.isEmpty)
    }
}

// MARK: - URL Safety Tests

final class URLSafetyTests: XCTestCase {

    func testValidURLConstruction() {
        let url = URL(string: "https://grafana.example.com/d/abc123")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "grafana.example.com")
    }

    func testURLEdgeCases() {
        // These should not crash
        _ = URL(string: "javascript:alert(1)")
        _ = URL(string: "data:text/html,<script>alert(1)</script>")
        _ = URL(string: "")
        _ = URL(string: "http://")
        _ = URL(string: String(repeating: "a", count: 50000))
    }

    func testMaliciousURLs() {
        let urls = [
            "http://192.168.1.1:8080/../../../etc/passwd",
            "http://attacker.com@192.168.1.1/",
            "http://192.168.1.1:8080/api/configure?url=http://evil.com"
        ]

        for urlString in urls {
            // Constructing the URL should not crash
            let url = URL(string: urlString)
            // The URL might still be created, but the host should be resolvable
            if let url = url {
                _ = url.host
                _ = url.path
            }
        }
    }

    func testURLListDecodability() throws {
        let jsonData = """
        ["https://grafana.example.com", "https://kibana.example.com", "invalid-url"]
        """.data(using: .utf8)!

        let urls = try JSONDecoder().decode([String].self, from: jsonData)
        XCTAssertEqual(urls.count, 3)

        // Verify URL construction for each
        let validURLs = urls.compactMap { URL(string: $0) }
        XCTAssertEqual(validURLs.count, 3) // "invalid-url" is valid URL(string:) input
    }
}
