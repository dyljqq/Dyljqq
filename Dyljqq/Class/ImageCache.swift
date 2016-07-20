//
//  ImageCache.swift
//  Dyljqq
//
//  Created by 季勤强 on 16/7/15.
//  Copyright © 2016年 季勤强. All rights reserved.
//

import UIKit

private let ioQueueName = "com.dyljqq.io"
private let progressQueueName = "com.dyljqq.progress"
private let defaultName = "defaultName"
private let instance = ImageCache(name: defaultName)

enum CacheType {
    case MemoryCache, DiskCache, None
}

public class ImageCache {
    
    private var memoryCache = NSCache()
    
    private let progressQueue: dispatch_queue_t
    private let ioQueue: dispatch_queue_t
    
    private var fileManager: NSFileManager!
    private var diskCachePath: String
    
    public class var defaultCache: ImageCache {
        return instance
    }
    
    public init(name: String) {
        if name.isEmpty {
            fatalError("Image cache's name cannot empty...")
        }
        
        progressQueue = dispatch_queue_create(progressQueueName + name, DISPATCH_QUEUE_CONCURRENT)
        ioQueue = dispatch_queue_create(ioQueueName + name, DISPATCH_QUEUE_SERIAL)
        
        let dstPath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        diskCachePath = (dstPath as NSString).stringByAppendingString("com.dyljqq." + name)
        
        dispatch_async(ioQueue, {
            self.fileManager = NSFileManager()
        })
    }
    
}

// MARK: Store & Remove
extension ImageCache {
    
    func storeImage(image: Image, originData: NSData? = nil, forKey key: String, toDisk: Bool = true, completionHandler: (()-> ())? = nil) {
        memoryCache.setObject(image, forKey: key, cost: image.dj_imageCost)
        
        func callHandlerInMainQueue() {
            if let handler = completionHandler {
                dispatch_async(dispatch_get_main_queue()) {
                    handler()
                }
            }
        }
        if toDisk {
            dispatch_async(dispatch_get_main_queue(), {
                if !self.fileManager.fileExistsAtPath(self.diskCachePath) {
                    do {
                        try self.fileManager.createDirectoryAtPath(self.diskCachePath, withIntermediateDirectories: true, attributes: nil)
                    } catch _ {}
                }
                if let data = originData {
                    self.fileManager.createFileAtPath(self.cachePathForkey(key), contents: data, attributes: nil)
                } else  {
                    let data = UIImagePNGRepresentation(image)
                    self.fileManager.createFileAtPath(self.cachePathForkey(key), contents: data, attributes: nil)
                }
                callHandlerInMainQueue()
            })
        } else {
            callHandlerInMainQueue()
        }
    }
    
    func removeImageForKey(key: String, fromDisk: Bool = false, completionHandler: (()-> Void)?) {
        memoryCache.removeObjectForKey(key)
        
        func callHandler() {
            if let handler = completionHandler {
                dispatch_async(dispatch_get_main_queue(), {
                    handler()
                })
            }
        }
        
        if fromDisk {
            dispatch_async(ioQueue, {
                if self.fileManager.fileExistsAtPath(self.diskCachePath) {
                    do {
                       let filePath = self.cachePathForkey(key)
                        try self.fileManager.removeItemAtPath(filePath)
                    } catch _ {}
                }
            })
        }
    }
}

// MARK: - Retrieve image
extension ImageCache {
    
    func retrieveImage(key: String, completionHandler: ((Image?, CacheType)-> Void)) {
        if let image = retrieveImageFromCacheForKey(key) {
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(image, .MemoryCache)
            })
        } else {
            if let image = retrieveImageFromDisk(key) {
                dispatch_barrier_sync(ioQueue, {
                    self.storeImage(image, forKey: key, toDisk: false)
                    completionHandler(image, .DiskCache)
                })
            } else {
                completionHandler(nil, .None)
            }
        }
    }
    
    func retrieveImageFromDisk(key: String)-> Image? {
        return diskImageForKey(key)
    }
    
    func diskImageForKey(key: String)-> Image? {
        if let data = diskImageDataForKey(key) {
            return Image(data: data)
        }
        return nil
    }
    
    func retrieveImageFromCacheForKey(key: String)-> Image? {
        return memoryCache.objectForKey(key) as? Image
    }
    
    func isExsitForKey(key: String)-> Bool {
        return isExistInMemory(key) || isExistInDisk(key)
    }
}

// MARK: Image cache helper
extension ImageCache {
    
    func cachePathForkey(key: String)-> String {
        let fileName = self.cacheFileForKey(key)
        return (self.diskCachePath as NSString).stringByAppendingString(fileName)
    }
    
    func cacheFileForKey(key:String)-> String {
        return key.kf_MD5
    }
    
    func diskImageDataForKey(key: String)-> NSData? {
        let filePath = cachePathForkey(key)
        return NSData(contentsOfFile: filePath)
    }
    
    func isExistInMemory(key: String)-> Bool {
        return retrieveImageFromCacheForKey(key) != nil
    }
    
    func isExistInDisk(key: String)-> Bool {
        return retrieveImageFromDisk(key) != nil
    }
    
}

// MARK: Image
extension Image {
    var dj_imageCost: Int {
        return Int(size.height * size.width * scale * scale)
    }
}
