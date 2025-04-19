import 'package:flutter/material.dart';

import 'package:argent/components/debug.dart';

typedef FilterCallback = void Function(String? year, String? month);

/// Refresh Controller Class
class EventController extends ChangeNotifier {
  
  /// Data change events represent a change in the data pipeline content
  final List<VoidCallback> _dataChangeEventListeners = [];
 
  /// Account events represent a change in data concerning accounts
  final List<VoidCallback> _accountEventListeners = [];

  /// Filter events represent a change in the existing data being displayed
  final List<FilterCallback> _filterEventListeners = [];

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

  /// Add a listener to listen to filter events 
  void addFilterEventListener(FilterCallback listener) {
    _filterEventListeners.add(listener);
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

  /// Filter change event
  void notifyFilterChangeEvent(String? year, String? month) {
    for (final listener in _filterEventListeners) {
      listener(year, month);
    }
  }
}