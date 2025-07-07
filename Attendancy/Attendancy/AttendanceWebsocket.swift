
//
//  AttendanceWebsocket.swift
//  Attendancy
//
//  Created by Don on 2/26/25.
//

import SwiftUI

struct AttendanceWebsocket: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var attendees: [String: String] = [:] // Name: Button selected
    @State private var connectionStatus = "Connecting..."
    @State private var statusColor: Color = .orange
    @State private var displayMessage = ""
    @State private var errorMessage = ""
    @State private var retryCount = 0
    @State private var showErrorAlert = false
    @State private var showNamePrompt = false
    @State private var attendeeName = "Anonymous"
    @State private var showQuizView = false
    @State private var hasResponded = false
    @State private var selectedButton = ""
    @State private var timeRemaining = 0
    @State private var showLeaveConfirmation = false
    
    let sessionCode: String
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Attendance Session")
                .font(.largeTitle)
                .padding(.top, 30)
            
            Divider()
            
            if connectionStatus == "Session closed by host" {
                // Show session closed view
                VStack(alignment: .center, spacing: 20) {
                    Text(connectionStatus)
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    Text("Thank you for participating!")
                        .font(.title3)
                        .padding()
                    
                    if hasResponded {
                        Text("Your response: \(selectedButton)")
                            .font(.headline)
                            .padding()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .background(getColorForResponse(selectedButton))
                            .cornerRadius(10)
                            .padding()
                    }
                    
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 100))
                        .foregroundColor(.green)
                        .padding()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGray5).opacity(0.3))
                .cornerRadius(12)
                .padding()
            } else if showQuizView && connectionStatus == "Connected" && WebSocketClient.shared.isSessionStarted() {
                // Kahoot-style quiz view for attendees
                VStack(spacing: 20) {
                    Text("Select your answer")
                        .font(.title)
                        .padding()
                    
                    // Show time remaining
                    Text("Time remaining: \(timeRemaining)s")
                        .font(.title3)
                        .foregroundColor(timeRemaining <= 10 ? .red : .primary)
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
            } else {
                VStack(alignment: .center, spacing: 20) {
                    Text(connectionStatus)
                        .font(.title2)
                        .foregroundColor(statusColor)
                    
                    Text("Session ID: \(sessionCode)")
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    
                    if displayMessage.isEmpty {
                        // Activity indicator
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    } else {
                        Text(displayMessage)
                            .font(.system(size: 80, weight: .bold))
                            .padding()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGray5).opacity(0.3))
                .cornerRadius(12)
                .padding()
            }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Display connected status
            Text("WebSocket: \(connectionStatus == "Connected" ? "Active" : connectionStatus)")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            HStack(spacing: 20) {
                if connectionStatus != "Connected" && connectionStatus != "Session closed by host" && retryCount < 3 {
                    Button(action: {
                        retryCount += 1
                        connectToWebSocket()
                    }) {
                        Text("Retry Connection")
                            .font(.headline)
                            .padding()
                            .frame(width: 180)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Button(action: {
                    // Show leave confirmation before disconnecting
                    showLeaveConfirmation = true
                }) {
                    Text("Disconnect")
                        .font(.headline)
                        .padding()
                        .frame(width: 180)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            // Show leave confirmation before dismissing
            showLeaveConfirmation = true
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        })
        .onAppear {
            // Show name prompt when connecting
            showNamePrompt = true
            
            // Get the initial session state
            checkSessionState()
            
            // Connect to WebSocket when view appears
            connectToWebSocket()
            
            // Listen for notifications
            setupNotifications()
        }
        .onDisappear {
            // Disconnect when view disappears
            WebSocketClient.shared.disconnect()
            
            // Remove notification observers
            NotificationCenter.default.removeObserver(self)
        }
        .alert("Connection Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
            Button("Retry") {
                retryCount += 1
                connectToWebSocket()
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Enter Your Name", isPresented: $showNamePrompt) {
            TextField("Your Name", text: $attendeeName)
            
            Button("Join") {
                if attendeeName.isEmpty {
                    attendeeName = "Anonymous"
                }
            }
        } message: {
            Text("Please enter your name to join the session")
        }
        .alert("Leave Session", isPresented: $showLeaveConfirmation) {
            Button("Stay", role: .cancel) {}
            Button("Leave", role: .destructive) {
                // Properly close the websocket connection before dismissing
                WebSocketClient.shared.disconnect()
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to leave this session?")
        }
    }
    
    private func checkSessionState() {
        Task {
            do {
                // First validate the code to get current session state
                let validationResult = try await APIClient.shared.validateCode(code: sessionCode)
                
                if validationResult.valid {
                    // Then join the session to get display message
                    print("Session code is valid, joining session...")
                    let joinResult = try await APIClient.shared.joinSession(withCode: sessionCode, attendeeName: attendeeName)
                    
                    if joinResult.success {
                        DispatchQueue.main.async {
                            if joinResult.status == "ACTIVE" {
                                self.connectionStatus = "Connected"
                                self.statusColor = .green
                                if let display = joinResult.display {
                                    self.displayMessage = display  // Should be "321" for attendees
                                    self.showQuizView = WebSocketClient.shared.isSessionStarted()
                                }
                            } else {
                                self.connectionStatus = "Waiting for host..."
                                self.statusColor = .orange
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.connectionStatus = "Failed to join"
                            self.statusColor = .red
                            self.errorMessage = joinResult.message
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.connectionStatus = "Invalid Session"
                        self.statusColor = .red
                        self.errorMessage = validationResult.message
                    }
                }
            } catch {
                print("Error checking session state: \(error)")
                DispatchQueue.main.async {
                    self.connectionStatus = "Connection Error"
                    self.statusColor = .red
                    self.errorMessage = "Failed to connect to server: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func connectToWebSocket() {
        print("Attempting to connect to WebSocket with code: \(sessionCode)")
        self.connectionStatus = "Connecting..."
        self.statusColor = .orange
        self.errorMessage = ""
        
        WebSocketClient.shared.connect(withSessionCode: sessionCode) { success in
            DispatchQueue.main.async {
                if success {
                    print("WebSocket connected successfully")
                    if self.displayMessage.isEmpty {
                        self.connectionStatus = "Waiting for host..."
                        self.statusColor = .orange
                    } else {
                        self.connectionStatus = "Connected"
                        self.statusColor = .green
                        self.showQuizView = WebSocketClient.shared.isSessionStarted()
                    }
                } else {
                    print("WebSocket connection failed")
                    self.connectionStatus = "Connection failed"
                    self.statusColor = .red
                    self.errorMessage = "Could not establish connection to the attendance server. Please check your internet connection and try again."
                    
                    if self.retryCount >= 3 {
                        self.errorMessage += "\n\nToo many failed attempts. There might be an issue with the server."
                    } else {
                        self.showErrorAlert = true
                    }
                }
            }
        }
    }
    
    private func setupNotifications() {
        // Listen for session status updates
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SessionStarted"),
            object: nil,
            queue: .main
        ) { notification in
            print("Received SessionStarted notification")
            self.connectionStatus = "Connected"
            self.statusColor = .green
            
            if let userInfo = notification.userInfo,
               let display = userInfo["display"] as? String {
                self.displayMessage = display  // Should be "321" for attendees
                self.showQuizView = true
            }
        }
        
        // Listen for session closure
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SessionClosed"),
            object: nil,
            queue: .main
        ) { _ in
            print("Received SessionClosed notification")
            self.connectionStatus = "Session closed by host"
            self.statusColor = .red
        }
        
        // Listen for connection errors
        NotificationCenter.default.addObserver(
            forName: Notification.Name("WebSocketError"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let errorMessage = userInfo["message"] as? String {
                self.errorMessage = errorMessage
                self.connectionStatus = "Connection Error"
                self.statusColor = .red
            }
        }
        
        // Listen for time updates
        NotificationCenter.default.addObserver(
            forName: Notification.Name("TimeUpdate"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let remaining = userInfo["timeRemaining"] as? Int {
                self.timeRemaining = remaining
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
