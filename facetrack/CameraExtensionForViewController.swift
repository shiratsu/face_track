//
//  CameraExtensionForViewController.swift
//  facetrack
//
//  Created by 平塚 俊輔 on 2017/12/18.
//  Copyright © 2017年 平塚 俊輔. All rights reserved.
//


import AVFoundation
import UIKit
import Vision

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
        
//        // CMSampleBufferをCVPixelBufferに変換
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//
//        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
//
//        // attachements無くても作れるけど、attachmentsは必要なのかどうかよくわからんなあ
//        let ciImage = CIImage(cvImageBuffer: pixelBuffer, options: attachments as! [String : Any]?)
//
//
//        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
//
//
//        let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, false)
//
//        performRectangleDetection(ciImage, cleanAperture: cleanAperture)
        
        // CMSampleBufferをCVPixelBufferに変換
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // CoreMLのモデルクラスの初期化
        guard let model = try? VNCoreMLModel(for: dev3.init().model) else { return }
        
        
        // 画像認識リクエストを作成（引数はモデルとハンドラ）
        let request = VNCoreMLRequest(model: model) {
            [weak self] (request: VNRequest, error: Error?) in
            guard let results = request.results as? [VNClassificationObservation] else { return }
            
            // 判別結果とその確信度を上位3件まで表示
            // identifierは類義語がカンマ区切りで複数書かれていることがあるので、最初の単語のみ取得する
            let displayText = results.prefix(3).flatMap { "\(Int($0.confidence * 100))% \($0.identifier.components(separatedBy: ", ")[0])" }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self?.textview.text = displayText
            }
        }
        
        // CVPixelBufferに対し、画像認識リクエストを実行
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        

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
            if features.count > 0{
                
                for feature in features {
                    
                    if let faceFeature = feature as? CIFaceFeature {
                        
                        // 顔の形を取得する
//                        let faceRects = CIDetectOfFace(UIImage(ciImage: image), margin_rate: 0.4)
                        let faceRects = calcFaceRect2(faceFeature, image: UIImage(ciImage: image), margin_rate: 0.4)
                        if let faceRect = inclusionRect(faceRects){
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
        faceRect.origin.x -= widthMargin*2
        faceRect.size.width += widthMargin*2
        
        let heightMargin = faceRect.height * margin_rate
        faceRect.origin.y -= heightMargin*2
        faceRect.size.height += heightMargin*3
        
        print(faceRect," in ",image.size)
        print(feature.bounds," in ",image.size)
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
