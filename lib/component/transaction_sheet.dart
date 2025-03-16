import 'package:argent/component/transaction_obj.dart';
import 'package:argent/database/database_interface.dart';
import 'package:argent/component/app_config.dart';
import 'package:argent/component/debug.dart';

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

/// Handles manipulations of an uploaded transaction file
class TransactionSheet {

  TransactionSheet(this.file);

  /// Path to file
  File file;

  /// Name of sheet
  String name = '';

  /// Headers for the file (used in identifying the account type)
  String? headers;

  /// Raw data from the csv
  List<List<dynamic>> rawCsvData = [];

  /// TransactionObjs loaded from the csv
  List<TransactionObj> data = [];

  /// The account name of this transaction sheet
  String account = '';

  /// The type of account of this transaction sheet
  String type = '';

  /// Connection to database instance
  DatabaseInterface dbs = DatabaseInterface();

  /// Application config for parsing values
  Appconfig appconfig = Appconfig();

  /// Holds the component information for debugging messages
  CompInfo compInfo = CompInfo('TransSheet', 2);

  /// On load, locate the account name and load all data
  /// 
  /// Returns (success, error message)
  Future<(bool,String)> load() async {
    name = basename(file.path);
    bool resExist = await dbs.doesSheetExist(name);
    if (resExist) return (false, 'File already uploaded!');
    var resRead = await readFile(file);
    if (!resRead.$1) return resRead;
    var resIdent = await identifyAccount();
    if (!resIdent.$1) return resIdent;
    var resLoad = loadTransactionObjs();
    if (!resLoad.$1) return resLoad;
    return (true, '');
  }

  /// Reads the file and loads the rawCsvData object
  ///
  /// Returns (success, error message)
  Future<(bool,String)> readFile(File file) async {
    try {
      // Check the file extension to determine how to read the file
      if (file.path.endsWith('.csv') || file.path.endsWith('.CSV')) {
        String csvDataStr = await file.readAsString();
        // convert to 2d array
        List<dynamic> lines = csvDataStr.split('\n');
        for (var i=0; i<lines.length; i++) {
          String line = lines[i];
          if (line.isNotEmpty) {
            line = line.replaceAll('\n', '');
            line = line.replaceAll('\r', '');
            // delete extra separator at end of header
            if (i == 0 && line[line.length-1] == ',')
            {
              line = line.substring(0,line.length-1);
            }
            rawCsvData.add(line.split(','));
          }
        }
        compInfo.printout('Raw data: $rawCsvData');
        headers = rawCsvData[0].join(',');
        compInfo.printout('CSV Headers: $headers');
        return (true, '');
      } else if (file.path.endsWith('.xlsx')) {
        var bytes = await file.readAsBytes();
        var excel = Excel.decodeBytes(bytes);
        var firstTable = excel.tables[excel.tables.keys.first];
        if (firstTable != null) {
          rawCsvData = firstTable.rows;
          headers = firstTable.rows[0]
              .map((cell) => cell?.value != null ? cell?.value.toString() : '')
              .join(',');
          compInfo.printout('Excel Headers: $headers');
          return (true, '');
        } else {
          compInfo.printout('No tables found in Excel file.');
          return (false, 'Error: Excel file empty!');
        }
      } else {
        compInfo.printout('Unsupported file type! -> $file');
        return (false, 'Error: Unsupported file type!');
      }
    } catch (e) {
      compInfo.printout('Failed to read in file -> $e');
      return (false, 'Error: Failed to read file ($e)');
    }
  }

  /// Parses the config for the appropriate account type
  ///
  /// Returns (success, error message)
  Future<(bool,String)> identifyAccount() async {
    try {
      if (appconfig.accountInfo != null) {
        for (var accounttype in appconfig.accountInfo!.keys) {
          if (appconfig.accountInfo![accounttype]['headers'] == headers) {
            account = accounttype;
            type = appconfig.accountInfo![accounttype]['type'];
            compInfo.printout('Account name matched: $account [$type]');
            return (true, '');
          }
        }
        compInfo.printout('Unsupported account!');
        return (false, 'Error: Unsupport account!');
      } else {
        compInfo.printout('Config not loaded!');
        return (false, 'Error: Issue loading application configuration');
      }
    } catch (e) {
      compInfo.printout('Error with config! -> $e');
      return (false, 'An unknown error occurred.');
    }
  }

  /// Loads the data object with transactions from the file
  ///
  /// Returns (success, error message)
  (bool,String) loadTransactionObjs() {
    // TODO: clean up function
    try {
      if (appconfig.accountInfo != null) {
        Map<String, dynamic> transactionMap = TransactionObj().getBlankMap();
        for (var i = 1; i < rawCsvData.length; i++) {
          for (var j = 0; j < rawCsvData[0].length; j++) {
            String key = rawCsvData[0][j];
            dynamic value = rawCsvData[i][j];
            // check if config maps the given key to a transactionobj key
            if (value != '' && appconfig.accountInfo![account]['format'].containsKey(key)) {
              // load the format to check for additional parsing
              Map<String,dynamic> keyFormat = appconfig.accountInfo![account]['format'][key];
              // if a value requires addional parsing, check the 'parsing' key
              if (keyFormat.containsKey('parsing')) {
                // check the type of parsing
                if (keyFormat['parsing'] == 'dateformat') {
                  // check the parsing format for the proper datetime parsing format
                  value = DateFormat(keyFormat['formatter']).parse(value);
                } else if (keyFormat['parsing'] == 'spending' && keyFormat['formatter'] == 'inverse') {
                  value = -double.parse(value);
                } else if (keyFormat['parsing'] == 'int') {
                  value = int.parse(value);
                }
              }
              // key is present therefore place the value of the csv into the transaction map
              transactionMap[keyFormat['column']] = value;
            }
          }
          // add account type as a column
          transactionMap['Account'] = account;
          // add sheet name as a column
          transactionMap['Sheet'] = name;
          // done going through columns, add transactionobj to list
          // print(transactionMap);
          TransactionObj currentTrans = TransactionObj.loadFromMap(transactionMap);
          data.add(currentTrans);
        }
        return (true, '');
      }
      return (false, 'Error: Issue loading account configuration');
    } catch (e) {
      compInfo.printout('Error: Failed loading transactions ($e)');
      return (false, 'Error: Failed loading transactions ($e)');
    }
  }

  /// Adds all transactions to the database
  void addTransactionsToDatabase() {
    for (TransactionObj trans in data) {
      dbs.addTransaction(trans);
    }
  }

  /// Deletes all transactions associated with this file
  Future<void> deleteTransactionsByAccount() async {
    try {
      await dbs.deleteTransactionsBySheet(account);
      compInfo.printout('All transactions for account $account deleted');
    } catch (e) {
      throw Exception("Failed to delete transactions for $account -> $e");
    }
  }
}
