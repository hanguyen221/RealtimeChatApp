//
//  Extensions.swift
//  RealtimeChatApp
//
//  Created by Ha Nguyen on 8/16/17.
//  Copyright © 2017 Ha Nguyen. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        self.image = nil
        
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            self.image = cachedImage
            return
        }
        
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            if error != nil {
                print(error!)
                return
            }
            DispatchQueue.main.async {
                
                if let downloadedImage = UIImage(data: data!) {
                
                    imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                    
                    self.image = downloadedImage
                }
                
            }
        }).resume()
    }
}
