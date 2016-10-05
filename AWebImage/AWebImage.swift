//
//  AWebImage.swift
//  AWebImage
//
//  Created by 秦 道平 on 16/6/1.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation
import UIKit

public typealias AWImageLoaderCallback = (UIImage,URL) -> ()
public typealias AWImageLoaderCallbackList = [AWImageLoaderCallback]


private let emptyImage = UIImage()
// MARK: - AWImageLoaderManager
private let _sharedManager = AWImageLoaderManager()

open class AWImageLoaderManager {
    /// 用来保存生成好图片
    var fastCache : NSCache<NSString, AnyObject>!
    /// 回调列表
    var fetchList:[String:AWImageLoaderCallbackList] = [:]
    /// 用于操作回调列表的队列
    var fetchListOperationQueue:DispatchQueue = DispatchQueue(label: "adow.adimageloader.fetchlist_operation_queue", attributes: DispatchQueue.Attributes.concurrent)
    /// 用于继续图片编码的队列
    var imageDecodeQueue : DispatchQueue = DispatchQueue(label: "adow.awimageloader.decode_queue", attributes: DispatchQueue.Attributes.concurrent)
    /// http 操作
    var sessionConfiguration : URLSessionConfiguration!
    /// http 队列
    var sessionQueue : OperationQueue!
    /// 共享单个 session
    lazy var defaultSession : URLSession! = URLSession(configuration: self.sessionConfiguration, delegate: nil, delegateQueue: self.sessionQueue)
    fileprivate init () {
        fastCache = NSCache()
        fastCache.totalCostLimit = 30 * 1024 * 1024
        sessionQueue = OperationQueue()
        sessionQueue.maxConcurrentOperationCount = 6
        sessionQueue.name = "adow.adimageloader.session"
        sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.requestCachePolicy = .useProtocolCachePolicy
        sessionConfiguration.timeoutIntervalForRequest = 3
        sessionConfiguration.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024,
                                                   diskCapacity: 30 * 1024 * 1024,
                                                   diskPath: "adow.adimageloader.urlcache")
    }
    open static var sharedManager : AWImageLoaderManager {
        return _sharedManager
    }
    
}
extension AWImageLoaderManager {
    func readFetch(_ key:String) -> AWImageLoaderCallbackList? {
        return fetchList[key]
    }
    func addFetch(_ key:String, callback:@escaping AWImageLoaderCallback) -> Bool {
        var skip = false
        let f_list = fetchList[key]
        if f_list != nil {
            skip = true
        }
        fetchListOperationQueue.sync(flags: .barrier, execute: {
            if var f_list = f_list {
                f_list.append(callback)
                self.fetchList[key] = f_list
//                NSLog("callback list:%d",f_list.count)
            }
            else {
                self.fetchList[key] = [callback,]
            }
        }) 
        return skip
        
    }
    func removeFetch(_ key:String) {
        _ = fetchListOperationQueue.sync(flags: .barrier, execute: {
            self.fetchList.removeValue(forKey: key)
        }) 
    }
    func clearFetch() {
        fetchListOperationQueue.async(flags: .barrier, execute: {
            self.fetchList.removeAll()
        }) 
    }
    
}
extension AWImageLoaderManager {
    public func clearCache() {
        self.fastCache.removeAllObjects()
        self.sessionConfiguration.urlCache?.removeAllCachedResponses()
    }
}

// MARK: - AWImageLoader
open class AWImageLoader : NSObject {
    var task : URLSessionTask?
    public override init() {
        super.init()
        
    }
}

extension AWImageLoader {
    /// 获取已经处理号的图片
    public func imageFromFastCache(_ url:URL) -> UIImage? {
        let fetch_key = url.absoluteString
        return AWImageLoaderManager.sharedManager.fastCache.object(forKey: fetch_key as NSString) as? UIImage
    
    }
    public func downloadImage(_ url:URL, callback : @escaping AWImageLoaderCallback){
        if let cached_image = self.imageFromFastCache(url) {
            callback(cached_image, url)
            return
        }
        let fetch_key = url.absoluteString
        /// 用来将图片返回到所有的回调函数
        let f_callback = {
            (image:UIImage) -> () in
            if let f_list = AWImageLoaderManager.sharedManager.readFetch(fetch_key) {
                AWImageLoaderManager.sharedManager.removeFetch(fetch_key)
                DispatchQueue.concurrentPerform(iterations: f_list.count, execute: { (i) in
                    let f = f_list[i]
                    f(image,url)
                })
            }
        }
        /// origin
        let skip = AWImageLoaderManager.sharedManager.addFetch(fetch_key, callback: callback)
        if skip {
//            NSLog("skip")
            return
        }
        /// request
        let session = AWImageLoaderManager.sharedManager.defaultSession
        let request = URLRequest(url: url)
        self.task = session?.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                NSLog("error:%@", error.localizedDescription)
            }
            /// no data
            guard let _data = data else {
                NSLog("no image:\(url.absoluteString)")
                f_callback(emptyImage)
                return
            }
            AWImageLoaderManager.sharedManager.imageDecodeQueue.async(execute: {
//                NSLog("origin:%@", url.absoluteString)
                let image = UIImage(data: _data) ?? emptyImage
                AWImageLoaderManager.sharedManager.fastCache.setObject(image, forKey: fetch_key as NSString) /// fastCachehttps://github.com/vim                f_callback(image)
                return
            })
        }) 
        self.task?.resume()
    }
}
extension AWImageLoader {
    public func cancelTask() {
        guard let _task = self.task else {
            return
        }
        if _task.state == .running || _task.state == .running {
           _task.cancel()
        }
    }
}
