//
//  SecurityTests.swift
//  DashboardTVTests
//
//  Security tests for DashboardTV: credential scanning, loopback API,
//  safe URL handling, no sensitive data exposure
//  Created by Jordan Koch
//

import XCTest
@testable import DashboardTV

final class DashboardTVSecurityTests: XCTestCase {

    // MARK: - Source Code Credential Scanning

    func testNoHardcodedCredentialsInSource() throws {
        let projectDir = findProjectDirectory()
        guard let dir = projectDir else { return }

        let suspiciousPatterns = [
            "sk-[A-Za-z0-9]{20,}",          // OpenAI keys
            "AKIA[A-Z0-9]{16}",              // AWS access keys
            "ghp_[A-Za-z0-9]{36}",           // GitHub PATs
            "xox[bpoas]-[A-Za-z0-9-]+",      // Slack tokens
            "Bearer [A-Za-z0-9._-]{20,}",    // Bearer tokens
        ]

        let swiftFiles = findSwiftFiles(in: dir)
        var violations: [String] = []

        for file in swiftFiles {
            if file.contains("Tests/") || file.contains("SecurityTests") { continue }

            guard let content = try? String(contentsOfFile: file, encoding: .utf8) else { continue }

            for pattern in suspiciousPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern),
                   regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) != nil {
                    violations.append("Potential credential in \(file) matching: \(pattern)")
                }
            }
        }

        XCTAssertTrue(violations.isEmpty, "Found potential credentials:\n\(violations.joined(separator: "\n"))")
    }

    // MARK: - Nova API Server Security

    func testAPIServerBindsToLoopback() throws {
        let projectDir = findProjectDirectory()
        guard let dir = projectDir else { return }

        let serverPath = dir + "/DashboardTV/NovaAPIServer.swift"
        guard let content = try? String(contentsOfFile: serverPath, encoding: .utf8) else {
            return
        }

        XCTAssertTrue(content.contains("127.0.0.1"), "NovaAPIServer must bind to 127.0.0.1 only")
        XCTAssertFalse(content.contains("0.0.0.0"), "NovaAPIServer must NOT bind to all interfaces")
    }

    func testAPIServerCorrectPort() throws {
        let projectDir = findProjectDirectory()
        guard let dir = projectDir else { return }

        let serverPath = dir + "/DashboardTV/NovaAPIServer.swift"
        guard let content = try? String(contentsOfFile: serverPath, encoding: .utf8) else {
            return
        }

        XCTAssertTrue(content.contains("37429"), "DashboardTV NovaAPIServer should use port 37429")
    }

    func testAPIServerResponseSecurity() throws {
        let projectDir = findProjectDirectory()
        guard let dir = projectDir else { return }

        let serverPath = dir + "/DashboardTV/NovaAPIServer.swift"
        guard let content = try? String(contentsOfFile: serverPath, encoding: .utf8) else {
            return
        }

        XCTAssertTrue(content.contains("Connection: close"), "Server should close connections after response")
        XCTAssertTrue(content.contains("Content-Length"), "Server should set Content-Length header")
    }

    // MARK: - Configuration Server Security

    func testConfigurationServerPort() throws {
        let projectDir = findProjectDirectory()
        guard let dir = projectDir else { return }

        let appPath = dir + "/DashboardTV/DashboardTVApp.swift"
        guard let content = try? String(contentsOfFile: appPath, encoding: .utf8) else {
            return
        }

        XCTAssertTrue(content.contains("8080"), "ConfigurationServer should use port 8080")
        XCTAssertTrue(content.contains("_dashboardtv._tcp"), "Should advertise correct Bonjour service type")
    }

    // MARK: - URL Handling Safety

    func testURLConstructionSafety() {
        // Valid URL
        let validURL = URL(string: "https://grafana.example.com/d/abc123")
        XCTAssertNotNil(validURL)

        // Malicious URL should not crash
        let maliciousURLs = [
            "javascript:alert(1)",
            "data:text/html,<script>alert(1)</script>",
            "",
            "http://",
            String(repeating: "a", count: 50000),
            "http://192.168.1.1:8080/../../../etc/passwd"
        ]

        for urlString in maliciousURLs {
            // Should not crash
            _ = URL(string: urlString)
        }
    }

    // MARK: - App Group Identifier

    func testAppGroupIdentifierFormat() throws {
        let projectDir = findProjectDirectory()
        guard let dir = projectDir else { return }

        let topShelfPath = dir + "/DashboardTV/TopShelfDataManager.swift"
        guard let content = try? String(contentsOfFile: topShelfPath, encoding: .utf8) else {
            return
        }

        // Verify app group identifier follows Apple conventions
        XCTAssertTrue(content.contains("group.com.jordankoch.dashboardtv"), "Should use proper app group identifier")
    }

    // MARK: - No Sensitive Data in UserDefaults Keys

    func testUserDefaultsKeysAreSafe() throws {
        let projectDir = findProjectDirectory()
        guard let dir = projectDir else { return }

        let swiftFiles = findSwiftFiles(in: dir)

        for file in swiftFiles {
            if file.contains("Tests/") { continue }
            guard let content = try? String(contentsOfFile: file, encoding: .utf8) else { continue }

            // UserDefaults keys should not contain "password", "secret", "token", "apikey"
            let sensitiveKeyPatterns = [
                "UserDefaults.*\"[^\"]*password[^\"]*\"",
                "UserDefaults.*\"[^\"]*secret[^\"]*\"",
                "UserDefaults.*\"[^\"]*token[^\"]*\"",
                "UserDefaults.*\"[^\"]*apikey[^\"]*\"",
            ]

            for pattern in sensitiveKeyPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                   regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) != nil {
                    XCTFail("Found sensitive key stored in UserDefaults in \(file)")
                }
            }
        }
    }

    // MARK: - Helpers

    private func findProjectDirectory() -> String? {
        let paths = [
            "/Volumes/Data/xcode/DashboardTV",
            Bundle.main.bundlePath + "/../../.."
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path + "/DashboardTV") {
                return path
            }
        }
        return nil
    }

    private func findSwiftFiles(in directory: String) -> [String] {
        var files: [String] = []
        let enumerator = FileManager.default.enumerator(atPath: directory)
        while let element = enumerator?.nextObject() as? String {
            if element.hasSuffix(".swift") && !element.contains("build/") && !element.contains(".xcodeproj") {
                files.append(directory + "/" + element)
            }
        }
        return files
    }
}
