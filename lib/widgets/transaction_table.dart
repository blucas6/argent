import 'package:argent/component/data_pipeline.dart';
import 'package:argent/component/transaction_obj.dart';

import 'package:flutter/material.dart';

/// This widget displays the transaction table
class TransactionTableWidget extends StatefulWidget {

  const TransactionTableWidget({super.key, required this.datadistributer});

  /// Provides access to data pipeline
  final DataPipeline datadistributer;

  /// Controls the total length of the table widget
  final double maxTransactionWidgetHeight = 450;

  @override
  State<TransactionTableWidget> createState() => TransactionTableWidgetState();
}

class TransactionTableWidgetState extends State<TransactionTableWidget> {

  /// List of transaction objects
  List<TransactionObj> allTransactions = [];

  /// Sorted transactions based on filters
  List<TransactionObj> currentFilteredTransactions = [];

  /// List of transaction objects as strings for display
  List<List<String>> currentTransactionStrings = [];

  /// Current filter for the year
  String? activeYearFilter;

  /// Current filter for the month
  String? activeMonthFilter;

  /// Holds the display size for each column
  Map<int, TableColumnWidth> columnSizes = {};

  // Keep track of which rows are being hovered
  List<List<bool>> rowHovers = [];

  /// Used to keep track of which columns are sorted, starts off with all
  /// columns as null
  List<bool?> columnSorts = List.filled(
                          TransactionObj().getProperties().keys.length, null);
    
  // load transactions on startup
  @override
  void initState() {
    super.initState();
    // loadTransactions();
  }

    @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [] //createDataTableHeaders(),
        ),
        Container(
          constraints: BoxConstraints(
            minWidth: 500,
            minHeight: 200,
            maxHeight: widget.maxTransactionWidgetHeight),
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: null //createDataTable(context)
          ),
        )
      ]);
  }
}