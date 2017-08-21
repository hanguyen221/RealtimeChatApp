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
    var imageUrl: String?
    var imageHeight: NSNumber?
    var imageWidth: NSNumber?
    var videoUrl: String?
    
    func chatPartnerId() -> String? {
        if fromId == Auth.auth().currentUser?.uid {
            return toId
        } else {
            return fromId
        }
    }
    
    init(dictionary: [String: Any]) {
        super.init()
        
        fromId = dictionary["fromId"] as? String
        text = dictionary["text"] as? String
        toId = dictionary["toId"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        
        imageUrl = dictionary["imageUrl"] as? String
        imageHeight = dictionary["imageHeight"] as? NSNumber
        imageWidth = dictionary["imageWidth"] as? NSNumber
        videoUrl = dictionary["videoUrl"] as? String
    }
}
