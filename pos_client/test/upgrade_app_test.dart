import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/tool/upgrade_app.dart';

void main() {
  group('UpgradeApp.fetchLatestInfoFromGitHub', () {
    test('returns expected version and correct platform asset', () async {
      final upgradeApp = UpgradeApp();
      final info = await upgradeApp.fetchLatestInfoFromGitHub();

      expect(info, isNotNull);
      expect(info!['version'], '0.1.4');
      final url = info['downloadUrl'] as String;
      if (Platform.isMacOS) {
        expect(url, 'https://github.com/orange2000121/pos-system/releases/download/0.1.4/POS.dmg');
      } else if (Platform.isWindows) {
        expect(url, 'https://github.com/orange2000121/pos-system/releases/download/0.1.4/setupPOS.exe');
      } else {
        // 其他平台會落在預設第一個 asset（.exe）
        expect(url, anyOf('https://example.com/pos_setup.exe', 'https://example.com/pos_setup.dmg'));
      }
    });
  });
}
