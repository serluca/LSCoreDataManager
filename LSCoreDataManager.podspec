Pod::Spec.new do |s|
  s.name     = 'LSCoreDataManager'
  s.platform = :ios, '7.0'
  s.version  = '1.0'
  s.license  = 'Copyright, 2014, Luca Serpico'
  s.summary  = 'It is a nice library to manage the Core Data simplifying the developer task in performance management.'
  s.homepage = 'https://github.com/serluca/LSCoreDataManager'
  s.author  = {'Luca Serpico' => 'serpicoluca@gmail.com'}
  s.source   = { :git => 'git@github.com:serluca/LSCoreDataManager.git', :tag => '1.0' }
  s.requires_arc = true
  s.ios.deployment_target = '7.0'
  s.source_files = 'LSCoreDataManager/*.{h,m}'
end
