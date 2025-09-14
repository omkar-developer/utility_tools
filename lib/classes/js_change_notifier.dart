import 'package:flutter/material.dart';

class JSChangeNotifier extends ChangeNotifier {
  static final JSChangeNotifier instance = JSChangeNotifier._();

  JSChangeNotifier._();

  void reloadTools() {
    notifyListeners();
  }
}
