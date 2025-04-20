import 'package:argent/components/event_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:argent/components/data_pipeline.dart';
import 'package:argent/components/debug.dart';
import 'package:argent/components/transaction_obj.dart';
import 'package:argent/components/tags.dart';

/// This class holds monthly spending data together
class SpendingObj {

  /// Total spent
  double totalSpent = 0.0;

  /// Total rent
  double rent = 0.0;

  /// Total savings
  double savings = 0.0;

  /// Total costs
  double costs = 0.0;

  /// Add a transaction to this object
  void addTransaction(TransactionObj trans) {
    if (Tags().isRent(trans)) {
      rent += trans.cost * -1;
    } else if (Tags().isSavings(trans)) {
      savings += trans.cost * -1;
    } else {
      costs += trans.cost * -1;
    }
    totalSpent += trans.cost * -1;
  }
}

class YearlyBarChartWidget extends StatefulWidget {

  const YearlyBarChartWidget({super.key, required this.dataPipeline});

  /// Connection to transaction data
  final DataPipeline dataPipeline;

  @override
  State<YearlyBarChartWidget> createState() => _YearlyBarChartWidgetState();
}

class _YearlyBarChartWidgetState extends State<YearlyBarChartWidget> {
  
  /// Holds the component information for debugging messages
  CompInfo compInfo = CompInfo('YearlyBar', 2);

  /// Transaction data from pipeline
  List<TransactionObj> allTransactions = [];

  /// Current year filter
  String? activeYearFilter;

  /// Dictionary to generate bar chart from
  /// { month : spendingObj }
  Map<String,dynamic> spendingData = {};

  /// Tallest bar in chart
  double maxBarHeight = 0;

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

  /// Receives the active year filter and reloads the data
  void handleFilterEvent(String? year, String? month) {
    if (activeYearFilter != year) {
      activeYearFilter = year;
      loadData();
    }
  }

  void loadData() async {
    compInfo.printout('Reloading bar data');
    spendingData = {};
    allTransactions = await widget.dataPipeline.allTransactions;
    for (TransactionObj trans in allTransactions) {
      // if there is an active filter, only take filtered transactions
      if (activeYearFilter == null || activeYearFilter == trans.year) {
        // HIDDEN money not counted in spending
        if (Tags().isValid(trans)) {
          // refunds are counted as lowering total spending
          // (does not need to be > 0)
          if (!spendingData.containsKey(trans.month)) {
            spendingData[trans.month] = SpendingObj();
          }
          spendingData[trans.month].addTransaction(trans);
        }
      }
    }
    setState(() {});
  }

  /// Create the bars for the chart from the dictionary
  List<BarChartGroupData> getBarsForChart() {
    List<BarChartGroupData> barChartData = [];
    return barChartData;
  }

  /// Create the tool tip data for the chart
  BarTouchData getToolTipData() {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          String category = allBars.keys.toList()[groupIndex.toInt()];
          String rent = allBars[category]['rent'].toStringAsFixed(2);
          String spending = allBars[category]['spending'].toStringAsFixed(2);
          String income = allBars[category]['income'].toStringAsFixed(2);
          return BarTooltipItem(
            '$category\nSpending: \$$spending \nRent: \$$rent\nIncome: \$$income',
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BarChartWidget(
      barsForChart: getBarsForChart(),
      barTitles: spendingData.keys.toList(),
      toolTipData: getToolTipData(),
      barHeight: maxBarHeight,
    );
  }
}

/// This widget displays a bar chart
class BarChartWidget extends StatefulWidget {

  const BarChartWidget({super.key,
                        required this.barsForChart,
                        required this.barTitles,
                        required this.toolTipData,
                        required this.barHeight
                      });

  /// Bars to be displayed
  final List<BarChartGroupData> barsForChart;

  /// String titles for all bars
  final List<String> barTitles;

  /// Tool tip data
  final BarTouchData? toolTipData;

  /// Animation time for the chart
  final int animationTime = 750;

  /// Minimum height of the chart
  final double maxHeightMIN = 1000.0;

  /// Height of the tallest bar
  final double barHeight;

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {

  @override
  Widget build(BuildContext context) {
    return BarChart(
      duration: Duration(milliseconds: widget.animationTime),
      curve: Curves.easeInOutQuint,
      BarChartData(
        maxY: widget.barHeight > widget.maxHeightMIN
              ? widget.barHeight : widget.maxHeightMIN,
        minY: 0,
        barGroups: widget.barsForChart,
        borderData: FlBorderData(show: true),
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double index, _) {
                return Text(
                          widget.barTitles[index.toInt()],
                          style: TextStyle(fontSize: 12)
                        );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false
            )
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false
            )
          )
        ),
        barTouchData: widget.toolTipData
      ),
    );
  }
}