//
//  UIViewController+Record.swift
//  GifMaker_Swift_Template
//
//  Created by Christina Bharara on 3/28/17.
//  Copyright © 2017 Gabrielle Miller-Messner. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import AVFoundation

// Regift constants
let frameCount = 16
let delayTime: Float = 0.2
let loopCount = 0 //0 means loop forever

extension UIViewController {
    // MARK: Select Video
    
    @IBAction func presentVideoOptions(){
        
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
            //launch photo library
        } else{
            let newGifActionSheet = UIAlertController(title: "Create new GIF", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
            
            let recordVideo = UIAlertAction(title: "Record a Video", style: UIAlertActionStyle.default, handler: {
                (UIAlertAction) in
                    self.launchVideoCamera()
                })
            
            let chooseFromExisting = UIAlertAction(title:"Choose from Existing", style:UIAlertActionStyle.default, handler: { (UIAlertAction) in
                self.launchPhotoLibrary()
            })
            
            let cancel = UIAlertAction(title:"Cancel", style:UIAlertActionStyle.cancel, handler:nil)
            
            newGifActionSheet.addAction(recordVideo)
            newGifActionSheet.addAction(chooseFromExisting)
            newGifActionSheet.addAction(cancel)
            
            present(newGifActionSheet, animated:true, completion:nil)
            let pinkColor = UIColor(red:255.0/255.0, green:65.0/255.0, blue:112.0/255.0, alpha:1.0)
            newGifActionSheet.view.tintColor = pinkColor
            
        }
        
        
    }
    
    func launchPhotoLibrary() {
        let recordVideoController = UIImagePickerController()
        recordVideoController.sourceType = UIImagePickerControllerSourceType.photoLibrary
        recordVideoController.mediaTypes = [kUTTypeMovie as String]
        recordVideoController.allowsEditing = true
        recordVideoController.delegate = self
        
        present(recordVideoController, animated: true, completion: nil)
        
    }
    
   func launchVideoCamera() {
        let recordVideoController = UIImagePickerController()
        recordVideoController.sourceType = UIImagePickerControllerSourceType.camera
        recordVideoController.mediaTypes = [kUTTypeMovie as String]
        recordVideoController.allowsEditing = true
        recordVideoController.delegate = self
        
        present(recordVideoController, animated: true, completion: nil)
        
    }
}

extension UIViewController : UINavigationControllerDelegate {}

extension UIViewController : UIImagePickerControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        
        if mediaType == kUTTypeMovie as String{
            let videoURL = info[UIImagePickerControllerMediaURL] as! NSURL
            let start: NSNumber? = info["_UIImagePickerControllerVideoEditingStart"] as? NSNumber
            let end: NSNumber? = info["_UIImagePickerControllerVideoEditingEnd"] as? NSNumber
            var duration: NSNumber?
            if let start = start {
                duration = NSNumber(value: (end!.floatValue) - (start.floatValue))
            } else {
                duration = nil
            }
            //convertVideoToGIF(videoURL: videoURL, start: start, duration: duration)
            
            cropVideoToSquare(rawVideoURL:videoURL as URL, start: start, duration: duration);
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //gif conversion methods
    func convertVideoToGIF(videoURL: URL, start: NSNumber?, duration: NSNumber?){
        
        let regift: Regift;
        
        if let start = start {
            // Trimmed
            regift = Regift(sourceFileURL: videoURL, destinationFileURL: nil, startTime: start.floatValue, duration: duration!.floatValue, frameRate: frameCount, loopCount: loopCount)
        } else {
            // Untrimmed
            regift = Regift(sourceFileURL: videoURL, destinationFileURL: nil, frameCount: frameCount, delayTime: delayTime, loopCount: loopCount)
        }
        
        let gifURL = regift.createGif()
        let gif = Gif(url: gifURL!, videoURL: videoURL as URL, caption: nil)
        
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
            self.displayGIF(gif)
        }
    }
    
    func displayGIF(_ gif: Gif){
        
        let gifEditorVC = storyboard?.instantiateViewController(withIdentifier: "GifEditorViewController") as! GifEditorViewController
        gifEditorVC.gif = gif
        navigationController?.pushViewController(gifEditorVC, animated: true)
        
    }
    
    func cropVideoToSquare(rawVideoURL: URL, start: NSNumber?, duration: NSNumber?){
        
        let videoAsset = AVAsset(url: rawVideoURL)
        let videoTrack = videoAsset.tracks(withMediaType: AVMediaTypeVideo)[0]
        
        let videoComposition = AVMutableVideoComposition()
        
        videoComposition.renderSize = CGSize.init(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.height)
        
        videoComposition.frameDuration = CMTime.init(seconds: 1, preferredTimescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        
        instruction.timeRange = CMTimeRange.init(start: kCMTimeZero, duration: CMTimeMakeWithSeconds(60, 30))
        
        //Center the cropped video
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack:videoTrack)
        let firstTransform = CGAffineTransform(translationX: videoTrack.naturalSize.height, y: -(videoTrack.naturalSize.width - videoTrack.naturalSize.height)/2.0)
        
        //Rotate 90 degrees to portrait
        let halfOfPi: CGFloat = CGFloat(M_PI_2)
        let secondTransform = firstTransform.rotated(by: halfOfPi);
        let finalTransform = secondTransform;
        transformer.setTransform(finalTransform, at:kCMTimeZero)
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        // Export the square video
        let exporter = AVAssetExportSession(asset:videoAsset, presetName:AVAssetExportPresetHighestQuality)!
        exporter.videoComposition = videoComposition
        let path = createPath()
        exporter.outputURL = URL(fileURLWithPath:path)
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        
        //var squareURL = URL()
        exporter.exportAsynchronously {
            let squareURL = exporter.outputURL;
            self.convertVideoToGIF(videoURL: squareURL!, start: start, duration: duration)
        }
    }
        
    func createPath()->String{
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0]
        var outPath = path.appending("/output")
        do {
            try FileManager.default.createDirectory(atPath: outPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError{
            print(error.localizedDescription)
        }
        
        outPath = outPath.appending("output.mov")
        
        do {
            try FileManager.default.removeItem(atPath: outPath)
        } catch let error as NSError{
            print(error.localizedDescription)
        }

        
        return outPath
    }
    
    
}
