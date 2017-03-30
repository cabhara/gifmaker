//
//  PreviewViewController.swift
//  GifMaker_Swift_Template
//
//  Created by Christina Bharara on 3/28/17.
//  Copyright © 2017 Gabrielle Miller-Messner. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController {
    
    var gif: Gif?
    
    @IBOutlet var imageView:UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = gif?.gifImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func shareGif(sender: AnyObject) {
        let url: URL = (self.gif?.url)!
        let animatedGIF = NSData(contentsOf: url)!
        let itemsToShare = [animatedGIF]
        
        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        activityVC.completionWithItemsHandler = {(activity, completed, items, error) in
            if (completed) {
                _ = self.navigationController?.popToRootViewController(animated: true)
            }
        }
        
        navigationController?.present(activityVC, animated: true, completion: nil)
    }

}
