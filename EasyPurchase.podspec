Pod::Spec.new do |s|
  s.name         = "EasyPurchase"
  s.version      = "1.0.0"
  s.summary      = "An easy-to-use In-App Purchase library for iOS."
  s.license = "MIT"
  s.homepage     = "https://github.com/BJIT-RnD/EasyPurchase"
  s.author       = { "BJIT" => "bjit@bjitgroup.com" }
  s.ios.deployment_target = "11.0"
  s.swift_version = "5.0"
  s.source = { :git => "https://github.com/BJIT-RnD/EasyPurchase.git", :tag => "v1.0.0" }
  s.source_files = "Sources/EasyPurchase/**/*.swift"
  s.requires_arc = true
  s.documentation_url = "https://github.com/BJIT-RnD/EasyPurchase#readme"
  s.test_spec "Tests" do |test_spec|
    test_spec.source_files = "Tests/**/*.swift"
    test_spec.requires_app_host = true
    test_spec.libraries = "swiftSyntax" # Optional, specify any test dependencies
    test_spec.xcconfig = { "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "UNIT_TEST" }
  end
end
