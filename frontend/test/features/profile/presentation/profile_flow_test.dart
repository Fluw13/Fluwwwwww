import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/core/database/app_database.dart';
import 'package:fluw/core/database/database_provider.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/data/profile_repository.dart';
import 'package:fluw/features/profile/data/stored_profile.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/sex.dart';

import '../../../helpers/load_app_fonts.dart';
import '../../../helpers/pump_fluw_app.dart';
import '../domain/profile_fixture.dart';

void main() {
  ProfileRepository repositoryOf(WidgetTester tester) => appContainer(tester).read(profileRepositoryProvider);

  /// Offstage tabs and the screen under a pushed page keep their own lists, so scroll the one the user can touch.
  Future<void> scrollTo(WidgetTester tester, Finder finder, {double delta = 200}) async {
    // Picked once: a list ignores pointers while it scrolls, so a hit-test finder would lose it mid-drag.
    final touchable = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axis == Axis.vertical);
    final list = touchable.hitTestable().evaluate().first;
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find.byElementPredicate((element) => identical(element, list)),
      // At 310% text the profile page is close to 20,000 px tall.
      maxScrolls: 500,
    );
    // scrollUntilVisible stops once the widget is built, which can still be in the cache area below the screen.
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openProfileTab(WidgetTester tester, {HealthProfile? saved}) async {
    await pumpFluwApp(tester);
    if (saved != null) {
      await tester.runAsync(() => repositoryOf(tester).save(saved));
    }
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('chưa có hồ sơ thì mời thiết lập và mở màn Thiết lập', (tester) async {
    await openProfileTab(tester);

    expect(find.text('Chưa có hồ sơ sức khỏe'), findsOneWidget);
    await tester.tap(find.text('Thiết lập hồ sơ').last);
    await tester.pumpAndSettle();

    expect(find.text('1. Thông tin cơ bản'), findsOneWidget);
  });

  testWidgets('hồ sơ đã lưu hiện số đo, BMI và chỉ tiêu mỗi ngày tính từ hồ sơ', (tester) async {
    await openProfileTab(tester, saved: buildProfile(displayName: 'An'));

    expect(find.text('An'), findsOneWidget);
    expect(find.text('20 tuổi · Nam'), findsOneWidget);
    expect(find.text('22.8'), findsOneWidget);
    expect(find.text('Bình thường'), findsOneWidget);
    await scrollTo(tester, find.text('2,083 kcal/ngày'));
    expect(find.text('2,083 kcal/ngày'), findsOneWidget);
    expect(find.text('126–168 g/ngày'), findsOneWidget);
  });

  testWidgets('dưới 18 tuổi không hiện BMI và calo, có lời khuyên gặp chuyên gia', (tester) async {
    await openProfileTab(tester, saved: buildProfile(birthDate: CalendarDate(2010, 1, 1), weeklyChangeKg: null));

    expect(find.textContaining('BMI'), findsNothing);
    await scrollTo(tester, find.textContaining('không tính calo'));
    expect(find.text('Năng lượng'), findsNothing);
  });

  testWidgets('hồ sơ hỏng thì báo không đọc được, không mở form trống lặng lẽ', (tester) async {
    await openProfileTab(tester, saved: buildProfile());
    await tester.runAsync(() {
      final database = appContainer(tester).read(appDatabaseProvider);
      return database.update(database.profiles).write(const ProfilesCompanion(sex: Value('unknown')));
    });
    await tester.pumpAndSettle();

    expect(find.text('Không đọc được hồ sơ đã lưu'), findsOneWidget);
  });

  testWidgets('hồ sơ đã lưu có tốc độ ngoài giới hạn: không crash, không hiện BMI, báo cần sửa', (tester) async {
    await openProfileTab(tester, saved: buildProfile(weeklyChangeKg: 0));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('BMI'), findsNothing);
    await scrollTo(tester, find.text('Hồ sơ cần sửa trước khi tính:'));
    expect(find.textContaining('Tốc độ thay đổi cân nặng phải lớn hơn 0'), findsOneWidget);
  });

  testWidgets('chỉ chạm vào ô hoặc sửa rồi trả lại như cũ thì quay lại không bị hỏi', (tester) async {
    await openProfileTab(tester, saved: buildProfile());
    await scrollTo(tester, find.text('Cập nhật hồ sơ'));
    await tester.tap(find.text('Cập nhật hồ sơ'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextField, 'Cân nặng'));
    await tester.enterText(find.widgetWithText(TextField, 'Cân nặng'), '71');
    await tester.enterText(find.widgetWithText(TextField, 'Cân nặng'), '70');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Bỏ các thay đổi?'), findsNothing);
    expect(find.text('1. Thông tin cơ bản'), findsNothing);
  });

  testWidgets('sửa cân nặng rồi lưu thì lưu vào máy và màn Hồ Sơ cập nhật ngay', (tester) async {
    await openProfileTab(tester, saved: buildProfile());
    await scrollTo(tester, find.text('Cập nhật hồ sơ'));
    await tester.tap(find.text('Cập nhật hồ sơ'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Cân nặng'), '72,5');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Đã lưu hồ sơ.'), findsOneWidget);
    await scrollTo(tester, find.text('72.5 kg'), delta: -200);
    expect(find.text('72.5 kg'), findsOneWidget);
    expect(((await tester.runAsync(repositoryOf(tester).load)) as LoadedProfile).profile, buildProfile(weightKg: 72.5));
  });

  testWidgets('lưu khi còn thiếu thì báo lỗi ở từng ô và không lưu gì', (tester) async {
    await openProfileTab(tester);
    await tester.tap(find.text('Thiết lập hồ sơ').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Còn 7 mục cần sửa trước khi lưu.'), findsOneWidget);
    expect(find.text('Chọn giới tính.'), findsOneWidget);
    expect(find.text('Nhập chiều cao.'), findsOneWidget);
    expect(await tester.runAsync(repositoryOf(tester).load), isA<NoProfile>());
  });

  testWidgets('bấm quay lại khi đang sửa dở thì hỏi trước khi bỏ thay đổi', (tester) async {
    await openProfileTab(tester, saved: buildProfile());
    await scrollTo(tester, find.text('Cập nhật hồ sơ'));
    await tester.tap(find.text('Cập nhật hồ sơ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Cân nặng'), '90');
    await tester.pump();

    // pageBack() looks for the English "Back" tooltip; the app runs in Vietnamese.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ các thay đổi?'), findsOneWidget);

    await tester.tap(find.text('Bỏ thay đổi'));
    await tester.pumpAndSettle();
    expect(find.text('1. Thông tin cơ bản'), findsNothing);
    expect(((await tester.runAsync(repositoryOf(tester).load)) as LoadedProfile).profile, buildProfile());
  });

  testWidgets('tạo hồ sơ mới từ đầu: chọn ngày sinh, giới tính Khác và công thức BMR, rồi lưu', (tester) async {
    await openProfileTab(tester);
    await tester.tap(find.text('Thiết lập hồ sơ').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Tên gọi (không bắt buộc)'), 'Linh');
    await tester.tap(find.text('Chọn ngày sinh'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '04/03/1998');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('04/03/1998 (28 tuổi)'), findsOneWidget);

    await tester.tap(find.text('Khác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theo công thức Nữ'));
    await tester.enterText(find.widgetWithText(TextField, 'Chiều cao'), '165');
    await tester.enterText(find.widgetWithText(TextField, 'Cân nặng'), '58.5');
    await tester.enterText(find.widgetWithText(TextField, 'Cân nặng mong muốn'), '58.5');
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Mức vận động hằng ngày'));
    await tester.tap(find.text('Mức vận động hằng ngày'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoạt động nhẹ').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Hình thức tập'));
    await tester.tap(find.text('Hình thức tập'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhẹ / sức bền').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    final saved = ((await tester.runAsync(repositoryOf(tester).load)) as LoadedProfile).profile;
    expect(saved.displayName, 'Linh');
    expect(saved.birthDate, CalendarDate(1998, 3, 4));
    expect(saved.sex, Sex.other);
    expect(saved.bmrFormulaForOther, BmrFormula.female);
    expect(saved.weightKg, 58.5);
    expect(saved.weeklyChangeKg, isNull);
    expect(find.text('Linh'), findsOneWidget);
  });

  // 200% is Android's largest font size; 310% is iOS's largest accessibility size.
  for (final textScale in [2.0, 3.1]) {
    testWidgets('320x568, cỡ chữ ${(textScale * 100).round()}%: Hồ Sơ và Thiết lập không tràn bố cục', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await loadAppFonts();

      await openProfileTab(
        tester,
        saved: buildProfile(displayName: 'Nguyễn Thị Phương Linh', conditions: {HealthCondition.diabetes}),
      );
      await scrollTo(tester, find.text('Cập nhật hồ sơ'), delta: 100);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cập nhật hồ sơ'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Khác'), delta: 100);
      await tester.tap(find.text('Khác'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Lưu hồ sơ'), delta: 100);
      expect(tester.takeException(), isNull);
    });
  }
}
