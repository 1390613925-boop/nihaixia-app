/// Single source of truth for distribution-specific identity.
///
/// Keep medical content and feature code independent from the fork's brand and
/// update feed. Build-time overrides are supported for internal test builds,
/// while production builds use these checked-in defaults.
abstract final class AppIdentity {
  static const displayName = String.fromEnvironment(
    'APP_DISPLAY_NAME',
    defaultValue: '覓源',
  );

  static const assistantName = String.fromEnvironment(
    'APP_ASSISTANT_NAME',
    defaultValue: '覓源辨证助手',
  );

  static const tagline = '循经典之源，索辨证之方';
  static const packageName = 'com.nihaisha.nihaisha_app';

  static const updateRepositoryOwner = String.fromEnvironment(
    'UPDATE_REPOSITORY_OWNER',
    defaultValue: '1390613925-boop',
  );

  static const updateRepositoryName = String.fromEnvironment(
    'UPDATE_REPOSITORY_NAME',
    defaultValue: 'nihaixia-app',
  );

  static const updateReleasesApiUrl =
      'https://api.github.com/repos/$updateRepositoryOwner/'
      '$updateRepositoryName/releases/latest';
}
