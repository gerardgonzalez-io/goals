//
//  WeekRow.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 11-08-25.
//

import SwiftUI

struct WeekRow: View
{
    let days: [String] = ["M", "T", "W", "T", "F", "S", "S"]
    var isSelected: [Bool] = [true, true, true, true, false, false, false]
    
    var body: some View
    {
        HStack(spacing: 18)
        {
            ForEach(days.indices, id: \.self)
            { index in
                WeekDay(name: days[index], isSelected: isSelected[index])
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 22)
    }
}

#Preview("Dark")
{
    WeekRow()
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    WeekRow()
        .preferredColorScheme(.light)
}
