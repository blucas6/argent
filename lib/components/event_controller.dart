import 'package:flutter/material.dart';

import 'package:argent/components/debug.dart';

/// Refresh Controller Class
class EventController extends ChangeNotifier {
  
  /// Data change events represent a change in the data pipeline content
  final List<VoidCallback> _dataChangeEventListeners = [];
 
  /// Account events represent a change in data concerning accounts
  final List<VoidCallback> _accountEventListeners = [];

  /// Holds the component information for debugging messages
  CompInfo compInfo = CompInfo('Event', 1);

  /// Add a listener to listen for account changes
  void addAccountEventListener(VoidCallback listener) {
    _accountEventListeners.add(listener);
  }

  /// Add a listener to listen to data change events
  void addDataChangeEventListener(VoidCallback listener) {
    _dataChangeEventListeners.add(listener);
  }

  /// Data change event
  void notifyDataChangeEvent() {
    for (final listener in _dataChangeEventListeners) {
      listener();
    }
  }

  /// Account changes event
  void notifyAccountEvent() {
    for (final listener in _accountEventListeners) {
      listener();
    }
  }
}