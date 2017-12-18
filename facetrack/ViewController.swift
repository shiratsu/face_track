//
//  ViewController.swift
//  facetrack
//
//  Created by 平塚 俊輔 on 2017/12/18.
//  Copyright © 2017年 平塚 俊輔. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    var session: AVCaptureSession!
    
    // カメラの定義
    // positionをbackにすると通常モード
    // frontにすると自撮りモード
    lazy var backCamera: AVCaptureDevice? = {
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] else { return nil }
        
        return devices.filter { $0.position == .front }.first
    }()
    
    // カメラの映像を画面に表示する為のレイヤー
    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        var previewLay = AVCaptureVideoPreviewLayer(session: self.session!)
        previewLay.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        return previewLay
    }()

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraView.frame
        previewLayer?.frame.origin.x -= 22
        previewLayer?.frame.origin.y -= 20
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let previewLayer = previewLayer else { return }
        
//        previewLayer.frame = cameraView.frame
        cameraView.layer.addSublayer(previewLayer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCamera()
        session?.startRunning()
    }
    
    // カメラの設定
    func prepareCamera() {
        
        // まずはカメラ使うにはこいつが必要
        session = AVCaptureSession()
        
        // セッションとカメラをセット
        guard let session = session, let captureDevice = backCamera else { return }
        
        // キャプチャの品質レベル、ビットレートなどのクオリティを設定
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        do {
            // AVCaptureDeviceオブジェクトからデータをキャプチャするために使用するAVCaptureInputのサブクラスです。
            // これを使用して、デバイスをAVCaptureSessionに繋ぎます。
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            session.beginConfiguration()
            
            // セッションにカメラを入力機器として接続
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            // アウトプットの設定
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            
            // 遅れてきたフレームは無視する
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            // 設定をコミットする。
            session.commitConfiguration()
            
            // フレームをキャプチャするためのサブスレッド用のシリアルキューを用意
            // didOutputSampleBufferを呼ぶため用
            let queue = DispatchQueue(label: "output.queue")
            output.setSampleBufferDelegate(self, queue: queue)
            
        } catch {
            print("error with creating AVCaptureDeviceInput")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


