import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xinput_gui/ui/screens/device_screen.dart';
import 'package:xinput_gui/ui/screens/home_screen.dart';

@immutable
class AppRouter {

  final GoRouter config = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        pageBuilder: (BuildContext context, GoRouterState state) =>
          MaterialPage<void>(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
      ),
      GoRoute(
        path: '/device/:deviceId',
        pageBuilder: (BuildContext context, GoRouterState state) =>
          MaterialPage<void>(
            key: state.pageKey,
            child: DeviceScreen(deviceId: int.parse(state.pathParameters['deviceId']!)),
          ),
      ),
    ],
  );

  AppRouter();

}
