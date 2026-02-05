//
//  TopShelfDataManager.swift
//  DashboardTV
//
//  Created by Jordan Koch
//  Manages data sharing between the main app and Top Shelf extension
//

import Foundation
import TVServices

/// Manages data synchronization between the main app and the Top Shelf extension
final class TopShelfDataManager {

    // MARK: - Singleton
    static let shared = TopShelfDataManager()

    // MARK: - Constants
    private let appGroupIdentifier = "group.com.jordankoch.dashboardtv"

    private enum Keys {
        static let currentDashboardURL = "currentDashboardURL"
        static let rotationEnabled = "rotationEnabled"
        static let savedDashboards = "savedDashboards"
        static let lastUpdateTime = "topShelfLastUpdateTime"
    }

    // MARK: - Properties
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Public Methods

    /// Updates the currently displayed dashboard URL
    func updateCurrentDashboard(_ url: String?) {
        sharedDefaults?.set(url, forKey: Keys.currentDashboardURL)
        notifyTopShelfUpdate()
    }

    /// Updates the rotation enabled status
    func updateRotationStatus(_ enabled: Bool) {
        sharedDefaults?.set(enabled, forKey: Keys.rotationEnabled)
        notifyTopShelfUpdate()
    }

    /// Updates the saved dashboards list
    func updateSavedDashboards(_ dashboards: [Dashboard]) {
        if let data = try? JSONEncoder().encode(dashboards) {
            sharedDefaults?.set(data, forKey: Keys.savedDashboards)
        }
        notifyTopShelfUpdate()
    }

    /// Notifies the system that Top Shelf content has changed
    func notifyTopShelfUpdate() {
        TVTopShelfContentProvider.topShelfContentDidChange()
    }

    /// Clears all Top Shelf data
    func clearTopShelfData() {
        sharedDefaults?.removeObject(forKey: Keys.currentDashboardURL)
        sharedDefaults?.set(false, forKey: Keys.rotationEnabled)
        sharedDefaults?.removeObject(forKey: Keys.savedDashboards)
        notifyTopShelfUpdate()
    }

    // MARK: - Convenience Methods

    /// Call when dashboard configuration changes
    func onConfigurationChanged(currentURL: String?, rotation: Bool, dashboards: [Dashboard]) {
        updateCurrentDashboard(currentURL)
        updateRotationStatus(rotation)
        updateSavedDashboards(dashboards)
    }

    /// Call when a dashboard is selected
    func onDashboardSelected(_ url: String) {
        updateCurrentDashboard(url)
    }

    /// Call when rotation is toggled
    func onRotationToggled(_ enabled: Bool) {
        updateRotationStatus(enabled)
    }
}

// MARK: - Dashboard Model (shared with Top Shelf)

struct Dashboard: Codable {
    let name: String
    let url: String

    init(name: String, url: String) {
        self.name = name
        self.url = url
    }
}
