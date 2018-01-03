//
//  SecondViewController.swift
//  facetrack
//
//  Created by 平塚 俊輔 on 2017/12/21.
//  Copyright © 2017年 平塚 俊輔. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {

    
    @IBOutlet weak var photoView: UIImageView!
    
    var features: CGRect? = nil
    var ciImage: CIImage? = nil
    var faceImage: UIImage? = nil
    
    /**
     xibを読み込む
     */
    override func loadView() {
        if let view = UINib(nibName: "SecondViewController", bundle: nil).instantiate(withOwner: self, options: nil).first as? UIView {
            self.view = view
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if let constCiImage: CIImage = ciImage,let constFeatures = features{
//            let beforeImage: UIImage = UIImage(ciImage: constCiImage)
//
////            if let fiximage = fixOrientationOfImage(image: beforeImage){
////                photoView.image = fiximage
////            }
//            print(constFeatures)
//            photoView.image = beforeImage
//
//
//        }
        
        if let constImage = faceImage{
            photoView.image = constImage
        }
        
        // Do any additional setup after loading the view.
    }
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func goBackViewController(_ sender: Any) {
        
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
