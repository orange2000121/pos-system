import 'package:shared_preferences/shared_preferences.dart';

enum AppInfoKey {
  version,
  updateExePath,
}

class AppInfoSharedPreferenes {
  final SharedPreferences prefs;
  AppInfoSharedPreferenes(this.prefs);
  void setAppVersion(String version) async {
    prefs.setString(AppInfoKey.version.toString(), version);
  }

  String? getAppVersion() {
    return prefs.getString(AppInfoKey.version.toString());
  }

  String? getUpdateExePath() {
    return prefs.getString(AppInfoKey.updateExePath.toString());
  }

  void setUpdateExePath(String path) {
    prefs.setString(AppInfoKey.updateExePath.toString(), path);
  }
}
