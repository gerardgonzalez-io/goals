//
//  FocusSessionHeaderView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 18-12-24.
//

import SwiftUI

struct FocusSessionHeaderView: View {
    let secondsElapsed: Int
    let secondsRemaining: Int
    let theme: Theme

    private var totalSeconds: Int {
        secondsElapsed + secondsRemaining
    }

    private var progress: Double {
        guard totalSeconds > 0 else { return 1 }
        return Double(secondsElapsed) / Double(totalSeconds)
    }
    private var minutesRemaining: Int {
        secondsRemaining / 60
    }

    var body: some View {
        VStack {
            ProgressView(value: progress)
                .progressViewStyle(GoalsProgressViewStyle(theme: theme))
            HStack {
                VStack(alignment: .leading) {
                    Text("Seconds Elapsed")
                        .font(.caption)
                    Label("\(secondsElapsed)", systemImage: "hourglass.tophalf.fill")
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Seconds Remaining")
                        .font(.caption)
                    Label("\(secondsRemaining)", systemImage: "hourglass.bottomhalf.fill")
                        .labelStyle(.trailingIcon)
                }
            }
        }
        .padding([.top, .horizontal])
    }
}

#Preview {
    FocusSessionHeaderView(secondsElapsed: 60, secondsRemaining: 80, theme: .goldenYellow)
}
