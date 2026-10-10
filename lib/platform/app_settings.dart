import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('gymf/app_settings');

Future<void> openAppSettings() async {
  try {
    await _channel.invokeMethod<void>('open');
  } catch (_) {}
}