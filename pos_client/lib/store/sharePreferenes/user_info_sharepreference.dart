import 'package:shared_preferences/shared_preferences.dart';

enum UserInfoKey {
  userName,
  address,
  phone,
}

enum SettingKey {
  useReceiptPrinter,
}

class SharedPreferenceHelper {
  static SharedPreferenceHelper? _instance;
  static SharedPreferenceHelper get instance {
    _instance ??= SharedPreferenceHelper();
    return _instance!;
  }

  late SharedPreferences? prefs;
  Future<bool> init() async {
    prefs = await SharedPreferences.getInstance();
    return true;
  }

  void editUserInfo(String userName, UserInfoKey key) async {
    prefs!.setString(key.toString(), userName);
  }

  String? getUserInfo(UserInfoKey key) {
    return prefs!.getString(key.toString()) ?? '';
  }

  editSetting(bool value, SettingKey key) async {
    prefs!.setBool(key.toString(), value);
  }

  bool? getSetting(SettingKey key) {
    return prefs!.getBool(key.toString());
  }
}
