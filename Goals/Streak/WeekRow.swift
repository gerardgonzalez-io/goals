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
    var selectedIndex: Int = 0
    
    var body: some View
    {
        HStack(spacing: 18)
        {
            ForEach(days.indices, id: \.self)
            { index in
                WeekDay(name: days[index], isSelected: index == selectedIndex)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 22)
    }
}

#Preview
{
    WeekRow()
}
