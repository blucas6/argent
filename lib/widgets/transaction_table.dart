import 'package:argent/components/data_pipeline.dart';
import 'package:argent/components/debug.dart';
import 'package:argent/components/transaction_obj.dart';
import 'package:argent/components/tags.dart';
import 'package:argent/widgets/edit_menu.dart';
import 'package:argent/components/event_controller.dart';

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';

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
  List<TransactionObj> sortedTransactions = [];

  /// Current filter for the year
  String? activeYearFilter;

  /// Current filter for the month
  String? activeMonthFilter;

  /// Holds the display size for each column
  Map<int, TableColumnWidth> columnSizes = {};

  /// Used to keep track of which columns are sorted, starts off with all
  /// columns as unsorted null, false is L->H and true is H->L
  List<bool?> columnSorts = List.filled(
                              TransactionObj().getProperties().keys.length, null
                            );

  /// Holds the component information for debugging messages
  CompInfo compInfo = CompInfo('Table', 2);

  /// Controls the total length of the table widget
  double maxTransactionWidgetHeight = 450;

  /// Keeps track of which rows are being hovered
  List<bool> rowHovers = [];

  /// Scroll controller for table
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // data has changed listener
    context.read<EventController>().addDataChangeEventListener(loadTransactions);
    // data filter has changed listener
    context.read<EventController>().addFilterEventListener(handleFilterEvent);
  }

  /// Receive the filter event, clear sorting, apply filters and set the state
  void handleFilterEvent(String? year, String? month) {
    activeYearFilter = year;
    activeMonthFilter = month;
    clearSorting();
    applyFilters();
    setState(() {});
  }

  /// Applies a set of filters to the current data being displayed
  void applyFilters() {
    compInfo.printout('Applying filters $activeYearFilter $activeMonthFilter');
    List<TransactionObj> filteredTransactions = [];
    // if both filters are active grab all transactions for that month and year
    if (activeYearFilter != null && activeMonthFilter != null) {
      for (TransactionObj trans in allTransactions) {
        if (trans.year == activeYearFilter && trans.month == activeMonthFilter)
        {
          filteredTransactions.add(trans);
        }
      }
      // set the current displaying transactions to the filtered ones
      sortedTransactions = List.from(filteredTransactions);
    }
    else if (activeYearFilter != null && activeMonthFilter == null) {
      // if only year filter is active grab all transactions for that year
      for (TransactionObj trans in allTransactions) {
        if (trans.year == activeYearFilter) {
          filteredTransactions.add(trans);
        }
      }
      // set the filtered transactions to the display
      sortedTransactions = List.from(filteredTransactions);
    }
  }

  /// Reloads all transaction data and applies active filters
  void loadTransactions() async {
    compInfo.printout('Reloading transaction widget');
    // get the transactions from the datadistributer
    allTransactions = await widget.dataPipeline.allTransactions;
    // copy data - do not reference
    sortedTransactions = List<TransactionObj>.from(allTransactions);
    // create a 2D array for which row is being hovered
    rowHovers = List.filled(sortedTransactions.length, false);
    // apply filters if there are any
    applyFilters();
    // if a column is being sorted, sort transactions
    applySorting();
    setState(() {});
  }

  /// Apply any existing sorting, need to call set state after call
  void applySorting() {
    // go through the array and sort active column
    for (int col=0; col<columnSorts.length; col++) {
      if (columnSorts[col] != null) {
        updateIcons(col);
        sortMe(col);
      }
    }
  }

  /// Clears all active sorting and returns icons to normal
  void clearSorting() {
    sortedTransactions = List<TransactionObj>.from(allTransactions);
    columnSorts = List.filled(
                              TransactionObj().getProperties().keys.length, null
                            );
  }

  /// Updates the icon state
  void updateIcons(int columnIndex) {
    // set all columns besides the one of interest to null
    for (int i=0; i<columnSorts.length; i++) {
      columnSorts[i] = columnIndex != i ? null : columnSorts[i];
    }
    if (columnSorts[columnIndex] == null) {
      // turning true, point up
      columnSorts[columnIndex] = true;
    } else if (columnSorts[columnIndex] == true) {
      // turning false, point down
      columnSorts[columnIndex] = false;
    } else {
      // turning null, point back to left
      columnSorts[columnIndex] = null;
    }
  }

  /// Sorts the columns by column index
  void sortMe(int columnIndex) {
    // if the sorting column contains a list do not sort
    if (sortedTransactions[0].getProperties().values.toList()
      [columnIndex] is List) {
      return;
    }
    if (columnSorts[columnIndex] == true) {
      // just turned true, sort from highest ot lowest
      sortedTransactions.sort((a,b) {
        return a.getProperties().values.toList()[columnIndex].
            compareTo(b.getProperties().values.toList()[columnIndex]);
      });
    } else if (columnSorts[columnIndex] == false) {
      // just turned false, sort from lowest to highest
      sortedTransactions.sort((a,b) {
        return b.getProperties().values.toList()[columnIndex].
            compareTo(a.getProperties().values.toList()[columnIndex]);
      });
    } else {
      // just turned null, return to default order
      sortedTransactions = List<TransactionObj>.from(allTransactions);
    }
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
      onPressed: () {
        updateIcons(cindex);
        sortMe(cindex);
        setState(() {});
      },
      icon: myIcon,
      padding: EdgeInsets.zero
    );
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
                          double cwidth,
                          BuildContext context) {
    // add index and respective size
    columnSizes.addEntries([MapEntry(displayIndex, FixedColumnWidth(cwidth))]);
    return Container(
      padding: EdgeInsets.only(left: 5),
      decoration: getHeaderDecoration(displayIndex, maxCols, context),
      width: cwidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Container(
            height: 35,
            width: 30,
            child: getColumnIcon(sortIndex)
          )
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
    Map<String, dynamic> displaySizes = TransactionObj.defaultTransaction().
                                                        getDisplaySizing();
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
                                          displaySizes[title],
                                          context);
        myHeaders.add(theHeader);
        displayIndex++; // increment columns when done building
      }
      // increment sort index regardless if column is displayed or not
      sortIndex++;
    });
    return myHeaders;
  }

  /// Sets the corresponding row to be highlighted
  void onHover(int rowNum, bool isHover) {
    setState(() {
      rowHovers[rowNum] = isHover;
    });
  }

  /// Returns the appropriate text style for the row
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

  /// Returns the tag cell object
  Text getTagCellContent(List<String> tags) {
    return Text(
        tags.join('\n'),
      );
  }

  /// Returns the coloring for the whole row
  Color getColorForRow(int rowNum, BuildContext context) {
    return rowNum % 2 == 0 ? (rowHovers[rowNum] ? 
                            Theme.of(context).colorScheme.secondaryFixed
                            : Theme.of(context).colorScheme.tertiaryFixed)
                          : (rowHovers[rowNum] ?
                            Theme.of(context).colorScheme.secondaryFixed
                            : Theme.of(context).colorScheme.surface);
  }

  /// Turn a transaction object into cells
  List<TableCell> getCellsFromTransactionObj(TransactionObj transObj,
                                            Map<String,dynamic> displayProps,
                                            int rowNum) {
    List<TableCell> myCells = [];
    
    // get the text style for each cell
    TextStyle cellTextStyle = getTextStyleFromTransObj(transObj);

    // get the coloration for the row
    Color rowColor = getColorForRow(rowNum, context);

    transObj.getPropsForDisplay().forEach((key, value) {
      // skip if column is not displayed
      if (!displayProps[key]) return;
      dynamic cellContent;
      if (key == transObj.tagCol) {
        // special cell for tags
        cellContent = getTagCellContent(transObj.tags);
      } else {
        cellContent = Text(
                        value,
                        style: cellTextStyle);
      }
      myCells.add(
        TableCell(
          child: MouseRegion(
            onEnter: (_) => onHover(rowNum, true),
            onExit: (_) => onHover(rowNum, false),
            child: GestureDetector(
              onTap: () async {
                var controller = context.read<EventController>();
                bool update = await showEditMenu(context, rowNum);
                if (update) {
                  controller.notifyDataChangeEvent();
                }
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                height: 30,
                padding: EdgeInsets.only(left: 10),
                alignment: Alignment.centerLeft,
                color: rowColor,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: cellContent
                ),
              ),
            ),
          ),
        )
      );
    });    
    return myCells;
  }

  /// Pops up the edit menu widget and updates the transactions
  Future<bool> showEditMenu(BuildContext context, int rowNum) async {
    String? newTag = await showDialog<String?>(
                                      context: context,
                                      builder: (BuildContext context) {
      return EditMenuWidget();
    });
    if (newTag != null) {
      compInfo.printout("Adding new tag: $newTag");
      List<String> currentTags = sortedTransactions[rowNum].tags;
      if (newTag == Tags().delete) {
        currentTags = [];
      } else if (currentTags.isEmpty || currentTags[0] == '') {
        currentTags = [newTag];
      } else {
        currentTags.add(newTag);
      }
      compInfo.printout(currentTags);
      // update the transaction by id
      // no need to reload transaction data because the new data push event
      // will handle reloading
      await widget.dataPipeline.updateData(sortedTransactions[rowNum].id!,
                                  TransactionObj().tagCol,
                                  currentTags.join(TransactionObj().tagdelim));
    }
    return true;
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
    for (TransactionObj transObj in sortedTransactions) {
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
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.vertical,
                  child: createDataTable(context)
                ),
              ),
            ),
          ]
        )
      ]
    );
  }
}