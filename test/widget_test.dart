import 'package:flutter_test/flutter_test.dart';
import 'package:desa_wisata/main.dart';
import 'package:desa_wisata/screens/splash_screen.dart';

void main() {
  testWidgets('App starts on the DesaKita splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DesaKitaApp());

    expect(find.byType(SplashScreen), findsOneWidget);

    // Jalankan timer 2 detik pada splash agar tidak ada pending timer saat test selesai
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
