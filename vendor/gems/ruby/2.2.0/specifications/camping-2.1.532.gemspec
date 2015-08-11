# -*- encoding: utf-8 -*-
# stub: camping 2.1.532 ruby lib

Gem::Specification.new do |s|
  s.name = "camping"
  s.version = "2.1.532"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["why the lucky stiff"]
  s.date = "2013-03-21"
  s.email = "why@ruby-lang.org"
  s.executables = ["camping"]
  s.extra_rdoc_files = ["README.md", "CHANGELOG", "COPYING", "book/01_introduction.md", "book/02_getting_started.md", "book/51_upgrading.md"]
  s.files = ["CHANGELOG", "COPYING", "README.md", "bin/camping", "book/01_introduction.md", "book/02_getting_started.md", "book/51_upgrading.md"]
  s.homepage = "http://camping.rubyforge.org/"
  s.rdoc_options = ["--line-numbers", "--quiet", "--main", "README", "--exclude", "^(examples|extras)\\/", "--exclude", "lib/camping.rb"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.2")
  s.rubyforge_project = "camping"
  s.rubygems_version = "2.4.5"
  s.summary = "minature rails for stay-at-home moms"

  s.installed_by_version = "2.4.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 1.0"])
      s.add_runtime_dependency(%q<mab>, [">= 0.0.3"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rack-test>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 1.0"])
      s.add_dependency(%q<mab>, [">= 0.0.3"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rack-test>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 1.0"])
    s.add_dependency(%q<mab>, [">= 0.0.3"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rack-test>, [">= 0"])
  end
end
