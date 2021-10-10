# -*- coding: utf-8 -*-

Gem::Specification.new do |o|
  o.name          = "cdnget"
  o.version       = '$Release: 0.0.0 $'.split()[1]
  o.authors       = ["makoto kuwata"]
  o.email         = ["kwa@kuwata-lab.com"]

  o.summary       = "download JS/CSS files from public CDN (CDNJS/jsDelivr/UNPKG/Google)"
  o.description   = "download JS/CSS files from public CDN (CDNJS/jsDelivr/UNPKG/Google)"
  o.homepage      = "https://github.com/kwatch/cdnget/tree/ruby-release"
  o.license       = "MIT"

  o.files         = Dir[*%w[
                      README.md CHANGES.md MIT-LICENSE Rakefile cdnget.gemspec
                      lib/**/*.rb
                      bin/cdnget
                      test/**/*_test.rb
                    ]]
  o.bindir        = "bin"
  o.executables   = ["cdnget"]
  o.require_paths = ["lib"]

  o.required_ruby_version = '>= 2.0'

  o.add_development_dependency "oktest", "~> 1.0"
end
