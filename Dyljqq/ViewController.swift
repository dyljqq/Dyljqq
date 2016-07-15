//
//  ViewController.swift
//  Dyljqq
//
//  Created by 季勤强 on 16/7/15.
//  Copyright © 2016年 季勤强. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        ImageDownloader.defaultDownloader.downloadImageForURL(NSURL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-1.jpg")!, progressBlock: { receivedSize, totalSize in
//            print("receivedSize: \(receivedSize), totalSize: \(totalSize)")
//            }, completionHandler: { image, error, imageURL, originData in
//                if let image = image {
//                    self.imageView.image = image
//                }
//        })
        
        ImageManager.sharedManager.downloadImage(NSURL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-1.jpg")!, progressBlock: { receivedSize, totalSize in
            print("receivedSize: \(receivedSize), totalSize: \(totalSize)")
            }, completionHandler: { image, error in
                if let image = image {
                    self.imageView.image = image
                }
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

