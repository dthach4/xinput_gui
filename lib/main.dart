import 'package:flutter/material.dart';
import 'package:xinput_gui/classes/app_router.dart';

void main() => runApp(const MyApp());

@immutable
class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'XInput GUI',
    theme: ThemeData.dark(),
    routerConfig: AppRouter().config,
  );

}
