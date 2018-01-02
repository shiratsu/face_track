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
        
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        
        // get the clean aperture
        // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
        // that represents image data valid for display.
        let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, false)
        
//        performRectangleDetection(ciImage, cleanAperture: cleanAperture)
        
        pickDelegate?.trimFace(["faceRect": [:],"ciImage": ciImage])
    }
    
    //MARK: Utility methods
    
    /// 多分顔画像を取得してくれるのではないかと。
    ///
    /// - Parameter image: <#image description#>
    /// - Returns: <#return value description#>
    func performRectangleDetection(_ image: CIImage,cleanAperture: CGRect){
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
                        
                        // 顔の形を取得する
                        let faceRect = calculateFaceRect(facePosition: faceFeature.mouthPosition, faceBounds: faceFeature.bounds, clearAperture: cleanAperture)
                        print("-----------------------------")
                        print(faceRect)
                        print("-----------------------------")
//                        resultImage = image.cropped(to: faceRect)
                        pickDelegate?.trimFace(["faceRect": faceRect,"ciImage": image])
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
    
    /// 顔を取得する処理
    ///
    /// - Parameters:
    ///   - facePosition: <#facePosition description#>
    ///   - faceBounds: <#faceBounds description#>
    ///   - clearAperture: <#clearAperture description#>
    /// - Returns: <#return value description#>
    func calculateFaceRect(facePosition: CGPoint, faceBounds: CGRect, clearAperture: CGRect) -> CGRect {
        let parentFrameSize = previewLayer!.frame.size
        
        print("----------------parentFrameSize---------------------")
        print(parentFrameSize)
        
        
        let previewBox = videoBox(frameSize: parentFrameSize, apertureSize: clearAperture.size)
        
        print("----------------previewBox.size---------------------")
        print(previewBox.size)
        
        var faceRect = faceBounds
        
        swap(&faceRect.size.width, &faceRect.size.height)
        swap(&faceRect.origin.x, &faceRect.origin.y)
        
        let widthScaleBy = previewBox.size.width / clearAperture.size.height
        let heightScaleBy = previewBox.size.height / clearAperture.size.width
        
        faceRect.size.width *= widthScaleBy
        faceRect.size.height *= heightScaleBy
        faceRect.origin.x *= widthScaleBy
        faceRect.origin.y *= heightScaleBy
        
        faceRect = faceRect.offsetBy(dx: 0.0, dy: previewBox.origin.y)
        let frame = CGRect(x: parentFrameSize.width - faceRect.origin.x - faceRect.size.width / 2.0 - previewBox.origin.x / 2.0, y: faceRect.origin.y, width: faceRect.width, height: faceRect.height)
        
        return frame
    }
    
    func videoBox(frameSize: CGSize, apertureSize: CGSize) -> CGRect {
        let apertureRatio = apertureSize.height / apertureSize.width
        let viewRatio = frameSize.width / frameSize.height
        
        var size = CGSize.zero
        
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width
            size.height = apertureSize.width * (frameSize.width / apertureSize.height)
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width)
            size.height = frameSize.height
        }
        
        var videoBox = CGRect(origin: .zero, size: size)
        
        if (size.width < frameSize.width) {
            videoBox.origin.x = (frameSize.width - size.width) / 2.0
        } else {
            videoBox.origin.x = (size.width - frameSize.width) / 2.0
        }
        
        if (size.height < frameSize.height) {
            videoBox.origin.y = (frameSize.height - size.height) / 2.0
        } else {
            videoBox.origin.y = (size.height - frameSize.height) / 2.0
        }
        
        return videoBox
    }
}

extension ViewController: PickFaceInfo{
    
    func trimFace(_ faceInfo: [String : Any]) {
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.goToPreview(faceInfo)
            }
        }
    }
}
