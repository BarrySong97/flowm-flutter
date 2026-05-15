import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

void sendWebMessage(dynamic message, String targetOrigin) {
  debugPrint('sendWebMessage: $message');
  web.window.parent?.postMessage(message.jsify(), targetOrigin.toJS);
}
