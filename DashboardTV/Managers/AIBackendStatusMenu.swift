import SwiftUI

//
//  AIBackendStatusMenu.swift
//  DashboardTV
//
//  AI Backend status display for DashboardTV
//  Author: Jordan Koch
//

struct AIBackendStatusMenu: View {
    @ObservedObject var manager = AIBackendManager.shared
    @State private var isRefreshing = false

    var compact: Bool = false
    var showModelPicker: Bool = true

    var body: some View {
        HStack(spacing: compact ? 8 : 12) {
            // Status Indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                if !compact {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(statusColor)

                        if let backend = manager.activeBackend {
                            Text(backend.rawValue)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Model Selector (for Ollama)
            if showModelPicker && manager.activeBackend == .ollama && !manager.ollamaModels.isEmpty {
                Menu {
                    ForEach(manager.ollamaModels, id: \.self) { model in
                        Button(action: {
                            manager.selectedOllamaModel = model
                            manager.saveSettings()
                        }) {
                            HStack {
                                Text(model)
                                Spacer()
                                if manager.selectedOllamaModel == model {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "brain")
                        Text(truncateModelName(manager.selectedOllamaModel))
                            .font(.system(size: 11))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .foregroundColor(.blue)
                }
                .menuStyle(.borderlessButton)
                .frame(height: 24)
            }

            // Refresh Button
            Button(action: {
                isRefreshing = true
                Task {
                    await manager.checkBackendAvailability()
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    isRefreshing = false
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRefreshing)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    private var statusColor: Color {
        if manager.activeBackend != nil {
            return .green
        } else if manager.isOllamaAvailable || manager.isTinyLLMAvailable || manager.isTinyChatAvailable {
            return .gray
        } else {
            return .red
        }
    }

    private var statusText: String {
        if manager.activeBackend != nil {
            return "Connected"
        } else {
            return "Offline"
        }
    }

    private func truncateModelName(_ name: String) -> String {
        let parts = name.split(separator: ":")
        return String(parts.first ?? Substring(name))
    }
}

struct AIBackendStatusMenuCompact: View {
    var body: some View {
        AIBackendStatusMenu(compact: true, showModelPicker: false)
    }
}
