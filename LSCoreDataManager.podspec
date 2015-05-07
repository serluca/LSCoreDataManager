Pod::Spec.new do |s|
  s.name     = 'LSCoreDataManager'
  s.platform = :ios, '7.0'
  s.version  = '1.3.1'
  s.license  = 'Copyright, 2015, Luca Serpico'
  s.summary  = 'It is a nice library to manage the Core Data simplifying the developer task in performance management.'
  s.homepage = 'https://github.com/serluca/LSCoreDataManager'
  s.author  = {'Luca Serpico' => 'serpicoluca@gmail.com'}
  s.source   = { :git => 'https://github.com/serluca/LSCoreDataManager.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/serluca'
  s.requires_arc = true
  s.ios.deployment_target = '7.0'
  s.source_files = 'LSCoreDataManager/*.{h,m}'
end
