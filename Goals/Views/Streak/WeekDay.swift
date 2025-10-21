//
//  WeekDay.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//
import SwiftUI

enum DayState
{
    case none
    case progress
    case completed
}

struct WeekDay: View
{
    let name: String
    var state: DayState = .none
    
    var body: some View
    {
        Text(name)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(fillColor.opacity(fillOpacity))
                    .overlay(
                        Circle()
                            .stroke(strokeColor, lineWidth: 1.2)
                    )
            )
    }
    
    private var fillColor: Color
    {
        switch state
        {
        case .none: return .clear
        case .progress: return .primary
        case .completed: return .accentColor
        }
    }

    private var fillOpacity: Double
    {
        switch state
        {
        case .none: return 0
        case .progress: return 0.12
        case .completed: return 0.28
        }
    }

    private var strokeColor: Color
    {
        switch state
        {
        case .completed:
            return Color.accentColor.opacity(0.6)
        default:
            return Color.primary.opacity(0.25)
        }
    }
}

#Preview("Dark")
{
    WeekDay(name: "M", state: .completed)
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    WeekDay(name: "M", state: .completed)
        .preferredColorScheme(.light)
}
