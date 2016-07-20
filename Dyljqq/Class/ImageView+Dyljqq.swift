//
//  ImageView+Dyljqq.swift
//  Dyljqq
//
//  Created by 季勤强 on 16/7/20.
//  Copyright © 2016年 季勤强. All rights reserved.
//

import UIKit

typealias ImageView = UIImageView
typealias IndicatorView = UIActivityIndicatorView

extension ImageView {
    
    // set image
    func setImageWithURL(URL: NSURL, placeholdImage: Image? = nil, progressBlock: ProgressBlock? = nil, completionHandler: CompletionHandler? = nil) {
        
        image = placeholdImage
        
        let showIndicatorWhenLoading = dj_showIndicatorWhenLoading
        var indicator: IndicatorView? = nil
        if showIndicatorWhenLoading {
            indicator = dj_indicator()
            indicator?.hidden = false
            indicator?.dj_startAnimating()
        }
        
        ImageManager.sharedManager.downloadImage(URL, progressBlock: { receivedSize, totalSize in
            
            print("receivedSize: \(receivedSize), totalSize: \(totalSize)")
            
            }, completionHandler: {[weak self] image, error in
                
                indicator?.stopAnimating()
                
                guard let sSelf = self else {
                    print("self is nil...")
                    return
                }
                
                guard let image = image else {
                    print("image is nil...")
                    return
                }
                sSelf.image = image
                completionHandler?(image: image, error: error)
                
        })
    }
    
}

// MARK: - Associated object

private var lastURLKey: Void?
private var indicatorKey: Void?
private var showIndicatorWhenLoadingKey: Void?

extension ImageView {
    
    private func dj_setWebURL(URL: NSURL) {
        objc_setAssociatedObject(self, &lastURLKey, URL, .OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    func dj_webURL()-> NSURL? {
        return objc_getAssociatedObject(self, &lastURLKey) as? NSURL
    }
    
    public var dj_showIndicatorWhenLoading: Bool {
        get {
            if let result = objc_getAssociatedObject(self, &showIndicatorWhenLoadingKey) as? NSNumber {
                return result.boolValue
            } else {
                return false
            }
        }
        
        set {
            
            if dj_showIndicatorWhenLoading == newValue {
                return
            } else {
                if newValue {
                    
                    let style = UIActivityIndicatorViewStyle.Gray
                    let indicatorView = IndicatorView(activityIndicatorStyle: style)
                    indicatorView.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleBottomMargin]
                    indicatorView.center = CGPoint(x: CGRectGetMidX(bounds), y: CGRectGetMidY(bounds))
                    indicatorView.hidden = true
                    self.addSubview(indicatorView)
                    
                    dj_setIndicator(indicatorView)
                    
                } else {
                    dj_indicator()?.removeFromSuperview()
                    dj_setIndicator(nil)
                }
                objc_setAssociatedObject(self, &showIndicatorWhenLoadingKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
        }
    }
    
    private func dj_setIndicator(indicator: IndicatorView?) {
        objc_setAssociatedObject(self, &indicatorKey, indicator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func dj_indicator()-> IndicatorView? {
        return objc_getAssociatedObject(self, &indicatorKey) as? IndicatorView
    }
    
}

// MARK: - IndicatorView

extension IndicatorView {
    
    func dj_stopAnimating() {
        stopAnimating()
        hidden = true
    }
    
    func dj_startAnimating() {
        startAnimating()
        hidden = false
    }
    
}

