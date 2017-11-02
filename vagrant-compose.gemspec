$:.unshift File.expand_path("../lib", __FILE__)
require 'vagrant/compose/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-compose"
  spec.version       = Vagrant::Compose::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.license       = "MIT"
  spec.authors       = ["Fabrizio Pandini"]
  spec.email         = ["fabrizio.pandini@gmail.com"]
  spec.homepage      = "https://github.com/fabriziopandini/vagrant-compose/"
  spec.summary       = %q{A Vagrant plugin that helps building complex multi-machine scenarios.}
  spec.description   = %q{A Vagrant plugin that helps building complex multi-machine scenarios.}

  spec.required_rubygems_version = ">= 2.0.13"

  spec.add_development_dependency "rake", "~> 10.4.2"
  spec.add_development_dependency "rspec", "~> 3.4.0"
  spec.add_development_dependency "rspec-its", "~> 1.2.0"
  spec.add_dependency "open4", "~> 1.3.4"

  # The following block of code determines the files that should be included
  # in the gem. It does this by reading all the files in the directory where
  # this gemspec is, and parsing out the ignored files from the gitignore.
  # Note that the entire gitignore(5) syntax is not supported, specifically
  # the "!" syntax, but it should mostly work correctly.
  root_path      = File.dirname(__FILE__)
  all_files      = Dir.chdir(root_path) { Dir.glob("**/{*,.*}") }
  all_files.reject! { |file| [".", ".."].include?(File.basename(file)) }
  gitignore_path = File.join(root_path, ".gitignore")
  gitignore      = File.readlines(gitignore_path)
  gitignore.map!    { |line| line.chomp.strip }
  gitignore.reject! { |line| line.empty? || line =~ /^(#|!)/ }

  unignored_files = all_files.reject do |file|
    # Ignore any directories, the gemspec only cares about files
    next true if File.directory?(file)

    # Ignore any paths that match anything in the gitignore. We do
    # two tests here:
    #
    #   - First, test to see if the entire path matches the gitignore.
    #   - Second, match if the basename does, this makes it so that things
    #     like '.DS_Store' will match sub-directories too (same behavior
    #     as git).
    #
    gitignore.any? do |ignore|
      File.fnmatch(ignore, file, File::FNM_PATHNAME) ||
        File.fnmatch(ignore, File.basename(file), File::FNM_PATHNAME)
    end
  end

  spec.files         = unignored_files
  spec.executables   = unignored_files.map { |f| f[/^bin\/(.*)/, 1] }.compact
  spec.require_path  = 'lib'
end
