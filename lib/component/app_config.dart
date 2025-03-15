import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// This object serves as the configuration object for the application
class Appconfig {

  /// Config file name
  static final String configFileName = 'accounttypes.json';
  
  /// Singleton instance, load on creation
  Appconfig._internal() {
    load();
  }

  static final Appconfig _instance = Appconfig._internal();
  factory Appconfig() => _instance;

  /// Holds the JSON configuration
  Map<String, dynamic>? accountInfo;

  // load the application config as json
  void load() async {
    try {
      String jstring = await rootBundle.loadString('assets/$configFileName');
      accountInfo = json.decode(jstring);
    } catch (e) {
      debugPrint('Failed to load config -> $e');
    }
  }
}
