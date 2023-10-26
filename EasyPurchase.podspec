Pod::Spec.new do |s|
  s.name         = "EasyPurchase"
  s.version      = "1.0.0"
  s.summary      = "An easy-to-use In-App Purchase library for iOS."
  s.license      = "MIT"
  s.homepage     = "https://github.com/BJIT-RnD/EasyPurchase"
  s.author       = { "BJIT" => "bjit@bjitgroup.com" }
  s.swift_version = "5.0"
  s.source       = { :git => "https://github.com/BJIT-RnD/EasyPurchase.git", :tag => "v1.0.0" }
  s.source_files = "Sources/EasyPurchase/**/*.swift"
  s.requires_arc = true
  s.documentation_url = "https://github.com/BJIT-RnD/EasyPurchase#readme"
end
