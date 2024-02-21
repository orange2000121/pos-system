import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pos/store/sharePreferenes/setting_key.dart';
import 'package:pos/store/sharePreferenes/sharepreference_helper.dart';
import 'package:pos/tool/upgrade_app.dart';
import 'package:pos/view/home.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  UpgradeApp().upgradeApp();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
  }
  databaseFactory = databaseFactoryFfi;
  runApp(
    const RestartWidget(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getSetting(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MaterialApp(
              title: 'Flutter Demo',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
              ),
              home: const Home(),
              builder: (context, child) {
                final MediaQueryData data = MediaQuery.of(context);
                double scale = snapshot.data?.getDoubleSetting(DoubleSettingKey.fontSizeScale) ?? 1.0;
                return MediaQuery(
                  data: data.copyWith(textScaler: TextScaler.linear(data.textScaleFactor * scale)),
                  child: child!,
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Future<SettingSharedPreference> getSetting() async {
    SharedPreferenceHelper sharedPreferenceHelper = SharedPreferenceHelper();
    await sharedPreferenceHelper.init();
    return sharedPreferenceHelper.setting;
  }
}

class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  static restartApp(BuildContext context) {
    final _RestartWidgetState? state = context.findAncestorStateOfType<_RestartWidgetState>();
    state?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      child: widget.child,
    );
  }
}
