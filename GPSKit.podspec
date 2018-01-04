Pod::Spec.new do |spec|
  spec.name = "GPSKit"
  spec.version = "0.9.4"
  spec.summary = "CoreLocation without the fuss (and with blocks!)."

  spec.homepage = "https://github.com/parrots/GPSKit"
  spec.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
  spec.author = {
    "Curtis Herbert" => "me@curtisherbert.com"
  }
  spec.source = {
    :git => 'https://github.com/parrots/GPSKit.git',
    :tag => spec.version.to_s
  }

  spec.source_files = 'Source/*.{m,h}'
  spec.platform = :ios, '7.0'
  spec.framework = 'CoreLocation'
  spec.requires_arc = true
  spec.ios.deployment_target = '7.0'
  spec.watchos.deployment_target = '3.0'
end
