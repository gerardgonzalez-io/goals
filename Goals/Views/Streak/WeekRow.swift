//
//  WeekRow.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI

struct WeekRow: View
{
    let days: [String]
    let states: [DayState] // size 7
    
    var body: some View
    {
        HStack(spacing: 18)
        {
            ForEach(days.indices, id: \.self)
            { index in
                WeekDay(name: days[index], state: states[index])
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 22)
    }
}

#Preview("Dark")
{
    let days = ["M","T","W","T","F","S","S"]
    let states: [DayState] = [.progress, .progress, .completed, .none, .none, .none, .none]
    return WeekRow(days: days, states: states)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    let days = ["M","T","W","T","F","S","S"]
    let states: [DayState] = [.progress, .progress, .completed, .none, .none, .none, .none]
    return WeekRow(days: days, states: states)
        .preferredColorScheme(.light)
}

