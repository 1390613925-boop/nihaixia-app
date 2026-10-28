import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/config/app_identity.dart';

void main() {
  test('distribution identity has one stable source of truth', () {
    expect(AppIdentity.displayName, '覓源');
    expect(AppIdentity.assistantName, '覓源辨证助手');
    expect(AppIdentity.tagline, '循经典之源，索辨证之方');
    expect(AppIdentity.packageName, 'com.nihaisha.nihaisha_app');
  });

  test('update feed remains on the personal repository', () {
    expect(AppIdentity.updateRepositoryOwner, '1390613925-boop');
    expect(AppIdentity.updateRepositoryName, 'nihaixia-app');
    expect(
      AppIdentity.updateReleasesApiUrl,
      'https://api.github.com/repos/1390613925-boop/'
      'nihaixia-app/releases/latest',
    );
  });
}
