describe Fastlane::Actions::UpdateGooglePlayReleaseRolloutAction do
  describe '#run' do
    let(:package_name) { 'com.example.app' }
    let(:track) { 'production' }
    let(:version_name) { '1.0.0' }
    let(:user_fraction) { 0.5 }
    let(:json_file_path) { './spec/fixtures/sample_service_account.json' }
    let(:client) { instance_double(Fastlane::GooglePlayTrackUpdater::GooglePlayClient) }

    before do
      allow(Fastlane::GooglePlayTrackUpdater::GooglePlayClient).to receive(:new).and_return(client)
      allow(client).to receive(:update_rollout)
    end

    it 'creates a GooglePlayClient with json_file_path' do
      Fastlane::Actions::UpdateGooglePlayReleaseRolloutAction.run(
        package_name: package_name,
        track: track,
        version_name: version_name,
        user_fraction: user_fraction,
        json_file_path: json_file_path
      )

      expect(Fastlane::GooglePlayTrackUpdater::GooglePlayClient).to have_received(:new).with(
        json_file_path: json_file_path,
        json_key_data: nil
      ).once
    end

    it 'calls update_rollout with correct parameters' do
      Fastlane::Actions::UpdateGooglePlayReleaseRolloutAction.run(
        package_name: package_name,
        track: track,
        version_name: version_name,
        user_fraction: user_fraction,
        json_file_path: json_file_path
      )

      expect(client).to have_received(:update_rollout).with(
        package_name: package_name,
        track: track,
        version_name: version_name,
        user_fraction: user_fraction
      ).once
    end

    context 'with json_key_data' do
      let(:json_key_data) { '{"type":"service_account"}' }

      it 'creates a GooglePlayClient with json_key_data' do
        Fastlane::Actions::UpdateGooglePlayReleaseRolloutAction.run(
          package_name: package_name,
          track: track,
          version_name: version_name,
          user_fraction: user_fraction,
          json_key_data: json_key_data
        )

        expect(Fastlane::GooglePlayTrackUpdater::GooglePlayClient).to have_received(:new).with(
          json_file_path: nil,
          json_key_data: json_key_data
        ).once
      end
    end
  end

  describe '#description' do
    it 'returns the correct description' do
      expect(Fastlane::Actions::UpdateGooglePlayReleaseRolloutAction.description).to eq(
        'Updates the rollout percentage for a staged rollout on a Google Play track.'
      )
    end
  end

  describe '#available_options' do
    it 'returns the correct options' do
      options = Fastlane::Actions::UpdateGooglePlayReleaseRolloutAction.available_options
      expect(options).to be_an(Array)
      expect(options.map(&:key)).to include(:package_name, :track, :version_name, :user_fraction, :json_file_path, :json_key_data)
    end
  end

  describe '#is_supported?' do
    it 'supports android platform' do
      expect(Fastlane::Actions::UpdateGooglePlayReleaseRolloutAction.is_supported?(:android)).to be true
    end

    it 'does not support ios platform' do
      expect(Fastlane::Actions::UpdateGooglePlayReleaseRolloutAction.is_supported?(:ios)).to be false
    end
  end
end
