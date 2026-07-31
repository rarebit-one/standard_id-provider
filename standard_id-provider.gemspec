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
    Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 4.0"

  spec.add_dependency "rails", ">= 8.0"

  # `~> 0.33` — TWO components, deliberately. It means `>= 0.33, < 1.0`.
  #
  # The old `~> 0.3` was `>= 0.3, < 1.0`: technically the same ceiling, but it
  # claimed compatibility all the way back to 0.3 for a gem that `prepend`s into
  # four NON-PUBLIC StandardId::Oauth classes. Nothing verified that claim,
  # because CI ran no tests. It does now (see the `compat` job below), and 0.33
  # is the oldest version that claim has actually been tested against.
  #
  # A three-component cap (`~> 0.33.0`, i.e. `< 0.34`) would be worse, not
  # better. That is the shape that created the landmine in rarebit-one/rarebit-ops#278:
  # a satellite capped to a version narrower than what standard_id had already
  # published, so consumers either resolved an untested combination or could not
  # resolve at all. With two components, patch AND minor releases of standard_id
  # roll through without a gemspec edit — and the `compat` CI job is what turns
  # "rolls through" into "rolls through, tested."
  spec.add_dependency "standard_id", "~> 0.33"
end
