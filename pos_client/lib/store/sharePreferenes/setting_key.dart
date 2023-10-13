import 'package:shared_preferences/shared_preferences.dart';

enum BoolSettingKey {
  useReceiptPrinter,
}

enum DoubleSettingKey {
  fontSizeScale,
}

class SettingSharedPreference {
  final SharedPreferences prefs;

  SettingSharedPreference(this.prefs);

  editSetting(bool value, BoolSettingKey key) async {
    prefs.setBool(key.toString(), value);
  }

  bool? getSetting(BoolSettingKey key) {
    return prefs.getBool(key.toString());
  }

  editDoubleSetting(double value, DoubleSettingKey key) async {
    prefs.setDouble(key.toString(), value);
  }

  double? getDoubleSetting(DoubleSettingKey key) {
    return prefs.getDouble(key.toString());
  }
}
