import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:assign_3/pages/home_page.dart';
import 'dart:math';

class ChartsPage extends StatelessWidget {
  final List<Expense> expenses;

  ChartsPage({required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Distributions',
          style: TextStyle(
            color: Colors.deepPurple[700],
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 38,
          ),
        ),
        backgroundColor: Colors.deepPurple[300],
        centerTitle: true,
        elevation: 0.0,
      ),
      backgroundColor: Colors.deepPurple[300],
      body: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 0,
          sections: getExpenseCategorySections(),
        ),
      ),
    );
  }

  List<PieChartSectionData> getExpenseCategorySections() {
    Map<String, int> categoryAmountMap = Map();
    expenses.forEach((expense) {
      categoryAmountMap.update(
          expense.category, (value) => value + expense.amount.abs(),
          ifAbsent: () => expense.amount.abs());
    });
    return categoryAmountMap.entries
        .map((entry) => PieChartSectionData(
              titlePositionPercentageOffset: 1,
              color: getRandomColor(),
              value: entry.value.toDouble(),
              title: '${entry.key}\n(${entry.value})',
              radius: 158,
              titleStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ))
        .toList();
  }

  Color getRandomColor() {
    final Random random = Random();
    final int pinkShade = random.nextInt(200) + 55;
    final int blueShade = random.nextInt(200) + 55;
    return Color.fromRGBO(pinkShade, 0, blueShade, 1);
  }
}
