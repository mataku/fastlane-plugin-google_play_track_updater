lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/google_play_track_updater/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-google_play_track_updater'
  spec.version       = Fastlane::GooglePlayTrackUpdater::VERSION
  spec.author        = 'Takuma Homma'
  spec.email         = 'nagomimatcha@gmail.com'

  spec.summary       = 'Control Google Play tracks by halting, resuming, or updating rollout fractions.'
  spec.description   = 'fastlane plugin for Google Play track management. Includes halt_google_play_release, resume_google_play_release, and update_google_play_release_rollout actions to control release statuses and rollout fractions.'
  spec.homepage      = "https://github.com/mataku/fastlane-plugin-google_play_track_updater"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 2.6' # the same version as fastlane

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'

  spec.add_dependency('google-apis-androidpublisher_v3', '~> 0.3')
end
