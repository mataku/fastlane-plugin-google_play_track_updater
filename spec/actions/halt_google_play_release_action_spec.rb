describe Fastlane::Actions::HaltGooglePlayReleaseAction do
  describe '#run' do
    let(:package_name) { 'com.example.app' }
    let(:track) { 'production' }
    let(:version_name) { '1.0.0' }
    let(:json_file_path) { './spec/fixtures/sample_service_account.json' }
    let(:client) { instance_double(Fastlane::GooglePlayTrackUpdater::GooglePlayClient) }

    before do
      allow(Fastlane::GooglePlayTrackUpdater::GooglePlayClient).to receive(:new).and_return(client)
      allow(client).to receive(:halt_release)
    end

    it 'creates a GooglePlayClient with json_file_path' do
      Fastlane::Actions::HaltGooglePlayReleaseAction.run(
        package_name: package_name,
        track: track,
        version_name: version_name,
        json_file_path: json_file_path
      )

      expect(Fastlane::GooglePlayTrackUpdater::GooglePlayClient).to have_received(:new).with(
        json_file_path: json_file_path,
        json_key_data: nil
      ).once
    end

    it 'calls halt_release with correct parameters' do
      Fastlane::Actions::HaltGooglePlayReleaseAction.run(
        package_name: package_name,
        track: track,
        version_name: version_name,
        json_file_path: json_file_path
      )

      expect(client).to have_received(:halt_release).with(
        package_name: package_name,
        track: track,
        version_name: version_name
      ).once
    end

    context 'with json_key_data' do
      let(:json_key_data) { '{"type":"service_account"}' }

      it 'creates a GooglePlayClient with json_key_data' do
        Fastlane::Actions::HaltGooglePlayReleaseAction.run(
          package_name: package_name,
          track: track,
          version_name: version_name,
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
      expect(Fastlane::Actions::HaltGooglePlayReleaseAction.description).to eq(
        'Halts an active staged rollout or completed for a specific version on a Google Play track.'
      )
    end
  end

  describe '#available_options' do
    it 'returns the correct options' do
      options = Fastlane::Actions::HaltGooglePlayReleaseAction.available_options
      expect(options).to be_an(Array)
      expect(options.map(&:key)).to include(:package_name, :track, :version_name, :json_file_path, :json_key_data)
    end
  end

  describe '#is_supported?' do
    it 'supports android platform' do
      expect(Fastlane::Actions::HaltGooglePlayReleaseAction.is_supported?(:android)).to be true
    end

    it 'does not support ios platform' do
      expect(Fastlane::Actions::HaltGooglePlayReleaseAction.is_supported?(:ios)).to be false
    end
  end
end
