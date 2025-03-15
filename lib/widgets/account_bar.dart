import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:argent/component/data_pipeline.dart';
import 'package:argent/component/transaction_sheet.dart';

/// This widget displays the accounts available
class AccountBar extends StatefulWidget {

  /// Access to the data pipeline
  final DataPipeline dataPipeline;

  const AccountBar({super.key, required this.dataPipeline});

  @override
  State<AccountBar> createState() => _AccountBarState();
}

class _AccountBarState extends State<AccountBar> {

  /// All accounts available from the database
  List<String> accountList = [];

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  // on load, get data from the db
  void loadAccounts() async {
    accountList = await widget.dataPipeline.loadAccountList();
    setState(() {});
  }
  
  /// Adds a new transaction sheet to the database
  Future<void> addNewAccount() async {
    // account will be set on successful execution
    String account = '';
    // keep track of execution status
    (bool,String) resStatus;
    // Ask the user for a file
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      TransactionSheet tfile = TransactionSheet(file);
      resStatus = await tfile.load();
      if (resStatus.$1) {
        account = tfile.account;
        debugPrint('Identified Account: $account');
        if (account.isNotEmpty) {
          debugPrint('Adding transactions to database');
          // load new data to database
          await widget.dataPipeline.addTransactionSheetToDatabase(tfile);
          // load accounts list, data distributer should be up to date
          accountList = await widget.dataPipeline.loadAccountList();
        }
      } else {
        debugPrint('Error loading transaction file!');
      }
    } else {
      resStatus = (false, 'User did not select a file');
      debugPrint('User did not select a file');
      return;
    }

    setState(() {
      if (resStatus.$1) {
        // TODO: fix callback
        // trigger the callback to reload all widgets
        // widget.newDataTrigger();
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(resStatus.$2),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accounts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: accountList.map((account) => Row(
              children: [
                Icon(
                  Icons.account_balance, 
                  color: Theme.of(context).iconTheme.color
                ),
                const SizedBox(width: 8),
                Text(account, style: const TextStyle(fontSize: 16)),
              ],
            )).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: addNewAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
            ),
            child: const Text('+ Add Account', style: TextStyle(fontSize: 16))
          )
        ],
      )
    );
  }
}