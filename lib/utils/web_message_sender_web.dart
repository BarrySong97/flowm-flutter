import 'dart:html' as html;

import 'package:flutter/material.dart';

void sendWebMessage(dynamic message, String targetOrigin) {
  debugPrint('sendWebMessage: $message');
  html.window.parent?.postMessage(message, targetOrigin);
}
