# google_play_track_updater plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-google_play_track_updater)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-google_play_track_updater`, add it to your project by running:

```bash
# to Gemfile
bundle add 'fastlane-plugin-google_play_track_updater'
```

```bash
# to Pluginfile
fastlane add_plugin google_play_track_updater
```

## About google_play_track_updater

A fastlane plugin for managing Google Play release tracks. This plugin provides three actions to control release statuses and rollout fractions:

- **`halt_google_play_release`** - Halts an active staged rollout or completed release
- **`resume_google_play_release`** - Resumes a halted release
- **`update_google_play_release_rollout`** - Updates the rollout percentage for a staged rollout

## Motivation

While [supply](https://docs.fastlane.tools/actions/supply/) can also change release statuses, it requires many configuration parameters which can lead to unintended side effects. This plugin provides dedicated actions for each specific operation, making release management more explicit and manageable.

By using focused actions like `halt_google_play_release`, `resume_google_play_release`, and `update_google_play_release_rollout`, you can:

- Clearly express your intent in your Fastfile
- Reduce the risk of accidentally modifying other release properties
- Simplify your CI/CD pipelines with purpose-built commands

## Actions

### halt_google_play_release

Halts an active staged rollout or completed release for a specific version on a Google Play track.

```ruby
halt_google_play_release(
  package_name: "com.example.app",
  track: "production",
  version_name: "1.0.0",
  json_file_path: "path/to/service-account.json"
)
```

**Parameters:**

| Key | Description | Required | Type |
|-----|-------------|----------|------|
| `package_name` | The package name of the application (e.g., 'com.example.app') | Yes | String |
| `track` | The track of the application (production, beta, alpha, internal) | Yes | String |
| `version_name` | The version name to halt (e.g., '1.0.0') | Yes | String |
| `json_file_path` | Path to a file containing service account or external account JSON | No* | String |
| `json_key_data` | Service account or external account JSON data as a string | No* | String |

\* Either `json_file_path` or `json_key_data` must be provided

### resume_google_play_release

Resumes a halted staged rollout for a specific version on a Google Play track. The status will change from 'halted' to either 'completed' (if no user_fraction is set) or 'inProgress' (if user_fraction is set for staged rollout).

```ruby
resume_google_play_release(
  package_name: "com.example.app",
  track: "production",
  version_name: "1.0.0",
  json_file_path: "path/to/service-account.json"
)
```

**Parameters:**

| Key | Description | Required | Type |
|-----|-------------|----------|------|
| `package_name` | The package name of the application (e.g., 'com.example.app') | Yes | String |
| `track` | The track of the application (production, beta, alpha, internal) | Yes | String |
| `version_name` | The version name to resume (e.g., '1.0.0') | Yes | String |
| `json_file_path` | Path to a file containing service account or external account JSON | No* | String |
| `json_key_data` | Service account or external account JSON data as a string | No* | String |

\* Either `json_file_path` or `json_key_data` must be provided

### update_google_play_release_rollout

Updates the rollout percentage for a staged rollout on a Google Play track. Only updates releases with 'inProgress' status.

```ruby
update_google_play_release_rollout(
  package_name: "com.example.app",
  track: "production",
  version_name: "1.0.0",
  user_fraction: 0.5, # 50% rollout
  json_file_path: "path/to/service-account.json"
)
```

**Parameters:**

| Key | Description | Required | Type |
|-----|-------------|----------|------|
| `package_name` | The package name of the application (e.g., 'com.example.app') | Yes | String |
| `track` | The track of the application (production, beta, alpha, internal) | Yes | String |
| `version_name` | The version name to update (e.g., '1.0.0') | Yes | String |
| `user_fraction` | The rollout percentage as a fraction (0.0 to 1.0, exclusive). e.g., 0.1 for 10% rollout | Yes | Float |
| `json_file_path` | Path to a file containing service account or external account JSON | No* | String |
| `json_key_data` | Service account or external account JSON data as a string | No* | String |

\* Either `json_file_path` or `json_key_data` must be provided

## Example

Here are examples of how to use each action in your `Fastfile`:

```ruby
lane :halt_release do
  halt_google_play_release(
    package_name: "com.example.app",
    track: "production",
    version_name: "1.0.0",
    json_file_path: "path/to/service-account.json"
  )
end

lane :resume_release do
  resume_google_play_release(
    package_name: "com.example.app",
    track: "production",
    version_name: "1.0.0",
    json_file_path: "path/to/external-account.json"
  )
end

lane :update_rollout do
  update_google_play_release_rollout(
    package_name: "com.example.app",
    track: "production",
    version_name: "1.0.0",
    user_fraction: 0.5,
    json_file_path: "path/to/service-account.json"
  )
end
```

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
