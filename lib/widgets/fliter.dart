

import 'package:argent/components/data_pipeline.dart';
import 'package:argent/main.dart';
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

  List<DropdownMenuItem> getYearChoices() {
    List<DropdownMenuItem> choices = [];
    return choices;
  }

  List<DropdownMenuItem> getMonthChoices() {
    List<DropdownMenuItem> choices = [];
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
              context.read<RefreshController>().refreshWidgets();
            }
          },
        ),
        DropdownButton(
          value: currentYear,
          hint: const Text('Select a month'),
          items: getMonthChoices(),
          onChanged: (dynamic newVal) {
            if (newVal != currentMonth)
            {
              currentMonth = newVal;
              context.read<RefreshController>().refreshWidgets();
            }
          },
        )
      ],
    );
  }
}