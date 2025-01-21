//
//  GoalsProgressViewStyle.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-12-24.
//

import SwiftUI

struct GoalsProgressViewStyle: ProgressViewStyle {
    var theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(theme.accentColor)
                .frame(height: 20.0)
            if #available(iOS 15.0, *) {
                ProgressView(configuration)
                    .tint(theme.mainColor)
                    .frame(height: 12.0)
                    .padding(.horizontal)
            } else {
                ProgressView(configuration)
                    .frame(height: 12.0)
                    .padding(.horizontal)
            }
        }
    }
}


#Preview {
    ProgressView(value: 0.5)
        .progressViewStyle(GoalsProgressViewStyle(theme: .goldenYellow))
}
