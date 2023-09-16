import 'dart:io';

import 'package:meta/meta.dart';
import 'package:xinput_gui/exceptions/xinput_command_error.dart';
import 'package:xinput_gui/exceptions/xinput_format_error.dart';
import 'package:xinput_gui/models/xinput_device_property.dart';

@immutable
class XInputDevice {

  final int id;
  final String name;

  const XInputDevice({
    required this.id,
    required this.name,
  });

  factory XInputDevice.fromCommandRow(String row) {
    final RegExp regExp = RegExp(r'^\W*(?<name>.*?)\s+id=(?<id>\d+)');
    final RegExpMatch? match = regExp.firstMatch(row);
    if (null == match) {
      throw XInputFormatError(row);
    }
    return XInputDevice(
      id: int.parse(match.namedGroup('id')!),
      name: match.namedGroup('name')!,
    );
  }

  static Future<List<XInputDevice>> getAll() async {
    final ProcessResult result = await Process.run(
      'xinput',
      ['list', '--short'],
      stdoutEncoding: const SystemEncoding(),
    );
    if (0 != result.exitCode) {
      throw XInputCommandError(exitCode: result.exitCode);
    }
    final List<String> rows = (result.stdout as String).split('\n');
    final List<XInputDevice> devices = rows
      .where((String row) => row.trim().isNotEmpty)
      .map((String row) => XInputDevice.fromCommandRow(row))
      .toList();
    return devices;
  }

  static Future<XInputDevice> getById(int id) async {
    final ProcessResult result = await Process.run(
      'xinput',
      ['list', '--name-only', '$id'],
      stdoutEncoding: const SystemEncoding(),
    );
    if (0 != result.exitCode) {
      throw XInputCommandError(exitCode: result.exitCode);
    }
    final String deviceName = (result.stdout as String).trim();
    return XInputDevice(
      id: id,
      name: deviceName,
    );
  }

  Future<List<XInputDeviceProperty>> getProperties() => XInputDeviceProperty.fromDeviceId(id);

}
