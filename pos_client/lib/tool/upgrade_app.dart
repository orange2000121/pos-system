import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pos/store/sharePreferenes/sharepreference_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pos/tool/database_backup.dart';

class UpgradeApp {
  Map? latestVersionInfo;

  Future<bool> upgradeApp({Function(double percentageValue)? progress}) async {
    if (await isNeedUpgrade()) {
      String? downloadUrl = latestVersionInfo?['downloadUrl'];
      if (downloadUrl != null) {
        if (!await DataBaseBackup().backup()) return false; // 備份資料庫
        final tempFilePath = await downloadFile(downloadUrl, progress: progress); // 下載安裝檔
        print('下載完成，檔案路徑: $tempFilePath');
        if (Platform.isWindows) {
          if (!await executeSetupEXE(tempFilePath)) return false; // 執行安裝檔
        } else if (Platform.isMacOS) {
          await installDMG(tempFilePath!);
        }
      } else {
        return false;
      }
    }
    return true;
  }

  Future<bool> isNeedUpgrade() async {
    latestVersionInfo = await fetchLatestInfoFromGitHub();
    final currentVersion = await getCurrentAppVersion(); // 自己实现获取当前应用版本的逻辑
    String? latestVersion = latestVersionInfo?['version'];
    if (latestVersion == null) return false;
    if (currentVersion == null) return true;
    final currentVersionList = currentVersion.split('.');
    final latestVersionList = latestVersion.split('.');
    for (int i = 0; i < currentVersionList.length; i++) {
      final currentVersionNumber = int.parse(currentVersionList[i]);
      final latestVersionNumber = int.parse(latestVersionList[i]);
      if (currentVersionNumber < latestVersionNumber) {
        return true;
      } else if (currentVersionNumber > latestVersionNumber) {
        return false;
      }
    }
    return false;
  }

  Future<String?> getCurrentAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<Map?> fetchLatestInfoFromGitHub() async {
    final dio = Dio();
    final response = await dio.get('https://api.github.com/repos/orange2000121/pos-system/releases/latest');
    if (response.statusCode == 200) {
      final json = response.data;
      final version = json['name'];
      var asset = json['assets'][0];
      for (int i = 0; i < json['assets'].length; i++) {
        if (Platform.isWindows) {
          if ((json['assets'][i]['name'] as String).toLowerCase().endsWith('.exe')) {
            asset = json['assets'][i];
            break;
          }
        } else if (Platform.isMacOS) {
          if ((json['assets'][i]['name'] as String).toLowerCase().endsWith('.dmg')) {
            asset = json['assets'][i];
            break;
          }
        }
      }
      print('最新版本: $version, 下載連結: ${asset['browser_download_url']}');
      return {
        'version': version.toString(),
        'downloadUrl': asset['browser_download_url'],
      };
    }
    return null;
  }

  Future<String?> downloadFile(String url, {Function(double percentageValue)? progress}) async {
    final tempDir = Directory.systemTemp;
    File tempFile;
    if (Platform.isWindows) {
      tempFile = File('${tempDir.path}/setupPOS.exe');
    } else if (Platform.isMacOS) {
      tempFile = File('${tempDir.path}/POS.dmg');
    } else {
      return null;
    }

    final response = await Dio().get(
      url,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (total != -1) {
          if (progress != null) progress(received / total);
        }
      },
    );

    if (response.statusCode == 200) {
      await tempFile.writeAsBytes(response.data);
      return tempFile.path;
    }
    return null;
  }

  Future<bool> executeSetupEXE(String? filePath) async {
    if (filePath == null) return false;
    if (File(filePath).existsSync()) {
    } else {
      return false;
    }
    ProcessResult processResult = await Process.run(filePath, ['/VERYSILENT'], runInShell: true);
    if (processResult.exitCode == 0) {
      //刪除安裝檔
      File(filePath).delete();
      return true;
    }
    return false;
  }

  Future<bool> isUpgradeExeExist() async {
    SharedPreferenceHelper sharedPreferenceHelper = SharedPreferenceHelper();
    await sharedPreferenceHelper.init();
    String? filePath = sharedPreferenceHelper.appInfo.getUpdateExePath();
    if (filePath == null) return false;
    if (File(filePath).existsSync()) {
      return true;
    } else {
      return false;
    }
  }
}
