import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'package:argent/component/transaction_obj.dart';
import 'package:argent/database/database_interface.dart';
import 'package:argent/component/transaction_sheet.dart';
import 'package:argent/component/tags.dart';

/// This object serves as a data pipeline from the database to the application 
/// widgets
class DataPipeline {

  /// Holds all transactions available from the database
  List<TransactionObj> _allTransactions = [];
  /// Holds a list of accounts available from the database
  List<String> _allAccounts = [];

  /// Connection to database
  DatabaseInterface dbs = DatabaseInterface();

  // load the pipeline on instantiation
  DataPipeline() {
    loadPipeline();
  }

  /// Keeps track if the pipeline is ready or not, _initCompleter will be false 
  /// if not done grabbing data
  final Completer<void> _initCompleter = Completer<void>();

  /// Method that will wait on the _initCompleter to be done
  Future<void> ensureInitialized() async {
    return _initCompleter.future;
  }

  /// Getter for the internal allTransactions object that will wait for the 
  /// pipeline to be done
  Future<List<TransactionObj>> get allTransactions async {
    await ensureInitialized();
    return _allTransactions;
  }

  /// Getter for the internal allAccounts object will wait for the pipeline to 
  /// be done
  Future<List<String>> get allAccounts async {
    await ensureInitialized();
    return _allAccounts;
  }

  /// Gathers all data for other widgets to use
  Future<void> loadPipeline() async {
    // if pipeline has already been loaded previously
    if (_initCompleter.isCompleted) {
      // reset it so that other objects will know the
      // pipeline is not currently ready
      _initCompleter.future;
    }
    // gather all necessary data
    _allTransactions = await dbs.getTransactions();
    _allAccounts = await loadAccountList();
    // label pipeline as ready
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
    debugPrint("Done loading data pipeline!");
  }

  /// Adds a transactions from a transaction sheet to the database
  Future<bool> addTransactionSheetToDatabase(TransactionSheet tsheet) async {
    try {
      // add the new account to the account table if it does not exist already
      if (!await dbs.checkIfAccountExists(tsheet.account)) {
        dbs.addAccount(tsheet.account);
      }
      // go through the list of transactionobjs and add the database
      for (TransactionObj trans in tsheet.data) {
        dbs.addTransaction(trans);
      }
      // reload updated data
      await loadPipeline();
      return true;
    } catch (e) {
      debugPrint('''
        Unable to add ${path.basename(tsheet.file.path)} to database -> $e
      ''');
    }
    return false;
  }

  /// Updates a single transaction in the database
  Future<bool> updateData(int id, String column, String value) async {
    // TODO: Pass old and new transaction and let this function determine
    // the values that changed to update the database
    bool success =  await dbs.updateTransactionByID(id, column, value);
    // no need to reload the entire pipeline just update the internal value
    for (int t=0; t<_allTransactions.length; t++) {
      // find matching transaction
      if (_allTransactions[t].id == id) {
        // get the properties as a map
        Map<String,dynamic> props = _allTransactions[t].getProperties();
        // change the value
        props[column] = value;
        // replace the index with the new object
        _allTransactions[t] = TransactionObj.loadFromMap(props);
      }
    }
    return success;
  }

  /// Returns a list of all accounts in database
  Future<List<String>> loadAccountList() async {
    List<Map<String,dynamic>> accounts = await dbs.getAllAccounts();
    List<String> accountlist = [];
    for (Map<String,dynamic> row in accounts) {
      accountlist.add(row['name']);
    }
    return accountlist;
  }

  /// Sort the data from all spending across all accounts into a profile
  Future<Map<String,double>> loadProfile() async {
    await ensureInitialized();
    double totalspending = 0;
    double totalincome = 0;
    double totalsavings = 0;
    for (TransactionObj row in _allTransactions)
    {
      if (Tags().isIncome(row)) {
        totalincome += row.cost;
      } else if (Tags().isSavings(row)) {
        totalsavings += row.cost;
      } else if (Tags().isValid(row)) {
        totalspending += row.cost;
      }
    }

    if (totalspending != 0) totalspending *= -1;
    if (totalsavings != 0) totalsavings *= -1;

    return
    {
      'totalspending': totalspending,
      'totalincome': totalincome,
      'totalsavings': totalsavings,
      'totalassets': totalsavings + totalincome - totalspending,
    };
  }

  /// Fetches a data range for the user to filter transactions by returning the
  /// structure:
  /// 
  /// { year1 : [month1, month2, ...],
  /// 
  ///   year2 : [month1, month2, ..] }
  Future<Map<String, dynamic>> getTotalDateRange() async {
    await ensureInitialized();
    Map<String, dynamic> totalRange = {};
    for (TransactionObj row in _allTransactions) {
      // check if year is in map
      if (!totalRange.containsKey(row.year)) {
        // if not, add it
        totalRange[row.year] = [];
      }
      // first check if month has an associated year in map
      if (totalRange.containsKey(row.year)
      && !totalRange[row.year].contains(row.month)) {
        // if not, add it
        totalRange[row.year].add(row.month);
      }
    }
    return totalRange;
  }

  /// Deletes all transactions associated with an account from the database
  Future<bool> deleteTransactionsByAccount(String account) async {
    await ensureInitialized();
    bool success = await dbs.deleteTransactionsByAccount(account);
    await loadPipeline();
    return success;
  }

  /// Deletes an account from the account table
  Future<bool> deleteAccount(String account) async {
    await ensureInitialized();
    bool success = await dbs.deleteAccount(account);
    await loadPipeline();
    return success;
  }

}