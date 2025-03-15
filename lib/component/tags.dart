import 'package:argent/component/transaction_obj.dart';

/// Helper class to handle sorting transactions
class Tags {

  /// Hides transaction from being counted in calculations
  static final String hidden = 'Hidden';
  
  /// Only money earned, not considered in the refund category
  static final String income = 'Income';

  // Money transfered to saving accounts, not counted as spending, not 
  // subtracted from networth
  static final String savings = 'Savings';

  // Used for lifestyle calculations
  static final String rent = 'Rent';

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