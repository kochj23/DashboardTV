//
//  PlatformHelpers.swift
//  DashboardTV
//
//  Platform-specific helpers for tvOS and iOS (iPad)
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Platform Detection

#if os(tvOS)
let isTV = true
let isiOS = false
#elseif os(iOS)
let isTV = false
let isiOS = true
#else
let isTV = false
let isiOS = false
#endif

// MARK: - Platform Constants

struct PlatformConstants {
    static var isiPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }

    /// Font size scale factor
    static var fontScale: CGFloat {
        isTV ? 1.5 : 1.0
    }

    /// Padding scale factor
    static var paddingScale: CGFloat {
        isTV ? 2.0 : 1.0
    }

    /// Corner radius for cards
    static var cornerRadius: CGFloat {
        isTV ? 20 : 12
    }
}

// MARK: - Platform-Adaptive Font

extension Font {
    static func platformTitle() -> Font {
        .system(size: isTV ? 48 : 28, weight: .bold, design: .rounded)
    }

    static func platformHeadline() -> Font {
        .system(size: isTV ? 36 : 22, weight: .semibold, design: .rounded)
    }

    static func platformBody() -> Font {
        .system(size: isTV ? 24 : 17)
    }

    static func platformCaption() -> Font {
        .system(size: isTV ? 18 : 14)
    }
}

// MARK: - Platform View Modifiers

extension View {
    /// Apply platform-specific padding
    func platformPadding(_ edges: Edge.Set = .all, _ amount: CGFloat = 16) -> some View {
        self.padding(edges, amount * PlatformConstants.paddingScale)
    }

    /// Apply glassmorphic background
    func glassBackground() -> some View {
        self.background(Color.black.opacity(0.5))
            .cornerRadius(PlatformConstants.cornerRadius)
    }
}
