//
//  iPadContentView.swift
//  DashboardTV
//
//  iPad-optimized dashboard view with actual WKWebView rendering
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

#if os(iOS)
import SwiftUI
import WebKit

struct iPadContentView: View {
    @EnvironmentObject var configServer: ConfigurationServer
    @EnvironmentObject var dashboardManager: TVDashboardManager

    @State private var isFullscreen = true
    @State private var showControls = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            if dashboardManager.urls.isEmpty {
                emptyStateView
            } else {
                webViewContent
            }

            // Floating controls (tap to show)
            if showControls {
                controlsOverlay
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls.toggle()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 {
                        // Swipe left - next dashboard
                        dashboardManager.nextDashboard()
                    } else if value.translation.width > 50 {
                        // Swipe right - previous dashboard
                        dashboardManager.previousDashboard()
                    }
                }
        )
        .onAppear {
            if !dashboardManager.urls.isEmpty && !dashboardManager.isRotating {
                dashboardManager.startRotation()
            }
        }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "display")
                .font(.system(size: 60))
                .foregroundColor(.cyan.opacity(0.6))

            Text("DashboardTV")
                .font(.platformTitle())
                .foregroundColor(.white)

            Text("Configure from Dashboard Screensaver on your Mac")
                .font(.platformBody())
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(configServer.isRunning ? .green : .orange)
                    Text(configServer.isRunning ? "Ready for configuration" : "Starting...")
                        .foregroundColor(.white.opacity(0.7))
                }

                if let ip = NetworkUtilities.getIPAddress() {
                    Text("IP Address: \(ip)")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.cyan)
                }
            }
            .padding()
            .glassBackground()

            // iPad-specific instructions
            VStack(spacing: 8) {
                Text("Gestures")
                    .font(.platformHeadline())
                    .foregroundColor(.white)

                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: "hand.draw")
                            .font(.title)
                        Text("Swipe to navigate")
                            .font(.platformCaption())
                    }

                    VStack {
                        Image(systemName: "hand.tap")
                            .font(.title)
                        Text("Tap for controls")
                            .font(.platformCaption())
                    }
                }
                .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .glassBackground()
        }
        .padding(40)
    }

    private var webViewContent: some View {
        ZStack {
            if let url = dashboardManager.currentURL {
                DashboardWebView(url: url)
                    .id(dashboardManager.currentIndex) // Force refresh on change
            }

            // Status overlay
            VStack {
                HStack {
                    statusIndicator
                    Spacer()
                    dashboardCounter
                }
                .padding()

                Spacer()
            }
            .opacity(showControls ? 1 : 0)
        }
    }

    private var controlsOverlay: some View {
        VStack {
            Spacer()

            HStack(spacing: 20) {
                // Previous
                Button(action: { dashboardManager.previousDashboard() }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }

                // Play/Pause
                Button(action: {
                    if dashboardManager.isRotating {
                        dashboardManager.stopRotation()
                    } else {
                        dashboardManager.startRotation()
                    }
                }) {
                    Image(systemName: dashboardManager.isRotating ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.cyan)
                }

                // Next
                Button(action: { dashboardManager.nextDashboard() }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
            }
            .padding(30)
            .glassBackground()
            .padding(.bottom, 40)
        }
    }

    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(dashboardManager.isRotating ? Color.green : Color.orange)
                .frame(width: 10, height: 10)

            Text(dashboardManager.isRotating ? "Rotating" : "Paused")
                .font(.platformCaption())
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassBackground()
    }

    private var dashboardCounter: some View {
        Text("\(dashboardManager.currentIndex + 1) / \(dashboardManager.urls.count)")
            .font(.platformCaption())
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassBackground()
    }
}

// MARK: - Dashboard WebView

struct DashboardWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// MARK: - Network Utilities

struct NetworkUtilities {
    static func getIPAddress() -> String? {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }

        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    )
                    address = String(cString: hostname)
                }
            }
        }

        return address
    }
}

#Preview {
    iPadContentView()
        .environmentObject(ConfigurationServer.shared)
        .environmentObject(TVDashboardManager.shared)
}
#endif
