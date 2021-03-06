module Datanet
  module Skel
    class RepositoryAuth
      attr_accessor :repo_secret_path, :settings, :authenticator, :cors

      def authenticate!(creds)
        unauthenticate!('Valid proxy is required to access the repository') if creds.nil? || creds.empty?
        unauthenticate!('Given user proxy is invalid') unless authenticator.authenticate(creds)
      end

      def authorize!(creds)
        unauthorize!('You are not allowed to read/write to this repository') unless authorized?(creds)
      end

      def authorized?(creds)
        public? || owner?(username(creds))
      end

      def admin?(token)
        has_secret? and secret === token
      end

      def repository_type=(type)
        update_settings("repository_type", type.to_s)
      end

      def owners=(owners)
        update_settings("owners", owners)
      end

      def cors_origins=(cors_origins)
        update_settings("cors_origins", cors_origins)
        update_cors if cors
      end

      def data_separation=(data_separation)
        update_settings("data_separation", !!data_separation)
      end

      def cors_origins
        settings['cors_origins'] || []
      end

      def configuration
        YAML.load_file settings.config_file
      end

      def username(creds)
        authenticator.username(creds)
      end

      private

      def unauthenticate!(msg)
        raise Datanet::Skel::Unauthenticated.new(msg)
      end

      def unauthorize!(msg)
        raise Datanet::Skel::Unauthorized.new(msg)
      end

      def update_settings(key, value)
        data = YAML.load_file settings.config_file
        data[key] = value
        File.open(settings.config_file, 'w') { |f| YAML.dump(data, f) }

        settings.reload!
      end

      def owner?(username)
        not owners.nil? and owners.include? username
      end

      def owners
        settings.owners
      end

      def public?
        settings.repository_type == 'public'
      end

      def has_secret?
        File.exist? repo_secret_path
      end

      def secret
        @secret ||= File.read(repo_secret_path).chomp
      end

      def update_cors
        cors.origins(*(cors_origins))
      end
    end
  end
end
