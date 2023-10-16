import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pos/store/sharePreferenes/sharepreference_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpgradeApp {
  Map? latestVersionInfo;

  void upgradeApp({bool executeSetup = false}) async {
    SharedPreferenceHelper sharedPreferenceHelper = SharedPreferenceHelper();
    await sharedPreferenceHelper.init();
    if (executeSetup) {
      if (await executeSetupEXE(sharedPreferenceHelper.appInfo.getUpdateExePath())) {
        print('更新成功');
        return;
      } else {
        print('更新失敗');
      }
    }
    if (await isNeedUpgrade()) {
      String? downloadUrl = latestVersionInfo?['downloadUrl'];
      if (downloadUrl != null) {
        final tempFilePath = await downloadFile(downloadUrl);
        sharedPreferenceHelper.appInfo.setUpdateExePath(tempFilePath ?? '');
      }
    }
  }

  Future<bool> isNeedUpgrade() async {
    latestVersionInfo = await fetchLatestInfoFromGitHub();
    final currentVersion = await getCurrentAppVersion(); // 自己实现获取当前应用版本的逻辑
    print('currentVersion: $currentVersion');
    print('latestVersionInfo: $latestVersionInfo');
    String? latestVersion = latestVersionInfo?['version'];
    if (latestVersion == null) return false;
    if (currentVersion == null) return true;
    final currentVersionList = currentVersion.split('.');
    final lastestVersionList = latestVersion.split('.');
    for (int i = 0; i < currentVersionList.length; i++) {
      final currentVersionNumber = int.parse(currentVersionList[i]);
      final latestVersionNumber = int.parse(lastestVersionList[i]);
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
      final asset = json['assets'][0];
      return {
        'version': version.toString(),
        'downloadUrl': asset['browser_download_url'],
      };
    }
    return null;
  }

  Future<String?> downloadFile(String url) async {
    print('downLoading');
    final response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
    if (response.statusCode == 200) {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/setupPOS.exe');
      await tempFile.writeAsBytes(response.data);
      print('tempFile: ${tempFile.path}');
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
