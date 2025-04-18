import 'package:argent/components/transaction_obj.dart';

/// Helper class to handle sorting transactions
class Tags {

  /// Hides transaction from being counted in calculations
  final String hidden = 'Hidden';
  
  /// Only money earned, not considered in the refund category
  final String income = 'Income';

  /// Money transfered to saving accounts, not counted as spending, not 
  /// subtracted from networth
  final String savings = 'Savings';

  /// Used for lifestyle calculations
  final String rent = 'Rent';

  /// Special tag returned from an edit menu to delete all tags in
  /// a transaction, not meant to be displayed
  final String delete = '_delete_';
  
  /// Returns a list of all tags
  List<String> getAllTags() {
    return [
      hidden,
      income,
      savings,
      rent
    ];
  }

  /// Determines transactions that are part of spending
  bool isTransactionSpending(TransactionObj trans) {
    // cannot be hidden
    if (trans.tags.contains(hidden)) {
      return false;
    }
    // cannot be income - would lower spending
    if (trans.tags.contains(income)) {
      return false;
    }
    // cannot be savings - would inflate spending
    if (trans.tags.contains(savings)) {
      return false;
    }
    return true;
  }

  /// Determines transactions that are income
  bool isIncome(TransactionObj trans) {
    // check for income tag
    if (trans.tags.contains(income)) return true;
    return false;
  }

  /// Determines transactions that are savings
  bool isSavings(TransactionObj trans) {
    // check for savings tag
    if (trans.tags.contains(savings)) return true;
    return false;
  }

  /// Determines transactions that are valid
  bool isValid(TransactionObj trans) {
    // check for hidden tag
    if (trans.tags.contains(hidden)) return false;
    return true;
  }

  /// Determines transactions that are rent
  bool isRent(TransactionObj trans) {
    // check for rent tag
    if (trans.tags.contains(rent)) return true;
    return false;
  }
}