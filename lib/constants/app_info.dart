/// Keep in sync with `version` in pubspec.yaml (name+build → 1.0.4+5).
class AppInfo {
  static const version = '1.0.4';
  static const buildNumber = '4';

  static String get versionLabel => 'Version $version ($buildNumber)-actual 4';
}
