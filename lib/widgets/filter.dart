import 'package:argent/components/data_pipeline.dart';
import 'package:argent/components/debug.dart';
import 'package:argent/components/event_controller.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// This widget displays the available filters
class FilterWidget extends StatefulWidget {
  
  const FilterWidget({super.key, required this.dataPipeline});

  /// Access to the data pipeline
  final DataPipeline dataPipeline;

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {

  /// Holds the current year filter
  String? currentYear;
  /// Holds the current month filter
  String? currentMonth;

  /// Holds the date ranges available per what is in the database
  /// 
  /// { year1 : [month1, month2, ...],
  /// 
  ///   year2 : [month4, month5, ..] }
  Map<String, dynamic> dataRange = {};

  /// Holds the component information for debugging messages
  CompInfo compInfo = CompInfo('Filter', 2);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    context.read<EventController>().addDataChangeEventListener(loadData);
  }

  Future<void> loadData() async {
    compInfo.printout('Reloading filters');
    dataRange = await widget.dataPipeline.getTotalDateRange();
    setState(() {});
  }

  /// Gathers all the years from the data range into a list
  List<DropdownMenuItem> getYearChoices() {
    List<DropdownMenuItem> choices = [];
    dataRange.forEach((year, month) {
      choices.add(DropdownMenuItem(value: year, child: Text(year)));
    });
    return choices;
  }

  /// Gathers all the months for a certain year into a list
  List<DropdownMenuItem> getMonthChoices() {
    List<DropdownMenuItem> choices = [];
    if (currentYear != null && dataRange.containsKey(currentYear)) {
      for (String month in dataRange[currentYear]) {
        choices.add(DropdownMenuItem(value: month, child: Text(month)));
      }
    }
    return choices;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton(
          value: currentYear,
          hint: const Text('Select a year'),
          items: getYearChoices(),
          onChanged: (dynamic newVal) {
            if (newVal != currentYear)
            {
              currentYear = newVal;
              context.read<EventController>().notifyFilterChangeEvent(
                                                    currentYear, currentMonth);
            }
            setState(() {});
          },
        ),
        DropdownButton(
          value: currentMonth,
          hint: const Text('Select a month'),
          items: getMonthChoices(),
          onChanged: (dynamic newVal) {
            if (newVal != currentMonth)
            {
              currentMonth = newVal;
              context.read<EventController>().notifyFilterChangeEvent(
                                                    currentYear, currentMonth);
              setState(() {});
            }
          },
        )
      ],
    );
  }
}