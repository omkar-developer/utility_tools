import 'package:flutter/material.dart';

extension CustomColors on ColorScheme {
  Color get success => brightness == Brightness.light
      ? Colors.green.shade600
      : Colors.green.shade400;
}
