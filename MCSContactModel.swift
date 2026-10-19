import Foundation

struct MCSContactModel: Identifiable, Codable {
    var id: Int?
    var name: String
    var phoneNumber: String
    var isTrusted: Bool       // maps to is_guardian
    var isPrimary: Bool       // maps to is_primary
    
    // Provides a non-optional ID for SwiftUI's Identifiable conformance
    var computedID: Int {
        return id ?? phoneNumber.hashValue
    }
    
    var idValue: Int {
        return id ?? 0
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case phoneNumber = "phone_number"
        case isTrusted = "is_guardian"
        case isPrimary = "is_primary"
    }
}
