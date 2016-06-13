# AWebImage

使用 NSURLCache 缓存实现的简单图片下载库；

## 使用

	import AWebImage
	
	let url = NSURL(string: "https://drscdn.500px.org/photo/156556773/q%3D80_m%3D1000/93815cf3d792ce50d26b00fe53018061")!
	let loader = AWImageLoader()
	loader.downloadImage(url) { [weak self][img,url] in 
		self?.imageView.image = img
	}
	
### 使用 UIImageView+AWebImage

	let url = NSURL(string: "https://drscdn.500px.org/photo/156556773/q%3D80_m%3D1000/93815cf3d792ce50d26b00fe53018061")!
	self.imageView.aw_downloadImageURL(url, showLoading: true, completionBlock: { (_, _) in
                                
    })  
	

## 安装

### Carthage

在项目中创建 Cartfile 文件，并添加下面内容

	git "https://github.com/adow/AWebImage.git" >= 0.1.0
	
运行 `Carthage update`, 获取 AWebImage;

拖动 `Carthage/Build/iOS` 下面的 `AWebImage.framwork` 到项目 Targets, General 设置标签的 `Linked Frameworks and Linraries` 中；
在 Targes 的 `Build Phases` 设置中，点击 + 按钮，添加 `New Run Script Phase` 来添加脚本:

	/usr/local/bin/carthage copy-frameworks
	
同时在下面的 `Input Files` 中添加:

	$(SRCROOT)/Carthage/Build/iOS/AWebImage.framework

### Cocoapods
	
	source 'https://github.com/CocoaPods/Specs.git'
	platform :ios, '8.0'
	use_frameworks!
	
	pod 'AWebImage', '~> 0.1.2'
	
### Git Submodule

通过 Submodule 将 AWebImage 作为 Embedded Framework 添加到项目中。

1. 首先确保项目已经在 git 仓库中;
2. 添加 AWebImage 作为 Submodule:

		git submodule add https://github.com/adow/AWebImage.git

3. 在 Xcode 中打开项目，将 AWebImage.xcodeproj 拖放到你的项目的根目录下;

4. 在你的项目下，选择 Targets , General 中添加 `Embedded Binaries`, 选择 `AWebImage.framework`, 确保 `Build Phases` 中的 `Link Binary with Libraries` 中有 `AWebImage.framework`;

### 直接集成

`iOS 7` 及以下版本无法使用 `Embedeed Framework`, 只能把 `AWebImage.swift`, `UIImageView+AWebImage.swift` 复制到项目中，使用的时候也不用 `import AWebImage`.

