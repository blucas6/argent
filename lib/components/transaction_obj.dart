import 'package:intl/intl.dart';

/// Transaction object is the internal structure of a transaction
class TransactionObj {

  // Properties
  /// Date the transaction occurred
  late DateTime date;
  /// Generated unique ID
  int? id;
  /// Card number for the transaction
  int? cardn;
  /// Amount of the transaction
  late double cost;
  /// A description of the transaction
  String? content;
  /// Assigned category by the card company
  String? category;
  /// Account where the transaction came from
  String? account;
  /// Tags associated with the transaction
  late List<String> tags;
  /// Transaction sheet from where the transaction came from
  String? sheet;

  /// How tags are separated in a list
  String tagdelim = ';';

  /// Constructor
  TransactionObj(
      {this.id,
      String? dates,
      this.cardn,
      this.content,
      this.category,
      double? somecost,
      this.account,
      var sometags,
      String? sheet}) {
    date = dates != null ? DateTime.parse(dates) : DateTime.parse('1980-01-01');
    tags = sometags is String ? sometags.split(tagdelim) : (sometags != null ? sometags : []);
    cost = somecost == null ? 0 : somecost;
  }

  /// Return object members as a map
  Map<String, dynamic> getProperties() {
    return {
      'ID': id,
      'Date': DateFormat('yyyy-MM-dd').format(date),
      'Card': cardn,
      'Description': content,
      'Category': category,
      'Cost': cost,
      'Account': account,
      'Tags': tags,
      'Sheet': sheet
    };
  }

  /// Returns object members as a map with no ID
  Map<String, dynamic> getPropertiesNoID() {
    return {
      'Date': DateFormat('yyyy-MM-dd').format(date),
      'Card': cardn,
      'Description': content,
      'Category': category,
      'Cost': cost,
      'Account': account,
      'Tags': tags.join(tagdelim),
      'Sheet': sheet
    };
  }

  /// Returns object members as a map of displayable strings
  Map<String, dynamic> getPropsForDisplay() {
    return {
      'Date': DateFormat('yyyy-MM-dd').format(date),
      'Card': cardn.toString(),
      'Description': content,
      'Category': category,
      'Cost': cost.toStringAsFixed(2),
      'Account': account,
      'Tags': tags.join(tagdelim),
      'Sheet': sheet
    };
  }

  /// Creates a TransactionObj from a map of properties
  TransactionObj.loadFromMap(Map<String, dynamic> map) :
    id = map['ID'],
    date = map['Date'] is String ? DateTime.parse(map['Date']) : map['Date'],
    cardn = map['Card'],
    content = map['Description'],
    category = map['Category'],
    cost = map['Cost'] is double ? map['Cost'] : (map['Cost'] is int ? map['Cost'].toDouble() : (map['Cost'] is String ? double.parse(map['Cost']) : null)),   // in case of integers
    account = map['Account'],
    tags = map['Tags'] is String ? map['Tags'].split(';') : map['Tags'],
    sheet = map['Sheet'];

  /// Creates a sample transaction
  TransactionObj.defaultTransaction() :
    id = -1,
    date = DateTime.parse('1980-01-01'),
    cardn = 999,
    content = 'Default Transaction',
    category = 'Default',
    cost = -1,
    account = '',
    tags = [],
    sheet = '';

  /// Provide a blank map to generate a TransactionObj from
  Map<String, dynamic> getBlankMap() {
    return {
      'ID': 0,
      'Date': DateTime.parse('1980-01-01'),
      'Card': 0,
      'Description': '',
      'Category': '',
      'Cost': 0,
      'Account': '',
      'Tags': List<String>.empty(growable: true),
      'Sheet': ''
    };
  }

  /// Defines which cells are displayable in the transaction widget
  Map<String, dynamic> getDisplayProperties() {
    return {
      'ID': false,
      'Date': true,
      'Card': true,
      'Description': true,
      'Category': true,
      'Cost': true,
      'Account': false,
      'Tags': true,
      'Sheet': false
    };
  }

  /// Returns a map of the sizes for each category in a transaction
  /// used for determining how much space is needed per member
  Map<String, dynamic> getDisplaySizing() {
    return {
      'ID': 10.0,
      'Date': 90.0,
      'Card': 70.0,
      'Description': 300.0,
      'Category': 130.0,
      'Cost': 80.0,
      'Account': 80.0,
      'Tags': 80.0,
      'Sheet': 90.0
    };
  }

  /// Returns an SQL query according to properties
  Map<String, dynamic> getSQLProperties() {
    return {
      'ID': 'INTEGER PRIMARY KEY',
      'Date': 'DATE',
      'Card': 'INTEGER',
      'Description': 'TEXT',
      'Category': 'TEXT',
      'Cost': 'DOUBLE',
      'Account': 'TEXT',
      'Tags': 'TEXT',
      'Sheet': 'TEXT'
    };
  }

  /// Getter for the year as a string
  String get year {
    return date.year.toString();
  }

  /// Getter for the month as a string
  String get month {
    List<String> monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return monthNames[date.month - 1];
  }
}
