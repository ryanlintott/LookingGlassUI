Pod::Spec.new do |s|
  s.name             = 'LookingGlassUI'
  s.version          = '0.3.1'
  s.summary          = 'SwiftUI views that can rotate views based on device orientation.'

  s.description      = <<-DESC
  SwiftUI views that can rotate views based on device orientation. It's especially useful in faking a light reflection to create a shimmering effect when the device rotates.
                       DESC

  s.homepage         = 'https://github.com/fethica/FRadioPlayer'
  s.author           = { 'Ryan Lintott' => '@ryanlintott' }
  s.source           = { :git => 'https://github.com/ryanlintott/LookingGlassUI.git', :tag => s.version.to_s }
  s.ios.deployment_target = '14.0'
  s.source_files = 'Sources/LookingGlassUI/**/*.swift'
end
