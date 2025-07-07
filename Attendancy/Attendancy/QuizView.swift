//
//  QuizView.swift
//  Attendancy
//
//  Created by Don on 4/21/25.
//
import SwiftUI

struct QuizView: View {
    let attendeeName: String
    @Binding var hasResponded: Bool
    @Binding var selectedButton: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select your answer")
                .font(.title)
                .padding()
            
            if hasResponded {
                Text("Your response: \(selectedButton)")
                    .font(.title2)
                    .padding()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .background(getColorForResponse(selectedButton))
                    .cornerRadius(10)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    Button(action: {
                        selectAnswer("A")
                    }) {
                        Text("A")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        selectAnswer("B")
                    }) {
                        Text("B")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        selectAnswer("C")
                    }) {
                        Text("C")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .background(Color.yellow)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        selectAnswer("D")
                    }) {
                        Text("D")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
    }
    
    private func selectAnswer(_ answer: String) {
        selectedButton = answer
        hasResponded = true
        
        // Send the response to the host
        WebSocketClient.shared.submitResponse(name: attendeeName, response: answer)
    }
    
    // Helper function to get color based on response
    private func getColorForResponse(_ response: String) -> Color {
        switch response {
        case "A":
            return Color.red
        case "B":
            return Color.blue
        case "C":
            return Color.yellow
        case "D":
            return Color.green
        default:
            return Color.gray
        }
    }
}
