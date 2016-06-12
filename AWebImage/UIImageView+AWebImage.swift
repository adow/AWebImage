//
//  UIImageView+AWebImage.swift
//  AWebImage
//
//  Created by 秦 道平 on 16/6/2.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation
import UIKit
private var imageUrlKey : Void?
private var imageSetKey : Void?
private let imageLoadHudTag = 99989

public extension UIImageView {
    /// 下载的 imageurl
    public var aw_image_url : NSURL? {
        get{
            return objc_getAssociatedObject(self, &imageUrlKey) as? NSURL
        }
        set {
            objc_setAssociatedObject(self, &imageUrlKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    public var aw_image_set : Bool {
        get{
            return (objc_getAssociatedObject(self, &imageSetKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &imageSetKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
extension UIImageView {
    /// 显示载入提示
    func aw_showLoading() {
        if let hud = self.viewWithTag(imageLoadHudTag) as? UIActivityIndicatorView {
            hud.startAnimating()
            return
        }
        else {
            let hud = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            hud.tag = imageLoadHudTag
            hud.center = self.center
            hud.hidesWhenStopped = true
            self.addSubview(hud)
            self.bringSubviewToFront(hud)
            hud.center = self.center
            hud.startAnimating()
        }
    }
    /// 结束载入提示
    func aw_hideLoading() {
        if let hud = self.viewWithTag(imageLoadHudTag) as? UIActivityIndicatorView {
            hud.stopAnimating()
            return
        }
    }
}
public extension UIImageView {
    /// 为了要执行 selector
    private class _AWImageLoaderPar :NSObject{
        var url : NSURL!
        var showLoading:Bool!
        var completionBlock : AWImageLoaderCallback!
        init(url:NSURL, showLoading:Bool, completionBlock : AWImageLoaderCallback) {
            self.url = url
            self.showLoading = showLoading
            self.completionBlock = completionBlock
        }
        
    }
    /// 下载图片,如果有 delay 参数，那他会在 NSDefaultRunLoopMode 模式下运行
    public func aw_downloadImageURL(url:NSURL,
                                   showLoading:Bool,
                                   completionBlock:AWImageLoaderCallback){
        /// 先设置要下载的图片地址
        self.aw_image_url = url
        if showLoading {
            self.aw_showLoading()
        }
        let loader = AWImageLoader()
        loader.downloadImage(url) { [weak self](image, url) in
            if showLoading {
                self?.aw_hideLoading()
            }
            guard let _self = self, let _aw_image_url = _self.aw_image_url else {
                NSLog("no imageView")
                return
            }
            /// 校验一下现在是否还需要显示这个地址的图片
            if _aw_image_url.absoluteString != url.absoluteString {
                NSLog("url not match:%@,%@", _aw_image_url,url)
            }
            else{
                self?.aw_setImage(image)
                completionBlock(image,url)
            }
        }
    }
    /// 延时提交的方法，由于这个方法延时提交，所以可能 cell 在下一次的 reuse 中已经获得了 image， 而此时又开始执行这个方法时就第二次获得了内容，他又会替换第一次的内容；
    @objc private func aw_downloadImageURL_p(par:_AWImageLoaderPar) {
        if self.aw_image_set {
            NSLog("image existed")
            return
        }
        self.aw_downloadImageURL(par.url, showLoading: par.showLoading, completionBlock: par.completionBlock)
    }
    /// 只在 DefaultRunLoopMode 模式中加载
    public func aw_downloadImageURL_delay(url:NSURL,
                                   showloading:Bool,
                                   completionBlock : AWImageLoaderCallback) {
        /// 要一开始就重置状态，因为后面的方法被延时提交，而在返回的时候可能已经又其他图片从快速缓存中获取了
        self.aw_image_set = false
        /// 如果已经有存在的图片，就不要在 DefaultRunLoopMode 中加载
        let loader = AWImageLoader()
        if let cached_image = loader.imageFromFastCache(url) {
            self.aw_hideLoading()
            self.aw_setImage(cached_image)
            self.aw_image_url = url
            completionBlock(cached_image, url)
            return
        }
        /// 开始延时获取图片任务
        let par = _AWImageLoaderPar(url: url, showLoading: showloading, completionBlock: completionBlock)
        self.performSelector(#selector(UIImageView.aw_downloadImageURL_p(_:)), withObject: par, afterDelay: 0.0, inModes: [NSDefaultRunLoopMode,])
    }
    @objc
    private func aw_setImage(image:UIImage){
        self.image = image
        self.aw_image_set = true
    }
}