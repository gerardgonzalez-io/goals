//
//  StreakView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 11-08-25.
//


import SwiftUI

struct StreakView: View
{
    // Be careful, this always have to be between 0.0 and 1.0
    // Do this validation before pass this value to this struct
    // Validate if it is necessary to create this variable like an @State of the view
    @State private var progress: CGFloat = 0.5 // 0.0 a 1.0
    private let goalMinutes = 50

    var body: some View
    {
        VStack(spacing: 30)
        {
            Spacer()

            VStack(spacing: 8)
            {
                Text("Study Goal")
                    .font(.system(.title).bold())
                    .foregroundStyle(.primary)
                
                Text("Track your time, stay focused, and achieve your daily study goals.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 8)

            ZStack
            {
                //Background Arc
                SemiRing()
                    .stroke(lineWidth: 9)
                    .foregroundStyle(.quaternary)
                    .frame(width: 300, height: 150)

                //Progress Arc
                SemiRing()
                    .trim(from: 0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .foregroundStyle(.tint.opacity(0.6))
                    .frame(width: 300, height: 150)
                    .animation(.easeInOut(duration: 0.8), value: progress)
                
                VStack
                {
                    Text("Today’s Session")
                        .font(.callout).bold()
                        .foregroundStyle(.primary)
                        .opacity(0.85)
                    
                    Text("0:00")
                        .font(.system(size: 60, weight: .light, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 4)
                    {
                        Text("of your \(goalMinutes)-minute goal")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .offset(y: 16)
            }

            WeekRow()

            VStack(spacing: 4)
            {
                HStack(spacing: 6)
                {
                    Text("Start a new streak.")
                        .font(.callout.weight(.semibold))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.primary)
                
                Text("Your record is 9 days.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            // Chek if this Spacer() is really necessary
            Spacer()
        }
    }
}

struct SemiRing: Shape
{
    func path(in rect: CGRect) -> Path
    {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

#Preview("Dark")
{
    StreakView()
        .preferredColorScheme(.dark)
}

#Preview("Light")
{
    StreakView()
        .preferredColorScheme(.light)
}

