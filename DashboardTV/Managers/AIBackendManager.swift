//
//  AIBackendManager.swift
//  DashboardTV
//
//  AI Backend Manager with full multi-backend support for intelligent dashboard display
//  Author: Jordan Koch
//
//  THIRD-PARTY INTEGRATIONS:
//  - TinyChat by Jason Cox (https://github.com/jasonacox/tinychat)
//    Fast chatbot interface with OpenAI-compatible API
//  - TinyLLM by Jason Cox (https://github.com/jasonacox/TinyLLM)
//    Lightweight LLM server with OpenAI-compatible API
//
//  AI FEATURES FOR DASHBOARDTV:
//  - Intelligent dashboard rotation scheduling
//  - Content relevance analysis
//  - Anomaly detection in dashboard data
//

import Foundation
import SwiftUI
import Combine

// MARK: - AI Backend Type

enum AIBackend: String, Codable, CaseIterable {
    case ollama = "Ollama"
    case tinyLLM = "TinyLLM"
    case tinyChat = "TinyChat"
    case auto = "Auto (Prefer Local)"

    var icon: String {
        switch self {
        case .ollama: return "network"
        case .tinyLLM: return "cube"
        case .tinyChat: return "bubble.left.and.bubble.right.fill"
        case .auto: return "sparkles"
        }
    }

    var description: String {
        switch self {
        case .ollama: return "Ollama local LLM (localhost:11434)"
        case .tinyLLM: return "TinyLLM by Jason Cox - Lightweight LLM server"
        case .tinyChat: return "TinyChat by Jason Cox - Fast chatbot interface"
        case .auto: return "Automatically select best available backend"
        }
    }

    var attribution: String? {
        switch self {
        case .tinyLLM: return "TinyLLM by Jason Cox (https://github.com/jasonacox/TinyLLM)"
        case .tinyChat: return "TinyChat by Jason Cox (https://github.com/jasonacox/tinychat)"
        default: return nil
        }
    }
}

// MARK: - AI Backend Manager

@MainActor
class AIBackendManager: ObservableObject {
    static let shared = AIBackendManager()

    @Published var selectedBackend: AIBackend = .auto
    @Published var activeBackend: AIBackend? = nil
    @Published var isOllamaAvailable = false
    @Published var isTinyLLMAvailable = false
    @Published var isTinyChatAvailable = false
    @Published var isProcessing = false
    @Published var aiEnabled = true

