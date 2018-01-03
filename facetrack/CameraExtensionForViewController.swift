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
        
        performRectangleDetection(ciImage, cleanAperture: cleanAperture)
        
//        pickDelegate?.trimFace(["faceRect": [:],"ciImage": ciImage])
    }
    
    //MARK: Utility methods
    
    /// 多分顔画像を取得してくれるのではないかと。
    ///
    /// - Parameter image: <#image description#>
    /// - Returns: <#return value description#>
    func performRectangleDetection(_ image: CIImage,cleanAperture: CGRect){
        
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
                        let faceRects = calcFaceRect2(faceFeature, image: UIImage(ciImage: image), margin_rate: 0.35)
                        if let faceRect = inclusionRect(faceRects){
                            print("-----------------------------")
                            print(faceRect)
                            print("-----------------------------")
                            //                        resultImage = image.cropped(to: faceRect)
                            if let trimedImage = UIImage(ciImage: image).cropping(to: faceRect){
                                pickDelegate?.trimFace(["trimedImage": trimedImage])
                                break
                            }
                        }
                        
                        
                    }
                    
                }
            }
        }
        
    }
    
    /// 与えられた画像の顔の座標、大きさを返す。
    ///
    /// - Parameter image: 画像
    /// - Parameter margin: 余白
    /// - Returns: 顔の座標、大きさのCGRect配列
    func CIDetectOfFace(_ image: UIImage, quality:String = CIDetectorAccuracyHigh, margin_rate:CGFloat = 0.4)->[CGRect]{
        // CIDetector導入
        let ciImage  = CIImage(image:image)
        let ciDetector = CIDetector(ofType:CIDetectorTypeFace
            ,context:CIContext()
            ,options:[
                CIDetectorAccuracy:quality,
                CIDetectorSmile:true
            ]
        )
        
        // 認識
        let features = ciDetector?.features(in: ciImage!)
        var faceRects:[CGRect] = []
        
        // 顔情報取得
        for feature in features!{
            //face
            var faceRect = (feature as! CIFaceFeature).bounds
            
            // 左下起点、Rect左下から、左上起点、Rect左上へ、座標系を合わせる
            faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.height
            
            // 余白を持たせる
            let widthMargin = faceRect.width * margin_rate
            faceRect.origin.x -= widthMargin
            faceRect.size.width += widthMargin*2
            
            let heightMargin = faceRect.height * margin_rate
            faceRect.origin.y -= heightMargin*2
            faceRect.size.height += heightMargin*2
            
            print(faceRect," in ",image.size)
            image.size
            faceRects.append(faceRect)
            
        }
        return faceRects
    }
    
    
    /// 顔の特徴を取り出す
    ///
    /// - Parameters:
    ///   - feature: <#feature description#>
    ///   - image: <#image description#>
    ///   - margin_rate: <#margin_rate description#>
    /// - Returns: <#return value description#>
    func calcFaceRect2(_ feature: CIFaceFeature,image: UIImage,margin_rate: CGFloat = 0.4) -> [CGRect]{
    
        var faceRects:[CGRect] = []
        
        //face
        var faceRect = feature.bounds
        
        // 左下起点、Rect左下から、左上起点、Rect左上へ、座標系を合わせる
        faceRect.origin.y = image.size.height - faceRect.origin.y - faceRect.height
        
        // 余白を持たせる
        let widthMargin = faceRect.width * margin_rate
        faceRect.origin.x -= widthMargin
        faceRect.size.width += widthMargin*2
        
        let heightMargin = faceRect.height * margin_rate
        faceRect.origin.y -= heightMargin*2
        faceRect.size.height += heightMargin*2
        
        print(faceRect," in ",image.size)
        image.size
        faceRects.append(faceRect)
        
        return faceRects
    }
    
    /// 与えられたRect群を全て包含するようなRectを返す。
    ///
    /// - Parameter rects: 包含されるRect群
    /// - Returns: Rect群を包含するようなRect
    func  inclusionRect(_ rects:[CGRect])->CGRect?{
        if rects.count == 0{return nil}
        
        let maxX:CGFloat = rects.map({$0.maxX}).max()!
        let minX:CGFloat = rects.map({$0.minX}).min()!
        let maxY:CGFloat = rects.map({$0.maxY}).max()!
        let minY:CGFloat = rects.map({$0.minY}).min()!
        
        return CGRect(x:minX,y:minY,width:maxX-minX,height:maxY-minY)
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

extension UIImage {
    func cropping(to: CGRect) -> UIImage? {
        var opaque = false
        if let cgImage = cgImage {
            switch cgImage.alphaInfo {
            case .noneSkipLast, .noneSkipFirst:
                opaque = true
            default:
                break
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(to.size, opaque, scale)
        draw(at: CGPoint(x: -to.origin.x, y: -to.origin.y))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
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
