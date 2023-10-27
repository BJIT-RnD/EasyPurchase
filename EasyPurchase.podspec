Pod::Spec.new do |spec|
  spec.name          = "EasyPurchase"
  spec.version       = "1.0.0"
  spec.summary       = "An easy-to-use In-App Purchase library for iOS."
  spec.description   = "All basic functionalities are available to integrate In-App purchase in iOS project."
  spec.homepage      = "https://github.com/BJIT-RnD/EasyPurchase.git"
  spec.license       = "MIT"
  spec.author        = { "BJIT" => "rnd@bjitgroup.com" }
  spec.platform      = :ios, "11.0"
  spec.source        = { :git => "https://github.com/BJIT-RnD/EasyPurchase.git", :tag => "1.0.0" }
  spec.source_files  = "Sources/EasyPurchase/**/*"
  spec.requires_arc  = true
  spec.swift_version = "5.0"
end
