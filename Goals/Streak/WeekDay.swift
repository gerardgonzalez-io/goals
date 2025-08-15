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
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(isSelected ? .white.opacity(0.18) : .clear)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.25), lineWidth: 1.2)
                    )
            )
    }
}

#Preview
{
    WeekDay(name: "M", isSelected: true)
}
