import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    
    // REPLACE THIS WITH YOUR ACTUAL API ENDPOINT
    private let uploadURL = URL(string: "https://n8n.99bugs.org/webhook/ab33378c-60e2-4cf7-a9c6-0e8e58c928ab")!
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300 // 5 minutes for resource
        return URLSession(configuration: configuration)
    }()
    
    private init() {}
    
    enum NetworkError: LocalizedError {
        case invalidURL
        case imageConversionFailed
        case invalidResponse
        case serverError(statusCode: Int)
        case decodingError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL configuration."
            case .imageConversionFailed:
                return "Failed to process image for upload."
            case .invalidResponse:
                return "Invalid response from server."
            case .serverError(let statusCode):
                return "Server returned error status: \(statusCode)"
            case .decodingError(let error):
                return "Failed to parse menu data: \(error.localizedDescription)"
            }
        }
    }
    
    func uploadImage(_ image: UIImage) async throws -> Menu {
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.imageConversionFailed
        }
        
        let body = createBody(with: imageData, boundary: boundary, filename: "menu_image.jpg")
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Received JSON: \(responseString)")
        }
        
        do {
            let decoder = JSONDecoder()
            
            // Strategy 1: Try decoding Menu directly (matches latest logs)
            if let directMenu = try? decoder.decode(Menu.self, from: data) {
                return directMenu
            }
            
            // Strategy 2: N8n Array format
            if let responseArray = try? decoder.decode([N8nResponse].self, from: data),
               let firstItem = responseArray.first {
                return firstItem.output.menu
            }
            
            // Strategy 3: Legacy wrapped MenuResponse
            if let menuResponse = try? decoder.decode(MenuResponse.self, from: data) {
                return menuResponse.menu
            }
            
            // If all fail, throw the original decoding error by forcing a decode that we know will fail 
            // but capturing the error, or just throw invalidResponse. 
            // Better: just try one last time with logging to throw the detailed error
            let _ = try decoder.decode(Menu.self, from: data)
            throw NetworkError.invalidResponse // Should be unreachable if the line above throws
            
        } catch {
            print("Decoding error: \(error)")
            // Print response string for debugging if decoding fails
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response received (failed to decode): \(responseString)")
            }
            throw NetworkError.decodingError(error)
        }
    }
    
    private func createBody(with data: Data, boundary: String, filename: String) -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        
        body.append("--\(boundary + lineBreak)")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\(lineBreak)")
        body.append("Content-Type: image/jpeg\(lineBreak + lineBreak)")
        body.append(data)
        body.append(lineBreak)
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }

    }


extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
