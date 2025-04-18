import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';

import 'package:argent/components/data_pipeline.dart';
import 'package:argent/widgets/transaction_table.dart';
import 'package:argent/widgets/account_bar.dart';
import 'package:argent/components/event_controller.dart';
import 'package:argent/widgets/filter.dart';

/// Entrance
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = WindowOptions(
    size: Size(1600, 900),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  // Initialize databaseFactory for desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => EventController(),
      child: Argent()
    )
  );
}

/// Argent Main Class
class Argent extends StatelessWidget {
  const Argent({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Argent',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 209, 134, 23)
          ),
      ),
      home: HomePage(title: 'Argent'),
    );
  }
}

/// Argent Home Page
class HomePage extends StatefulWidget {
  HomePage({super.key, required this.title});

  /// Application data pipeline
  final DataPipeline dataPipeline = DataPipeline();

  /// Application title
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LEFT SECTION
            Container(
              decoration: BoxDecoration(
                color: null
              ),
              width: 350,
              child: Column(
                children: [
                  AccountBarWidget(dataPipeline: widget.dataPipeline)
                ],
              ),
            ),
            // MIDDLE SECTION
            Container(
              decoration: BoxDecoration(
                color: null
              ),
              width: 750,
              child: Column(
                children: [
                  FilterWidget(dataPipeline: widget.dataPipeline),
                  TransactionTableWidget(dataPipeline: widget.dataPipeline)
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: null
              ),
              width: 300,
              child: Column(),
            )
          ],
        )
      )
    );
  }
}
