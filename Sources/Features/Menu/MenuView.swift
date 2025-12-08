import SwiftUI

struct MenuView: View {
    let menu: Menu
    
    var body: some View {
        NavigationView {
            List {
                if let restaurantName = menu.restaurantName {
                    Text(restaurantName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)
                        .listRowSeparator(.hidden)
                }
                
                ForEach(menu.sections) { section in
                    Section(header: Text(section.categoryName).font(.title2).bold()) {
                        if let description = section.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Section description: \(description)")
                        }
                        
                        if let styles = section.availableStyles {
                            Text("Available Styles: \(styles.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ForEach(section.items) { item in
                            MenuItemRow(item: item, currency: menu.currency)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct MenuItemRow: View {
    let item: MenuItem
    let currency: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(item.name)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Text(formatPrice(item.price))
                    .font(.body)
                    .fontWeight(.semibold)
                    .accessibilityLabel("Price: \(formatPrice(item.price))")
            }
            
            if let description = item.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Description: \(description)")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.description ?? ""), Price \(formatPrice(item.price))")
    }
    
    func formatPrice(_ price: Double) -> String {
        // Simple formatter, in a real app use NumberFormatter
        return String(format: "%.2f %@", price, currency)
    }
}
