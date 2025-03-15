import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'package:argent/component/transaction_obj.dart';

// TODO: add versioning and update capability

/// Interact with the internal SQLite database
class DatabaseInterface {
  
  /// Private reference to database
  static Database? _db;

  /// Unnamed constructor so database can be a member without being loaded
  static final DatabaseInterface _instance = DatabaseInterface._constructor();
  factory DatabaseInterface() => _instance;

  // Database names
  static final String masterDatabaseName = "master_db.db";
  // Table names
  static final String transactionTableName = "transactions";
  static final String accountTableName = "accounts";
  static final String sheetTableName = "sheets";

  /// Setup the database on constructor call
  DatabaseInterface._constructor() {
    loadDatabase();
  }

  /// Returns the reference to the private database and makes sure it is 
  /// instantiated, otherwise will call loadDatabase()
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await loadDatabase();
    return _db!;
  }

  /// Returns a reference to the database
  Future<Database> loadDatabase() async {
    // get user area
    final databaseDirPath = await getApplicationSupportDirectory();
    final databasePath = join(databaseDirPath.path, masterDatabaseName);

    // build the query to instantiate the database
    String query = '';
    int index = 0;
    // go through all properties in a TransactionObj
    TransactionObj.defaultTransaction().getSQLProperties().forEach((name, value)
    {
      query += '$name $value';
      index++;
      if (index != TransactionObj().getProperties().keys.length) {
        query += ', ';
      }
    });

    // Open or create the database
    dynamic db;
    try {
      db = await openDatabase(
            databasePath,
            version: 1,
            onCreate: (db, version) async {
              await db.execute("PRAGMA foreign_keys = ON;");
              await db.execute("""
              CREATE TABLE IF NOT EXISTS $accountTableName (name TEXT NOT NULL);
              """);
              await db.execute("""
              CREATE TABLE IF NOT EXISTS $sheetTableName (name TEXT NOT NULL,
              Account TEXT NOT NULL, FOREIGN KEY (Account) REFERENCES 
              $accountTableName(name));
              """);
              await db.execute("""
              CREATE TABLE IF NOT EXISTS $transactionTableName ($query,
              FOREIGN KEY (Account) REFERENCES $accountTableName(name),
              FOREIGN KEY (Sheet) REFERENCES $sheetTableName(name));
              """);
              debugPrint("Database initialized at: $databasePath");
            },
          );
    } catch (e) {
      debugPrint("Failed to connect to database! -> $e");
    }
    debugPrint('Connected to database -> $databasePath');
    return db;
  }

  /// Returns whether an account exists or not
  Future<bool> checkIfAccountExists(String accountName) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT * FROM $accountTableName WHERE name = '$accountName'"
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Returns if a sheet has already been uploaded
  Future<bool> checkIfSheetExists(String sheetName) async {
    try {
      final db = await database;
      List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT * FROM $sheetTableName WHERE name = '$sheetName'"
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Returns all the accounts in the account table as a list
  Future<List<Map<String,dynamic>>> getAllAccounts() async {
    try {
      final db = await database;
      return await db.query(accountTableName);
    } catch (e) {
      debugPrint("Accounts query failed -> $e");
      return [{}];
    }
  }

  /// Adds an account type to the account table name
  Future<bool> addAccount(String accountName) async {
    // accounts must be added before transaction data because of the
    // foreign key constraint
    try {
      final db = await database;
      await db.insert(accountTableName, {'name': accountName});
      debugPrint("Account added: $accountName");
      return true;
    } catch (e) {
      debugPrint('Add account failed: $e');
      return false;
    }
  }

  /// Adds a singular transaction to the transaction table
  Future<bool> addTransaction(TransactionObj trans) async {
    try {
      // sqlite will increment the id, so provide a map with no id
      final db = await database;
      await db.insert(transactionTableName, trans.getPropertiesNoID());
      debugPrint("Transaction added: ${trans.getProperties()}");
      return true;
    } catch (e) {
      debugPrint('Add transaction failed: $e');
      return false;
    }
  }

  /// Gets all transactions
  Future<List<TransactionObj>> getTransactions() async {
    try {
      final db = await database;
      final data = await db.query(transactionTableName);
      // make use of transactionobj interface
      // create objects to return from database
      return data.map((entry) => TransactionObj.loadFromMap(entry)).toList();
    } catch (e) {
      debugPrint('Read transactions failed: $e');
    }
    return [];
  }

  /// Updates a transaction in the database by its id
  Future<bool> updateTransactionByID(int id, String column, dynamic value) async {
    // pass an id to update a transaction at a given column with a certain value
    try {
      final db = await database;
      int count = await db.update(
        transactionTableName,
        {column: value},
        where: 'ID = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      debugPrint('Update transaction failed: $e');
      return false;
    }
  }

  /// Deletes a transaction by its id
  Future<bool> deleteTransaction(int id) async {
    try {
      final db = await database;
      int count = await db.delete(
        transactionTableName,
        where: 'ID = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      debugPrint('Delete transaction failed: $e');
      return false;
    }
  }

  // Delete all transactions by account
  Future<bool> deleteTransactionsByAccount(String account) async {
    try {
      final db = await database;
      int count = await db.delete(
        transactionTableName,
        where: 'account = ?',
        whereArgs: [account],
      );
      return count > 0;
    } catch (e) {
      debugPrint('Delete transactions by account failed: $e');
      return false;
    }
  }

  /// Deletes an account
  Future<bool> deleteAccount(String account) async {
    try {
      final db = await database;
      int count = await db.delete(
        accountTableName,
        where: 'name = ?',
        whereArgs: [account],
      );
      return count > 0;
    } catch (e) {
      debugPrint('Delete account by account name failed: $e');
      return false;
    }
  }

  /// Debug prints all transactions in a database
  Future<void> printAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await 
                                                db.query(transactionTableName);

    if (results.isNotEmpty) {
      debugPrint('--- Transactions in Database ---');
      print(results);
      debugPrint('-------------------------------');
    } else {
      debugPrint('No transactions found in the database.');
    }
  }
}
