//
//  WeekDay.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 11-08-25.
//

import SwiftUI

struct WeekDay: View
{
    let name: String
    var isSelected: Bool = false
    
    var body: some View
    {
        Text(name)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(.primary.opacity(isSelected ? 0.12 : 0))
                    .overlay(
                        Circle()
                            .stroke(.primary.opacity(0.25), lineWidth: 1.2)
                    )
            )
    }
}

#Preview("Dark")
{
    WeekDay(name: "M", isSelected: true)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    WeekDay(name: "M", isSelected: true)
        .preferredColorScheme(.light)
}
