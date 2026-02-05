//
//  ContentProvider.swift
//  DashboardTVTopShelf
//
//  Created by Jordan Koch
//

import TVServices

class ContentProvider: TVTopShelfContentProvider {

    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        // Load dashboard configuration
        let dashboardConfig = loadDashboardConfig()

        var items: [TVTopShelfSectionedItem] = []

        // Current dashboard item
        if let currentURL = dashboardConfig.currentDashboardURL {
            let currentItem = TVTopShelfSectionedItem(identifier: "current")
            currentItem.title = "Current: \(currentURL)"
            if let url = URL(string: "dashboardtv://current") {
                currentItem.displayAction = TVTopShelfAction(url: url)
                currentItem.playAction = TVTopShelfAction(url: url)
            }
            items.append(currentItem)
        }

        // Toggle rotation item
        let rotationItem = TVTopShelfSectionedItem(identifier: "rotation")
        rotationItem.title = dashboardConfig.rotationEnabled ? "Pause Rotation" : "Start Rotation"
        if let url = URL(string: "dashboardtv://toggle-rotation") {
            rotationItem.displayAction = TVTopShelfAction(url: url)
            rotationItem.playAction = TVTopShelfAction(url: url)
        }
        items.append(rotationItem)

        // Dashboard URLs
        for (index, dashboard) in dashboardConfig.dashboards.prefix(5).enumerated() {
            let item = TVTopShelfSectionedItem(identifier: "dashboard_\(index)")
            item.title = dashboard.name.isEmpty ? "Dashboard \(index + 1)" : dashboard.name
            if let url = URL(string: "dashboardtv://show/\(index)") {
                item.displayAction = TVTopShelfAction(url: url)
                item.playAction = TVTopShelfAction(url: url)
            }
            items.append(item)
        }

        // Settings item
        let settingsItem = TVTopShelfSectionedItem(identifier: "settings")
        settingsItem.title = "Settings"
        if let url = URL(string: "dashboardtv://settings") {
            settingsItem.displayAction = TVTopShelfAction(url: url)
        }
        items.append(settingsItem)

        // Create sections
        var sections: [TVTopShelfItemCollection<TVTopShelfSectionedItem>] = []

        // Status section
        let statusSection = TVTopShelfItemCollection(items: Array(items.prefix(2)))
        statusSection.title = "DashboardTV"
        sections.append(statusSection)

        // Dashboards section
        let dashboardItems = items.filter { $0.identifier.starts(with: "dashboard_") }
        if !dashboardItems.isEmpty {
            let dashboardsSection = TVTopShelfItemCollection(items: dashboardItems)
            dashboardsSection.title = "Saved Dashboards"
            sections.append(dashboardsSection)
        }

        let content = TVTopShelfSectionedContent(sections: sections)
        completionHandler(content)
    }

    private func loadDashboardConfig() -> DashboardConfig {
        let userDefaults = UserDefaults(suiteName: "group.com.jordankoch.dashboardtv")

        let currentURL = userDefaults?.string(forKey: "currentDashboardURL")
        let rotationEnabled = userDefaults?.bool(forKey: "rotationEnabled") ?? false

        var dashboards: [Dashboard] = []
        if let data = userDefaults?.data(forKey: "savedDashboards"),
           let saved = try? JSONDecoder().decode([Dashboard].self, from: data) {
            dashboards = saved
        }

        return DashboardConfig(
            currentDashboardURL: currentURL,
            rotationEnabled: rotationEnabled,
            dashboards: dashboards
        )
    }
}

// MARK: - Dashboard Config Model
struct DashboardConfig {
    let currentDashboardURL: String?
    let rotationEnabled: Bool
    let dashboards: [Dashboard]
}

struct Dashboard: Codable {
    let name: String
    let url: String
}
