# DashboardTV

![Build](https://github.com/kochj23/DashboardTV/actions/workflows/build.yml/badge.svg)

tvOS companion app for Dashboard Screensaver. Displays dashboard URLs on Apple TV devices, configured remotely from the macOS Dashboard Screensaver app.

## Features

- **Remote Configuration** - Receive dashboard URLs from macOS app via Bonjour/HTTP (Hypertext Transfer Protocol)
- **Dashboard Rotation** - Automatically cycle through configured dashboards
- **Siri Remote Control** - Play/Pause to toggle rotation, Left/Right to navigate
- **IP (Internet Protocol) Address Display** - Shows device IP for easy configuration
- **Persistent Settings** - Remembers configuration across app restarts

## Requirements

- tvOS 17.0+
- Apple TV 4K (2nd generation or later)
- Dashboard Screensaver macOS app for configuration

## Usage

1. Install DashboardTV on your Apple TV
2. Launch the app - it will display its IP address
3. Open Dashboard Screensaver on your Mac
4. Add your Apple TV in the Apple TV Manager section
5. Configure dashboard URLs and push to the Apple TV

### Remote Controls

| Button | Action |
|--------|--------|
| Play/Pause | Toggle auto-rotation |
| Left | Previous dashboard |
| Right | Next dashboard |

## Configuration

DashboardTV accepts configuration via HTTP POST to `/api/configure`:

```json
{
  "urls": ["https://dashboard1.example.com", "https://dashboard2.example.com"],
  "rotationInterval": 30,
  "enableDarkMode": true,
  "enableAIDetection": false,
  "alertThreshold": 5.0
}
```

## Architecture

- **ConfigurationServer** - HTTP server on port 8080 for receiving configs
- **TVDashboardManager** - Manages dashboard URLs and rotation state
- **TVContentView** - Main UI displaying dashboards or empty state

## Building

```bash
cd /Volumes/Data/xcode/DashboardTV
xcodegen generate
xcodebuild -project DashboardTV.xcodeproj -scheme DashboardTV -destination 'generic/platform=tvOS' -configuration Release build
```

## License

MIT License - See LICENSE file for details.

## Author

Jordan Koch (kochj23)

---

> **Disclaimer:** This is a personal project created on my own time. It is not affiliated with, endorsed by, or representative of my employer.

## Nova / Claude API Integration

This app exposes a local HTTP API on port **37429** for integration with [Nova](https://github.com/kochj23) (OpenClaw AI) and Claude Code.

**Platform:** tvOS  
**Auth:** `X-Nova-Token` header required for tvOS requests.

### Standard Endpoints

```bash
curl http://127.0.0.1:37429/api/status   # App status + uptime
curl http://127.0.0.1:37429/api/ping     # Health check
```

### App-Specific Endpoints

```
/api/status
/api/ping
```

### Usage Example

```bash
# Check if running
curl -s http://127.0.0.1:37429/api/status | python3 -m json.tool

# From Nova (OpenClaw TUI)
# Nova has this pre-authorized and will use these endpoints automatically
```

The API server starts automatically when the app launches and binds to loopback only — no external network exposure.

