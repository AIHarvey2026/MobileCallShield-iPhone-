import Foundation

enum MobileCarrier: String, CaseIterable, Identifiable, Codable {
    case att = "AT&T"
    case verizon = "Verizon"
    case tmobile = "T-Mobile"
    case visible = "Visible (Verizon)"
    case totalWireless = "Total Wireless (Verizon)"
    case straightTalk = "Straight Talk"
    case cricket = "Cricket Wireless (AT&T)"
    case mint = "Mint Mobile (T-Mobile)"
    case metro = "Metro by T-Mobile"
    
    var id: String { self.rawValue }
    
    /// Generates carrier-specific USSD star code to activate conditional call forwarding
    func forwardingCode(for twilioNumber: String) -> String {
        // Strip out non-numeric characters (leaving only digits)
        let digitsOnly = twilioNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Take the last 10 digits (e.g., 2812476667)
        let tenDigitNumber = String(digitsOnly.suffix(10))
        
        switch self {
        case .verizon, .visible, .totalWireless, .straightTalk:
            // Verizon network code format (*71 + 10 digits)
            return "*71\(tenDigitNumber)"
            
        case .att, .cricket:
            // AT&T network code format (*61* + 10 digits + #)
            return "*61*\(tenDigitNumber)#"
            
        case .tmobile, .mint, .metro:
            // T-Mobile network code format (**61* + 10 digits + **15#)
            return "**61*\(tenDigitNumber)**15#"
        }
    }
    
    /// Generates the carrier code to disable call forwarding
    var disableCode: String {
        switch self {
        case .verizon, .visible, .totalWireless, .straightTalk:
            return "*73" //
        case .att, .cricket, .tmobile, .mint, .metro:
            return "##61#" //
        }
    }
}
