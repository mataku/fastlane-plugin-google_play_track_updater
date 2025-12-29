describe Fastlane::Actions::ResumeGooglePlayReleaseAction do
  describe '#run' do
    let(:package_name) { 'com.example.app' }
    let(:track) { 'production' }
    let(:version_name) { '1.0.0' }
    let(:json_file_path) { './spec/fixtures/sample_service_account.json' }
    let(:client) { instance_double(Fastlane::GooglePlayTrackUpdater::GooglePlayClient) }

    before do
      allow(Fastlane::GooglePlayTrackUpdater::GooglePlayClient).to receive(:new).and_return(client)
      allow(client).to receive(:resume_release)
    end

    it 'creates a GooglePlayClient with json_file_path' do
      Fastlane::Actions::ResumeGooglePlayReleaseAction.run(
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

    it 'calls resume_release with correct parameters' do
      Fastlane::Actions::ResumeGooglePlayReleaseAction.run(
        package_name: package_name,
        track: track,
        version_name: version_name,
        json_file_path: json_file_path
      )

      expect(client).to have_received(:resume_release).with(
        package_name: package_name,
        track: track,
        version_name: version_name
      ).once
    end

    context 'with json_key_data' do
      let(:json_key_data) { '{"type":"service_account"}' }

      it 'creates a GooglePlayClient with json_key_data' do
        Fastlane::Actions::ResumeGooglePlayReleaseAction.run(
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
      expect(Fastlane::Actions::ResumeGooglePlayReleaseAction.description).to eq(
        'Resumes a halted staged rollout for a specific version on a Google Play track.'
      )
    end
  end

  describe '#available_options' do
    it 'returns the correct options' do
      options = Fastlane::Actions::ResumeGooglePlayReleaseAction.available_options
      expect(options).to be_an(Array)
      expect(options.map(&:key)).to include(:package_name, :track, :version_name, :json_file_path, :json_key_data)
    end
  end

  describe '#is_supported?' do
    it 'supports android platform' do
      expect(Fastlane::Actions::ResumeGooglePlayReleaseAction.is_supported?(:android)).to be true
    end

    it 'does not support ios platform' do
      expect(Fastlane::Actions::ResumeGooglePlayReleaseAction.is_supported?(:ios)).to be false
    end
  end
end
