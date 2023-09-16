import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xinput_gui/exceptions/xinput_command_error.dart';
import 'package:xinput_gui/exceptions/xinput_format_error.dart';
import 'package:xinput_gui/models/xinput_device.dart';

@immutable
class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {

  final ScrollController scrollController = ScrollController();

  bool isLoading = true;
  List<XInputDevice> devices = [];

  _HomeScreenState();

  @override
  void initState() {
    _loadXInput();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('XInput GUI'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _loadXInput();
          }
        ),
      ],
    ),
    body: Center(
      child: isLoading
        ? const CircularProgressIndicator()
        : Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: ListView(
            controller: scrollController,
            children: devices
              .map((XInputDevice device) =>
                ListTile(
                  title: Text(device.name),
                  subtitle: Text("ID: ${device.id}"),
                  onTap: () {
                    GoRouter.of(context).push('/device/${device.id}');
                  },
                ),
              ).toList(),
            ),
        ),
    ),
  );

  void _loadXInput() {
    setState(() {
      isLoading = true;
    });
    XInputDevice.getAll().then((List<XInputDevice> inputDevices) {
      setState(() {
        isLoading = false;
        devices = inputDevices;
      });
    }).onError<ProcessException>(
      (ProcessException error, StackTrace trace) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: xinput command not found'))
        );
      },
    ).onError<XInputCommandError>(
      (XInputCommandError error, StackTrace trace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: xinput exited with code ${error.exitCode}'))
        );
      }
    ).onError<XInputFormatError>(
      (XInputFormatError error, StackTrace trace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to parse row '${error.row}'"))
        );
      }
    );
  }

}