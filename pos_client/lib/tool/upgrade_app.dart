import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info/package_info.dart';

void upgradeApp() async {
  // final latestVersion = await fetchLatestVersionFromGitHub();
  // final currentVersion = getCurrentAppVersion(); // 自己实现获取当前应用版本的逻辑

  // if (latestVersion != null && latestVersion > currentVersion) {
  final downloadUrl = await fetchDownloadUrlFromGitHub();
  if (downloadUrl != null) {
    final tempFilePath = await downloadFile(downloadUrl);
    if (tempFilePath != null) {
      executeSetupEXE(tempFilePath);
    }
  }
  // }
}

Future<String> getCurrentAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  final appVersion = packageInfo.version;
  return appVersion;
}

Future<String?> fetchLatestVersionFromGitHub() async {
  final dio = Dio();
  final response = await dio.get('https://api.github.com/repos/orange2000121/pos-system/releases/latest');
  if (response.statusCode == 200) {
    final json = response.data;
    final tagName = json['tag_name'];
    return tagName.toString();
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

void executeSetupEXE(String filePath) {
  Process.run(filePath, [], runInShell: true);
}
