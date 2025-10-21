//
//  GoalMinutesPickerSheet.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI

struct GoalMinutesPickerSheet: View
{
    @Binding var selectedMinutes: Int
    var onDone: () -> Void

    private let range = Array(1...240)

    var body: some View
    {
        NavigationStack
        {
            VStack(spacing: 0)
            {
                // Wheel-style picker
                Picker("Minutes", selection: $selectedMinutes)
                {
                    ForEach(range, id: \.self)
                    { minute in
                        Text("\(minute)")
                            .font(.title2)
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.horizontal)

                Spacer(minLength: 12)
            }
            .navigationTitle("Daily Study Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar
            {
                ToolbarItem(placement: .topBarTrailing)
                {
                    Button("Done")
                    {
                        onDone()
                    }
                }
            }
        }
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
    }
}


#Preview
{
    GoalMinutesPickerSheet(selectedMinutes: .constant(30)) {}
}
