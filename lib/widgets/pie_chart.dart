import 'package:argent/components/data_pipeline.dart';
import 'package:argent/components/event_controller.dart';
import 'package:argent/components/transaction_obj.dart';
import 'package:argent/components/debug.dart';
import 'package:argent/components/tags.dart';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

/// This widget displays expenses as a pie chart
class MonthlyPieChartWidget extends StatefulWidget {

  const MonthlyPieChartWidget({super.key, required this.dataPipeline});

  /// Connection to transaction data
  final DataPipeline dataPipeline;

  @override
  State<MonthlyPieChartWidget> createState() => _MonthlyPieChartWidgetState();
}

class _MonthlyPieChartWidgetState extends State<MonthlyPieChartWidget> {

  /// Holds the component information for debugging messages
  CompInfo compInfo = CompInfo('Pie', 2);

  /// Holds the transaction data as a set of categories with total cost
  Map<String, dynamic> categoryData = {};

  /// Transaction data from pipeline
  List<TransactionObj> allTransactions = [];

  /// Spending cost that has no category associated
  final String unnamedCategory = 'Unnamed';

  /// Current year filter
  String? activeYearFilter;

  /// Current month filter
  String? activeMonthFilter;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // data has changed listener
    context.read<EventController>().addDataChangeEventListener(loadData);
    // filter has changed listener
    context.read<EventController>().addFilterEventListener(handleFilterEvent);
  }

  /// Receives the active filters and reloads the data
  void handleFilterEvent(String? year, String? month) {
    if (activeYearFilter != year || activeMonthFilter != month) {
      activeYearFilter = year;
      activeMonthFilter = month;
      loadData();
    }
  }

  /// Loads the transaction data into a map by category
  void loadData() async {
    compInfo.printout('Reloading slice data');
    categoryData = {};
    allTransactions = await widget.dataPipeline.allTransactions;
    for (TransactionObj trans in allTransactions) {
      // only use transaction IF
      //  the transaction is not HIDDEN or INCOME
      if (Tags().isTransactionSpending(trans)) {
        // skip transactions that are not spending
        if (trans.cost > 0) continue;
        // flip cost for outputting in a pie chart
        double nonNegCost = trans.cost * -1;
        // check active filters
        if (activeYearFilter == null || trans.year == activeYearFilter) {
          if (activeMonthFilter == null || trans.month == activeMonthFilter) {
            // check if category is present in map
            if (trans.category != null && trans.category != '') {
              if (categoryData.containsKey(trans.category)) {
                categoryData[trans.category!] += nonNegCost;
              } else {
                categoryData[trans.category!] = nonNegCost;
              }
            } else if (categoryData.containsKey(unnamedCategory)) {
              categoryData[unnamedCategory] += nonNegCost;
            } else {
              categoryData[unnamedCategory] = nonNegCost;
            }
          }
        }
      }
    }
    compInfo.printout(categoryData);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PieChartWidget(
      totalHeight: 400,
      totalWidth: 400,
      title: 'Monthly Summary',
      sliceSize: 100,
      sliceExpanded: 110,
      sliceSpace: 2,
      radiusSize: 20,
      slicesMap: categoryData,
    );
  }
}

/// This widget displays a pie chart
class PieChartWidget extends StatefulWidget {

  PieChartWidget({super.key,
                  required this.totalHeight,
                  required this.totalWidth,
                  required this.title,
                  required this.sliceSize,
                  required this.sliceExpanded,
                  required this.sliceSpace,
                  required this.radiusSize,
                  required this.slicesMap
                });

  final double totalHeight;
  final double totalWidth;
  final double sliceSize;
  final double sliceExpanded;
  final double sliceSpace;
  final double radiusSize;
  final int animationTime = 750;
  final String title;
  /// Map of data used to generate the slices in the chart
  /// 
  /// { category : totalcost }
  final Map<String, dynamic> slicesMap;
  final List<MaterialColor> colorsList = [
    Colors.blue, Colors.amber, Colors.cyan, Colors.deepOrange,
    Colors.green, Colors.indigo, Colors.lime, Colors.deepPurple,
    Colors.yellow, Colors.purple, Colors.red, Colors.teal, 
    Colors.pink, Colors.lightGreen
  ];

  @override   
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {

  int? touchedIndex;
  double totalCost = 0;

  List<PieChartSectionData> getPieChartSections() {
    widget.slicesMap.forEach((category, value) {
      totalCost += value;
    });
    int sectionCounter = 0;
    List<PieChartSectionData> sections = [];
    if (totalCost > 0 && widget.slicesMap.isNotEmpty) {
      widget.slicesMap.forEach((category, value) {
        sections.add(PieChartSectionData(
          color: widget.colorsList[sectionCounter],
          value: value/totalCost*100,
          radius: touchedIndex == sectionCounter ? widget.sliceExpanded
                                                    : widget.sliceSize,
          title: '\$${(value).toStringAsFixed(2)}',
          titleStyle: touchedIndex == sectionCounter ? 
                      TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)
                      : TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)
        ));
        sectionCounter++;
      });
    } else {
      sections.add(PieChartSectionData(
        color: Colors.grey,
        value: 100,
        radius: widget.sliceSize,
        title: 'No Data',
        titleStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)
      ));
    }
    return sections;
  }

  /// Create the legend for the data
  List<Padding> getLegend() {
    List<Padding> mylegend = [];
    int sectionCounter = 0;
    widget.slicesMap.forEach((category, cost) {
      mylegend.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        child: Row(
          children: [
            Container(
              width: 15,
              height: 15,
              color: widget.colorsList[sectionCounter],
            ),
            SizedBox(width: 2),
            Text(category)
          ]
        ),
      ));
      sectionCounter++;
    });
    return mylegend;
  }

  @override
  Widget build(BuildContext context) {
    List<PieChartSectionData> mysections = getPieChartSections();
    return Container(
      height: widget.totalHeight,
      width: widget.totalWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 40),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: widget.totalHeight/2,
                width: widget.totalWidth/2,
                child: PieChart(
                  duration: Duration(milliseconds: widget.animationTime),
                  curve: Curves.easeInOutQuint,
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        int? beforeState = touchedIndex;
                        if (event.isInterestedForInteractions &&
                              pieTouchResponse != null) {
                          touchedIndex = pieTouchResponse.touchedSection?.
                                                          touchedSectionIndex;
                        } else {
                          touchedIndex = null;
                        }
                        if (beforeState != touchedIndex) setState(() {});
                      }
                    ),
                    sections: mysections,
                    centerSpaceRadius: widget.radiusSize,
                    sectionsSpace: widget.sliceSpace,
                  ),
                )
              ),
              SizedBox(width: 50),
              Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: getLegend()
                  )
                ],
              )
            ]
          )
        ]
      )
    );
  }
}
