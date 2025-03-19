import 'package:argent/components/data_pipeline.dart';
import 'package:argent/components/debug.dart';
import 'package:argent/components/transaction_obj.dart';
import 'package:argent/components/tags.dart';

import 'package:flutter/material.dart';
import 'dart:math';

/// This widget displays the transaction table
class TransactionTableWidget extends StatefulWidget {

  const TransactionTableWidget({super.key, required this.dataPipeline});

  /// Provides access to data pipeline
  final DataPipeline dataPipeline;

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

  /// Holds the component information for debugging messages
  CompInfo compInfo = CompInfo('Table', 1);

  /// Controls the total length of the table widget
  double maxTransactionWidgetHeight = 450;

  /// Sets the widths of data table column
  double defaultColumnWidth = 150;
  int smallColumnLength = 3;
  int mediumColummLength = 7;
  double smallColumnWidth = 80;
  double mediumColumnWidth = 90;

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  /// Reloads all transaction data and applies active filters
  void loadTransactions() async {
    compInfo.printout('Reloading transaction widget');
    // get the transactions from the datadistributer
    allTransactions = await widget.dataPipeline.allTransactions;

    // apply filters if there are any
    if (activeMonthFilter != null && activeYearFilter != null) {
      // applyFilters(activeYearFilter!, activeMonthFilter!);
    }
    setState(() {});
  }


  /// Returns an icon button that triggers the sort function
  IconButton getColumnIcon(int cindex) {
    Transform myIcon;
    if (columnSorts[cindex] == null) {
      // unsorted column
      myIcon = Transform.rotate(
        angle: 0,
        child: const Icon(Icons.arrow_left_rounded)
      );
    } else if (columnSorts[cindex] == false) {
      // column sorted lowest to highest
      myIcon = Transform.rotate(
        angle: 0,
        child: const Icon(Icons.arrow_drop_down_rounded)
      );
    } else {
      // column sorted highest to lowest
      myIcon = Transform.rotate(
        angle: 180 * pi / 180,
        child: const Icon(Icons.arrow_drop_down_rounded)
      );
    }
    return IconButton(
      onPressed: () => {},//sortMe(cindex),
      icon: myIcon,
      padding: EdgeInsets.zero
    );
  }

  /// Returns the appropriate column width for a title
  double getColumnWidth(String title) {
    if(title.length < smallColumnLength) {
      return smallColumnWidth;
    } else if (title.length < mediumColummLength) {
      return mediumColumnWidth;
    }
    return defaultColumnWidth;
  }

  /// Returns the box decoration for the header containers
  BoxDecoration getHeaderDecoration(int index,
                                    int maxCols,
                                    BuildContext context) {
    Color headerColor = Theme.of(context).colorScheme.tertiaryFixedDim;
    // topleft rounded box
    if (index == 0) {
      return BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
          color: headerColor
      );
    // topright rounded box
    } else if(index == maxCols-1) {
      return BoxDecoration(
          borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
          color: headerColor
      );
    // middle no rounding
    } else {
      return BoxDecoration(
        color: headerColor
      );
    }
  }

  /// Returns one header container for the headers in the table
  Container buildAHeader(String title,
                          int displayIndex,
                          int maxCols,
                          int sortIndex,
                          BuildContext context) {
    double cwidth = getColumnWidth(title);
    // add index and respective size
    columnSizes.addEntries([MapEntry(displayIndex, FixedColumnWidth(cwidth))]);
    return Container(
      decoration: getHeaderDecoration(displayIndex, maxCols, context),
      width: cwidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(title),
          getColumnIcon(sortIndex)
        ],
      )
    );
  }

  /// Returns the headers for the transaction table
  List<Container> createDataTableHeaders(BuildContext context) {
    List<Container> myHeaders = [];

    // use a default transaction for headers
    Map<String, dynamic> props = TransactionObj.defaultTransaction().
                                                              getProperties();
    Map<String, dynamic> displayProps = TransactionObj.defaultTransaction().
                                                        getDisplayProperties();

    // find how many columns to display
    int totalColumnsDisplayed = 0;
    displayProps.forEach((column, toDisplay) {
      if (toDisplay) totalColumnsDisplayed++;
    });

    // keep track of index for sorting
    int sortIndex = 0;

    // keep track of columns that are displayed
    int displayIndex = 0;

    props.forEach((title, _) {
      if (displayProps[title]) {
        // if column is displayable, build the header
        Container theHeader = buildAHeader(title,
                                          displayIndex,
                                          totalColumnsDisplayed,
                                          sortIndex,
                                          context);
        myHeaders.add(theHeader);
        displayIndex++; // increment columns when done building
      }
      // increment sort index regardless if column is displayed or not
      sortIndex++;
    });
    return myHeaders;
  }

  /// Returns the appropriate coloring for the row
  TextStyle getTextStyleFromTransObj(TransactionObj transObj) {
    List<String> taglist = transObj.tags;
    if (taglist.contains(Tags().hidden)) {
      return TextStyle(
        fontStyle: FontStyle.italic,
        color: Colors.grey
      );
    } else {
      return TextStyle(
        fontStyle: FontStyle.normal,
        color: Colors.black
      );
    }
  }

  /// Turn a transaction object into cells
  List<TableCell> getCellsFromTransactionObj(TransactionObj transObj,
                                            Map<String,dynamic> displayProps,
                                            int rowNum) {
    List<TableCell> myCells = [];
    
    // get the text style for each cell
    TextStyle cellTextStyle = getTextStyleFromTransObj(transObj);

    // get the coloration for the row
    Color rowColor = rowNum % 2 == 0 ? 
                        Theme.of(context).colorScheme.onSecondary
                        : Theme.of(context).colorScheme.tertiaryContainer;

    transObj.getProperties().forEach((column, value) {
      // skip if column is not displayed
      if (!displayProps[column]) return;
      myCells.add(
        TableCell(
          child: MouseRegion(
            onEnter: (_) => null, //onHover(rowc, colc, true),
            onExit: (_) => null, //onHover(rowc, colc, false),
            child: GestureDetector(
              onTap: () {
                //showEditMenu(context, rowc);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                height: 30,
                padding: EdgeInsets.only(left: 10),
                alignment: Alignment.centerLeft,
                color: rowColor,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Text(value.toString(), 
                    style: cellTextStyle
                  )
                ),
              ),
            ),
          ),
        )
      );
    });    
    return myCells;
  }

  /// Create the data rows for the data table
  Table createDataTable(BuildContext context) {
    // holds all rows for the table
    List<TableRow> myRows = [];
    Map<String, dynamic> displayProps = TransactionObj.defaultTransaction().
                                                        getDisplayProperties();
    // row number keeps track of alternate colored rows
    int rowNum = 0;
    // loop through the transactions to create the cells and rows
    for (TransactionObj transObj in allTransactions) {
      List<TableCell> myCells = getCellsFromTransactionObj(transObj,
                                                            displayProps,
                                                            rowNum);
      // add cells to row
      rowNum++;
      myRows.add(TableRow(children: myCells));
    }
    return Table(
      border: TableBorder.symmetric(),
      columnWidths: columnSizes,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: myRows,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: createDataTableHeaders(context),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: BoxConstraints(
                minWidth: 500,
                minHeight: 200,
                maxHeight: maxTransactionWidgetHeight
              ),
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: createDataTable(context)
              ),
            ),
          ]
        )
      ]);
  }
}