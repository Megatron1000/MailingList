import Cocoa

struct Member: Decodable {

    let address: String
    let bundleIdentifiers: Set<String>
    
}
