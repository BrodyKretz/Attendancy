
//
//  WebsocketClient.swift
//  Attendancy
//
//  Created by Don on 2/27/25.
//
import Foundation

class WebSocketClient {
    static let shared = WebSocketClient()
    
    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var isConnected = false
    private var attendeeResponses: [String: String] = [:] // Name: Response status
    private var sessionStarted = false
    private var correctAnswer = ""
    private var timeLimit = 30
    private var timeRemaining = 0
    private var sessionCode = ""
    private var timer: Timer?
    
    // Real WebSocket API endpoint
    private let webSocketBaseURL = "wss://t46mhsquzl.execute-api.us-west-2.amazonaws.com/production"
    
    private init() {
        session = URLSession(configuration: .default)
    }
    
    func connect(withSessionCode code: String, completion: @escaping (Bool) -> Void) {
        // Disconnect any existing connection
        disconnect()
        
        guard let session = session else {
            completion(false)
            return
        }
        
        // Include the session code as a query parameter in the WebSocket URL
        guard var urlComponents = URLComponents(string: webSocketBaseURL) else {
            completion(false)
            return
        }
        
        // Add session code as a query parameter
        let queryItems = [URLQueryItem(name: "sessionCode", value: code)]
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            completion(false)
            return
        }
        
        print("Connecting to WebSocket with URL: \(url.absoluteString)")
        
        // Create a new WebSocket connection with the session code in the URL
        webSocket = session.webSocketTask(with: url)
        
        // Start receiving messages
        receiveMessage()
        
        // Connect to the WebSocket
        webSocket?.resume()
        
        // Session code is stored for later use
        sessionCode = code
        
        // Send join message once connected
        let joinMessage: [String: Any] = [
            "action": "joinSession",
            "sessionCode": code,
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: joinMessage)
            let message = URLSessionWebSocketTask.Message.data(data)
            
