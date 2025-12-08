import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    
    // REPLACE THIS WITH YOUR ACTUAL API ENDPOINT
    private let uploadURL = URL(string: "https://n8n.99bugs.org/webhook/ab33378c-60e2-4cf7-a9c6-0e8e58c928ab")!
    
    private init() {}
    
    enum NetworkError: Error {
        case invalidURL
        case imageConversionFailed
        case invalidResponse
        case serverError(statusCode: Int)
        case decodingError(Error)
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            let menuResponse = try decoder.decode(MenuResponse.self, from: data)
            return menuResponse.menu
        } catch {
            print("Decoding error: \(error)")
            // Print response string for debugging if decoding fails
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response received: \(responseString)")
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
