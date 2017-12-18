//
//  CameraExtensionForViewController.swift
//  facetrack
//
//  Created by 平塚 俊輔 on 2017/12/18.
//  Copyright © 2017年 平塚 俊輔. All rights reserved.
//


import AVFoundation
import UIKit

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    
    /// キャプチャ中にずっと呼ばれる。
    /// 新しいビデオフレームが書かれたら呼ばれる
    ///
    /// - Parameters:
    ///   - captureOutput: <#captureOutput description#>
    ///   - sampleBuffer: <#sampleBuffer description#>
    ///   - connection: <#connection description#>
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        // CMSampleBufferをCVPixelBufferに変換
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
    }
        
}
