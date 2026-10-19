import SwiftUI
import MapKit
import Combine

class AddressSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()
    @Published var results: [MKLocalSearchCompletion] = []
    @Published var searchQuery: String = "" {
        didSet {
            completer.queryFragment = searchQuery
        }
    }
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("❌ Address completion error: \(error.localizedDescription)")
    }
}
