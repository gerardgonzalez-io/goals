//
//  WelcomePage.swift
//  GoalsV2
//
//  Created by Adolfo Gerard Montilla Gonzalez on 17-10-25.
//

import SwiftUI

struct WelcomePage: View
{
    var body: some View
    {
        VStack
        {
            ZStack
            {
                RoundedRectangle(cornerRadius: 30)
                    .frame(width: 150, height: 150)
                    .foregroundStyle(.tint)

                Image(systemName: "checkmark.arrow.trianglehead.counterclockwise")
                    .font(.system(size: 70))
                    .foregroundStyle(.white)
            }
            
            Text("Welcome to Goals")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.top)
            
            Text("Track your progress, stay focused, and build discipline.")
                .font(.title2)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview
{
    WelcomePage()
}
