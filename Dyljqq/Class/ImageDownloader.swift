//
//  ImageDownloader.swift
//  Dyljqq
//
//  Created by 季勤强 on 16/7/15.
//  Copyright © 2016年 季勤强. All rights reserved.
//

import UIKit

typealias ImageDownloaderProgressBlock = ((receivedSize: Int64, totalSize: Int64) -> ())
typealias ImageDownloaderCompletionHandler = ((image: Image?, error: NSError?, imageURL: NSURL?, originData: NSData?)-> ())

private let defaultName = "defaultName"
private let barrierQueueName = "com.dyljqq.barrier"
private let ioQueueName = "com.dyl.io"
private let instance = ImageDownloader(name: defaultName)
private let ImageDownloaderFetchErrorDomain = "com.dyljqq.error.domain"

enum ImageDownloaderFetchError: Int {
    case BadData = 1000
    case InvalidURL = 2000
}

public class ImageDownloader: NSObject {
    
    typealias callbackPair = (progress: ImageDownloaderProgressBlock?, completion: ImageDownloaderCompletionHandler?)
    class ImageFetchLoad {
        var callbackPairs = [callbackPair]()
        var responseData = NSMutableData()
        var downloadTask: NSURLSessionDataTask?
    }
    
    var session: NSURLSession?
    
    public var sessionConfigure = NSURLSessionConfiguration.ephemeralSessionConfiguration() {
        didSet {
            session = NSURLSession(configuration: sessionConfigure, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        }
    }
    
    var fetchLoads = [NSURL: ImageFetchLoad]()
    
    public class var defaultDownloader: ImageDownloader {
        return instance
    }
    
    private let barrierQueue: dispatch_queue_t
    private let ioQueue: dispatch_queue_t
    
    public init(name: String) {
        if  name.isEmpty {
            fatalError("Image downloader cannot empry...")
        }
        
        barrierQueue = dispatch_queue_create(barrierQueueName + name, DISPATCH_QUEUE_CONCURRENT)
        ioQueue = dispatch_queue_create(ioQueueName + name, DISPATCH_QUEUE_CONCURRENT)
        
        super.init()
        
        session = NSURLSession(configuration: sessionConfigure, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    // fetch image from fetchLoads
    func fetchLoadForKey(key: NSURL)-> ImageFetchLoad? {
        var fetchLoad: ImageFetchLoad?
        dispatch_barrier_sync(barrierQueue, {
            fetchLoad = self.fetchLoads[key]
        })
        return fetchLoad
    }
    
}

// MARK: - Downloader method
extension ImageDownloader {
    
    func downloadImageForURL(URL: NSURL,
                             progressBlock: ImageDownloaderProgressBlock?,
                             completionHandler: ImageDownloaderCompletionHandler?) {
        let request = NSMutableURLRequest(URL: URL, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 15.0)
        if request.URL == nil || request.URL!.absoluteString.isEmpty {
            completionHandler?(image: nil, error: nil, imageURL: nil, originData: nil)
            return
        }
        
        setupProgressBlock(progressBlock, completionHandler: completionHandler, forURL: URL) { session, fetchLoad in
            if fetchLoad.downloadTask == nil {
                let dataTask = session?.dataTaskWithRequest(request)
                dataTask?.resume()
            }
            
        }
    }
    
    internal func setupProgressBlock(progressBlock: ImageDownloaderProgressBlock?, completionHandler: ImageDownloaderCompletionHandler?, forURL URL: NSURL, start:
        ((NSURLSession?, ImageFetchLoad)-> ())) {
        
        dispatch_barrier_sync(barrierQueue) {
            let loadObjectForKey = self.fetchLoads[URL] ?? ImageFetchLoad()
            let callbackPair = (progress: progressBlock, completion: completionHandler)
            loadObjectForKey.callbackPairs.append(callbackPair)
            self.fetchLoads[URL] = loadObjectForKey
            
            if let session = self.session {
                start(session, loadObjectForKey)
            }
        }
    }
    
}

// MARK: - Clean Method
extension ImageDownloader {
    
    func cleanForKey(key: NSURL) {
        dispatch_barrier_sync(barrierQueue, {
            self.fetchLoads.removeValueForKey(key)
        })
        
    }
    
}

extension ImageDownloader: NSURLSessionDataDelegate {
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        print("downloading...")
        if let URL = dataTask.response?.URL, fetchLoad = self.fetchLoads[URL] {
            fetchLoad.responseData.appendData(data)
            
            for callbackPair in fetchLoad.callbackPairs {
                dispatch_async(dispatch_get_main_queue(), {
                    callbackPair.progress?(receivedSize: Int64(fetchLoad.responseData.length), totalSize: dataTask.response!.expectedContentLength)
                })
            }
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let URL = task.response?.URL {
            if let error = error {
                callbackWithImage(nil, error: error, imageURL: URL, originData: nil)
            } else {
                progressImageForTask(task, URL: URL)
            }
        }
    }
    
    private func callbackWithImage(image: Image?, error: NSError?, imageURL:NSURL, originData: NSData?) {
        if let callbackPairs = self.fetchLoadForKey(imageURL)?.callbackPairs {
            self.cleanForKey(imageURL)
            
            for callbackPair in callbackPairs {
                dispatch_async(dispatch_get_main_queue(), {
                    callbackPair.completion?(image: image, error: error, imageURL: imageURL, originData: originData)
                })
            }
        }
    }
    
    private func progressImageForTask(task: NSURLSessionTask?, URL: NSURL) {
        
        if let fetchLoad = self.fetchLoads[URL] {
            if let image = Image(data: fetchLoad.responseData) {
                callbackWithImage(image, error: nil, imageURL: URL, originData: fetchLoad.responseData)
            } else {
                callbackWithImage(nil, error: NSError(domain: ImageDownloaderFetchErrorDomain, code: ImageDownloaderFetchError.BadData.rawValue, userInfo: nil), imageURL: URL, originData: nil)
            }
        } else {
            callbackWithImage(nil, error: NSError(domain: ImageDownloaderFetchErrorDomain, code: ImageDownloaderFetchError.BadData.rawValue, userInfo: nil), imageURL: URL, originData: nil)
        }
        
    }
    
}
