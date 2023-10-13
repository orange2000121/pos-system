import 'package:pos/store/sharePreferenes/app_info_key.dart';
import 'package:pos/store/sharePreferenes/setting_key.dart';
import 'package:pos/store/sharePreferenes/user_info_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 使用函示之前必須先呼叫 Future<bool> init()
class SharedPreferenceHelper {
  static SharedPreferenceHelper? _instance;
  static SharedPreferenceHelper get instance {
    _instance ??= SharedPreferenceHelper();
    return _instance!;
  }

  // shared preference helper
  late SharedPreferences? prefs;
  late UserInfoSharedPreference userInfo;
  late SettingSharedPreference setting;
  late AppInfoSharedPreferenes appInfo;
  Future<bool> init() async {
    prefs = await SharedPreferences.getInstance();
    userInfo = UserInfoSharedPreference(prefs!);
    setting = SettingSharedPreference(prefs!);
    appInfo = AppInfoSharedPreferenes(prefs!);
    return true;
  }
}
