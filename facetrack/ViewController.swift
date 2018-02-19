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

final class ViewController: UIViewController {
    @IBOutlet weak var textview: UITextView!
    
    var session: AVCaptureSession?
    var borderLayer: CAShapeLayer?
    
    var pickDelegate: PickFaceInfo?
    
    // 顔とかその他情報を表示するためのview
    let detailsView: DetailsView = {
        let detailsView = DetailsView()
        detailsView.setup()
        
        return detailsView
    }()
    
    // カメラの映像を画面に表示する為のレイヤー
    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        var previewLay = AVCaptureVideoPreviewLayer(session: self.session!)
        previewLay.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        return previewLay
    }()
    
    // カメラの定義
    // positionをbackにすると通常モード
    // frontにすると自撮りモード
    lazy var backCamera: AVCaptureDevice? = {
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] else { return nil }
        
        return devices.filter { $0.position == .back }.first
    }()
    
    
    // 顔認識オブジェクト
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
    
    /**
     xibを読み込む
     */
    override func loadView() {
        if let view = UINib(nibName: "ViewController", bundle: nil).instantiate(withOwner: self, options: nil).first as? UIView {
            self.view = view
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.frame
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let previewLayer = previewLayer else { return }
        
        view.layer.addSublayer(previewLayer)
        view.addSubview(detailsView)
        view.bringSubview(toFront: detailsView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickDelegate = self
        sessionPrepare()
        session?.startRunning()
    }
}

extension ViewController {
    
    func sessionPrepare() {
        
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
            output.connection(with: .video)?.videoOrientation = .portrait
            
            
        } catch {
            print("error with creating AVCaptureDeviceInput")
        }
    }
}

extension ViewController {
    
    
    
    
    func goToPreview(_ sendDic: [String: Any]){
        
        self.performSegue(withIdentifier: "checkPreview", sender: sendDic)
        
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "checkPreview" {
            let vcl = segue.destination as! SecondViewController
            if let sendDic: [String: Any] = sender as? [String: Any]{
                vcl.faceImage = sendDic["trimedImage"] as? UIImage
                
            }
            session?.stopRunning()
        }
        
    }
}

extension ViewController {
    func update(with faceRect: CGRect, text: String) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.detailsView.detailsLabel.text = text
                self.detailsView.alpha = 1.0
                self.detailsView.frame = faceRect
            }
        }
    }
}



