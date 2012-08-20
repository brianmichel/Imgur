Pod::Spec.new do |s|
  s.name         = "Imgur"
  s.version      = "0.0.1"
  s.summary      = "Cocoa wrapper for the Imgur API."
  s.license      = 'MIT'
  s.author       = { "Brian Michel" => "brian.michel@gmail.com" }
  s.source       = { :git => "https://github.com/brianmichel/Imgur.git", :commit => "eb033606eda8611f8d623e7f3560b401a097d23a" }
  s.homepage     = 'http://github.com/brianmichel/Imgur'
  s.source_files = 'Imgur'
  s.requires_arc = true
  s.dependency 'MKNetworkKit'
  s.dependency 'RSOAuthEngine'
end
