import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pos/store/sharePreferenes/sharepreference_helper.dart';

void upgradeApp({bool executeSetup = false}) async {
  SharedPreferenceHelper sharedPreferenceHelper = SharedPreferenceHelper();
  await sharedPreferenceHelper.init();
  final latestVersionInfo = await fetchLatestInfoFromGitHub();
  final currentVersion = await getCurrentAppVersion(); // 自己实现获取当前应用版本的逻辑
  print('currentVersion: $currentVersion');
  print('latestVersionInfo: $latestVersionInfo');
  if (executeSetup) {
    if (await executeSetupEXE(sharedPreferenceHelper.appInfo.getUpdateExePath())) {
      print('更新成功');
      // 更新成功後，更新版本號
      sharedPreferenceHelper.appInfo.setAppVersion(latestVersionInfo?['version'] ?? '');
      return;
    } else {
      print('更新失敗');
    }
  }
  if (isNeedUpgrade(currentVersion, latestVersionInfo?['version'])) {
    String? downloadUrl = latestVersionInfo?['downloadUrl'];
    if (downloadUrl != null) {
      final tempFilePath = await downloadFile(downloadUrl);
      sharedPreferenceHelper.appInfo.setUpdateExePath(tempFilePath ?? '');
    }
  }
}

bool isNeedUpgrade(String? currentVersion, String? latestVersion) {
  if (latestVersion == null) return false;
  if (currentVersion == null) return true;
  final version1List = currentVersion.split('.');
  final version2List = latestVersion.split('.');
  for (int i = 0; i < version1List.length; i++) {
    final version1Number = int.parse(version1List[i]);
    final version2Number = int.parse(version2List[i]);
    if (version1Number > version2Number) {
      return true;
    } else if (version1Number < version2Number) {
      return false;
    }
  }
  return false;
}

Future<String?> getCurrentAppVersion() async {
  SharedPreferenceHelper sharedPreferenceHelper = SharedPreferenceHelper();
  await sharedPreferenceHelper.init();
  return sharedPreferenceHelper.appInfo.getAppVersion();
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

Future<String?> fetchDownloadUrlFromGitHub() async {
  final response = await Dio().get('https://api.github.com/repos/orange2000121/pos-system/releases/latest');
  if (response.statusCode == 200) {
    final json = response.data;
    final assets = json['assets'];
    final asset = assets[0];
    final downloadUrl = asset['browser_download_url'];
    return downloadUrl.toString();
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
