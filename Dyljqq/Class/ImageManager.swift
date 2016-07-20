//
//  ImageManager.swift
//  Dyljqq
//
//  Created by 季勤强 on 16/7/15.
//  Copyright © 2016年 季勤强. All rights reserved.
//

import UIKit

typealias ProgressBlock = (receivedSize: Int64, totalSize: Int64)-> ()
typealias CompletionHandler = (image: Image?, error: NSError?)-> ()

private let instance = ImageManager()

public class ImageManager {
    
    public class var sharedManager: ImageManager {
        return instance
    }
    
}

// MARK: - Download method
extension ImageManager {
    
    func downloadImage(URL: NSURL, placeHoldImage: Image? = nil, progressBlock: ProgressBlock?, completionHandler: CompletionHandler?) {
        
        if ImageCache.defaultCache.isExsitForKey(URL.absoluteString) {
            ImageCache.defaultCache.retrieveImage(URL.absoluteString) { image, cacheType in
                completionHandler?(image: image, error: nil)
            }
        } else {
            ImageDownloader.defaultDownloader.downloadImageForURL(URL, progressBlock: { receivedSize, totalSize in
                progressBlock?(receivedSize: receivedSize, totalSize: totalSize)
                }, completionHandler: { image, error, imageURL, originData in
                    if let image = image {
                        ImageCache.defaultCache.storeImage(image, forKey: URL.absoluteString)
                    }
                    completionHandler?(image: image, error: error)
            })
        }
        
    }
    
}