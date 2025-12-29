require 'fastlane/action'
require_relative '../client'

module Fastlane
  module Actions
    class ResumeGooglePlayReleaseAction < Action
      def self.run(params)
        package_name = params[:package_name]
        track = params[:track]
        version_name = params[:version_name]
        json_file_path = params[:json_file_path]
        json_key_data = params[:json_key_data]
        client = Fastlane::GooglePlayTrackUpdater::GooglePlayClient.new(
          json_file_path: json_file_path,
          json_key_data: json_key_data
        )
        client.resume_release(
          package_name: package_name,
          track: track,
          version_name: version_name
        )
      end

      def self.description
        'Resumes a halted staged rollout for a specific version on a Google Play track.'
      end

      def self.authors
        ["Takuma Homma"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        'Resumes a halted staged rollout for a specific version on a Google Play track.'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :package_name,
                                       env_name: 'RESUME_GOOGLE_PLAY_RELEASE_PACKAGE_NAME',
                                       description: 'The package name of the application. e.g. \'com.example.app\'',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :track,
                                       env_name: "RESUME_GOOGLE_PLAY_RELEASE_TRACK",
                                       description: 'The track of the application. The available tracks are: production, beta, alpha, internal',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :version_name,
                                       env_name: 'RESUME_GOOGLE_PLAY_RELEASE_VERSION_NAME',
                                       description: 'The version name to update. e.g. \'1.0.0\'',
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :json_file_path,
                                       env_name: 'RESUME_GOOGLE_PLAY_RELEASE_JSON_FILE_PATH',
                                       description: 'The path to a file containing service account or external account JSON, used to authenticate with Google',
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :json_key_data,
                                       env_name: 'RESUME_GOOGLE_PLAY_RELEASE_JSON_KEY_DATA',
                                       description: 'The file data containing service account or external account JSON, used to authenticate with Google',
                                       optional: true,
                                       type: String)

        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)

        platform == :android
      end
    end
  end
end
