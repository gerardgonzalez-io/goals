//
//  Theme.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 09-12-24.
//

import SwiftUI

enum Theme: String, CaseIterable, Identifiable, Codable {

    case bubblegum
    case buttercup
    case customIndigo
    case lavender
    case customMagenta
    case navy
    case customOrange
    case oxblood
    case periwinkle
    case poppy
    case customPurple
    case seafoam
    case sky
    case tan
    case customTeal
    case customYellow
    case kingblue
    case goldenYellow
    case deepNavy
    
    var accentColor: Color {
        switch self {
        case .bubblegum, .buttercup, .lavender, .customOrange, .periwinkle, .poppy, .seafoam, .sky, .tan, .customTeal, .customYellow, .goldenYellow: return .black
        case .customIndigo, .customMagenta, .navy, .oxblood, .customPurple, .kingblue, .deepNavy : return .white
        }
    }
    var mainColor: Color {
        Color(rawValue)
    }
    var name: String {
        rawValue.capitalized
    }
    var displayName: String {
        // Define custom name replacements
        let replacements: [String: String] = [
            "customOrange": "Orange",
            "customIndigo": "Indigo",
            "customMagenta": "Magenta",
            "customPurple": "Purple",
            "customTeal": "Teal",
            "customYellow": "Yellow",
            "deepNavy": "Deep Navy",
            "goldenYellow": "Golden Yellow"
        ]

        // Return the custom display name if a replacement exists; otherwise, use the default name
        return replacements[rawValue] ?? name
    }
    var id: String {
        name
    }
}
