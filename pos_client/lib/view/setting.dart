import 'package:flutter/material.dart';
import 'package:pos/main.dart';
import 'package:pos/store/sharePreferenes/user_info_sharepreference.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Setting'),
        ),
        body: FutureBuilder(
          future: getSetting(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              children: [
                ListTile(
                  title: const Text('開立發票'),
                  trailing: Switch(
                      value: snapshot.data!.getSetting(BoolSettingKey.useReceiptPrinter) ?? false,
                      onChanged: (isAvailable) {
                        snapshot.data!.editSetting(isAvailable, BoolSettingKey.useReceiptPrinter);
                        setState(() {});
                      }),
                ),
                ListTile(
                  title: const Text('字體放大'),
                  subtitle: Row(children: [
                    ElevatedButton(
                        onPressed: () {
                          snapshot.data!.editDoubleSetting(1.0, DoubleSettingKey.fontSizeScale);
                        },
                        child: const Text('X1')),
                    ElevatedButton(
                        onPressed: () {
                          snapshot.data!.editDoubleSetting(1.5, DoubleSettingKey.fontSizeScale);
                        },
                        child: const Text('X1.5')),
                    ElevatedButton(
                        onPressed: () {
                          snapshot.data!.editDoubleSetting(2.0, DoubleSettingKey.fontSizeScale);
                        },
                        child: const Text('X2')),
                  ]),
                  trailing: ElevatedButton(
                    onPressed: () {
                      RestartWidget.restartApp(context);
                    },
                    child: const Text('設定並重啟'),
                  ),
                ),
                userInfoSetting(
                  context: context,
                  title: '商店名稱',
                  settingValue: snapshot.data!.getUserInfo(UserInfoKey.userName) ?? '',
                  actionHint: '輸入商店名稱',
                  onEditFinished: (controller) => snapshot.data!.editUserInfo(controller.text, UserInfoKey.userName),
                ),
                userInfoSetting(
                  context: context,
                  title: '商店地址',
                  settingValue: snapshot.data!.getUserInfo(UserInfoKey.address) ?? '',
                  actionHint: '輸入商店地址',
                  onEditFinished: (controller) => snapshot.data!.editUserInfo(controller.text, UserInfoKey.address),
                ),
                userInfoSetting(
                  context: context,
                  title: '商店電話',
                  settingValue: snapshot.data!.getUserInfo(UserInfoKey.phone) ?? '',
                  actionHint: '輸入商店電話',
                  onEditFinished: (controller) => snapshot.data!.editUserInfo(controller.text, UserInfoKey.phone),
                ),
              ],
            );
          },
        ));
  }

  ListTile userInfoSetting({
    required BuildContext context,
    required String title,
    required String settingValue,
    required String actionHint,
    required Function(TextEditingController) onEditFinished,
  }) {
    TextEditingController controller = TextEditingController();
    return ListTile(
      title: Text(title),
      subtitle: Text(settingValue),
      trailing: ElevatedButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(actionHint),
                  content: TextField(
                    controller: controller,
                  ),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            onEditFinished(controller);
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('確定'))
                  ],
                );
              });
        },
        child: const Text('編輯'),
      ),
    );
  }

  Future<SharedPreferenceHelper> getSetting() async {
    SharedPreferenceHelper sharedPreferenceHelper = SharedPreferenceHelper();
    await sharedPreferenceHelper.init();
    return sharedPreferenceHelper;
  }
}
