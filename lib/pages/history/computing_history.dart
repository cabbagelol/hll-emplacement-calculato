import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:hll_emplacement_calculator/component/_empty/index.dart';
import 'package:hll_emplacement_calculator/provider/history_provider.dart';
import 'package:provider/provider.dart';

import '../../widgets/hisroy_calc_card.dart';

/// [计算历史]
/// 从状态机取出

class ComputingHistoryPage extends StatefulWidget {
  const ComputingHistoryPage({super.key});

  @override
  State<ComputingHistoryPage> createState() => _ComputingHistoryPageState();
}

class _ComputingHistoryPageState extends State<ComputingHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(builder: (context, historyData, widget) {
      return Scaffold(
        appBar: AppBar(
          title: Text(FlutterI18n.translate(context, "history.title")),
        ),
        body: historyData.list.isNotEmpty ? ListView(
          children: historyData.list.map((i) {
            return historyCalcCard(
              i: i,
            );
          }).toList(),
        ) : const Center(
          child: EmptyWidget(),
        ),
      );
    });
  }
}
