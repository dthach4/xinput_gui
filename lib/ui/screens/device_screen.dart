import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xinput_gui/exceptions/xinput_command_error.dart';
import 'package:xinput_gui/exceptions/xinput_format_error.dart';
import 'package:xinput_gui/models/xinput_device.dart';
import 'package:xinput_gui/models/xinput_device_property.dart';
import 'package:xinput_gui/models/xinput_device_property_watcher.dart';

@immutable
class DeviceScreen extends StatefulWidget {

  final int deviceId;

  const DeviceScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();

}

class _DeviceScreenState extends State<DeviceScreen> {

  final ScrollController scrollController = ScrollController();

  bool isLoading = true;
  XInputDevice? device;
  List<XInputDeviceProperty> properties = [];
  XInputDevicePropertiesWatcher? watcher;
  StreamSubscription<XInputDeviceProperty>? listener;

  _DeviceScreenState();

  @override
  void initState() {
    _loadDevice().then(
      (void _) {
        _loadDevicePropertiesWatcher();
      }
    );
    super.initState();
  }

  @override
  void dispose() {
    listener?.cancel();
    watcher?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: null == device
      ? AppBar(title: const Text('Device properties'))
      : AppBar(
        title: Text('${device!.name} (ID: ${device!.id})'),
      ),
    body: isLoading
      ? const Center(
        child: CircularProgressIndicator(),
      )
      : Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: ListView(
          controller: scrollController,
          children: properties.map((XInputDeviceProperty property) =>
            ListTile(
              title: Text(property.name),
              subtitle: Text('ID: ${property.id}'),
              trailing: Text(property.value),
              onTap: () {
                _openPropertyDialog(
                  context: context,
                  device: device!,
                  property: property,
                );
              },
            )
          ).toList(),
        ),
      ),
  );

  Future<void> _loadDevice() {
    setState(() {
      isLoading = true;
    });
    return XInputDevice.getById(widget.deviceId).then(
      (XInputDevice inputDevice) {
        setState(() {
          device = inputDevice;
        });
        XInputDeviceProperty.fromDeviceId(widget.deviceId).then((List<XInputDeviceProperty> inputDeviceProperties) {
          setState(() {
            isLoading = false;
            properties = inputDeviceProperties;
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
    ).onError<ProcessException>(
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

  void _loadDevicePropertiesWatcher() {
    XInputDevice.getById(widget.deviceId).then(
      (XInputDevice inputDevice) {
        setState(() {
          device = inputDevice;
        });
      }
    ).onError<ProcessException>(
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
    XInputDevicePropertiesWatcher.create(deviceId: widget.deviceId).then(
      (XInputDevicePropertiesWatcher thisWatcher) {
        watcher = thisWatcher;
        listener = thisWatcher.stream.listen(
          (XInputDeviceProperty property) {
            _updateProperty(property);
          }
        );
      }
    );
  }

  void _updateProperty(XInputDeviceProperty property) {
    final int propertyIndex = properties.indexWhere(
      (XInputDeviceProperty thisProperty) => thisProperty.id == property.id,
    );
    if(-1 == propertyIndex) {
      setState(() {
        properties.add(property);
      });
      return;
    }
    final XInputDeviceProperty oldProperty = properties[propertyIndex];
    if(
      property.name == oldProperty.name &&
      property.value == oldProperty.value
    ) {
      return;
    }
    setState(() {
      properties[propertyIndex] = property;
    });
  }

  void _openPropertyDialog({
    required BuildContext context,
    required XInputDevice device,
    required XInputDeviceProperty property,
  }) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String newValue = property.value;
    submit() {
      FormState form = formKey.currentState!;
      if(!form.validate()) {
        return;
      }
      form.save();
      XInputDeviceProperty.set(
        deviceId: device.id,
        propertyId: property.id,
        value: newValue,
      ).then(
        (void _) {
          GoRouter.of(context).pop();
        }
      ).onError<ProcessException>(
        (ProcessException error, StackTrace trace) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: xinput command not found'))
          );
        }
      ).onError<XInputCommandError>(
        (XInputCommandError error, StackTrace trace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: xinput exited with code ${error.exitCode}'))
          );
        }
      );
    }
    showDialog(
      context: context,
      builder: (BuildContext context) => Form(
        key: formKey,
        child: AlertDialog(
          actions: <Widget>[
            TextButton(
              onPressed: () {
                submit();
              },
              child: const Text('Save'),
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Device: ${device.name} (${device.id})'),
              Text('Property: ${property.name} (${property.id})'),
              TextFormField(
                initialValue: newValue,
                onSaved: (String? value) {
                  newValue = value ?? '';
                },
                onFieldSubmitted: (String? value) {
                  submit();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}