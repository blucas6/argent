import 'package:argent/components/data_pipeline.dart';
import 'package:argent/components/transaction_sheet.dart';
import 'package:argent/components/debug.dart';
import 'package:argent/components/popup.dart';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// This widget displays the accounts available
class AccountBarWidget extends StatefulWidget {

  /// Access to the data pipeline
  final DataPipeline dataPipeline;

  const AccountBarWidget({super.key, required this.dataPipeline});

  @override
  State<AccountBarWidget> createState() => _AccountBarWidgetState();
}

class _AccountBarWidgetState extends State<AccountBarWidget> {

  /// Tracks state of account widgets
  /// 
  /// { account name : [isVisible, isAnimating] }
  Map<String,dynamic> accountWidgetState = {};

  /// Holds a list of accounts available from the database
  /// 
  /// [ {name: accountname, type: accounttype, sheets: [...] } ]
  List<Map<String,dynamic>> accountList = [];

  /// Padding around account bar area
  double paddingAccountBar = 10;

  /// Animation time for drop down arrow
  int arrowAnimation = 100;

  /// Animation time for sheet drop down menu (milliseconds)
  int accountsDDAnimation = 550;

  /// Height of the sheet drop down menu
  double accountsDDHeight = 100.0;

  /// Holds the component information for debugging messages
  CompInfo compInfo = CompInfo('AccountBar', 1);

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  // on load, get data from the db
  void loadAccounts() async {
    try {
      accountList = await widget.dataPipeline.allAccounts;
      for (int i=0; i<accountList.length; i++) {
        String accName = accountList[i]['name'];
        if (!accountWidgetState.containsKey(accName)) {
          accountWidgetState[accName] = [false,false];
        }
      }
    } catch (e) {
      compInfo.printout('Error: load accounts failed! -> $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showErrorDialogue(e.toString(), context);
      });
    }
    setState(() {});
  }
  
  /// Adds a new transaction sheet to the database
  Future<void> addNewSheet() async {
    // account will be set on successful execution
    String account = '';
    // keep track of execution status
    (bool,String) resStatus;
    // ask the user for a file
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      try {
        File file = File(result.files.single.path!);
        TransactionSheet tfile = TransactionSheet(file);
        resStatus = await tfile.load();
        if (resStatus.$1) {
          account = tfile.account;
          compInfo.printout('Identified Account: $account');
          if (account.isNotEmpty) {
            compInfo.printout('Adding transactions to database');
            // load new data to database
            await widget.dataPipeline.addTransactionSheetToDatabase(tfile);
            // load accounts list, data distributer should be up to date
            loadAccounts();
          }
        } else {
          compInfo.printout('Error loading transaction file!');
        }
      } catch (e) {
        throw Exception(e);
      }
    } else {
      resStatus = (false, 'User did not select a file');
      compInfo.printout('User did not select a file');
      return;
    }
    setState(() {
      if (resStatus.$1) {
        // TODO: fix callback
        // trigger the callback to reload all widgets
        // widget.newDataTrigger();
      } else {
        showErrorDialogue(resStatus.$2, context);
      }
    });
  }

  /// Populates the file widgets in the account bar
  void toggleAccountSheets(String accountname) {
    setState(() {
      if (accountWidgetState.isNotEmpty) {
        if (accountWidgetState[accountname][0]) {
          // drop down is open
          setState(() {
            // start the animation
            accountWidgetState[accountname][1] = false;
          });
          // end visibility
          Future.delayed(Duration(milliseconds: accountsDDAnimation), () {
            setState(() {
              accountWidgetState[accountname][0] = false;
            });
          });
        } else {
          // drop down is closed, start animation and make visible
          accountWidgetState[accountname][0] = true;
          accountWidgetState[accountname][1] = true;
        }
      } else {
        compInfo.printout('Warning: accounts in account bar not loaded!');
      }
    });
  }

  /// Returns an animated drop down arrow
  AnimatedRotation getAnimatedArrow(String accName) {
    return AnimatedRotation(
      duration: Duration(milliseconds: arrowAnimation),
      turns: accountWidgetState[accName][0] ?
        -0.25 : 0.0,
      child: Icon(
        Icons.arrow_back_ios_rounded,
        color: Theme.of(context).iconTheme.color
      )
    );
  }

  /// Deletes a sheet from the database
  void removeSheetFromDatabase(String sheetName) async {
    await widget.dataPipeline.removeTransactionSheetFromDatabase(sheetName);
    loadAccounts();
  }

  /// Returns the animated transaction sheet view
  Container getSheetView(String accName, List<String> accSheets) {
    return Container(
      height: accountsDDHeight,
      decoration: BoxDecoration(
          color: Theme.of(context).secondaryHeaderColor,
          borderRadius: BorderRadius.circular(12)
      ),
      child: ListView(
        shrinkWrap: true,
        children: accSheets.map((acc) => 
          Padding(
            padding: EdgeInsets.only(left: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(acc, style: TextStyle(fontSize: 12),),
                Container(
                  height: 25,
                  child: IconButton(
                    onPressed: () async {
                      bool confirm = await showConfirmationDialogue(
                        'Delete Sheet',
                        'Delete transaction sheet?',
                        context);
                      if (confirm) {
                        try {
                          removeSheetFromDatabase(acc);
                        } catch (e) {
                          if (context.mounted) {
                            showErrorDialogue(e.toString(), context);
                          }
                        } 
                      }
                    },
                    icon: Icon(Icons.close),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                  ),
                )
              ]
            ),
          ),
        ).toList()
      ),
    );
  }

  /// Deletes all transactions and sheets associated with the account
  Future<void> deleteAccountData(String accName) async {
    try {
      // find account
      int? accIndex;
      for (int i=0; i<accountList.length; i++) {
        if (accName == accountList[i]['name']) accIndex = i;
      }
      if (accIndex != null) {
        // go through sheets and delete data
        List<String> sheets = accountList[accIndex]['sheets'];
        for (int s=0; s<sheets.length; s++) {
          await widget.dataPipeline.removeTransactionSheetFromDatabase(
                                                                    sheets[s]);
        }
        // delete from account table
        await widget.dataPipeline.deleteAccount(accountList[accIndex]['name']);
        // reload data
        loadAccounts();
      } else {
        throw Exception('Error: Failed to find account $accName!');
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Returns a list of the account widgets
  List<Widget> getAllAccountWidgets() {
    if (accountList.isEmpty) {
      return [];
    }
    // go through account list to build widgets
    return accountList.map((accMap) {
      if (accMap.isEmpty) return null;
      String accName = '';
      String accType = '';
      List<String> accSheets = [];
      try {
        accName = accMap['name'];
        accType = accMap['type'];
        accSheets = accMap['sheets'];
      } catch (e) {
        compInfo.printout('Error: Failed to parse account list!');
        return null;
      }
      return Column(
        children: [
          Container(
            padding: EdgeInsets.only(right: 1, left: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceDim,
              borderRadius: BorderRadius.circular(12)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      accType == 'card' ? Icons.credit_card
                        : Icons.account_balance, 
                      color: Theme.of(context).iconTheme.color
                    ),
                    const SizedBox(width: 8),
                    Text(accName, style: const TextStyle(fontSize: 16)),  
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        bool confirm = await showConfirmationDialogue(
                        'Delete Account',
                        'Are you sure you want to delete the $accName account?',
                        context);
                        if (confirm) {
                          try {
                            await deleteAccountData(accName);
                          } catch (e) {
                            if (context.mounted) {
                              showErrorDialogue(e.toString(), context);
                            }
                          }
                        }
                      }
                    ),
                    IconButton(
                      onPressed: () => toggleAccountSheets(accName),
                      icon: getAnimatedArrow(accName))
                  ]
                )
              ],
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: accountsDDAnimation),
            curve: Curves.easeInOut,
            height: accountWidgetState[accName][1]
                  ? accountsDDHeight : 0.0,
            child: Visibility(
              visible: accountWidgetState[accName][0],
              child: getSheetView(accName, accSheets)
            )
          )          
        ]
      );
    }).whereType<Widget>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(paddingAccountBar),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE
          const Text(
            'Accounts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // ACCOUNTS
          Container(
            padding: EdgeInsets.all(10),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: getAllAccountWidgets(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // BUTTON ADD
          ElevatedButton(
            onPressed: () {
              try {
                addNewSheet();
              } catch (e) {
                showErrorDialogue(e.toString(), context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
            ),
            child: const Text('+ Add Sheet', style: TextStyle(fontSize: 16))
          ),
        ],
      )
    );
  }
}