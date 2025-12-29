require 'fastlane/plugin/google_play_track_updater/client'

describe Fastlane::GooglePlayTrackUpdater::GooglePlayClient do
  describe '#initialize' do
    context 'no json specified' do
      it 'should call UI.user_error!' do
        expect { Fastlane::GooglePlayTrackUpdater::GooglePlayClient.new }.to raise_error(FastlaneCore::Interface::FastlaneError).with_message('Specify exactly one of \'json_file_path: \' or \'json_key_data: \' for service/external account authentication.')
      end
    end

    context 'service account JSON is specified' do
      let(:file_path) { './spec/fixtures/sample_service_account.json' }
      let(:auth_client) { double('auth_client') }
      before do
        allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(auth_client)
        allow(auth_client).to receive(:fetch_access_token!)
      end

      it 'should use Google::Auth::ServiceAccountCredentials' do
        client = Fastlane::GooglePlayTrackUpdater::GooglePlayClient.new(json_file_path: file_path)
        expect(Google::Auth::ServiceAccountCredentials).to have_received(:make_creds).once
        expect(auth_client).to have_received(:fetch_access_token!).once
      end
    end

    context 'external account JSON is specified' do
      let(:file_path) { './spec/fixtures/sample_external_account.json' }
      let(:auth_client) { double('auth_client') }
      before do
        allow(Google::Auth::ExternalAccount::Credentials).to receive(:make_creds).and_return(auth_client)
        allow(auth_client).to receive(:fetch_access_token!)
      end

      it 'should use Google::Auth::ExternalAccount::Credentials' do
        client = Fastlane::GooglePlayTrackUpdater::GooglePlayClient.new(json_file_path: file_path)
        expect(Google::Auth::ExternalAccount::Credentials).to have_received(:make_creds).once
        expect(auth_client).to have_received(:fetch_access_token!).once
      end
    end
  end

  describe '#halt_release' do
    let(:file_path) { './spec/fixtures/sample_external_account.json' }
    let(:auth_client) { double('auth_client') }
    let(:client) { Fastlane::GooglePlayTrackUpdater::GooglePlayClient.new(json_file_path: file_path) }

    let(:android_publisher_service) { double('android_publisher_service') }
    let(:app_edit) do
      instance_double(Google::Apis::AndroidpublisherV3::AppEdit)
    end
    let(:track) do
      instance_double(Google::Apis::AndroidpublisherV3::Track)
    end
    let(:track_release) do
      instance_double(Google::Apis::AndroidpublisherV3::TrackRelease)
    end
    let(:track_release_2) do
      instance_double(Google::Apis::AndroidpublisherV3::TrackRelease)
    end
    let(:target_version_name) { '1.0.0' }
    let(:target_track) { 'internal' }
    let(:package_name) { 'com.mataku.app' }
    let(:edit_id) { "1011010" }

    before do
      allow(Google::Auth::ExternalAccount::Credentials).to receive(:make_creds).and_return(auth_client)
      allow(auth_client).to receive(:fetch_access_token!)
      allow(track_release).to receive(:name).and_return('1.0.0')
      allow(track_release).to receive(:status).and_return('halted')
      allow(track_release_2).to receive(:name).and_return('0.9.0')
      allow(track_release_2).to receive(:status).and_return('halted')
      allow(track).to receive(:releases).and_return([track_release, track_release_2])
      allow(android_publisher_service).to receive(:authorization=)
      allow(android_publisher_service).to receive(:get_edit_track).and_return(track)
      allow(Google::Apis::AndroidpublisherV3::AndroidPublisherService).to receive(:new).and_return(android_publisher_service)
      allow(android_publisher_service).to receive(:insert_edit).and_return(app_edit)
      allow(app_edit).to receive(:id).and_return(edit_id)
    end

    context 'package_name is not specified' do
      it 'should raise UI.user_error!' do
        expect do
          client.halt_release(
            package_name: nil,
            track: nil,
            version_name: nil
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError).with_message('Specify the package name using the \'package_name:\' .')
      end
    end

    context 'track is not specified' do
      it 'should raise UI.user_error!' do
        expect do
          client.halt_release(
            package_name: 'com.mataku.app',
            track: nil,
            version_name: nil
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError).with_message('Specify the track using the \'track:\' .')
      end
    end

    context 'only releases with halted status exist' do
      before do
        allow(Fastlane::UI).to receive(:message)
      end

      it do
        client.halt_release(package_name: 'com.mataku.app', track: target_track, version_name: target_version_name)
        expect(Fastlane::UI).to have_received(:message).with("No releases found to halt for version '#{target_version_name}' on track: #{target_track}.").once
      end
    end

    context 'release with inProgress status exists' do
      before do
        allow(track_release).to receive(:status).and_return('inProgress')
        allow(track_release).to receive(:status=)
        allow(android_publisher_service).to receive(:update_edit_track)
        allow(android_publisher_service).to receive(:commit_edit)
        allow(Fastlane::UI).to receive(:success)
        allow(Fastlane::UI).to receive(:message)
      end

      it 'should commit changes' do
        client.halt_release(package_name: package_name, track: target_track, version_name: target_version_name)
        expect(android_publisher_service).to have_received(:update_edit_track).with(package_name, edit_id, target_track, any_args).once
        expect(android_publisher_service).to have_received(:commit_edit).with(package_name, edit_id).once
        expect(Fastlane::UI).to have_received(:message).once
        expect(Fastlane::UI).to have_received(:success).once
      end
    end

    context 'release with completed status exists' do
      before do
        allow(track_release).to receive(:status).and_return('completed')
        allow(track_release).to receive(:status=)
        allow(android_publisher_service).to receive(:update_edit_track)
        allow(android_publisher_service).to receive(:commit_edit)
        allow(Fastlane::UI).to receive(:success)
        allow(Fastlane::UI).to receive(:message)
      end

      it 'should commit changes' do
        client.halt_release(package_name: package_name, track: target_track, version_name: target_version_name)
        expect(android_publisher_service).to have_received(:update_edit_track).with(package_name, edit_id, target_track, any_args).once
        expect(android_publisher_service).to have_received(:commit_edit).with(package_name, edit_id).once
        expect(Fastlane::UI).to have_received(:message).once
        expect(Fastlane::UI).to have_received(:success).once
      end
    end
  end

  describe '#resume_release' do
    let(:file_path) { './spec/fixtures/sample_external_account.json' }
    let(:auth_client) { double('auth_client') }
    let(:client) { Fastlane::GooglePlayTrackUpdater::GooglePlayClient.new(json_file_path: file_path) }

    let(:android_publisher_service) { double('android_publisher_service') }
    let(:app_edit) do
      instance_double(Google::Apis::AndroidpublisherV3::AppEdit)
    end
    let(:track) do
      instance_double(Google::Apis::AndroidpublisherV3::Track)
    end
    let(:track_release) do
      instance_double(Google::Apis::AndroidpublisherV3::TrackRelease)
    end
    let(:track_release_2) do
      instance_double(Google::Apis::AndroidpublisherV3::TrackRelease)
    end
    let(:target_version_name) { '1.0.0' }
    let(:target_track) { 'internal' }
    let(:package_name) { 'com.mataku.app' }
    let(:edit_id) { "1011010" }

    before do
      allow(Google::Auth::ExternalAccount::Credentials).to receive(:make_creds).and_return(auth_client)
      allow(auth_client).to receive(:fetch_access_token!)
      allow(track_release).to receive(:name).and_return('1.0.0')
      allow(track_release).to receive(:status).and_return('inProgress')
      allow(track_release_2).to receive(:name).and_return('0.9.0')
      allow(track_release_2).to receive(:status).and_return('inProgress')
      allow(track).to receive(:releases).and_return([track_release, track_release_2])
      allow(android_publisher_service).to receive(:authorization=)
      allow(android_publisher_service).to receive(:get_edit_track).and_return(track)
      allow(Google::Apis::AndroidpublisherV3::AndroidPublisherService).to receive(:new).and_return(android_publisher_service)
      allow(android_publisher_service).to receive(:insert_edit).and_return(app_edit)
      allow(app_edit).to receive(:id).and_return(edit_id)
    end

    context 'package_name is not specified' do
      it 'should raise UI.user_error!' do
        expect do
          client.resume_release(
            package_name: nil,
            track: nil,
            version_name: nil
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError).with_message('Specify the package name using the \'package_name:\' .')
      end
    end

    context 'track is not specified' do
      it 'should raise UI.user_error!' do
        expect do
          client.resume_release(
            package_name: 'com.mataku.app',
            track: nil,
            version_name: nil
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError).with_message('Specify the track using the \'track:\' .')
      end
    end

    context 'only releases with not halted status exist' do
      before do
        allow(Fastlane::UI).to receive(:message)
      end

      it do
        client.resume_release(package_name: 'com.mataku.app', track: target_track, version_name: target_version_name)
        expect(Fastlane::UI).to have_received(:message).with("No halted releases found for version '#{target_version_name}' on track: #{target_track}.").once
      end
    end

    context 'release with halted inProgress status exists' do
      before do
        allow(track_release).to receive(:status).and_return('halted')
        allow(track_release).to receive(:status=)
        allow(track_release).to receive(:user_fraction).and_return(0.1)
        allow(android_publisher_service).to receive(:update_edit_track)
        allow(android_publisher_service).to receive(:commit_edit)
        allow(Fastlane::UI).to receive(:success)
        allow(Fastlane::UI).to receive(:message)
      end

      it 'should commit changes' do
        client.resume_release(package_name: package_name, track: target_track, version_name: target_version_name)
        expect(android_publisher_service).to have_received(:update_edit_track).with(package_name, edit_id, target_track, any_args).once
        expect(android_publisher_service).to have_received(:commit_edit).with(package_name, edit_id).once
        expect(track_release).to have_received(:status=).with('inProgress')
        expect(Fastlane::UI).to have_received(:message).once
        expect(Fastlane::UI).to have_received(:success).once
      end
    end

    context 'release with halted completed status exists' do
      before do
        allow(track_release).to receive(:status).and_return('halted')
        allow(track_release).to receive(:status=)
        allow(track_release).to receive(:user_fraction).and_return(nil)
        allow(android_publisher_service).to receive(:update_edit_track)
        allow(android_publisher_service).to receive(:commit_edit)
        allow(Fastlane::UI).to receive(:success)
        allow(Fastlane::UI).to receive(:message)
      end

      it 'should commit changes' do
        client.resume_release(package_name: package_name, track: target_track, version_name: target_version_name)
        expect(android_publisher_service).to have_received(:update_edit_track).with(package_name, edit_id, target_track, any_args).once
        expect(android_publisher_service).to have_received(:commit_edit).with(package_name, edit_id).once
        expect(track_release).to have_received(:status=).with('completed')
        expect(Fastlane::UI).to have_received(:message).once
        expect(Fastlane::UI).to have_received(:success).once
      end
    end

    context 'request failure' do
      let(:error) { Google::Apis::Error.new('error') }
      before do
        allow(android_publisher_service).to receive(:insert_edit).and_raise(error)
        allow(Fastlane::UI).to receive(:error!)
      end

      it do
        client.resume_release(package_name: package_name, track: target_track, version_name: target_version_name)
        expect(Fastlane::UI).to have_received(:error!).with("Failed to resume release for '#{target_version_name}' on track: #{target_track}. Google Api Error: error")
      end
    end
  end

  describe '#update_rollout' do
    let(:file_path) { './spec/fixtures/sample_external_account.json' }
    let(:auth_client) { double('auth_client') }
    let(:client) { Fastlane::GooglePlayTrackUpdater::GooglePlayClient.new(json_file_path: file_path) }

    let(:android_publisher_service) { double('android_publisher_service') }
    let(:app_edit) do
      instance_double(Google::Apis::AndroidpublisherV3::AppEdit)
    end
    let(:track) do
      instance_double(Google::Apis::AndroidpublisherV3::Track)
    end
    let(:track_release) do
      instance_double(Google::Apis::AndroidpublisherV3::TrackRelease)
    end
    let(:track_release_2) do
      instance_double(Google::Apis::AndroidpublisherV3::TrackRelease)
    end
    let(:target_version_name) { '1.0.0' }
    let(:target_track) { 'internal' }
    let(:package_name) { 'com.mataku.app' }
    let(:edit_id) { "1011010" }

    before do
      allow(Google::Auth::ExternalAccount::Credentials).to receive(:make_creds).and_return(auth_client)
      allow(auth_client).to receive(:fetch_access_token!)
      allow(track_release).to receive(:name).and_return('1.0.0')
      allow(track_release).to receive(:status).and_return('inProgress')
      allow(track_release_2).to receive(:name).and_return('0.9.0')
      allow(track_release_2).to receive(:status).and_return('inProgress')
      allow(track).to receive(:releases).and_return([track_release, track_release_2])
      allow(android_publisher_service).to receive(:authorization=)
      allow(android_publisher_service).to receive(:get_edit_track).and_return(track)
      allow(Google::Apis::AndroidpublisherV3::AndroidPublisherService).to receive(:new).and_return(android_publisher_service)
      allow(android_publisher_service).to receive(:insert_edit).and_return(app_edit)
      allow(app_edit).to receive(:id).and_return(edit_id)
    end

    context 'package_name is not specified' do
      it 'should raise UI.user_error!' do
        expect do
          client.update_rollout(
            package_name: nil,
            track: nil,
            version_name: nil,
            user_fraction: nil
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError).with_message('Specify the package name using the \'package_name:\' .')
      end
    end

    context 'track is not specified' do
      it 'should raise UI.user_error!' do
        expect do
          client.update_rollout(
            package_name: 'com.mataku.app',
            track: nil,
            version_name: nil,
            user_fraction: nil
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError).with_message('Specify the track using the \'track:\' .')
      end
    end

    context 'user_fraction is invalid' do
      it 'should raise UI.user_error!' do
        expect do
          client.update_rollout(
            package_name: 'com.mataku.app',
            track: 'internal',
            version_name: '1.0.0',
            user_fraction: 1.5
          )
        end.to raise_error(FastlaneCore::Interface::FastlaneError).with_message('Invalid \'user_fraction:\' provided. Please specify a value from 0 and 1 (exclusive). e.g., 0.1 for 10% rollout.')
      end
    end

    context 'release with inProgress status exists' do
      let(:user_fraction) { 0.2 }
      before do
        allow(track_release).to receive(:status).and_return('inProgress')
        allow(track_release).to receive(:status=)
        allow(track_release).to receive(:user_fraction=)
        allow(android_publisher_service).to receive(:update_edit_track)
        allow(android_publisher_service).to receive(:commit_edit)
        allow(Fastlane::UI).to receive(:success)
      end

      it 'should commit changes' do
        client.update_rollout(package_name: package_name, track: target_track, version_name: target_version_name, user_fraction: user_fraction)
        expect(android_publisher_service).to have_received(:update_edit_track).with(package_name, edit_id, target_track, any_args).once
        expect(android_publisher_service).to have_received(:commit_edit).with(package_name, edit_id).once
        expect(track_release).to have_received(:user_fraction=).with(user_fraction.to_f)
        expect(Fastlane::UI).to have_received(:success).with("Successfully updated rollout to #{user_fraction} for version '#{target_version_name}' on track: #{target_track}).").once
      end
    end

    context 'no inProgress releases exist' do
      before do
        allow(track_release).to receive(:status).and_return('completed')
        allow(android_publisher_service).to receive(:update_edit_track)
        allow(android_publisher_service).to receive(:commit_edit)
        allow(Fastlane::UI).to receive(:message)
      end
      it 'should not commit changes' do
        client.update_rollout(package_name: package_name, track: target_track, version_name: target_version_name, user_fraction: 0.1)
        expect(android_publisher_service).not_to have_received(:update_edit_track)
        expect(android_publisher_service).not_to have_received(:commit_edit)
        expect(Fastlane::UI).to have_received(:message).with("No inProgress releases found to update rollout for version '#{target_version_name}' on track: #{target_track}.").once
      end
    end

    context 'request failure' do
      let(:error) { Google::Apis::Error.new('error') }
      before do
        allow(android_publisher_service).to receive(:insert_edit).and_raise(error)
        allow(Fastlane::UI).to receive(:error!)
      end

      it do
        client.update_rollout(package_name: package_name, track: target_track, version_name: target_version_name, user_fraction: 0.1)
        expect(Fastlane::UI).to have_received(:error!).with("Failed to update rollout for version '#{target_version_name}' on track: #{target_track}. Google Api Error: error")
      end
    end
  end
end
