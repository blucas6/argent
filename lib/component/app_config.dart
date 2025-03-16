import 'package:argent/component/debug.dart';

import 'dart:convert';
import 'package:flutter/services.dart';

/// This object serves as the configuration object for the application
class Appconfig {

  /// Singleton instance, load on creation
  Appconfig._internal() {
    load();
  }

  static final Appconfig _instance = Appconfig._internal();
  factory Appconfig() => _instance;

  /// Config file name
  static final String configFileName = 'accounttypes.json';

  /// Holds the JSON configuration
  Map<String, dynamic>? accountInfo;

  /// Holds the component information for debugging messages
  CompInfo compInfo = CompInfo('Appconfig', 1);

  // load the application config as json
  void load() async {
    try {
      String jstring = await rootBundle.loadString('assets/$configFileName');
      accountInfo = json.decode(jstring);
      compInfo.printout('Configuration loaded');
    } catch (e) {
      compInfo.printout('Failed to load config -> $e');
    }
  }
}
