//
//  AWebImageProcess.swift
//  AWebImage
//
//  Created by 秦 道平 on 2016/12/18.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import Foundation

public protocol AWebImageProcess {
    var processName : String {get set}
    init()
    func make(fromInputImage inputImage : UIImage) -> UIImage?
    var cacheKey : String{get}
}

/// 创建圆角图片
public struct AWebRoundImageProcess : AWebImageProcess {
    public var processName: String = "adow.awebimageprocess.roundimageprocess"
    private var cornerRadius : CGFloat = 3.0
    public init() {
        
    }
    public init(cornerRadius : CGFloat) {
        self.cornerRadius = cornerRadius
    }
    public var cacheKey: String {
        return "\(self.processName).\(Int(self.cornerRadius))"
    }
    public func make(fromInputImage inputImage: UIImage) -> UIImage? {
        if inputImage.size == CGSizeZero {
            NSLog("zero image")
            return inputImage
        }
        UIGraphicsBeginImageContext(inputImage.size)
        let context = UIGraphicsGetCurrentContext()!
        CGContextSaveGState(context)
        let path = UIBezierPath(roundedRect: CGRectMake(0.0,
                        0.0,
                        inputImage.size.width,
                        inputImage.size.height),
                    cornerRadius: self.cornerRadius)
        path.addClip()
        inputImage.drawInRect(CGRectMake(0.0,
            0.0,
            inputImage.size.width,
            inputImage.size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        CGContextRestoreGState(context)
        UIGraphicsEndImageContext()
        return image
    }
}
/// 创建原型图片
public struct AWebCircleImageProcess : AWebImageProcess {
    public var processName: String = "adow.awebimageprocess.circleimageprocess"
    public init() {
        
    }
    public var cacheKey: String {
        return self.processName
    }
    public func make(fromInputImage inputImage: UIImage) -> UIImage? {
        let w : CGFloat = min(inputImage.size.width, inputImage.size.height)
        UIGraphicsBeginImageContext(inputImage.size)
        let context = UIGraphicsGetCurrentContext()!
        CGContextSaveGState(context)
        let path = UIBezierPath(arcCenter: CGPointMake(inputImage.size.width / 2.0, inputImage.size.height / 2.0),
                                radius: w / 2.0,
                                startAngle: 0.0, endAngle: CGFloat(M_PI) * 2.0, clockwise: true)
        path.addClip()
        inputImage.drawInRect(CGRectMake(0.0, 0.0, inputImage.size.width, inputImage.size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        CGContextRestoreGState(context)
        UIGraphicsEndImageContext()
        return image
    }
}
/// 创建方形图片
public struct AWebSquareImageProcess : AWebImageProcess {
    public var processName: String = "adow.awebimageprocess.squareimageprocess"
    public init() {
        
    }
    public var cacheKey: String {
        return self.processName
    }
    public func make(fromInputImage inputImage: UIImage) -> UIImage? {
        if inputImage.size == CGSizeZero {
            return inputImage
        }
        let old_width = inputImage.size.width
        let old_height = inputImage.size.height
        var target_width : CGFloat = 0.0
        var target_height : CGFloat = 0.0
        var clip : CGFloat = 0.0
        if old_width < old_height {
            clip = old_width
            target_width = old_width
            target_height = target_width * old_height / old_width
        }
        else {
            clip = old_height
            target_height = old_height
            target_width = target_height * old_width / old_height
        }
        let left = (target_width - old_width) / 2.0
        let top = (target_height - old_height) / 2.0
        let rect = CGRectMake(left, top, target_width, target_height)
        UIGraphicsBeginImageContext(CGSizeMake(clip, clip))
        let context = UIGraphicsGetCurrentContext()!
        CGContextSaveGState(context)
        inputImage.drawInRect(rect)
        let output_image = UIGraphicsGetImageFromCurrentImageContext()
        CGContextRestoreGState(context)
        UIGraphicsEndImageContext()
        return output_image
    }
}
/// 缩小图片(按照小的一边)
public struct AWebResizeImageProcess : AWebImageProcess {
    public var processName: String = "adow.awebimageprocess.resizeimageprocess"
    var w : CGFloat = 0.0
    public var cacheKey: String {
       return "\(processName).\(Int(w))"
    }
    public init() {
        
    }
    public init(w : CGFloat) {
        self.w = w
    }
    public func make(fromInputImage inputImage: UIImage) -> UIImage? {
        /// 如果太小就返回原图
        if fmin(inputImage.size.width, inputImage.size.height) < w {
            return inputImage
        }
        let old_width = inputImage.size.width
        let old_height = inputImage.size.height
        var target_width : CGFloat = 0.0
        var target_height : CGFloat = 0.0
        if old_width < old_height {
            target_width = w
            target_height = target_width * old_height / old_width
        }
        else {
            target_height = w
            target_width = target_height * old_width / old_height
        }
        let rect = CGRectMake(0.0, 0.0, target_width, target_height)
        UIGraphicsBeginImageContext(CGSizeMake(target_width, target_height))
        let context = UIGraphicsGetCurrentContext()!
        CGContextSaveGState(context)
        inputImage.drawInRect(rect)
        let output_image = UIGraphicsGetImageFromCurrentImageContext()
        CGContextRestoreGState(context)
        UIGraphicsEndImageContext()
        return output_image
    }
}
public struct AWebCropImageProcess : AWebImageProcess {
    public var processName: String = "adow.awebimageprocess.cropimageprocess"
    public var targetWidth: CGFloat = 0.0
    public var targetHeight : CGFloat = 0.0
    public var cacheKey: String {
        return "\(processName).\(Int(targetWidth))_\(Int(targetHeight))"
    }
    public init() {
        
    }
    public init(targetWidth : CGFloat, targetHeight : CGFloat) {
        self.targetWidth = targetWidth
        self.targetHeight = targetHeight
    }
    public func make(fromInputImage inputImage: UIImage) -> UIImage? {
        let (original_width, original_height) = (inputImage.size.width, inputImage.size.height)
        var (resize_width, resize_height) = (self.targetWidth, self.targetHeight)
//        let original_direction = original_width > original_height
//        let target_direction = self.targetWidth > self.targetHeight
//        if original_direction != target_direction {
//            if original_width < original_height {
//                resize_width = targetWidth
//                resize_height = resize_width * original_height / original_width
//            }
//            else {
//                resize_height = targetHeight
//                resize_width = resize_height * original_width / original_height
//            }
//        }
//        else {
//            if original_width < original_height {
//                resize_width = targetWidth
//                resize_height = resize_width * original_height / original_width
//            }
//            else {
//                resize_height = targetHeight
//                resize_width = resize_height * original_width / original_height
//            }
//        }
        if original_width < original_height {
            resize_width = targetWidth
            resize_height = resize_width * original_height / original_width
        }
        else {
            resize_height = targetHeight
            resize_width = resize_height * original_width / original_height
        }
        let left : CGFloat = (self.targetWidth - resize_width) / 2.0
        let top : CGFloat = (self.targetHeight - resize_height) / 2.0
        let rect = CGRectMake(left, top, resize_width, resize_height)
        debugPrint(rect)
        UIGraphicsBeginImageContext(CGSizeMake(self.targetWidth, self.targetHeight))
        let context = UIGraphicsGetCurrentContext()!
        CGContextSaveGState(context)
        inputImage.drawInRect(rect)
        let output_image = UIGraphicsGetImageFromCurrentImageContext()
        CGContextRestoreGState(context)
        UIGraphicsEndImageContext()
        return output_image
    }
    
}
