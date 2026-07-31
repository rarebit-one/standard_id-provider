require "rails_helper"
require "rails/generators"
require "generators/standard_id/provider/install/install_generator"

RSpec.describe StandardId::Provider::Generators::InstallGenerator do
  let(:destination) { Rails.root.join("tmp/generator_dest") }

  # Generators narrate to stdout; swallow it so the suite output stays readable.
  def run_generator(args = [])
    FileUtils.mkdir_p(destination)
    original = $stdout
    $stdout = StringIO.new
    described_class.start(args, destination_root: destination.to_s, shell: Thor::Shell::Basic.new)
  ensure
    $stdout = original
  end

  def write(relative, contents)
    path = destination.join(relative)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, contents)
  end

  def read(relative)
    File.read(destination.join(relative))
  end

  before do
    FileUtils.rm_rf(destination)
    write("config/routes.rb", "Rails.application.routes.draw do\nend\n")
  end

  after { FileUtils.rm_rf(destination) }

  describe "a fresh install" do
    before { run_generator }

    it "copies the engine's migrations with the install:migrations suffix" do
      copied = Dir.glob(destination.join("db/migrate/*.standard_id_provider.rb"))
      expect(copied.size).to eq(2)
      expect(copied.map { |p| File.basename(p) }).to include(
        a_string_matching(/create_standard_id_consent_grants\.standard_id_provider\.rb\z/),
        a_string_matching(/create_standard_id_revoked_tokens\.standard_id_provider\.rb\z/)
      )
    end

    it "writes the initializer" do
      expect(read("config/initializers/standard_id_provider.rb"))
        .to include("discovery_endpoint_base")
    end

    it "mounts the engine" do
      expect(read("config/routes.rb")).to include('mount StandardId::Provider::Engine => "/"')
    end
  end

  describe "idempotence" do
    it "does not copy the migrations twice" do
      run_generator
      first = Dir.glob(destination.join("db/migrate/*.rb")).size

      run_generator

      expect(Dir.glob(destination.join("db/migrate/*.rb")).size).to eq(first)
    end

    it "does not mount the engine twice" do
      run_generator
      run_generator

      expect(read("config/routes.rb").scan("StandardId::Provider::Engine").size).to eq(1)
    end

    it "leaves an existing initializer alone" do
      write("config/initializers/standard_id_provider.rb", "# hand-edited\n")

      run_generator

      expect(read("config/initializers/standard_id_provider.rb")).to eq("# hand-edited\n")
    end

    it "overwrites an existing initializer with --force" do
      write("config/initializers/standard_id_provider.rb", "# hand-edited\n")

      run_generator(%w[--force])

      expect(read("config/initializers/standard_id_provider.rb")).to include("StandardId.configure")
    end
  end

  describe "skip flags" do
    it "--skip-migrations copies nothing into db/migrate" do
      run_generator(%w[--skip-migrations])

      expect(Dir.glob(destination.join("db/migrate/*.rb"))).to be_empty
    end

    it "--skip-initializer writes no initializer" do
      run_generator(%w[--skip-initializer])

      expect(File.exist?(destination.join("config/initializers/standard_id_provider.rb"))).to be false
    end

    it "--skip-routes leaves routes.rb untouched" do
      run_generator(%w[--skip-routes])

      expect(read("config/routes.rb")).not_to include("StandardId::Provider::Engine")
    end
  end

  describe "--mount-path" do
    it "mounts at the given path" do
      run_generator(%w[--mount-path /auth])

      expect(read("config/routes.rb")).to include('mount StandardId::Provider::Engine => "/auth"')
    end
  end

  describe "when the host has no routes file" do
    it "warns instead of raising" do
      FileUtils.rm_f(destination.join("config/routes.rb"))

      expect { run_generator }.not_to raise_error
    end
  end
end
