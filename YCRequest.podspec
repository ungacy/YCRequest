#
# Be sure to run `pod lib lint YCRequest.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YCRequest'
  s.version          = '0.1.21'
  s.summary          = 'YCRequest.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
YCRequest with AFNetworking
                       DESC

  s.homepage         = 'https://github.com/ungacy/YCRequest'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'ungacy' => 'ungacy@126.com' }
  s.source           = { :git => 'https://github.com/ungacy/YCRequest.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/ungacy'

  s.ios.deployment_target = '8.0'

  s.source_files = 'YCRequest/Classes/*.{h,m}'
  s.public_header_files = 'YCRequest/Classes/YC*.h'
  
  s.dependency 'AFNetworking/NSURLSession'
  s.ios.frameworks = 'MobileCoreServices', 'SystemConfiguration'

end
