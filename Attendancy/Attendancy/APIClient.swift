//
//  ApiCLient.swift
//  Attendancy
// https://psafwffwu3.execute-api.us-west-2.amazonaws.com/prod
//
//  Created by Don on 2/27/25.
//
import Foundation
import UIKit

class APIClient {
    static let shared = APIClient()
    
    // Updated with your actual API Gateway URL
    private let baseURL = "https://psafwffwu3.execute-api.us-west-2.amazonaws.com/prod"
    
    // Try with alternative base URL for join/start
    private let joinBaseURL = "https://t46mhsquzl.execute-api.us-west-2.amazonaws.com/production"
    
    private init() {}
    
    func generateAttendanceCode() async throws -> String {
        guard let url = URL(string: "\(baseURL)/attendance") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Print request details for debugging
        print("Generate attendance code request: \(url)")
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug: Print raw response
        print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError
        }
        
        // Log HTTP status
        print("HTTP Status: \(httpResponse.statusCode)")
        
        if !(200...299).contains(httpResponse.statusCode) {
            // Log error details
            print("HTTP Error: \(httpResponse.statusCode)")
            print("Response: \(String(data: data, encoding: .utf8) ?? "No response body")")
            throw APIError.serverError
        }
        
        // Try to decode both response formats
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(CodeResponse.self, from: data)
            return result.code
        } catch {
            // Try alternative format if first one fails
            print("First decoding attempt failed: \(error)")
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(ApiResponseWrapper.self, from: data)
                
                // Check if we got a valid response body
                guard let responseBody = result.body,
                      let bodyData = responseBody.data(using: .utf8),
                      let codeResponse = try? decoder.decode(CodeResponse.self, from: bodyData) else {
                    throw APIError.decodingError
                }
                
                return codeResponse.code
            } catch {
                print("Second decoding attempt failed: \(error)")
                throw APIError.decodingError
            }
        }
    }
    
    func startSession(code: String) async throws -> StartSessionResponse {
        // Use a hardcoded response since you mentioned the backend isn't fully implemented
        return StartSessionResponse(
            success: true,
            message: "Session started successfully",
            display: "123" // This is what the host will see
        )
    }
    
    func joinSession(withCode code: String, attendeeName: String = "Anonymous") async throws -> JoinSessionResponse {
        // Use a hardcoded response since we can't seem to connect to the endpoint
        return JoinSessionResponse(
            success: true,
            status: "ACTIVE",
            message: "Joined active session",
            display: "321" // This is what attendees will see
        )
    }
    
    func validateCode(code: String) async throws -> ValidateCodeResponse {
        // Use a hardcoded successful response
        return ValidateCodeResponse(
            valid: true,
            status: "CREATED",
            message: "Waiting for host to start"
        )
    }
}

// Response models
struct CodeResponse: Codable {
    let code: String
    let expiresAt: TimeInterval
    let status: String
}

// Alternative response format - API Gateway might be wrapping the response
struct ApiResponseWrapper: Codable {
    let statusCode: Int
    let body: String?
    let headers: [String: String]?
}

struct ValidateCodeRequest: Codable {
    let code: String
}

struct ValidateCodeResponse: Codable {
    let valid: Bool
    let status: String?
    let message: String
}

struct StartSessionRequest: Codable {
    let code: String
}

struct StartSessionResponse: Codable {
    let success: Bool
    let message: String
    let display: String
}

struct JoinSessionRequest: Codable {
    let code: String
    let attendeeName: String
}

struct JoinSessionResponse: Codable {
    let success: Bool
    let status: String?
    let message: String
    let display: String?
}

// Error types
enum APIError: Error {
    case invalidURL
    case serverError
    case decodingError
}
