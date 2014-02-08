# -*- encoding: utf-8 -*-
require File.expand_path("../lib/serialisable/version", __FILE__)

Gem::Specification.new do |s|
  s.name         = "serialisable"
  s.author       = "Joshua Hawxwell"
  s.email        = "m@hawx.me"
  s.summary      = "Serialisable allows easy xml deserialisation"
  s.homepage     = "http://github.com/hawx/serialisable"
  s.version      = Serialisable::VERSION
  s.license      = 'MIT'

  s.description  = <<-DESC
    Serialisable provides a simple DSL for turning xml into ruby objects.
  DESC

  s.add_dependency 'nokogiri', '~> 1.6.1'
  s.add_development_dependency 'minitest', '~> 5.2.0'
  s.add_development_dependency 'mocha', '~> 1.0.0'

  s.files        = %w(README.md Rakefile)
  s.files       += Dir["{bin,lib,spec}/**/*"] & `git ls-files`.split("\n")
  s.test_files   = Dir["{spec}/**/*"] & `git ls-files`.split("\n")
end
