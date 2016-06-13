Pod::Spec.new do |s|

  s.name         = "AWebImage"
  s.version      = "0.1.0"
  s.summary      = "A library for downloading and caching image from web."

  s.description  = <<-DESC
		 A library for downloading and caching image from web. Implemented by NSURLCache in Swift.
                   DESC

  s.homepage     = "https://github.com/adow/AWebImage.git"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.authors            = { "adow" => "reynoldqin@gmail.com" }
  s.social_media_url   = "https://github.com/adow"

  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/adow/AWebImage.git", :tag => s.version }
  s.source_files  = "AWebImage/*.{h,swift}"
  s.requires_arc = true
  s.framework = "Foundation"
end
