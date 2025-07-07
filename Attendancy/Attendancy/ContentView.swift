//
//  ContentView.swift
//  Attendancy
//
//  Created by Don on 2/26/25.
//

import SwiftUI

struct ContentView: View {
    @State private var navigateToTakeAttendance = false
    @State private var navigateToAttend = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Attendancy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Button(action: {
                        navigateToTakeAttendance = true
                    }) {
                        Text("Take Attendance")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(width: 250, height: 60)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        navigateToAttend = true
                    }) {
                        Text("Attend")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(width: 250, height: 60)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .background(
                NavigationLink(
                    destination: TakeAttendanceView(),
                    isActive: $navigateToTakeAttendance
                ) {
                    EmptyView()
                }
            )
            .background(
                NavigationLink(
                    destination: AttendView(),
                    isActive: $navigateToAttend
                ) {
                    EmptyView()
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
