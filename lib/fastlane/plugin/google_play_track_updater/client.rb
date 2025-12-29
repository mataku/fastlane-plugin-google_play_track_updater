require 'googleauth'
require 'google/apis/androidpublisher_v3'
require 'json'

module Fastlane
  module GooglePlayTrackUpdater
    class GooglePlayClient
      attr_accessor :android_publisher_service

      AndroidPublisher = Google::Apis::AndroidpublisherV3

      # Initializes a new GooglePlayClient instance with authentication credentials
      #
      # @param json_file_path [String, nil] Path to a file containing service account or external account JSON
      # @param json_key_data [String, nil] Service account or external account JSON data as a string
      # @raise [FastlaneCore::Interface::FastlaneError] If neither or both authentication parameters are provided
      # @raise [FastlaneCore::Interface::FastlaneError] If the JSON type is not 'service_account' or 'external_account'
      def initialize(json_file_path: nil, json_key_data: nil)
        if json_file_path.nil? && json_key_data.nil?
          UI.user_error!('Specify exactly one of \'json_file_path: \' or \'json_key_data: \' for service/external account authentication.')
        end

        account_raw_json = if json_file_path
                             File.open(File.expand_path(json_file_path))
                           elsif json_key_data
                             StringIO.new(json_key_data)
                           end
        account_json = JSON.parse(account_raw_json.read)
        account_raw_json.rewind

        case account_json['type']
        when 'external_account'
          auth_client = Google::Auth::ExternalAccount::Credentials.make_creds(json_key_io: account_raw_json, scope: AndroidPublisher::AUTH_ANDROIDPUBLISHER)
        when 'service_account'
          auth_client = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: account_raw_json, scope: AndroidPublisher::AUTH_ANDROIDPUBLISHER)
        else
          UI.user_error!("Invalid Google Credentials JSON: type: #{account_json['type']} is not available.")
        end

        auth_client.fetch_access_token!

        service = AndroidPublisher::AndroidPublisherService.new
        service.authorization = auth_client
        self.android_publisher_service = service
      end

      # Halts an active staged rollout or completed release for a specific version on a Google Play track
      #
      # @param package_name [String] The package name of the application (e.g., 'com.example.app')
      # @param track [String] The track of the application (production, beta, alpha, internal)
      # @param version_name [String] The version name to halt (e.g., '1.0.0')
      # @raise [FastlaneCore::Interface::FastlaneError] If the release with the specified version is not found
      # @raise [Google::Apis::Error] If the API request fails
      def halt_release(package_name:, track:, version_name:)
        validate_inputs_release_status(package_name: package_name, track: track, version_name: version_name)

        begin
          edit = android_publisher_service.insert_edit(package_name)
          edit_id = edit.id

          current_track = android_publisher_service.get_edit_track(package_name, edit_id, track)

          target_releases = current_track.releases.select do |release|
            release.name == version_name
          end

          if target_releases.empty?
            UI.user_error!("Could not find a release with version '#{version_name}' on track: '#{track}'.")
          end

          is_halted = false

          target_releases.each do |release|
            next unless release.status == 'completed' || release.status == 'inProgress'

            release.status = 'halted'
            UI.message("Preparing to halt release for version '#{version_name}' on track: #{track}...")
            is_halted = true
          end

          if is_halted
            android_publisher_service.update_edit_track(package_name, edit_id, track, current_track)
            android_publisher_service.commit_edit(package_name, edit_id)
            UI.success("Successfully changed status to 'halted' for version '#{version_name}' on track: #{track}.")
          else
            UI.message("No releases found to halt for version '#{version_name}' on track: #{track}.")
          end
        rescue Google::Apis::Error => e
          UI.error!("Failed to halt release for version '#{version_name}' on track: #{track}. Google Api Error: #{e.message}")
        end
      end

      # Resumes a halted staged rollout for a specific version on a Google Play track
      #
      # Changes the status from 'halted' to either 'completed' (if no user_fraction is set)
      # or 'inProgress' (if user_fraction is set for staged rollout)
      #
      # @param package_name [String] The package name of the application (e.g., 'com.example.app')
      # @param track [String] The track of the application (production, beta, alpha, internal)
      # @param version_name [String] The version name to resume (e.g., '1.0.0')
      # @raise [FastlaneCore::Interface::FastlaneError] If the release with the specified version is not found
      # @raise [Google::Apis::Error] If the API request fails
      def resume_release(package_name:, track:, version_name:)
        validate_inputs_release_status(package_name: package_name, track: track, version_name: version_name)

        begin
          edit = android_publisher_service.insert_edit(package_name)
          edit_id = edit.id

          completed_changed = false
          in_progress_changed = false

          current_track = android_publisher_service.get_edit_track(package_name, edit_id, track)

          target_releases = current_track.releases.select do |release|
            release.name == version_name
          end

          if target_releases.empty?
            UI.user_error!("Could not find a release with version '#{version_name}' on track: '#{track}'.")
          end

          target_releases.each do |release|
            next unless release.status == 'halted'

            if release.user_fraction.nil?
              release.status = 'completed'
              completed_changed = true
            else
              release.status = 'inProgress'
              in_progress_changed = true
            end
            UI.message("Preparing to resume release for version '#{version_name}' on track: #{track}...")
          end

          if completed_changed || in_progress_changed
            android_publisher_service.update_edit_track(package_name, edit_id, track, current_track)
            android_publisher_service.commit_edit(package_name, edit_id)
            changed_release = if in_progress_changed
                                'inProgress'
                              elsif completed_changed
                                'completed'
                              end
            UI.success("Successfully changed status to #{changed_release || 'completed'} for version '#{version_name}' on track: #{track}.")
          else
            UI.message("No halted releases found for version '#{version_name}' on track: #{track}.")
          end
        rescue Google::Apis::Error => e
          UI.error!("Failed to resume release for '#{version_name}' on track: #{track}. Google Api Error: #{e.message}")
        end
      end

      # Updates the rollout percentage for a staged rollout on a Google Play track
      #
      # Only updates releases with 'inProgress' status
      #
      # @param package_name [String] The package name of the application (e.g., 'com.example.app')
      # @param track [String] The track of the application (production, beta, alpha, internal)
      # @param version_name [String] The version name to update (e.g., '1.0.0')
      # @param user_fraction [Float] The rollout percentage as a fraction (0.0 to 1.0, exclusive). e.g., 0.1 for 10% rollout
      # @raise [FastlaneCore::Interface::FastlaneError] If the release with the specified version is not found
      # @raise [FastlaneCore::Interface::FastlaneError] If user_fraction is not within the valid range (0.0, 1.0)
      # @raise [Google::Apis::Error] If the API request fails
      def update_rollout(package_name:, track:, version_name:, user_fraction:)
        validate_inputs_rollout(package_name: package_name, track: track, version_name: version_name, user_fraction: user_fraction)

        begin
          edit = android_publisher_service.insert_edit(package_name)
          edit_id = edit.id

          current_track = android_publisher_service.get_edit_track(package_name, edit_id, track)

          target_releases = current_track.releases.select do |release|
            release.name == version_name
          end

          if target_releases.empty?
            UI.user_error!("Could not find a release with version '#{version_name}' on track: '#{track}'.")
          end

          is_rollout_updated = false

          target_releases.each do |release|
            next unless release.status == 'inProgress'

            release.user_fraction = user_fraction.to_f
            UI.verbose("Preparing to update rollout to #{user_fraction} for version '#{version_name}' on track: #{track}...")
            is_rollout_updated = true
          end

          if is_rollout_updated
            android_publisher_service.update_edit_track(package_name, edit_id, track, current_track)
            android_publisher_service.commit_edit(package_name, edit_id)
            UI.success("Successfully updated rollout to #{user_fraction} for version '#{version_name}' on track: #{track}.")
          else
            UI.message("No inProgress releases found to update rollout for version '#{version_name}' on track: #{track}.")
          end
        rescue Google::Apis::Error => e
          UI.error!("Failed to update rollout for version '#{version_name}' on track: #{track}. Google Api Error: #{e.message}")
        end
      end

      private

      def validate_inputs_release_status(package_name:, track:, version_name:)
        if package_name.nil? || package_name.empty?
          UI.user_error!('Specify the package name using the \'package_name:\' .')
        end

        if track.nil? || track.empty?
          UI.user_error!('Specify the track using the \'track:\' .')
        end

        if version_name.nil? || version_name.empty?
          UI.user_error!('Specify the version_name using the \'version_name:\' .')
        end
      end

      def validate_inputs_rollout(package_name:, track:, version_name:, user_fraction:)
        if package_name.nil? || package_name.empty?
          UI.user_error!('Specify the package name using the \'package_name:\' .')
        end

        if track.nil? || track.empty?
          UI.user_error!('Specify the track using the \'track:\' .')
        end

        if version_name.nil? || version_name.empty?
          UI.user_error!('Specify the version_name using the \'version_name:\' .')
        end

        fraction = user_fraction&.to_f

        if fraction.nil? || fraction <= 0.0 || fraction >= 1.0
          UI.user_error!('Invalid \'user_fraction:\' provided. Please specify a value from 0 and 1 (exclusive). e.g., 0.1 for 10% rollout.')
        end
      end
    end
  end
end
