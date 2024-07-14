import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:assign_3/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:assign_3/charts_page.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';

Future<void> exportPDF(List<Expense> expenses) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Column(
            children: [
              pw.Text('Expense Report',
                  style: pw.TextStyle(
                      fontSize: 25, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: <pw.TableRow>[
                  // Column Headings
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        child: pw.Text(
                          'Category',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 20),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 20),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // Data Rows
                  for (var row in expenses)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                              vertical: 10, horizontal: 4),
                          child: pw.Text(
                            row.category,
                            style: pw.TextStyle(fontSize: 14),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.symmetric(
                              vertical: 10, horizontal: 4),
                          child: pw.Text(
                            row.amount.toString(),
                            style: pw.TextStyle(fontSize: 14),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
  final output = await getTemporaryDirectory();
  final file = File('${output.path}/expense_report.pdf');
  await file.writeAsBytes(await pdf.save());

  OpenFile.open(file.path);
}

class Expense {
  String category;
  int amount;
  Expense({required this.category, required this.amount});
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int TotalAmount = 0;
  final TextEditingController editAmountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  List<Expense> expenses = [];
  bool showCategories = false;
  final User? user = Auth().currentUser;
  List<int> dismissedIndices = [];

  Widget _exportPDFButton() {
    return ElevatedButton(
        style: ButtonStyle(
            fixedSize: MaterialStatePropertyAll(Size(10, 45)),
            backgroundColor: MaterialStatePropertyAll(Colors.deepPurple),
            elevation: MaterialStatePropertyAll(0),
            padding: MaterialStatePropertyAll(
              EdgeInsets.only(left: 8),
            )),
        onPressed: () {
          exportPDF(expenses);
        },
        child: Icon(
          Icons.download_rounded,
          size: 40,
        ));
  }

  void removeExpense(int index) {
    setState(() {
      TotalAmount -= expenses[index].amount;
      dismissedIndices.add(index);
    });
  }

  bool shouldDismiss(int index) {
    return dismissedIndices.contains(index);
  }

  void editExpense(int index) async {
    _amountController.text = expenses[index].amount.toString();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple[900],
          title: Center(
            child: Text(
              'Edit Expense',
              style: TextStyle(
                fontSize: 30,
                color: Colors.white60,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Price:',
                  labelStyle: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 25,
                    color: Colors.white60,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            FloatingActionButton(
              onPressed: () async {
                int newAmount = int.tryParse(_amountController.text) ?? 0;
                if (newAmount != 0) {
                  try {
                    final expenseToUpdate = expenses[index];
                    final expenseRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('expenses')
                        .where('category', isEqualTo: expenseToUpdate.category)
                        .where('amount', isEqualTo: expenseToUpdate.amount);

                    final expenseQuerySnapshot = await expenseRef.get();

                    if (expenseQuerySnapshot.docs.isNotEmpty) {
                      final expenseDocToUpdate =
                          expenseQuerySnapshot.docs.first;
                      await expenseDocToUpdate.reference.update({
                        'amount': newAmount,
                      });

                      setState(() {
                        TotalAmount =
                            TotalAmount - expenseToUpdate.amount + newAmount;
                        expenses[index].amount = newAmount;
                      });
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    print('Error updating expense: $e');
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid Amount.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Icon(
                Icons.check_circle_outline,
                size: 50,
              ),
              elevation: 0,
              backgroundColor: Colors.deepPurple[900],
              foregroundColor: Colors.white54,
            ),
          ],
        );
      },
    );
  }

  void deleteExpense(int index) async {
    try {
      final expenseToDelete = expenses[index];
      final expenseRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('expenses')
          .where('category', isEqualTo: expenseToDelete.category)
          .where('amount', isEqualTo: expenseToDelete.amount);

      final expenseQuerySnapshot = await expenseRef.get();

      if (expenseQuerySnapshot.docs.isNotEmpty) {
        final expenseDocToDelete = expenseQuerySnapshot.docs.first;
        await expenseDocToDelete.reference.delete();

        setState(() {
          TotalAmount -= expenses[index].amount;
          expenses.removeAt(index);
        });
      }
    } catch (e) {
      print('Error deleting expense: $e');
    }
  }

  void toggleCategoriesVisibility() {
    setState(() {
      showCategories = !showCategories;
    });
  }

  void AddExpense() async {
    _categoryController.clear();
    _amountController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple[900],
          title: Center(
            child: Text(
              'New Entry',
              style: TextStyle(
                fontSize: 30,
                color: Colors.white60,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category:',
                  labelStyle: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 25,
                    color: Colors.white60,
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Price:',
                  labelStyle: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: 25,
                    color: Colors.white60,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            FloatingActionButton(
              onPressed: () async {
                int amount = int.tryParse(_amountController.text) ?? 0;
                String category = _categoryController.text.trim();
                if (category.isNotEmpty && amount != 0) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('expenses')
                        .add({
                      'category': category,
                      'amount': amount,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    setState(() {
                      TotalAmount += amount;
                      expenses.add(Expense(
                        category: _categoryController.text,
                        amount: amount,
                      ));
                    });
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Error adding expense: $e');
                  }
                } else if (category.isEmpty && amount == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Please enter a valid Category and Amount.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (amount == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid Amount.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (category.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid Category.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                ;
              },
              child: Icon(
                Icons.check_circle_outline,
                size: 50,
              ),
              elevation: 0,
              backgroundColor: Colors.deepPurple[900],
              foregroundColor: Colors.white54,
            ),
          ],
        );
      },
    );
  }

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _signOutButton() {
    return ElevatedButton(
        style: ButtonStyle(
            fixedSize: MaterialStatePropertyAll(Size(20, 45)),
            backgroundColor: MaterialStatePropertyAll(Colors.deepPurpleAccent),
            padding: MaterialStatePropertyAll(EdgeInsets.all(0))),
        onPressed: signOut,
        child: Icon(
          Icons.person_rounded,
          size: 45,
        ));
  }

  void fetchExpenses() async {
    if (user == null) {
      return;
    } else {
      try {
        final expensesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('expenses')
            .get();

        setState(() {
          expenses = expensesSnapshot.docs.map((doc) {
            return Expense(
              category: doc['category'],
              amount: doc['amount'],
            );
          }).toList();

          TotalAmount = expenses.fold<int>(
              0, (previousValue, expense) => previousValue + expense.amount);
        });
      } catch (e) {
        print('Error fetching expenses: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Text(
              'Budget Tracker',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 27,
              ),
            ),
            _exportPDFButton(),
            SizedBox(
              width: 6,
            ),
            _signOutButton(),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 0.0,
      ),
      backgroundColor: Colors.deepPurple[300],
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 100, 10, 0),
              child: Container(
                width: 365,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[100],
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      'Total:             ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                    Text(
                      '${TotalAmount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        child: FloatingActionButton.small(
                          child: Icon(Icons.keyboard_double_arrow_down_rounded),
                          onPressed: () => toggleCategoriesVisibility(),
                          elevation: 0,
                          shape: CircleBorder(
                            side: BorderSide(color: Colors.black38, width: 3),
                          ),
                          foregroundColor: Colors.black54,
                          backgroundColor: Colors.deepPurple[100],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Visibility(
              visible: showCategories,
              child: Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    if (shouldDismiss(index)) {
                      return SizedBox.shrink();
                    }
                    return Slidable(
                      actionPane: SlidableDrawerActionPane(),
                      secondaryActions: [
                        IconSlideAction(
                          caption: 'Delete',
                          color: Colors.deepPurple[300],
                          iconWidget: Container(
                            child: Icon(
                              Icons.delete,
                              size: 35,
                            ),
                          ),
                          foregroundColor: Colors.black,
                          onTap: () => deleteExpense(index),
                        ),
                      ],
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(15, 0, 5, 10),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple[100],
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(width: 8),
                                    Text(
                                      expense.category,
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple[300],
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      '${expense.amount}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FloatingActionButton(
                              onPressed: () => editExpense(index),
                              child: Icon(
                                Icons.edit,
                                size: 30,
                              ),
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.deepPurple[300],
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        children: <Widget>[
          SizedBox(width: 23),
          IconButton(
            padding: EdgeInsets.fromLTRB(5, 0, 0, 25),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChartsPage(expenses: expenses),
                ),
              );
            },
            icon: Icon(
              Icons.pie_chart_rounded,
              size: 55,
            ),
          ),
          Spacer(),
          FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: AddExpense,
            foregroundColor: Colors.deepPurple[500],
            backgroundColor: Colors.deepPurple[100],
          ),
        ],
      ),
    );
  }
}
