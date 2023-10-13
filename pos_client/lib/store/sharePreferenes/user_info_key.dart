import 'package:shared_preferences/shared_preferences.dart';

enum UserInfoKey {
  userName,
  address,
  phone,
}

class UserInfoSharedPreference {
  final SharedPreferences prefs;
  UserInfoSharedPreference(this.prefs);
  void editUserInfo(String userName, UserInfoKey key) async {
    prefs.setString(key.toString(), userName);
  }

  String? getUserInfo(UserInfoKey key) {
    return prefs.getString(key.toString()) ?? '';
  }
}
