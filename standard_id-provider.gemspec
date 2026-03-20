require_relative "lib/standard_id/provider/version"

Gem::Specification.new do |spec|
  spec.name        = "standard_id-provider"
  spec.version     = StandardId::Provider::VERSION
  spec.authors     = [ "Jaryl Sim" ]
  spec.email       = [ "code@jaryl.dev" ]
  spec.homepage    = "https://github.com/rarebit-one/standard_id-provider"
  spec.summary     = "OpenID Connect Identity Provider addon for StandardId."
  spec.description = "Extends StandardId with full OIDC Identity Provider capabilities: ID tokens, consent management, token introspection, token revocation, and discovery."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rarebit-one/standard_id-provider"
  spec.metadata["changelog_uri"] = "https://github.com/rarebit-one/standard_id-provider/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/rarebit-one/standard_id-provider/issues"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.2"

  spec.add_dependency "rails", ">= 8.0"
  spec.add_dependency "standard_id", "~> 0.3"
end
