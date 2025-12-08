import Foundation

// MARK: - Menu Response
struct MenuResponse: Codable {
    let menu: Menu
}

// MARK: - Menu
struct Menu: Codable {
    let restaurantName: String?
    let currency: String
    let sections: [MenuSection]

    enum CodingKeys: String, CodingKey {
        case restaurantName = "restaurant_name"
        case currency
        case sections
    }
}

// MARK: - Menu Section
struct MenuSection: Codable, Identifiable {
    var id = UUID()
    let categoryName: String
    let description: String?
    let availableStyles: [String]?
    let items: [MenuItem]

    enum CodingKeys: String, CodingKey {
        case categoryName = "category_name"
        case description
        case availableStyles = "available_styles"
        case items
    }
}

// MARK: - Menu Item
struct MenuItem: Codable, Identifiable {
    var id = UUID()
    let name: String
    let description: String?
    let price: Double

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case price
    }
}
