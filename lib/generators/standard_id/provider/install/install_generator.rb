require "rails/generators"

module StandardId
  module Provider
    module Generators
      # Installs StandardId::Provider in a host Rails application.
      #
      # Three steps, each independently skippable:
      #
      #   * copies the engine's migrations into db/migrate/
      #   * writes config/initializers/standard_id_provider.rb
      #   * mounts the engine in config/routes.rb
      #
      # Idempotent: re-running skips pieces that are already installed and says
      # so. Pass `--skip-*` to opt out of individual steps and `--force` to
      # overwrite an existing initializer.
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path("templates", __dir__)

        desc <<~DESC
          Installs StandardId::Provider. By default this:
            * copies the engine's migrations into db/migrate/
            * writes config/initializers/standard_id_provider.rb
            * mounts StandardId::Provider::Engine in config/routes.rb

          Use --skip-* flags to opt out of individual steps when re-running on
          an existing install. The generator is idempotent — already-installed
          pieces are skipped with a clear message. Pass --force to overwrite an
          existing initializer.

          Run `rails db:migrate` afterwards.
        DESC

        class_option :skip_migrations, type: :boolean, default: false,
          desc: "Do not copy the engine's migrations into db/migrate"
        class_option :skip_initializer, type: :boolean, default: false,
          desc: "Do not write config/initializers/standard_id_provider.rb"
        class_option :skip_routes, type: :boolean, default: false,
          desc: "Do not mount StandardId::Provider::Engine in config/routes.rb"
        class_option :mount_path, type: :string, default: "/",
          desc: "Path to mount StandardId::Provider::Engine at"
        class_option :force, type: :boolean, default: false,
          desc: "Overwrite config/initializers/standard_id_provider.rb if it already exists"

        # Copies the engine's migrations with the same `.standard_id_provider`
        # suffix `rails standard_id_provider:install:migrations` uses, so the
        # two are interchangeable and neither double-installs the other's work.
        # Done in-process rather than by shelling out to that rake task so the
        # generator stays testable and does not need a booted host app.
        def copy_migrations
          if options[:skip_migrations]
            say_status("skip", "db/migrate (--skip-migrations)", :yellow)
            return
          end

          if existing_migrations.any?
            say_status(
              "identical",
              "StandardId::Provider migrations already present (#{existing_migrations.size}), skipping",
              :blue
            )
            return
          end

          engine_migrations.each_with_index do |source, index|
            name = File.basename(source, ".rb").sub(/\A\d+_/, "")
            copy_file source, "db/migrate/#{migration_number(index)}_#{name}.standard_id_provider.rb"
          end
        end

        def copy_initializer
          path = "config/initializers/standard_id_provider.rb"

          if options[:skip_initializer]
            say_status("skip", "#{path} (--skip-initializer)", :yellow)
            return
          end

          if File.exist?(File.join(destination_root, path)) && !options[:force]
            say_status("identical", "#{path} (already exists; pass --force to overwrite)", :blue)
            return
          end

          template "initializer.rb.erb", path, force: options[:force]
        end

        def mount_engine
          routes_path = "config/routes.rb"

          if options[:skip_routes]
            say_status("skip", "#{routes_path} (--skip-routes)", :yellow)
            return
          end

          unless File.exist?(File.join(destination_root, routes_path))
            say_status("warn", "#{routes_path} not found; mount the engine yourself", :red)
            return
          end

          if File.read(File.join(destination_root, routes_path)).include?("StandardId::Provider::Engine")
            say_status("identical", "#{routes_path} (engine already mounted)", :blue)
            return
          end

          route(%(mount StandardId::Provider::Engine => "#{options[:mount_path]}"))
        end

        def print_next_steps
          say ""
          say "StandardId::Provider installed. Next:", :green
          say "  1. rails db:migrate"
          say "  2. Set config.oauth.discovery_endpoint_base in your StandardId"
          say "     initializer — this engine's discovery document cannot detect"
          say "     the ApiEngine mount on its own. See the README."
          say "  3. Set config.oauth.introspection_enabled = true if you want the"
          say "     RFC 7662 endpoint (it is off by default in standard_id)."
          say ""
        end

        no_commands do
          def existing_migrations
            Dir.glob(File.join(destination_root, "db/migrate/*.standard_id_provider.rb"))
          end

          def engine_migrations
            Dir.glob(File.expand_path("../../../../../db/migrate/*.rb", __dir__)).sort
          end

          # Migrations are ordered among themselves and must not collide, hence
          # the index offset. `install:migrations` does the same thing.
          def migration_number(index)
            (Time.now.utc + index).strftime("%Y%m%d%H%M%S")
          end
        end
      end
    end
  end
end
