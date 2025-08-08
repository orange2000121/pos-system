import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pos/main.dart';
import 'package:pos/store/sharePreferenes/setting_key.dart';
import 'package:pos/store/sharePreferenes/sharepreference_helper.dart';
import 'package:pos/store/sharePreferenes/user_info_key.dart';
import 'package:pos/tool/database_backup.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

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
                      value: snapshot.data!.setting.getSetting(BoolSettingKey.useReceiptPrinter) ?? false,
                      onChanged: (isAvailable) {
                        snapshot.data!.setting.editSetting(isAvailable, BoolSettingKey.useReceiptPrinter);
                        setState(() {});
                      }),
                ),
                // 出貨單尺寸設定
                shippingSize(
                    context: context,
                    height: snapshot.data!.setting.getDoubleSetting(DoubleSettingKey.shippingPaperHeight),
                    width: snapshot.data!.setting.getDoubleSetting(DoubleSettingKey.shippingPaperWidth)),
                ListTile(
                  title: const Text('字體放大'),
                  subtitle: Row(children: [
                    ElevatedButton(
                        onPressed: () {
                          snapshot.data!.setting.editDoubleSetting(1.0, DoubleSettingKey.fontSizeScale);
                        },
                        child: const Text('小')),
                    ElevatedButton(
                        onPressed: () {
                          snapshot.data!.setting.editDoubleSetting(1.5, DoubleSettingKey.fontSizeScale);
                        },
                        child: const Text('中')),
                    ElevatedButton(
                        onPressed: () {
                          snapshot.data!.setting.editDoubleSetting(2.0, DoubleSettingKey.fontSizeScale);
                        },
                        child: const Text('大')),
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
                  settingValue: snapshot.data!.userInfo.getUserInfo(UserInfoKey.userName) ?? '',
                  actionHint: '輸入商店名稱',
                  onEditFinished: (controller) => snapshot.data!.userInfo.editUserInfo(controller.text, UserInfoKey.userName),
                ),
                userInfoSetting(
                  context: context,
                  title: '商店地址',
                  settingValue: snapshot.data!.userInfo.getUserInfo(UserInfoKey.address) ?? '',
                  actionHint: '輸入商店地址',
                  onEditFinished: (controller) => snapshot.data!.userInfo.editUserInfo(controller.text, UserInfoKey.address),
                ),
                userInfoSetting(
                  context: context,
                  title: '商店電話',
                  settingValue: snapshot.data!.userInfo.getUserInfo(UserInfoKey.phone) ?? '',
                  actionHint: '輸入商店電話',
                  onEditFinished: (controller) => snapshot.data!.userInfo.editUserInfo(controller.text, UserInfoKey.phone),
                ),
                ListTile(
                  title: const Text('載入備份資料'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      bool isRestore = await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('警告'),
                              content: const Text('載入資料備份將會覆蓋現有資料，確定要載入嗎？'),
                              actions: [
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: const Text('確定')),
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text('取消'))
                              ],
                            );
                          });
                      if (!isRestore) return;
                      var restoreResult = await DataBaseBackup().restore();
                      if (!context.mounted) return;
                      if (restoreResult) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('載入成功')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('載入失敗')));
                      }
                    },
                    child: const Text('載入'),
                  ),
                ),
                ListTile(
                    title: const Text('匯出資料'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await DataBaseBackup().backup(exportPath: await FilePicker.platform.getDirectoryPath());
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('匯出成功')));
                      },
                      child: const Text('匯出'),
                    )),
                ListTile(
                    title: const Text('打開資料庫位置'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        String dbPath = await getDatabasesPath();
                        Uri uri = Uri.file(dbPath.split('/database').first);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('打開成功')));
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法打開資料庫位置')));
                        }
                      },
                      child: const Text('打開'),
                    )),
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

  ListTile shippingSize({
    required BuildContext context,
    double? height,
    double? width,
  }) {
    TextEditingController widthController = TextEditingController();
    TextEditingController heightController = TextEditingController();
    widthController.text = width?.toString() ?? '';
    heightController.text = height?.toString() ?? '';
    SharedPreferenceHelper sharedPreferenceHelper = SharedPreferenceHelper();
    return ListTile(
      title: const Text('出貨單尺寸'),
      subtitle: Text('高(mm) X 寬(mm)：${height ?? ''} X ${width ?? ''}'),
      trailing: ElevatedButton(
        onPressed: () async {
          await sharedPreferenceHelper.init();
          if (!context.mounted) return;
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('輸入出貨單尺寸'),
                  content: Column(
                    children: [
                      const Text('高(mm)'),
                      TextFormField(
                        controller: heightController,
                      ),
                      const Text('寬(mm)'),
                      TextFormField(
                        controller: widthController,
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            sharedPreferenceHelper.setting.editDoubleSetting(double.parse(heightController.text), DoubleSettingKey.shippingPaperHeight);
                            sharedPreferenceHelper.setting.editDoubleSetting(double.parse(widthController.text), DoubleSettingKey.shippingPaperWidth);
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
