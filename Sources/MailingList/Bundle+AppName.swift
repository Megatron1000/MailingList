//
//  Copyright © 2017 John Lewis plc. All rights reserved.
//

import AppKit

public extension Bundle {
    
    var displayName: String? {
        return infoDictionary?["CFBundleName"] as? String
    }

}
