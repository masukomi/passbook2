require_relative "lib/passbook/version"


Gem::Specification.new do |s|
  s.name = "passbook2"
  s.version = Passbook::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Thomas Lauro", "Lance Gleason", "Kay Rhodes"]
  s.date = "2024-06-11"
  s.description = "This gem allows you to create Apple Passbook files."
  s.email = ["thomas@lauro.fr", "lgleason@polyglotprogramminginc.com", "masukomi@masukomi.org"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    ".travis.yml",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION",
    "lib/passbook2.rb",
    "lib/passbook/pk_multi_pass.rb",
    "lib/passbook/pkpass.rb",
    "lib/passbook/push_notification.rb",
    "lib/passbook/signer.rb",
    "lib/passbook/version.rb",
    "passbook.gemspec",
    "spec/data/icon.png",
    "spec/data/icon@2x.png",
    "spec/data/logo.png",
    "spec/data/logo@2x.png",
    "spec/lib/passbook/pk_multi_pass_spec.rb",
    "spec/lib/passbook/pkpass_spec.rb",
    "spec/lib/passbook/push_notification_spec.rb",
    "spec/lib/passbook/signer_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.homepage = "https://github.com/masukomi/passbook2"
  s.licenses = ["MIT"]
  s.rubygems_version = "3.4.17"
  s.summary = "An Apple Passbook file generator."

  s.specification_version = 4

  # runtime dependencies
  s.add_dependency(%q<grocer>, [">= 0"])
  s.add_dependency(%q<rubyzip>, [">= 1.0.0"])
  s.add_dependency(%q<activesupport>.freeze, [">= 0"])

  # development dependencies
  s.add_development_dependency(%q<debug>, [">= 0"])
  s.add_development_dependency(%q<rspec>, [">= 0"])
  s.add_development_dependency(%q<yard>, [">= 0"])
end
