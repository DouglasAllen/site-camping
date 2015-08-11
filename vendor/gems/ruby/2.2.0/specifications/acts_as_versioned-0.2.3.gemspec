# -*- encoding: utf-8 -*-
# stub: acts_as_versioned 0.2.3 ruby lib

Gem::Specification.new do |s|
  s.name = "acts_as_versioned"
  s.version = "0.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Rick Olson"]
  s.autorequire = "acts_as_versioned"
  s.date = "2005-11-13"
  s.email = "technoweenie@gmail.com"
  s.homepage = "http://techno-weenie.net"
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubygems_version = "2.4.5"
  s.summary = "Simple versioning with active record models"

  s.installed_by_version = "2.4.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 1

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, [">= 1.10.1"])
      s.add_runtime_dependency(%q<activesupport>, [">= 1.1.1"])
    else
      s.add_dependency(%q<activerecord>, [">= 1.10.1"])
      s.add_dependency(%q<activesupport>, [">= 1.1.1"])
    end
  else
    s.add_dependency(%q<activerecord>, [">= 1.10.1"])
    s.add_dependency(%q<activesupport>, [">= 1.1.1"])
  end
end
