Pod::Spec.new do |s|
  s.name             = "SwiftSockets"
  s.version          = "0.13.0"
  s.summary          = "A simple GCD based socket wrapper for Swift"
  s.description      = <<-DESC
                       A simple GCD based socket wrapper for Swift.
DESC
  s.homepage         = "https://github.com/AlwaysRightInstitute/SwiftSockets"

  s.license          = 'MIT'
  s.author           = { "Helge Heß" => "email@email.com" }
  s.source           = { :git => "https://github.com/AlwaysRightInstitute/SwiftSockets.g$
  s.social_media_url = 'http://twitter.com/'

  s.platform     = :osx, '10.10'

  s.requires_arc = true

  s.source_files = 'ARISockets/*.{h,c,swift}'

end









