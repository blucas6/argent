import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'package:argent/component/transaction_obj.dart';

// TODO: add versioning and update capability

/// Interact with the internal SQLite database
class DatabaseInterface {

  // NOTE: all functions should throw exceptions on failure
  
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
          CREATE TABLE IF NOT EXISTS $accountTableName (name TEXT NOT NULL,
          type TEXT NOT NULL);
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
    debugPrint('''
    SQL: checking if account $accountName exists''');
    try {
      final db = await database;
      List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT * FROM $accountTableName WHERE name = '$accountName'"
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('SQL: check if account exists failed.');
      throw Exception(e);
    }
  }

  /// Returns if a sheet has already been uploaded
  Future<bool> doesSheetExist(String sheetName) async {
    debugPrint('''
    SQL: checking if sheet $sheetName exists''');
    try {
      final db = await database;
      List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT * FROM $sheetTableName WHERE name = '$sheetName'"
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('SQL: check if sheet exists failed.');
      throw Exception(e);
    }
  }

  /// Returns all the accounts in the account table as a list
  Future<List<Map<String,dynamic>>> getAllAccounts() async {
    debugPrint('''
    SQL: getting all accounts from $accountTableName table''');
    try {
      final db = await database;
      return await db.query(accountTableName);
    } catch (e) {
      debugPrint('SQL: get all accounts failed.');
      throw Exception(e);
    }
  }

  /// Returns all the sheets associated with an account name
  Future<List<Map<String,dynamic>>> getAllSheetsForAccount(
    String accountName) async {
    debugPrint('''
    SQL: getting all sheets for account $accountName from $sheetTableName table
    ''');
    try {
      final db = await database;
      List<Map<String,dynamic>> result = await db.rawQuery(
        "SELECT * FROM $sheetTableName WHERE Account = '$accountName'"
      );
      return result;
    } catch (e) {
      debugPrint('SQL: get all sheets for account $accountName failed.');
      throw Exception(e);
    }
  }

  /// Adds the sheet name to the sheet table
  Future<bool> addSheet(String sheetName, String accountName) async {
    debugPrint('''
    SQL: adding sheet $sheetName to $sheetTableName''');
    try {
      final db = await database;
      await db.insert(sheetTableName, {'name': sheetName, 
                                      'Account': accountName});
      debugPrint('Sheet added: $sheetName');
      return true;
    } catch (e) {
      debugPrint('SQL: add sheet $sheetName failed.');
      throw Exception(e);
    }
  }

  /// Delete sheet from sheet table
  Future<int> deleteSheet(String sheetName) async {
    debugPrint('''
    SQL: deleting sheet $sheetName from $sheetTableName
    ''');
    String savePoint = 'deleteSheetSP';
    try {
      final db = await database;
      await db.execute("SAVEPOINT $savePoint;");
      int count = await db.delete(
        sheetTableName,
        where: 'name = ?',
        whereArgs: [sheetName]
      );
      if (count > 1) {
        await db.execute("ROLLBACK TO $savePoint;");
        throw Exception('SQL: duplicate sheets, rolling back delete');
      }
      await db.execute("RELEASE SAVEPOINT $savePoint;");
      return count;
    } catch (e) {
      debugPrint('SQL: delete sheet $sheetName from sheet table failed');
      throw Exception(e);
    }
  }

  /// Adds an account type to the account table name
  Future<bool> addAccount(String accountName, String type) async {
    // accounts must be added before transaction data because of the
    // foreign key constraint
    debugPrint('''
    SQL: adding account $accountName [$type] to $accountTableName
    ''');
    try {
      final db = await database;
      await db.insert(accountTableName, {'name': accountName, 'type': type});
      debugPrint('Account added: $accountName [$type]');
      return true;
    } catch (e) {
      debugPrint('SQL: add account $accountName failed.');
      throw Exception(e);
    }
  }

  /// Adds a singular transaction to the transaction table
  Future<bool> addTransaction(TransactionObj trans) async {
    debugPrint('''
    SQL: adding transaction ${trans.getProperties()} to $transactionTableName
    ''');
    try {
      // sqlite will increment the id, so provide a map with no id
      final db = await database;
      await db.insert(transactionTableName, trans.getPropertiesNoID());
      debugPrint('Transaction added: ${trans.getProperties()}');
      return true;
    } catch (e) {
      debugPrint('SQL: add transaction failed.');
      throw Exception(e);
    }
  }

  /// Gets all transactions from database
  Future<List<TransactionObj>> getTransactions() async {
    debugPrint('''
    SQL: getting all transactions from $transactionTableName table''');
    try {
      final db = await database;
      final data = await db.query(transactionTableName);
      return data.map((entry) => TransactionObj.loadFromMap(entry)).toList();
    } catch (e) {
      debugPrint('SQL: get all transactions failed.');
      throw Exception(e);
    }
  }

  /// Updates a transaction in the database by its id
  /// 
  /// Returns the amount of transactions updated
  Future<int> updateTransactionByID(int id, String column, dynamic value) async
  {
    debugPrint('''
    SQL: Updating transaction where ID: $id in $transactionTableName''');
    String savePoint = 'updateTransSP';
    // pass an id to update a transaction at a given column with a certain value
    try {
      final db = await database;
      await db.execute("SAVEPOINT $savePoint;");
      int count = await db.update(
        transactionTableName,
        {column: value},
        where: 'ID = ?',
        whereArgs: [id],
      );
      if (count > 1) {
        await db.execute("ROLLBACK TO $savePoint;");
        throw Exception('SQL: duplicate IDs in database!');
      }
      await db.execute("RELEASE SAVEPOINT $savePoint;");
      return count;
    } catch (e) {
      debugPrint('SQL: update transaction by ID $id failed.');
      throw Exception(e);
    }
  }

  /// Deletes a transaction by its id
  Future<int> deleteTransactionByID(int id) async {
    debugPrint('''
    SQL: deleting transaction where ID: $id from $transactionTableName''');
    String savePoint = 'deleteTransSP';
    try {
      final db = await database;
      await db.execute("SAVEPOINT $savePoint;");
      int count = await db.delete(
        transactionTableName,
        where: 'ID = ?',
        whereArgs: [id],
      );
      if (count > 1) {
        await db.execute("ROLLBACK TO $savePoint;");
        throw Exception('SQL: duplicate IDs, rolling back delete');
      }
      await db.execute("RELEASE SAVEPOINT $savePoint;");
      return count;
    } catch (e) {
      debugPrint('SQL: delete transaction by ID $id failed');
      throw Exception(e);
    }
  }

  /// Delete all transactions by transaction sheet from transaction table
  Future<int> deleteTransactionsBySheet(String sheet) async {
    debugPrint('''
    SQL: deleting transactions by sheet $sheet from $transactionTableName table
    ''');
    try {
      final db = await database;
      int count = await db.delete(
        transactionTableName,
        where: 'Sheet = ?',
        whereArgs: [sheet],
      );
      return count;
    } catch (e) {
      debugPrint('SQL: delete transactions by sheet $sheet failed');
      throw Exception(e);
    }
  }

  /// Deletes an account
  Future<int> deleteAccount(String account) async {
    debugPrint('''
    Deleting $account from $accountTableName table''');
    String savePoint = 'deleteAccountSP';
    try {
      final db = await database;
      await db.execute("SAVEPOINT $savePoint;");
      int count = await db.delete(
        accountTableName,
        where: 'name = ?',
        whereArgs: [account],
      );
      debugPrint('count $count account $account');
      if (count > 1) {
        await db.execute("ROLLBACK TO $savePoint;");
        throw Exception('SQL: duplicate accounts, rolling back delete');
      }
      await db.execute("RELEASE SAVEPOINT $savePoint;");
      return count;
    } catch (e) {
      debugPrint('SQL: delete account by account name $account failed');
      throw Exception(e);
    }
  }

  /// Debug prints all transactions in a database
  Future<void> printAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await 
                                                db.query(transactionTableName);

    if (results.isNotEmpty) {
      debugPrint('--- Transactions in Database ---');
      debugPrint('$results');
      debugPrint('--------------------------------');
    } else {
      debugPrint('No transactions found in the database.');
    }
  }
}
