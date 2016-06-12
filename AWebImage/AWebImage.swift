//
//  AWebImage.swift
//  AWebImage
//
//  Created by 秦 道平 on 16/6/1.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation
import UIKit

public typealias AWImageLoaderCallback = (UIImage,NSURL) -> ()
public typealias AWImageLoaderCallbackList = [AWImageLoaderCallback]


private let emptyImage = UIImage()
// MARK: - AWImageLoaderManager
private let _sharedManager = AWImageLoaderManager()

private class AWImageLoaderManager {
    /// 用来保存生成好图片
    var fastCache : NSCache!
    /// 回调列表
    var fetchList:[String:AWImageLoaderCallbackList] = [:]
    /// 用于操作回调列表的队列
    var fetchListOperationQueue:dispatch_queue_t = dispatch_queue_create("adow.adimageloader.fetchlist_operation_queue", DISPATCH_QUEUE_CONCURRENT)
    /// 用于继续图片编码的队列
    var imageDecodeQueue : dispatch_queue_t = dispatch_queue_create("adow.awimageloader.decode_queue", DISPATCH_QUEUE_CONCURRENT)
    /// http 操作
    var sessionConfiguration : NSURLSessionConfiguration!
    /// http 队列
    var sessionQueue : NSOperationQueue!
    /// 共享单个 session
    lazy var defaultSession : NSURLSession! = NSURLSession(configuration: self.sessionConfiguration, delegate: nil, delegateQueue: self.sessionQueue)
    private init () {
        fastCache = NSCache()
        fastCache.totalCostLimit = 30 * 1024 * 1024
        sessionQueue = NSOperationQueue()
        sessionQueue.maxConcurrentOperationCount = 6
        sessionQueue.name = "adow.adimageloader.session"
        sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfiguration.requestCachePolicy = .UseProtocolCachePolicy
        sessionConfiguration.timeoutIntervalForRequest = 3
        sessionConfiguration.URLCache = NSURLCache(memoryCapacity: 10 * 1024 * 1024,
                                                   diskCapacity: 30 * 1024 * 1024,
                                                   diskPath: "adow.adimageloader.urlcache")
    }
    static var sharedManager : AWImageLoaderManager {
        return _sharedManager
    }
    
}
extension AWImageLoaderManager {
    func readFetch(key:String) -> AWImageLoaderCallbackList? {
        return fetchList[key]
    }
    func addFetch(key:String, callback:AWImageLoaderCallback) -> Bool {
        var skip = false
        let f_list = fetchList[key]
        if f_list != nil {
            skip = true
        }
        dispatch_barrier_sync(fetchListOperationQueue) {
            if var f_list = f_list {
                f_list.append(callback)
                self.fetchList[key] = f_list
//                NSLog("callback list:%d",f_list.count)
            }
            else {
                self.fetchList[key] = [callback,]
            }
        }
        return skip
        
    }
    func removeFetch(key:String) {
        dispatch_barrier_sync(fetchListOperationQueue) {
            self.fetchList.removeValueForKey(key)
        }
    }
    func clearFetch() {
        dispatch_barrier_async(fetchListOperationQueue) {
            self.fetchList.removeAll()
        }
    }
    
}
extension AWImageLoaderManager {
    func clearCache() {
        self.fastCache.removeAllObjects()
        self.sessionConfiguration.URLCache?.removeAllCachedResponses()
    }
}

// MARK: - AWImageLoader
public class AWImageLoader : NSObject {
    var task : NSURLSessionTask?
    public override init() {
        super.init()
        
    }
}

extension AWImageLoader {
    /// 获取已经处理号的图片
    public func imageFromFastCache(url:NSURL) -> UIImage? {
        let fetch_key = url.absoluteString
        return AWImageLoaderManager.sharedManager.fastCache.objectForKey(fetch_key) as? UIImage
    
    }
    public func downloadImage(url:NSURL, callback : AWImageLoaderCallback){
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
                dispatch_apply(f_list.count, dispatch_get_main_queue(), { (i) in
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
        let request = NSURLRequest(URL: url)
        self.task = session.dataTaskWithRequest(request) { (data, response, error) in
            if let error = error {
                NSLog("error:%@", error.domain)
            }
            /// no data
            guard let _data = data else {
                NSLog("no image:%@", url.absoluteString)
                f_callback(emptyImage)
                return
            }
            dispatch_async(AWImageLoaderManager.sharedManager.imageDecodeQueue, {
//                NSLog("origin:%@", url.absoluteString)
                let image = UIImage(data: _data) ?? emptyImage
                AWImageLoaderManager.sharedManager.fastCache.setObject(image, forKey: fetch_key) /// fastCache
                f_callback(image)
                return
            })
        }
        self.task?.resume()
    }
}
extension AWImageLoader {
    public func cancelTask() {
        guard let _task = self.task else {
            return
        }
        if _task.state == .Running || _task.state == .Running {
           _task.cancel()
        }
    }
}
