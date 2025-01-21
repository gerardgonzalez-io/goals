//
//  ThemePicker.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 21-01-25.
//
import SwiftUI

struct ThemePicker: View {
    @Binding var selection: Theme
    
    var body: some View {
        Picker("Theme", selection: $selection) {
            ForEach(Theme.allCases) { theme in
                ThemeView(theme: theme)
                    .tag(theme)
            }
        }
        .pickerStyle(.navigationLink)
    }
}

#Preview {
    ThemePicker(selection: .constant(.goldenYellow))
}
