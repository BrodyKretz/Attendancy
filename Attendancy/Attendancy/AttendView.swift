//
//  AttendView.swift
//  Attendancy
//
//  Created by Don on 2/26/25.
//
import SwiftUI

struct AttendView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showCodePrompt = false
    @State private var showQRScanner = false
    @State private var navigateToWebsocket = false
    @State private var enteredCode = ""
    @State private var isJoining = false
    @State private var isRetrying = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showLeaveConfirmation = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Attend")
                .font(.largeTitle)
                .padding(.top, 30)
            
            Spacer()
            
            VStack(spacing: 20) {
                Button(action: {
                    print("Test console - Button tapped")
                    showCodePrompt = true
                }) {
                    HStack {
                        Image(systemName: "keyboard")
                            .font(.title2)
                        Text("Join with code")
                            .font(.title2)
                    }
                    .frame(width: 250, height: 60)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showQRScanner = true
                }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.title2)
                        Text("Join with QR CODE")
                            .font(.title2)
                    }
                    .frame(width: 250, height: 60)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    // TBD functionality
                }) {
                    HStack {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                        Text("TBD")
                            .font(.title2)
                    }
                    .frame(width: 250, height: 60)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            if isRetrying {
                Text("Retrying connection...")
                    .foregroundColor(.orange)
                    .padding()
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
        .alert("Enter Attendance Code", isPresented: $showCodePrompt) {
            TextField("Code", text: $enteredCode)
                .keyboardType(.default)
                .autocapitalization(.allCharacters)
            Button("Cancel", role: .cancel) {
                enteredCode = ""
            }
            Button("Join") {
                joinSession(withCode: enteredCode)
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("Retry", role: .none) {
                joinSession(withCode: enteredCode)
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerView(onCodeScanned: { code in
                enteredCode = code
                showQRScanner = false
                
                // Check the scanned code
                joinSession(withCode: code)
            })
        }
        .background(
            NavigationLink(
                destination: AttendanceWebsocket(sessionCode: enteredCode),
                isActive: $navigateToWebsocket
            ) {
                EmptyView()
            }
        )
    }
    
    private func joinSession(withCode code: String) {
        print("Attempting to join session with code: \(code)")
        isJoining = true
        
        // Check if the code is valid
        if !WebSocketClient.shared.isValidCode(code) {
            DispatchQueue.main.async {
                isJoining = false
                errorMessage = "This room doesn't exist. Please try a different code."
                showErrorAlert = true
            }
            return
        }
        
        Task {
            do {
                // Skip validation and directly join the session
                print("Joining session with code: \(code)")
                let joinResult = try await APIClient.shared.joinSession(withCode: code)
                print("Join result: \(joinResult)")
                
                DispatchQueue.main.async {
                    self.isJoining = false
                    
                    if joinResult.success {
                        // Store any data needed for the next screen
                        self.enteredCode = code
                        self.navigateToWebsocket = true
                    } else {
                        self.errorMessage = joinResult.message
                        self.showErrorAlert = true
                    }
                }
            } catch {
                print("Error joining session: \(error)")
                print("Raw error details: \(String(describing: error))")
                
                DispatchQueue.main.async {
                    self.isJoining = false
                    
                    // Enhanced error reporting
                    if let urlError = error as? URLError {
                        self.errorMessage = "Network error: \(urlError.localizedDescription)"
                    } else if let apiError = error as? APIError {
                        switch apiError {
                        case .invalidURL:
                            self.errorMessage = "Invalid API endpoint"
                        case .serverError:
                            self.errorMessage = "Server error. Please try again later."
                        case .decodingError:
                            self.errorMessage = "Error processing server response"
                        }
                    } else {
                        self.errorMessage = "Failed to join session: \(error.localizedDescription)"
                    }
                    
                    self.showErrorAlert = true
                }
            }
        }
    }
}

// Rest of the file remains the same
struct QRScannerView: View {
    var onCodeScanned: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("QR Scanner")
                .font(.largeTitle)
                .padding()
            
            Text("Camera would open here to scan QR code")
                .font(.headline)
                .padding()
            
            // Simulated camera view
            Rectangle()
                .stroke(Color.blue, lineWidth: 3)
                .frame(width: 250, height: 250)
                .overlay(
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                )
            
            Button("Simulate Scan of 'ADMIN' Code") {
                onCodeScanned("ADMIN")
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.top, 40)
            
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding(.top, 20)
        }
    }
}
