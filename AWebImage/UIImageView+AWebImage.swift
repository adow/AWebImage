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
private let imageLoadHudTag = 99989

extension UIImageView {
    /// 下载的 imageurl
    var aw_image_url : NSURL? {
        get{
            return objc_getAssociatedObject(self, &imageUrlKey) as? NSURL
        }
        set {
            objc_setAssociatedObject(self, &imageUrlKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
            hud.translatesAutoresizingMaskIntoConstraints = false
            let constraints_CenterX = NSLayoutConstraint(item: hud, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
            let constraints_CenterY = NSLayoutConstraint(item: hud, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
            self.addConstraints([constraints_CenterX,constraints_CenterY])
            hud.startAnimating()
        }
    }
    /// 结束载入提示
    func aw_hideLoading() {
        if let hud = self.viewWithTag(imageLoadHudTag) as? UIActivityIndicatorView {
            hud.stopAnimating()
            hud.removeFromSuperview()
            return
        }
    }
}
extension UIImageView {
    /// 下载图片,如果有 delay 参数，那他会在 NSDefaultRunLoopMode 模式下运行
    func aw_downloadImageURL_delay(url:NSURL,
                                   delay:Bool,showLoading:Bool,
                                   completionBlock:AWImageLoaderCallback){
        /// 先设置要下载的图片地址
        self.aw_image_url = url
        self.aw_showLoading()
        let loader = AWImageLoader()
        loader.downloadImage(url) { [weak self](image, url) in
            self?.aw_hideLoading()
            guard let _self = self, let _aw_image_url = _self.aw_image_url else {
                NSLog("no imageView")
                return
            }
            /// 校验一下现在是否还需要显示这个地址的图片
            if _aw_image_url.absoluteString != url.absoluteString {
                NSLog("url not match:%@,%@", _aw_image_url,url)
            }
            else{
                if delay {
                    self?.performSelector(#selector(UIImageView.aw_setImage(_:)),
                                          withObject: image,
                                          afterDelay: 0.0, inModes: [NSDefaultRunLoopMode])
                }
                else{
                    self?.image = image
                }
                completionBlock(image,url)
            }
        }
    }
    /// 直接在在所有模式贴图
    func aw_downloadImageURL(url:NSURL,
                             completionBlock:AWImageLoaderCallback){
        self.aw_downloadImageURL_delay(url,
                                       delay: false,
                                       showLoading: true ,
                                       completionBlock: completionBlock)
    }
    /// 在所有模式下贴图，可以选择是否显示载入
    func aw_downloadImageURL_loading(url: NSURL,
                                     showLoading:Bool,
                                     completionBlock:AWImageLoaderCallback) {
        self.aw_downloadImageURL_delay(url,
                                       delay: false,
                                       showLoading: showLoading,
                                       completionBlock: completionBlock)
    }
    @objc
    private func aw_setImage(image:UIImage){
        self.image = image
    }
}