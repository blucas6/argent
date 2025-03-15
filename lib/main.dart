import 'package:argent/component/data_pipeline.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'package:argent/widgets/account_bar.dart';

/// Entrance
void main() {
  // Initialize databaseFactory for desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const Argent());
}

/// Argent Main Class
class Argent extends StatelessWidget {
  const Argent({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Argent',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 209, 134, 23)),
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
        child: Column(
          children: [
            Expanded(child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    AccountBar(dataPipeline: widget.dataPipeline)
                  ],
                )
              ],
            ))
          ],
        ),
      ),
    );
  }
}
