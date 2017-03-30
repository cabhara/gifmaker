//
//  Gif.swift
//  GifMaker_Swift_Template
//
//  Created by Christina Bharara on 3/29/17.
//  Copyright © 2017 Gabrielle Miller-Messner. All rights reserved.
//

import Foundation
import UIKit

class Gif: NSObject {
    
    var url:URL?
    var caption:String?
    let gifImage:UIImage?
    var videoURL:URL?
    var gifData:NSData?
    
    init(url:URL, videoURL:URL, caption:String?){
        self.url = url
        self.videoURL = videoURL
        self.caption = caption
        self.gifImage = UIImage.gif(url: url.absoluteString)
        self.gifData = nil
    }
    
    init(name:String){
        self.gifImage = UIImage.gif(name: name)
    }
    
}
