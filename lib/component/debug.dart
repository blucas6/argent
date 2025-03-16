import 'package:flutter/foundation.dart';

/// Holds component information for organized debugging messages
class CompInfo {
  CompInfo(this.name, this.priority);

  /// Name of the component where messages are coming from
  String name;

  /// Priority of message
  int priority;

  /// Character to indent with
  String indent = '  ';

  /// Print out a debugging message with a priority
  void printout(String msg) {
    int thePrio = priority - 1;
    String tabs = '';
    if (thePrio > 0) tabs = indent * thePrio;
    debugPrint('$tabs[$name]: $msg');
  }
}