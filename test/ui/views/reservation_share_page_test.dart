import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/ui/views/reservation_share_page.dart';
import 'package:cos_connect/data/provider/share_page_provider.dart';
import 'package:cos_connect/data/models/reservation.dart';

void main() {
  group('ReservationSharePage', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('初始化時應該正確顯示標題', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: ReservationSharePage(isPublic: true),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // 使用更精確的查找方式
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.title, isA<Text>());
      expect((appBar.title as Text).data, '建立分享卡片');
    });

    testWidgets('輸入文字應該正確更新狀態', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: ReservationSharePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 找到地點輸入框並輸入文字
      final locationField = find.byType(TextField).first;
      await tester.enterText(locationField, '測試地點');
      await tester.pump();
      await tester.pumpAndSettle();

      // 驗證 provider 中的值
      final state = container.read(sharePageProvider);
      expect(state.location, '測試地點');
    });

    testWidgets('身份選擇應該正確更新', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: ReservationSharePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 找到下拉選單
      final dropdown = find.byType(DropdownButtonFormField<IdentityType>);
      expect(dropdown, findsOneWidget);

      // 點擊下拉選單
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // 選擇攝影師選項
      await tester.tap(find.text('攝影師').last);
      await tester.pumpAndSettle();

      // 驗證 provider 中的值
      final state = container.read(sharePageProvider);
      expect(state.identity, IdentityType.photographer);
    });

    testWidgets('公開模式不應該顯示照片上傳區域', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: ReservationSharePage(isPublic: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 驗證照片上傳區域不存在
      expect(find.byIcon(Icons.add_photo_alternate), findsNothing);
    });

    testWidgets('文字輸入不應該造成無限循環更新', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: ReservationSharePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 找到所有文字輸入框
      final textFields = find.byType(TextField);
      final texts = ['測試地點', '測試名稱', '測試備註'];

      // 對每個輸入框進行測試
      for (int i = 0; i < 3; i++) {
        await tester.enterText(textFields.at(i), texts[i]);
        await tester.pump();
        await tester.pumpAndSettle();
      }

      // 驗證 provider 中的值
      final state = container.read(sharePageProvider);
      expect(state.location, '測試地點');
      expect(state.name, '測試名稱');
      expect(state.note, '測試備註');
    });
  });
}
