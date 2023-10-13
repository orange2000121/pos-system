import 'package:shared_preferences/shared_preferences.dart';

enum AppInfoKey {
  version,
  updateExePath,
}

class AppInfoSharedPreferenes {
  final SharedPreferences prefs;
  AppInfoSharedPreferenes(this.prefs);
  void editAppInfo(String version, AppInfoKey key) async {
    prefs.setString(key.toString(), version);
  }

  String? getAppInfo(AppInfoKey key) {
    return prefs.getString(key.toString());
  }

  String? getUpdateExePath() {
    return prefs.getString(AppInfoKey.updateExePath.toString());
  }

  void setUpdateExePath(String path) {
    prefs.setString(AppInfoKey.updateExePath.toString(), path);
  }
}
