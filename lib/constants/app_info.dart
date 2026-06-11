/// Keep in sync with `version` in pubspec.yaml (name+build → 1.0.3+3).
class AppInfo {
  static const version = '1.0.3';
  static const buildNumber = '3';

  static String get versionLabel => 'Version $version ($buildNumber)';
}
