
//
//  AttendanceWebsocket.swift
//  Attendancy
//
//  Created by Don on 2/26/25.
//
import SwiftUI
import CoreImage.CIFilterBuiltins

struct TakeAttendanceView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var generatedCode = ""
    @State private var navigateToWebsocket = false
    @State private var isGeneratingCode = false
    @State private var showCodeView = false
    @State private var isStartingSession = false
    @State private var sessionStarted = false
    @State private var sessionEnded = false
    @State private var hostDisplayMessage = ""
    @State private var attendeeResponses: [String: String] = [:] // Name: Response status
    @State private var showShareSheet = false
    @State private var responseCSV: String = ""
    @State private var showQuestionOptions = false
    @State private var selectedQuestion = "Kahoot-style Quiz"
    @State private var correctAnswer = "A"
    @State private var timeLimit = 30
    @State private var showTimeUpAlert = false
    @State private var timeRemaining = 0
    
    let questionOptions = ["Kahoot-style Quiz"]
    let answerOptions = ["A", "B", "C", "D"]
    let timeLimitOptions = [10, 20, 30, 60, 120]
    
    var body: some View {
        VStack {
            Text("Take Attendance")
                .font(.largeTitle)
                .padding(.top, 30)
            
            Spacer()
            
            if showCodeView {
                // Show generated code view
                VStack(spacing: 25) {
                    if sessionStarted {
                        Text(sessionEnded ? "Session Ended" : "Session Active")
                            .font(.headline)
                            .foregroundColor(sessionEnded ? .red : .green)
                        
                        Text(hostDisplayMessage)
                            .font(.system(size: 80, weight: .bold))
                            .padding()
                        
                        if !sessionEnded {
                            // Show countdown timer
                            Text("Time remaining: \(timeRemaining)s")
                                .font(.title2)
                                .foregroundColor(timeRemaining <= 10 ? .red : .primary)
                                .padding()
                        }
                        
                        Text("Session Code: \(generatedCode)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            
                        // Show attendee responses
                        if !attendeeResponses.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Attendee Responses:")
                                    .font(.headline)
                                    .padding(.top)
                                
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(attendeeResponses.sorted(by: { $0.key < $1.key }), id: \.key) { name, response in
                                            HStack {
                                                Text(name)
                                                    .fontWeight(.medium)
                                                Spacer()
                                                Text(response)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(getColorForResponse(response))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(8)
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                    .padding()
                                }
                                .frame(height: 200)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding()
                        }
                        
                        // Session management buttons
                        HStack(spacing: 20) {
                            if !sessionEnded {
                                Button(action: {
                                    endSession()
                                }) {
                                    Text("End Session")
                                        .font(.headline)
                                        .padding()
                                        .frame(width: 150)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            
                            if sessionEnded && !attendeeResponses.isEmpty {
                                Button(action: {
                                    prepareAndShareResponses()
                                }) {
                                    Text("Share Results")
                                        .font(.headline)
                                        .padding()
                                        .frame(width: 150)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.top, 10)
                        
                    } else {
                        Text("Attendance Code")
                            .font(.headline)
                        
                        // QR Code visualization
                        QRCodeView(code: generatedCode)
                            .frame(width: 200, height: 200)
                            .padding(.vertical, 10)
                        
                        Text(generatedCode)
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .padding()
                            .frame(width: 280, height: 80)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        
                        Text("Share this code with attendees")
                            .font(.subheadline)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                UIPasteboard.general.string = generatedCode
                            }) {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                // Share code functionality
                                let activityController = UIActivityViewController(
                                    activityItems: ["Join my attendance session with code: \(generatedCode)"],
                                    applicationActivities: nil
                                )
                                
                                // Get the root view controller
                                if let windowScene = UIApplication.shared.connectedScenes
                                    .filter({ $0.activationState == .foregroundActive })
                                    .first as? UIWindowScene,
                                   let rootViewController = windowScene.windows.first?.rootViewController {
                                    rootViewController.present(activityController, animated: true)
                                }
                            }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical)
                        
                        Button(action: {
                            showQuestionOptions = true
                        }) {
                            HStack {
                                if isStartingSession {
                                    ProgressView()
                                        .padding(.trailing, 10)
                                }
                                
                                Text(isStartingSession ? "Starting..." : "Start Session")
                                    .font(.headline)
                            }
                            .frame(width: 200, height: 50)
                            .background(isStartingSession ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isStartingSession)
                    }
                    
                    Button(action: {
                        // Reset to generate new code
                        showCodeView = false
                        generatedCode = ""
                        sessionStarted = false
                        sessionEnded = false
                        hostDisplayMessage = ""
                        attendeeResponses.removeAll()
                    }) {
                        Text("Generate New Code")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal)
            } else {
                // Show generate code button
                VStack(spacing: 20) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 100))
                        .foregroundColor(.blue)
                        .padding(.bottom, 20)
                    
                    Text("Generate a unique code for attendance")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        generateAttendanceCode()
                    }) {
                        HStack {
                            if isGeneratingCode {
                                ProgressView()
                                    .padding(.trailing, 10)
                            }
                            
                            Text(isGeneratingCode ? "Generating..." : "Generate Code")
                                .font(.headline)
                        }
                        .frame(width: 200, height: 50)
                        .background(isGeneratingCode ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isGeneratingCode)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(false)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        })
        .onAppear {
            // Set up attendee response notification
            NotificationCenter.default.addObserver(
                forName: Notification.Name("AttendeeResponse"),
                object: nil,
                queue: .main
            ) { [self] notification in
                if let userInfo = notification.userInfo,
                   let name = userInfo["attendeeName"] as? String,
                   let response = userInfo["response"] as? String {
                    self.attendeeResponses[name] = response
                }
            }
            
            // Set up time update notification
            NotificationCenter.default.addObserver(
                forName: Notification.Name("TimeUpdate"),
                object: nil,
                queue: .main
            ) { [self] notification in
                if let userInfo = notification.userInfo,
                   let remaining = userInfo["timeRemaining"] as? Int {
                    self.timeRemaining = remaining
                }
            }
            
            // Set up time up notification
            NotificationCenter.default.addObserver(
                forName: Notification.Name("TimeUp"),
                object: nil,
                queue: .main
            ) { [self] _ in
                self.showTimeUpAlert = true
            }
        }
        .onDisappear {
            // Remove notification observers
            NotificationCenter.default.removeObserver(self)
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: [responseCSV])
        }
        .alert("Question Options", isPresented: $showQuestionOptions) {
            VStack {
                Picker("Question Type", selection: $selectedQuestion) {
                    ForEach(questionOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                
                Picker("Correct Answer", selection: $correctAnswer) {
                    ForEach(answerOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                
                Picker("Time Limit (seconds)", selection: $timeLimit) {
                    ForEach(timeLimitOptions, id: \.self) { option in
                        Text("\(option)").tag(option)
                    }
                }
                
                Button("Start") {
                    startSession()
                }
                
                Button("Cancel", role: .cancel) { }
            }
        }
        .alert("Time's Up!", isPresented: $showTimeUpAlert) {
            Button("End Session", role: .destructive) {
                endSession()
            }
        } message: {
            Text("The time limit has been reached. Would you like to end the session now?")
        }
    }
    
    // Function to generate attendance code
    private func generateAttendanceCode() {
        isGeneratingCode = true
        
        Task {
            do {
                // Call the API to generate a code
                let code = try await APIClient.shared.generateAttendanceCode()
                
                // Add to valid codes list
                WebSocketClient.shared.addValidCode(code)
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.generatedCode = code
                    self.isGeneratingCode = false
                    self.showCodeView = true
                }
            } catch {
                // Handle errors
                print("Error generating code: \(error)")
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.isGeneratingCode = false
                    // You could show an alert here
                }
            }
        }
    }
    
    // Function to start the session
    private func startSession() {
        isStartingSession = true
        
        Task {
            do {
                // Call API to start the session
                let result = try await APIClient.shared.startSession(code: generatedCode)
                
                DispatchQueue.main.async {
                    self.isStartingSession = false
                    self.sessionStarted = true
                    self.hostDisplayMessage = result.display
                    self.timeRemaining = self.timeLimit
                    
                    // Tell WebSocketClient to start the session
                    WebSocketClient.shared.startSession(withCorrectAnswer: self.correctAnswer, timeLimit: self.timeLimit)
                }
            } catch {
                print("Error starting session: \(error)")
                
                DispatchQueue.main.async {
                    self.isStartingSession = false
                }
            }
        }
    }
    
    // Function to end the session
    private func endSession() {
        sessionEnded = true
        
        // Tell WebSocketClient to end the session
        WebSocketClient.shared.endSession()
        
        // Get all responses for export
        attendeeResponses = WebSocketClient.shared.getAttendeeResponses()
    }
    
    // Function to prepare and share responses
    private func prepareAndShareResponses() {
        // Create CSV data
        var csvString = "Name,Response\n"
        
        for (name, response) in attendeeResponses.sorted(by: { $0.key < $1.key }) {
            csvString.append("\(name),\(response)\n")
        }
        
        // Set CSV for sharing
        responseCSV = csvString
        
        // Show share sheet
        showShareSheet = true
    }
    
    // Helper function to get color based on response
    private func getColorForResponse(_ response: String) -> Color {
        switch response {
        case "Correct":
            return Color.green
        case "Wrong":
            return Color.red
        case "Missing":
            return Color.orange
        default:
            return Color.gray
        }
    }
}

// Activity View Controller for sharing
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}
