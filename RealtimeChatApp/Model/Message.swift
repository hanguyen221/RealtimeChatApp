//
//  Message.swift
//  RealtimeChatApp
//
//  Created by Nguyen Thanh Ha on 8/17/17.
//  Copyright © 2017 Ha Nguyen. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    var fromId: String?
    var text: String?
    var toId: String?
    var timestamp: NSNumber?
    
    func chatPartnerId() -> String? {
        
        if fromId == Auth.auth().currentUser?.uid {
            return toId
        } else {
            return fromId
        }
    }
}
