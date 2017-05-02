//
//  AWExtensions.swift
//  AWebImage
//
//  Created by 秦 道平 on 16/6/5.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation
extension String {
    static func stringFromAnyObject(_ anyObject:AnyObject?) -> String?{
        if let s = anyObject as? String {
            return s
        }
        else if let s = anyObject as? Int {
            return "\(s)"
        }
        else if let s = anyObject as? Double {
            return "\(s)"
        }
        else {
            return nil
        }
    }
    static func isNilOrEmpty(_ str:String?) -> Bool{
        let length = str?.lengthOfBytes(using: String.Encoding.utf8) ?? 0
        return length == 0
    }
}
extension String {
    func toDouble()->Double{
        return NSString(string: self).doubleValue
    }
    func bus_escape() -> (String) {
        let raw: NSString = self as NSString
        let str = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,raw,"[]." as CFString!,":/?&=;+!@#$()',*" as CFString!,CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue))
        return str! as String
    }
    /// 解码 base64
    func bus_decodeBase64()->String{
        //        let data = self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        let data_decode = Data(base64Encoded: self, options: NSData.Base64DecodingOptions(rawValue: 0))
        return NSString(data: data_decode!, encoding: String.Encoding.utf8.rawValue)! as String
    }
    func stringbyappendingPathcomponent(_ component:String)->String{
        return URL(string: self)!.appendingPathComponent(component).absoluteString
    }
}
extension Int {
    static func valueFromAnyObject(_ anyObject:AnyObject?) -> Int? {
        if let v = anyObject as? Int {
            return v
        }
        if let s = anyObject as? String {
            return (s as NSString).integerValue
        }
        else {
            return nil
        }
    }
}
extension Double {
    static func valueFromAnyObject(_ anyObject:AnyObject?) -> Double? {
        if let v = anyObject as? Double {
            return v
        }
        else if let s = anyObject as? String {
            return (s as NSString).doubleValue
        }
        else {
            return nil
        }
    }
}