            webSocket?.send(message) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("WebSocket send error: \(error)")
                        completion(false)
                        return
                    }
                    
                    self.isConnected = true
                    completion(true)
                    print("Successfully connected to WebSocket and sent join message")
                }
            }
        } catch {
            print("Failed to serialize join message: \(error)")
            completion(false)
        }
    }
    
    func startSession(withCorrectAnswer answer: String, timeLimit: Int) {
        guard isConnected, let webSocket = webSocket else { return }
        
        self.correctAnswer = answer
        self.timeLimit = timeLimit
        self.timeRemaining = timeLimit
        self.sessionStarted = true
        
        // Send start session message
        let startMessage: [String: Any] = [
            "action": "startSession",
            "sessionCode": sessionCode,
            "correctAnswer": answer,
            "timeLimit": timeLimit,
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: startMessage)
            let message = URLSessionWebSocketTask.Message.data(data)
            
            webSocket.send(message) { error in
                if let error = error {
                    print("Error sending start session message: \(error)")
                    return
                }
                
                print("Successfully sent start session message")
                
                // Start local timer for countdown
                self.startTimer()
            }
        } catch {
            print("Failed to serialize start session message: \(error)")
        }
        
        // Notify local listeners
        NotificationCenter.default.post(
            name: Notification.Name("SessionStarted"),
            object: nil,
            userInfo: ["display": "123"]
        )
    }
    
    func submitResponse(name: String, response: String) {
        guard isConnected, let webSocket = webSocket, sessionStarted, timeRemaining > 0 else { return }
        
        // Send response message
        let responseMessage: [String: Any] = [
            "action": "submitResponse",
            "sessionCode": sessionCode,
            "data": [
                "attendeeName": name,
                "response": response
            ],
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: responseMessage)
            let message = URLSessionWebSocketTask.Message.data(data)
            
            webSocket.send(message) { error in
                if let error = error {
                    print("Error sending response message: \(error)")
                    return
                }
                
                print("Successfully sent response for \(name): \(response)")
            }
        } catch {
            print("Failed to serialize response message: \(error)")
        }
        
        // Store local copy (will be updated with correct/wrong when server responds)
        attendeeResponses[name] = "Pending"
    }
    
    func endSession() {
        guard isConnected, let webSocket = webSocket else { return }
        
        sessionStarted = false
        
        // Stop the timer
        timer?.invalidate()
        timer = nil
        
        // Send end session message
        let endMessage: [String: Any] = [
            "action": "endSession",
            "sessionCode": sessionCode,
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: endMessage)
            let message = URLSessionWebSocketTask.Message.data(data)
            
            webSocket.send(message) { error in
                if let error = error {
                    print("Error sending end session message: \(error)")
                    return
                }
                
                print("Successfully sent end session message")
            }
        } catch {
            print("Failed to serialize end session message: \(error)")
        }
        
        // Notify local listeners
        NotificationCenter.default.post(
            name: Notification.Name("SessionClosed"),
            object: nil
        )
    }
    
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        isConnected = false
        sessionStarted = false
        attendeeResponses.removeAll()
        
        // Stop the timer
        timer?.invalidate()
        timer = nil
        
        print("WebSocket disconnected")
    }
    
    private func startTimer() {
        timeRemaining = timeLimit
        
        // Create a timer to count down
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                
                // Notify time update
                NotificationCenter.default.post(
                    name: Notification.Name("TimeUpdate"),
                    object: nil,
                    userInfo: ["timeRemaining": self.timeRemaining]
                )
            } else {
                // Time is up
                self.timer?.invalidate()
                self.timer = nil
                
                // Notify that time is up
                NotificationCenter.default.post(
                    name: Notification.Name("TimeUp"),
                    object: nil
                )
            }
        }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                print("Received WebSocket message")
                self.handleMessage(message)
                
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self.isConnected = false
                
                // Notify about the error
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: Notification.Name("WebSocketError"),
                        object: nil,
                        userInfo: ["message": error.localizedDescription]
                    )
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            print("Received data message: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
            handleJsonData(data)
            
        case .string(let string):
            print("Received string message: \(string)")
            if let data = string.data(using: .utf8) {
                handleJsonData(data)
            }
            
        @unknown default:
            print("Unknown message type received")
        }
    }
    
    private func handleJsonData(_ data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Parsed JSON: \(json)")
                
                let eventType = json["eventType"] as? String ?? "unknown"
                
                // Handle different types of events
                switch eventType {
                case "attendeeJoined":
                    // Notify observers that an attendee joined
                    NotificationCenter.default.post(
                        name: Notification.Name("AttendeeJoined"),
                        object: nil,
                        userInfo: json
                    )
                    
                case "sessionStarted":
                    // Notify observers that the session started
                    NotificationCenter.default.post(
                        name: Notification.Name("SessionStarted"),
                        object: nil,
                        userInfo: json
                    )
                    
                case "sessionClosed":
                    // Notify observers that the session was closed
                    NotificationCenter.default.post(
                        name: Notification.Name("SessionClosed"),
                        object: nil,
                        userInfo: json
                    )
                    
                case "attendeeResponse":
                    // Store and notify about attendee response
                    if let name = json["attendeeName"] as? String,
                       let response = json["response"] as? String,
                       let choice = json["choice"] as? String {
                        attendeeResponses[name] = response
                        
                        NotificationCenter.default.post(
                            name: Notification.Name("AttendeeResponse"),
                            object: nil,
                            userInfo: [
                                "attendeeName": name,
                                "response": response,
                                "choice": choice
                            ]
                        )
                    }
                    
                case "timeUpdate":
                    // Update time remaining
                    if let timeRemaining = json["timeRemaining"] as? Int {
                        self.timeRemaining = timeRemaining
                        
                        NotificationCenter.default.post(
                            name: Notification.Name("TimeUpdate"),
                            object: nil,
                            userInfo: ["timeRemaining": timeRemaining]
                        )
                    }
                    
                case "timeUp":
                    // Time is up
                    NotificationCenter.default.post(
                        name: Notification.Name("TimeUp"),
                        object: nil
                    )
                    
                case "error":
                    print("Error from server: \(json["message"] as? String ?? "Unknown error")")
                    
                case "unknown":
                    // Check if this is a connection confirmation
                    if json["connectionId"] != nil {
                        print("WebSocket connection confirmed with ID: \(json["connectionId"] ?? "unknown")")
                    } else {
                        print("Unidentified message format: \(json)")
                    }
                    
                default:
                    print("Unhandled event type: \(eventType)")
                }
            }
        } catch {
            print("Failed to parse message: \(error). Raw data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
        }
    }
    
    func getAttendeeResponses() -> [String: String] {
        return attendeeResponses
    }
    
    func isSessionStarted() -> Bool {
        return sessionStarted
    }
    
    func getTimeRemaining() -> Int {
        return timeRemaining
    }
    
    // For validation of codes - this would be replaced by server validation in production
    private var validCodes: [String] = ["ADMIN", "TEST123"]
    
    func addValidCode(_ code: String) {
        if !validCodes.contains(code) {
            validCodes.append(code)
        }
        sessionCode = code
        print("Added valid code: \(code)")
    }
    
    func isValidCode(_ code: String) -> Bool {
        // In production, this would check against the server
        if validCodes.contains(code) {
            return true
        }
        
        // For demo purposes, add any code used to valid codes
        addValidCode(code)
        return true
    }
}
