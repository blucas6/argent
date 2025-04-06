import 'package:intl/intl.dart';

/// Transaction object is the internal structure of a transaction
class TransactionObj {

  // Properties
  /// Date the transaction occurred
  late DateTime date;
  String dateCol = 'Date';
  /// Generated unique ID
  int? id;
  String idCol = 'ID';
  /// Card number for the transaction
  int? cardn;
  String cardCol = 'Card';
  /// Amount of the transaction
  late double cost;
  String costCol = 'Cost';
  /// A description of the transaction
  String? content;
  String contentCol = 'Description';
  /// Assigned category by the card company
  String? category;
  String categoryCol = 'Category';
  /// Account where the transaction came from
  String? account;
  String accountCol = 'Account';
  /// Tags associated with the transaction
  late List<String> tags;
  String tagCol = 'Tags';
  /// Transaction sheet from where the transaction came from
  String? sheet;
  String sheetCol = 'Sheet';

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
    tags = sometags is String ? sometags.split(tagdelim) : (sometags ?? []);
    cost = somecost ?? 0;
  }

  /// Return object members as a map
  Map<String, dynamic> getProperties() {
    return {
      idCol: id,
      dateCol: DateFormat('yyyy-MM-dd').format(date),
      cardCol: cardn,
      contentCol: content,
      categoryCol: category,
      costCol: cost,
      accountCol: account,
      tagCol: tags,
      sheetCol: sheet
    };
  }

  /// Returns object members as a map with no ID
  Map<String, dynamic> getPropertiesNoID() {
    return {
      dateCol: DateFormat('yyyy-MM-dd').format(date),
      cardCol: cardn,
      contentCol: content,
      categoryCol: category,
      costCol: cost,
      accountCol: account,
      tagCol: tags.length == 1 ? tags[0] : tags.join(tagdelim),
      sheetCol: sheet
    };
  }

  /// Returns object members as a map of displayable strings
  Map<String, dynamic> getPropsForDisplay() {
    return {
      dateCol: DateFormat('yyyy-MM-dd').format(date),
      cardCol: cardn.toString(),
      contentCol: content,
      categoryCol: category,
      costCol: cost.toStringAsFixed(2),
      accountCol: account,
      tagCol: tags.length == 1 ? tags[0] : tags.join(tagdelim),
      sheetCol: sheet
    };
  }

  /// Creates a TransactionObj from a map of properties
  TransactionObj.loadFromMap(Map<String, dynamic> map) :
    id = map['ID'],
    date = map['Date'] is String ? DateTime.parse(map['Date']) : map['Date'],
    cardn = map['Card'],
    content = map['Description'],
    category = map['Category'],
    cost = map['Cost'] is double ? 
            map['Cost']
            : (map['Cost'] is int ?
              map['Cost'].toDouble()
              : (map['Cost'] is String ?
                double.parse(map['Cost'])
                : null)),   // in case of integers
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
      idCol: 0,
      dateCol: DateTime.parse('1980-01-01'),
      cardCol: 0,
      contentCol: '',
      categoryCol: '',
      costCol: 0,
      accountCol: '',
      tagCol: List<String>.empty(growable: true),
      sheetCol: ''
    };
  }

  /// Defines which cells are displayable in the transaction widget
  Map<String, dynamic> getDisplayProperties() {
    return {
      idCol: false,
      dateCol: true,
      cardCol: true,
      contentCol: true,
      categoryCol: true,
      costCol: true,
      accountCol: false,
      tagCol: true,
      sheetCol: false
    };
  }

  /// Returns a map of the sizes for each category in a transaction
  /// used for determining how much space is needed per member
  Map<String, dynamic> getDisplaySizing() {
    return {
      idCol: 10.0,
      dateCol: 90.0,
      cardCol: 70.0,
      contentCol: 300.0,
      categoryCol: 130.0,
      costCol: 80.0,
      accountCol: 80.0,
      tagCol: 80.0,
      sheetCol: 90.0
    };
  }

  /// Returns an SQL query according to properties
  Map<String, dynamic> getSQLProperties() {
    return {
      idCol: 'INTEGER PRIMARY KEY',
      dateCol: 'DATE',
      cardCol: 'INTEGER',
      contentCol: 'TEXT',
      categoryCol: 'TEXT',
      costCol: 'DOUBLE',
      accountCol: 'TEXT',
      tagCol: 'TEXT',
      sheetCol: 'TEXT'
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
