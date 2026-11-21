import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/privacy/health_data_consent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_preferences_store.dart';

void main() {
  test('mặc định chưa đồng ý; đồng ý thì lưu phiên bản chữ và thời điểm (UTC), mở lại vẫn nhớ', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = HealthDataConsentStorage(preferences);
    expect(storage.hasConsent, isFalse);

    await storage.giveConsent(DateTime.utc(2026, 11, 18, 3, 4, 5));

    expect(storage.hasConsent, isTrue);
    expect(preferences.getInt(HealthDataConsentStorage.versionKey), HealthDataConsentStorage.currentVersion);
    expect(preferences.getString(HealthDataConsentStorage.agreedAtKey), '2026-11-18T03:04:05.000Z');
    expect(HealthDataConsentStorage(await SharedPreferences.getInstance()).hasConsent, isTrue);
  });

  test('đồng ý với chữ phiên bản khác, giá trị sai kiểu hay không có kho thì coi như chưa đồng ý', () async {
    SharedPreferences.setMockInitialValues({
      HealthDataConsentStorage.versionKey: HealthDataConsentStorage.currentVersion + 1,
    });
    expect(HealthDataConsentStorage(await SharedPreferences.getInstance()).hasConsent, isFalse);

    SharedPreferences.setMockInitialValues({HealthDataConsentStorage.versionKey: 'có'});
    expect(HealthDataConsentStorage(await SharedPreferences.getInstance()).hasConsent, isFalse);

    const noStore = HealthDataConsentStorage(null);
    await noStore.giveConsent(DateTime.utc(2026));
    expect(noStore.hasConsent, isFalse);
  });

  test('ghi lỗi không ném ra ngoài: người dùng đã đồng ý, lần lưu sau hỏi lại', () async {
    FakePreferencesStore(failWrites: true).install();
    final storage = HealthDataConsentStorage(await SharedPreferences.getInstance());

    await expectLater(storage.giveConsent(DateTime.utc(2026)), completes);
  });
}