    @Published var ollamaURL: String = "http://localhost:11434"
    @Published var tinyLLMServerURL: String = "http://localhost:8000"
    @Published var tinyChatServerURL: String = "http://localhost:8000"
    @Published var ollamaModels: [String] = []
    @Published var selectedOllamaModel: String = "llama3.2"

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let selectedBackend = "AIBackendManager_SelectedBackend"
        static let ollamaModel = "AIBackendManager_OllamaModel"
        static let tinyLLMServerURL = "AIBackendManager_TinyLLMServerURL"
        static let tinyChatServerURL = "AIBackendManager_TinyChatServerURL"
        static let aiEnabled = "AIBackendManager_AIEnabled"
    }

    private init() {
        loadSettings()
        Task { await checkBackendAvailability() }
    }

    private func loadSettings() {
        if let backendRaw = userDefaults.string(forKey: Keys.selectedBackend),
           let backend = AIBackend(rawValue: backendRaw) {
            selectedBackend = backend
        }
        selectedOllamaModel = userDefaults.string(forKey: Keys.ollamaModel) ?? "llama3.2"
        tinyLLMServerURL = userDefaults.string(forKey: Keys.tinyLLMServerURL) ?? "http://localhost:8000"
        tinyChatServerURL = userDefaults.string(forKey: Keys.tinyChatServerURL) ?? "http://localhost:8000"
        aiEnabled = userDefaults.bool(forKey: Keys.aiEnabled)
    }

    func saveSettings() {
        userDefaults.set(selectedBackend.rawValue, forKey: Keys.selectedBackend)
        userDefaults.set(selectedOllamaModel, forKey: Keys.ollamaModel)
        userDefaults.set(tinyLLMServerURL, forKey: Keys.tinyLLMServerURL)
        userDefaults.set(tinyChatServerURL, forKey: Keys.tinyChatServerURL)
        userDefaults.set(aiEnabled, forKey: Keys.aiEnabled)
    }

    // MARK: - Backend Availability

    func checkBackendAvailability() async {
        async let ollamaCheck = checkOllamaAvailability()
        async let tinyLLMCheck = checkTinyLLMAvailability()
        async let tinyChatCheck = checkTinyChatAvailability()

        let (ollama, tinyLLM, tinyChat) = await (ollamaCheck, tinyLLMCheck, tinyChatCheck)
        isOllamaAvailable = ollama
        isTinyLLMAvailable = tinyLLM
        isTinyChatAvailable = tinyChat
        determineActiveBackend()
    }

    private func determineActiveBackend() {
        switch selectedBackend {
        case .ollama: activeBackend = isOllamaAvailable ? .ollama : nil
        case .tinyLLM: activeBackend = isTinyLLMAvailable ? .tinyLLM : nil
        case .tinyChat: activeBackend = isTinyChatAvailable ? .tinyChat : nil
        case .auto:
            if isOllamaAvailable { activeBackend = .ollama }
            else if isTinyChatAvailable { activeBackend = .tinyChat }
            else if isTinyLLMAvailable { activeBackend = .tinyLLM }
            else { activeBackend = nil }
        }
    }

    private func checkOllamaAvailability() async -> Bool {
        guard let url = URL(string: "\(ollamaURL)/api/tags") else { return false }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                let modelNames = models.compactMap { $0["name"] as? String }
                await MainActor.run { self.ollamaModels = modelNames }
            }
            return true
        } catch { return false }
    }

    // TinyLLM by Jason Cox: https://github.com/jasonacox/TinyLLM
    private func checkTinyLLMAvailability() async -> Bool {
        guard let url = URL(string: "\(tinyLLMServerURL)/") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }

    // TinyChat by Jason Cox: https://github.com/jasonacox/tinychat
    private func checkTinyChatAvailability() async -> Bool {
        guard let url = URL(string: "\(tinyChatServerURL)/") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch { return false }
    }

    // MARK: - Text Generation

    func generate(prompt: String, systemPrompt: String? = nil, temperature: Float = 0.7, maxTokens: Int = 1024) async throws -> String {
        guard aiEnabled, let backend = activeBackend else {
            throw AIBackendError.noBackendAvailable
        }

        isProcessing = true
        defer { isProcessing = false }

        switch backend {
        case .ollama: return try await generateWithOllama(prompt: prompt, systemPrompt: systemPrompt, temperature: temperature, maxTokens: maxTokens)
        case .tinyLLM: return try await generateWithTinyLLM(prompt: prompt, systemPrompt: systemPrompt, temperature: temperature, maxTokens: maxTokens)
        case .tinyChat: return try await generateWithTinyChat(prompt: prompt, systemPrompt: systemPrompt, temperature: temperature, maxTokens: maxTokens)
        case .auto: throw AIBackendError.invalidState
        }
    }

    private func generateWithOllama(prompt: String, systemPrompt: String?, temperature: Float, maxTokens: Int) async throws -> String {
        guard let url = URL(string: "\(ollamaURL)/api/generate") else { throw AIBackendError.invalidConfiguration }
        var requestBody: [String: Any] = ["model": selectedOllamaModel, "prompt": prompt, "stream": false, "options": ["temperature": temperature, "num_predict": maxTokens]]
        if let systemPrompt = systemPrompt { requestBody["system"] = systemPrompt }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        let (data, _) = try await URLSession.shared.data(for: request)
        struct OllamaResponse: Codable { let response: String }
        return try JSONDecoder().decode(OllamaResponse.self, from: data).response
    }

    // TinyLLM by Jason Cox: https://github.com/jasonacox/TinyLLM
    private func generateWithTinyLLM(prompt: String, systemPrompt: String?, temperature: Float, maxTokens: Int) async throws -> String {
        guard let url = URL(string: "\(tinyLLMServerURL)/v1/chat/completions") else { throw AIBackendError.invalidConfiguration }
        var messages: [[String: String]] = []
        if let systemPrompt = systemPrompt { messages.append(["role": "system", "content": systemPrompt]) }
        messages.append(["role": "user", "content": prompt])
        let requestBody: [String: Any] = ["messages": messages, "max_tokens": maxTokens, "temperature": temperature, "stream": false]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        let (data, _) = try await URLSession.shared.data(for: request)
        struct Response: Codable { struct Choice: Codable { struct Message: Codable { let content: String }; let message: Message }; let choices: [Choice] }
        return try JSONDecoder().decode(Response.self, from: data).choices.first?.message.content ?? ""
    }

    // TinyChat by Jason Cox: https://github.com/jasonacox/tinychat
    private func generateWithTinyChat(prompt: String, systemPrompt: String?, temperature: Float, maxTokens: Int) async throws -> String {
        guard let url = URL(string: "\(tinyChatServerURL)/v1/chat/completions") else { throw AIBackendError.invalidConfiguration }
        var messages: [[String: String]] = []
        if let systemPrompt = systemPrompt { messages.append(["role": "system", "content": systemPrompt]) }
        messages.append(["role": "user", "content": prompt])
        let requestBody: [String: Any] = ["messages": messages, "max_tokens": maxTokens, "temperature": temperature, "stream": false]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        let (data, _) = try await URLSession.shared.data(for: request)
        struct Response: Codable { struct Choice: Codable { struct Message: Codable { let content: String }; let message: Message }; let choices: [Choice] }
        return try JSONDecoder().decode(Response.self, from: data).choices.first?.message.content ?? ""
    }

    // MARK: - DashboardTV AI Features

    /// Suggest optimal dashboard rotation based on time of day
    func suggestDashboardPriority(dashboards: [String], currentHour: Int) async -> [String]? {
        guard aiEnabled, activeBackend != nil else { return nil }
        let prompt = """
        Prioritize these dashboards for display at \(currentHour):00:
        \(dashboards.joined(separator: ", "))

        Consider: business hours, relevance, typical viewing patterns.
        Return ordered list, most important first.
        """
        if let response = try? await generate(prompt: prompt, systemPrompt: "You are a dashboard optimization expert. Return only dashboard names in priority order.") {
            return response.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
        return nil
    }
}

// MARK: - Errors

enum AIBackendError: LocalizedError {
    case noBackendAvailable, invalidConfiguration, invalidState
    var errorDescription: String? {
        switch self {
        case .noBackendAvailable: return "No AI backend available. Install Ollama, TinyChat, or TinyLLM."
        case .invalidConfiguration: return "AI backend configuration is invalid."
        case .invalidState: return "AI backend is in an invalid state."
        }
    }
}
