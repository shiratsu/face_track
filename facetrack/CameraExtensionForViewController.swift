//
//  CameraExtensionForViewController.swift
//  facetrack
//
//  Created by 平塚 俊輔 on 2017/12/18.
//  Copyright © 2017年 平塚 俊輔. All rights reserved.
//


import AVFoundation
import UIKit

protocol PickFaceInfo: class{
    
    
    /// 画像を取得して渡す
    ///
    /// - Parameter faceInfo: <#faceInfo description#>
    func trimFace(_ faceInfo: [String: Any])
    
}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    
    /// キャプチャ中にずっと呼ばれる。
    /// 新しいビデオフレームが書かれたら呼ばれる
    ///
    /// - Parameters:
    ///   - captureOutput: <#captureOutput description#>
    ///   - sampleBuffer: <#sampleBuffer description#>
    ///   - connection: <#connection description#>
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        print("testextestst")
        // CMSampleBufferをCVPixelBufferに変換
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        
        // attachements無くても作れるけど、attachmentsは必要なのかどうかよくわからんなあ
        let ciImage = CIImage(cvImageBuffer: pixelBuffer, options: attachments as! [String : Any]?)
        
        
        
        print("testextestst")
        
        
        
//        var dicFace: [String: Any?] = [:]
//        dicFace["ciImage"] = ciImage
//        dicFace["faceFeatures"] = []
        
//        print(dicFace)
//        goToPreview(dicFace)
        
        performRectangleDetection(ciImage)
        
        
    }
    
    //MARK: Utility methods
    
    /// 多分顔画像を取得してくれるのではないかと。
    ///
    /// - Parameter image: <#image description#>
    /// - Returns: <#return value description#>
    func performRectangleDetection(_ image: CIImage){
        var resultImage: CIImage?
        
        let options: [String : Any] = [CIDetectorImageOrientation: exifOrientation(orientation: UIDevice.current.orientation),
                                       CIDetectorSmile: true,
                                       CIDetectorEyeBlink: true]
        
        if let detector = faceDetector {
            // Get the detections
            let features = detector.features(in: image, options: options)
            print("features")
            print(features)
            if features.count > 0{
                
                for feature in features {
                    
                    if let faceFeature = feature as? CIFaceFeature {
                        
                        resultImage = image.cropped(to: faceFeature.bounds)
                        pickDelegate?.trimFace(["faceFeature": faceFeature,"ciImage": resultImage])
                        break
                    }
                    
                }
            }
        }
        
    }
    
    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
        switch orientation {
        case .portraitUpsideDown:
            return 8
        case .landscapeLeft:
            return 3
        case .landscapeRight:
            return 1
        default:
            return 6
        }
    }
}

extension ViewController: PickFaceInfo{
    
    func trimFace(_ faceInfo: [String : Any]) {
        goToPreview(faceInfo)
    }
}
