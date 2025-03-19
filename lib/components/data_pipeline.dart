import 'package:argent/components/transaction_obj.dart';
import 'package:argent/database/database_interface.dart';
import 'package:argent/components/transaction_sheet.dart';
import 'package:argent/components/tags.dart';
import 'package:argent/components/debug.dart';

import 'dart:async';
import 'package:path/path.dart' as path;

/// This object serves as a data pipeline from the database to the application 
/// widgets
class DataPipeline {
  
  // load the pipeline on instantiation
  DataPipeline() {
    loadPipeline();
  }

  /// Holds all transactions available from the database
  List<TransactionObj> _allTransactions = [];

  /// Holds a list of accounts available from the database
  /// 
  /// [ {name: accountname, type: accounttype, sheets: [...] } ]
  List<Map<String,dynamic>> _allAccounts = [];

  /// Connection to database
  DatabaseInterface dbs = DatabaseInterface();

  /// Holds the component information for debugging messages
  CompInfo compInfo = CompInfo('Pipeline', 1);

  /// Keeps track if the pipeline is ready or not, _initCompleter will be false 
  /// if not done grabbing data
  final Completer<void> _initCompleter = Completer<void>();

  /// Method that will wait for initialization to be done
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
  Future<List<Map<String,dynamic>>> get allAccounts async {
    await ensureInitialized();
    return _allAccounts;
  }

  /// Gathers all data for other widgets to use
  Future<void> loadPipeline() async {
    compInfo.printout('Loading pipeline...');
    // if pipeline has already been loaded previously
    if (_initCompleter.isCompleted) {
      // reset it so that other objects will know the
      // pipeline is not currently ready
      _initCompleter.future;
    }
    // gather all necessary data
    try {
      _allTransactions = await dbs.getTransactions();
      _allAccounts = await loadAccountList(startup: true);
    } catch (e) {
      compInfo.printout('Error: Failed to load pipeline! -> $e');
      return;
    }
    // label pipeline as ready
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
    compInfo.printout('Done loading data pipeline!');
  }

  /// Adds a transactions from a transaction sheet to the database
  Future<bool> addTransactionSheetToDatabase(TransactionSheet tsheet) async {
    try {
      await ensureInitialized();
      // add the new account to the account table if it does not exist already
      if (!await dbs.checkIfAccountExists(tsheet.account)) {
        dbs.addAccount(tsheet.account, tsheet.type);
      }
      // add the new sheet to the sheet table with associated account
      dbs.addSheet(tsheet.name, tsheet.account);
      // go through the list of transactionobjs and add the database
      for (TransactionObj trans in tsheet.data) {
        dbs.addTransaction(trans);
      }
      // reload updated data
      await loadPipeline();
      return true;
    } catch (e) {
      compInfo.printout('Unable to add ${path.basename(tsheet.file.path)} to '
                        'database -> $e');
      return false;
    }
  }

  /// Deletes all transactions associated with a sheet from the transactions
  /// table and deletes the transaction sheet from the sheet table
  Future<bool> removeTransactionSheetFromDatabase(String sheetName) async {
    try {
      await ensureInitialized();
      await dbs.deleteTransactionsBySheet(sheetName);
      await dbs.deleteSheet(sheetName);
      await loadPipeline();
      return true;
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Updates a single transaction in the database
  Future<bool> updateData(int id, String column, String value) async {
    // TODO: Pass old and new transaction and let this function determine
    // the values that changed to update the database
    try {
      await ensureInitialized();
      await dbs.updateTransactionByID(id, column, value);
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
      return true;
    } catch (e) {
      throw Exception('Error: Failed to update data! -> $e');
    }
  }

  /// Returns a list of all accounts in database
  /// 
  /// Do not check for pipeline initialization on startup
  Future<List<Map<String,dynamic>>> loadAccountList(
                                              {bool startup = false}) async {
    try {
      if (!startup) await ensureInitialized();
      List<Map<String,dynamic>> accounts = await dbs.getAllAccounts();
      List<Map<String,dynamic>> accountlist = [];
      for (Map<String,dynamic> row in accounts) {
        List<Map<String,dynamic>> sheetsData = await dbs.getAllSheetsForAccount(row['name']);
        List<String> sheets = [];
        for (int s=0; s<sheetsData.length; s++) {
          sheets.add(sheetsData[s]['name']);
        }
        var entry = <String,dynamic>{'name': row['name'], 'type': row['type'], 'sheets': sheets};
        accountlist.add(entry);
      }
      compInfo.printout('Account list loaded: $accountlist');
      return accountlist;
    } catch (e) {
      throw Exception('Error: failed to load account list -> $e');
    }
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
    try {
      await dbs.deleteTransactionsBySheet(account);
    } catch (e) {
      throw Exception('Error: failed to delete transactions by account -> $e');
    }
    await loadPipeline();
    return true;
  }

  /// Deletes an account from the account table
  Future<bool> deleteAccount(String account) async {
    await ensureInitialized();
    try {
      await dbs.deleteAccount(account);
    } catch (e) {
      throw Exception('Error: failed to delete account -> $e');
    }
    await loadPipeline();
    return true;
  }

}