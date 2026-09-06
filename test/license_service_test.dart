import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/data/database_helper.dart';
import 'package:nihaisha_app/services/license_service.dart';

void main() {
  const device = '00112233445566778899aabbccddeeff';
  const futureCode = 'C04vjqA8sRVE89euuAn';
  const permanentCode = 'SKhdOov8mYLckWMvCie';
  const expiredCode = '002l3LAL4ihQXHTdA6u';

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.resetForTest();
    await DatabaseHelper.instance.setSetting('device_id', device);
  });

  test('长期卡校验并解析到期日', () async {
    final info = await LicenseService.verify(futureCode);
    expect(info.result, LicenseResult.valid);
    expect(info.expiryLabel, '2099-12-31');
    expect(info.isPermanent, isFalse);
  });

  test('永久卡校验', () async {
    final info = await LicenseService.verify(permanentCode);
    expect(info.result, LicenseResult.valid);
    expect(info.isPermanent, isTrue);
    expect(info.expiryLabel, '永久有效');
  });

  test('过期卡、错设备与格式错误分开返回', () async {
    expect(
      (await LicenseService.verify(expiredCode)).result,
      LicenseResult.expired,
    );
    await DatabaseHelper.instance.setSetting(
      'device_id',
      'ffeeddccbbaa99887766554433221100',
    );
    expect(
      (await LicenseService.verify(futureCode)).result,
      LicenseResult.deviceMismatch,
    );
    expect(
      (await LicenseService.verify('bad')).result,
      LicenseResult.badFormat,
    );
  });

  test('激活后冷启动可从本地恢复', () async {
    expect((await LicenseService.activate(futureCode)).isValid, isTrue);
    final restored = await LicenseService.current();
    expect(restored.isValid, isTrue);
    expect(restored.deviceId, device);
  });
}
