import 'dart:io';

import 'package:meta/meta.dart';
import 'package:xinput_gui/exceptions/xinput_command_error.dart';
import 'package:xinput_gui/exceptions/xinput_format_error.dart';

@immutable
class XInputDeviceProperty {

  final int id;
  final String name;
  final String value;

  const XInputDeviceProperty({
    required this.id,
    required this.name,
    required this.value,
  });

  factory XInputDeviceProperty.fromCommandRow(String row) {
    final RegExp regExp = RegExp(r'^\s+(?<name>.*) \((?<id>\d+)\):\s+(?<value>.*?)$');
    final RegExpMatch? match = regExp.firstMatch(row);
    if (null == match) {
      throw XInputFormatError(row);
    }
    final String value = match.namedGroup('value')!;
    return XInputDeviceProperty(
      id: int.parse(match.namedGroup('id')!),
      name: match.namedGroup('name')!,
      value: '<no items>' == value ? '' : value,
    );
  }

  static Future<List<XInputDeviceProperty>> fromDeviceId(int deviceId) async {
    final ProcessResult result = await Process.run(
      'xinput',
      ['list-props', '$deviceId'],
      stdoutEncoding: const SystemEncoding(),
    );
    if (0 != result.exitCode) {
      throw XInputCommandError(exitCode: result.exitCode);
    }
    final List<String> propRows = (result.stdout as String).split('\n').sublist(1);
    final List<XInputDeviceProperty> props = propRows
      .where((String row) => row.trim().isNotEmpty)
      .map((String row) => XInputDeviceProperty.fromCommandRow(row))
      .toList();
    return props;
  }

  static Future<void> set({
    required int deviceId,
    required int propertyId,
    required String value,
  }) async {
    final ProcessResult result = await Process.run(
      'xinput',
      ['set-prop', "$deviceId", "$propertyId", value]
    );
    if(0 != result.exitCode) {
      throw XInputCommandError(exitCode: result.exitCode);
    }
    return;
  }

}
