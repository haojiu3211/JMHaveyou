Pod::Spec.new do |s|
  s.name             = 'YPImagePicker'
  s.version          = "5.3.2-local"
  s.summary          = "Instagram-like image picker & filters for iOS (local fork)"
  s.homepage         = "https://github.com/Yummypets/YPImagePicker"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.authors = { 'S4cha'   => 'https://twitter.com/sachadso',
                'NikeKov' => 'nikkovios@gmail.com' }
  s.platform         = :ios
  s.source           = { :path => '.' }
  s.ios.deployment_target = "15.0"
  s.source_files = 'Source/**/*.swift'
  s.dependency 'SteviaLayout', '= 6.2.2'
  s.dependency 'PryntTrimmerView', '= 4.0.2'
  s.resources    = ['Source/Resources/*', 'Source/**/*.xib']
  s.description  = "Instagram-like image picker & filters for iOS supporting videos and albums (locally managed fork)."
  s.swift_versions = ['5.5']
end
