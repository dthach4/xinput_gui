import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:xinput_gui/models/xinput_device_property.dart';

class XInputDevicePropertiesWatcher {

  final int deviceId;
  final Process process;
  final Stream<XInputDeviceProperty> stream;
  
  XInputDevicePropertiesWatcher({
    required this.deviceId,
    required this.process,
    required this.stream,
  });

  void dispose() {
    process.kill();
  }

  static Future<XInputDevicePropertiesWatcher> create({required int deviceId}) async {
    Process process = await Process.start(
      'stdbuf',
      ['--output=L', 'xinput', 'watch-props', '$deviceId'],
    );
    Stream<XInputDeviceProperty> stream = process.stdout
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .where((String line) => line.startsWith('\t'))
      .map<XInputDeviceProperty>((String row) => XInputDeviceProperty.fromCommandRow(row));
    return XInputDevicePropertiesWatcher(
      deviceId: deviceId, 
      process: process,
      stream: stream,
    );
  }

}