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
                      value: snapshot.data.getSetting(BoolSettingKey.useReceiptPrinter) ?? false,
                      onChanged: (isAvailable) {
                        snapshot.data.editSetting(isAvailable, BoolSettingKey.useReceiptPrinter);
                        setState(() {});
                      }),
                ),
                ListTile(
                  title: const Text('字體放大'),
                  subtitle: Row(children: [
                    ElevatedButton(
                        onPressed: () {
                          snapshot.data.editDoubleSetting(1.0, DoubleSettingKey.fontSizeScale);
                        },
                        child: const Text('X1')),
                    ElevatedButton(
                        onPressed: () {
                          snapshot.data.editDoubleSetting(1.5, DoubleSettingKey.fontSizeScale);
                        },
                        child: const Text('X1.5')),
                    ElevatedButton(
                        onPressed: () {
                          snapshot.data.editDoubleSetting(2.0, DoubleSettingKey.fontSizeScale);
                        },
                        child: const Text('X2')),
                  ]),
                  trailing: ElevatedButton(
                    onPressed: () {
                      RestartWidget.restartApp(context);
                    },
                    child: const Text('設定並重啟'),
                  ),
                )
              ],
            );
          },
        ));
  }

  Future getSetting() async {
    SharedPreferenceHelper sharedPreferenceHelper = SharedPreferenceHelper();
    await sharedPreferenceHelper.init();
    return sharedPreferenceHelper;
  }
}
