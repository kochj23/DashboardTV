# DashboardTV

tvOS companion app for Dashboard Screensaver. Displays dashboard URLs on Apple TV devices, configured remotely from the macOS Dashboard Screensaver app.

## Features

- **Remote Configuration** - Receive dashboard URLs from macOS app via Bonjour/HTTP
- **Dashboard Rotation** - Automatically cycle through configured dashboards
- **Siri Remote Control** - Play/Pause to toggle rotation, Left/Right to navigate
- **IP Address Display** - Shows device IP for easy configuration
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
