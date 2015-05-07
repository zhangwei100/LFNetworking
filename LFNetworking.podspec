Pod::Spec.new do |s|
  s.name     = 'LFNetworking'
  s.version  = '0.0.3'
  s.license  = 'MIT'
  s.summary  = 'A lightweight networking framework.'
  s.homepage = 'https://github.com/zhangwei100/LFNetworking'
  s.authors  = { 'Wei Zhang' => 'zhangwei100@gmail.com' }
  s.source   = { :git => 'https://github.com/zhangwei100/LFNetworking.git', :tag => "0.0.3", :submodules => false }
  s.requires_arc = true

  s.dependency 'AFNetworking', '~> 2.5.1'

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'LFNetworking/*', 'LFNetworking/ThirdParty/*'
  s.exclude_files = 'Example'
  
  s.ios.frameworks = 'MobileCoreServices', 'CoreGraphics', 'Security'
  s.osx.frameworks = 'CoreServices', 'Security'

end
