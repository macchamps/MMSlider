#
# Be sure to run `pod lib lint MMSlider.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MMSlider'
  s.version          = "1.0.0"
  s.summary          = 'UISlider clone with multiple thumbs and values, optional snap intervals, optional value labels.'

  s.swift_version = '4.2'
  s.swift_versions = ['4.2', '5.0']
  s.platform     = :ios, "9.0"
  s.requires_arc = true

  s.homepage         = 'https://github.com/macchamps/MMSlider'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'macchamps' => 'monang.1995@gmail.com' }
  s.social_media_url   = "https://monangchampaneri.info"
  s.source           = { :git => 'https://github.com/macchamps/MMSlider.git', :tag => s.version.to_s }
  s.source_files = 'MMSlider/Classes/**/*'

  
  s.dependency 'SweeterSwift'
  s.dependency 'AvailableHapticFeedback'
end
