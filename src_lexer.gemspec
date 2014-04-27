# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'src_lexer/version'

Gem::Specification.new do |spec|
  spec.name          = "src_lexer"
  spec.version       = SrcLexer::VERSION
  spec.authors       = ["kkikzk"]
  spec.email         = ["kkikzk@gmail.com"]
  spec.summary       = %q{A simple source file lexer}
  spec.description   = ""
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
