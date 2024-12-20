import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';

import '/component/_keyboard/index.dart';
import '/provider/collect_provider.dart';
import '/constants/app.dart';
import '/data/index.dart';
import '/provider/calc_provider.dart';

class GunComparisonTablePage extends HomeAppWidget {
  GunComparisonTablePage({super.key});

  @override
  State<GunComparisonTablePage> createState() => _GunComparisonTablePageState();
}

class _GunComparisonTablePageState extends State<GunComparisonTablePage> with AutomaticKeepAliveClientMixin {
  Factions inputFactions = Factions.None;

  final ValueNotifier<TextEditingController> _textController = ValueNotifier(TextEditingController());

  // 火炮表格
  List gunCalcTable = [];

  // 范围选择器状态
  bool rangeSelectorStatus = false;

  FocusNode focusNode = FocusNode();

  GlobalKey<KeyboardWidgetState> keyboardWidgetKey = GlobalKey<KeyboardWidgetState>();

  /// 配置S

  /// 输入值+-范围
  int valueRange = 10;

  /// 建议范围滚动
  ScrollController rangeSelectorListViewController = ScrollController();

  /// 表格对照数量
  /// 默认1600 - 100，此值会被后续动态更新
  int length = 1600 - 100;

  /// 配置E

  @override
  void initState() {
    CalculatingFunction currentCalculatingFunction = App.provider.ofCalc(context).currentCalculatingFunction;
    Factions firstName = Factions.None;

    firstName = currentCalculatingFunction.child.keys.first;

    setState(() {
      // 初始所支持的阵营
      if (Factions.values.where((e) => e == firstName).isNotEmpty) inputFactions = Factions.values.where((e) => e == firstName).first;
    });

    _generateTableData();
    super.initState();
  }

  /// 处理回退
  void handleBackspace() {
    final currentText = _textController.value.text;
    final selection = _textController.value.selection;
    if (selection.baseOffset != selection.extentOffset) {
      final newText = currentText.replaceRange(
        selection.baseOffset,
        selection.extentOffset,
        '',
      );
      _textController.value.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset,
        ),
      );
    } else if (selection.baseOffset > 0) {
      final newText = currentText.replaceRange(
        selection.baseOffset - 1,
        selection.baseOffset,
        '',
      );
      _textController.value.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset - 1,
        ),
      );
    }

    setState(() {});
  }

  /// 区间建议
  List getSuggestionGroups(List list, {int minGroups = 1, int maxGroups = 10}) {
    if (list.isEmpty) {
      return [];
    }

    int groupSize = list.length ~/ maxGroups;
    groupSize = groupSize > 0 ? groupSize : 1;

    List<dynamic> result = [];
    for (int i = 0; i < list.length; i += groupSize) {
      int mid = i + groupSize ~/ 2;
      mid = mid < list.length ? mid : list.length - 1;
      result.add(list[mid]);
    }

    while (result.length > maxGroups) {
      result.removeLast();
    }

    while (result.length < minGroups) {
      result.add([]);
    }

    return result;
  }

  /// 中间数
  num centerNumber(dynamic start, dynamic end) {
    num _start = num.parse(start.toString());
    num _end = num.parse(end.toString());
    return ((_start + _end) / 2).ceil();
  }

  /// 生成火炮数据
  void _generateTableData() {
    List list = [];
    CalcProvider calcData = App.provider.ofCalc(context);
    CalculatingFunctionChild e = calcData.defaultCalculatingFunction.childValue(inputFactions)!;
    int maximumRange = e.maximumRange; // 最大角度
    int minimumRange = e.minimumRange; // 最小角度
    int inputRangValue = _textController.value.text.isEmpty ? -1 : int.parse((_textController.value.text).toString());

    /// 输入值范围表
    if (inputRangValue >= 0) {
      length = (inputRangValue + valueRange) - (inputRangValue - valueRange);

      num start = inputRangValue - valueRange;
      num end = inputRangValue + valueRange;
      num count = start; // 初始赋予开始值 count

      while (count >= start && count <= end) {
        CalcResult calcResult = App.calc.on(
          inputFactions: inputFactions,
          inputValue: count,
          calculatingFunctionInfo: calcData.currentCalculatingFunction,
        );

        list.add([count, calcResult.outputValue]);
        count++;
      }
    }

    /// 所有
    if (inputRangValue < 0) {
      int count = minimumRange;

      while (count >= minimumRange && count <= maximumRange) {
        CalcResult calcResult = App.calc.on(
          inputFactions: inputFactions,
          inputValue: count,
          calculatingFunctionInfo: calcData.currentCalculatingFunction,
        );

        list.add([count, calcResult.outputValue]);
        count++;
      }
    }

    setState(() {
      gunCalcTable = list;
    });
  }

  /// 打开配置
  void _openSettingModal() {
    TextEditingController valueRangeController = TextEditingController(text: valueRange.toString());

    valueRangeController.addListener(() {
      if (valueRangeController.text.isEmpty) {
        valueRange = 10;
      } else {
        valueRange = int.parse(valueRangeController.text);
      }
    });

    showModalBottomSheet<void>(
      context: context,
      clipBehavior: Clip.hardEdge,
      useSafeArea: true,
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            leading: const CloseButton(),
          ),
          body: ListView(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: "0",
                  labelText: FlutterI18n.translate(context, "gunComparisonTable.setting.section"),
                  helperText: FlutterI18n.translate(context, "gunComparisonTable.setting.sectionHelperText"),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                ),
                keyboardType: TextInputType.number,
                controller: valueRangeController,
              )
            ],
          ),
        );
      },
    );
  }

  /// 选择阵营
  void _openSelectFactions() {
    showModalBottomSheet<void>(
      context: context,
      clipBehavior: Clip.hardEdge,
      useSafeArea: true,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, modalSetState) {
          return Consumer<CalcProvider>(
            builder: (context, calcData, widget) {
              return Scaffold(
                appBar: AppBar(
                  leading: const CloseButton(),
                ),
                body: ListView(
                  children: Factions.values.where((i) => i != Factions.None).map((i) {
                    return ListTile(
                      selected: inputFactions.value == i.value,
                      enabled: calcData.currentCalculatingFunction.hasChildValue(i),
                      title: Text(FlutterI18n.translate(context, "basic.factions.${i.value}")),
                      trailing: Text(calcData.currentCalculatingFunction.hasChildValue(i) ? "" : "不支持"),
                      onTap: () {
                        if (!calcData.currentCalculatingFunction.hasChildValue(i)) {
                          return;
                        }

                        setState(() {
                          inputFactions = i;
                        });
                        modalSetState(() {});

                        Future.delayed(const Duration(milliseconds: 500)).then((value) {
                          Navigator.pop(context);
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer2<CalcProvider, CollectProvider>(
      builder: (context, calcData, collectData, widget) {
        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// table content
              Expanded(
                flex: 1,
                child: Stack(
                  children: [
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: gunCalcTable.length,
                      itemBuilder: (context, index) {
                        List gunItem = gunCalcTable[index];

                        return Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 5,
                                  children: [
                                    const SizedBox(width: 8),
                                    if (gunItem[0].toString().trim() == _textController.value.text.trim())
                                      const SizedBox(
                                        width: 40,
                                        child: Icon(Icons.search),
                                      ),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(gunItem[0]);
                                      },
                                      child: Text(
                                        "${gunItem[0]}",
                                        style: TextStyle(
                                          color: gunItem[0].toString().trim() == _textController.value.text.trim() ? Theme.of(context).colorScheme.primary : null,
                                          fontSize: 25,
                                          fontWeight: gunItem[0].toString().trim() == _textController.value.text.trim() ? FontWeight.bold : FontWeight.normal,
                                          decoration: TextDecoration.underline,
                                          decorationStyle: TextDecorationStyle.dashed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width / 8,
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              constraints: const BoxConstraints(
                                minWidth: 10,
                                maxWidth: 100,
                              ),
                              child: const Divider(height: 1),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 5,
                                  children: [
                                    Text(
                                      "${gunItem[1]}",
                                      style: TextStyle(
                                        fontSize: 25,
                                        color: Color.lerp(Theme.of(context).primaryColor, Colors.red, .1),
                                        fontWeight: gunItem[0].toString().trim() == _textController.value.text.trim() ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      FlutterI18n.translate(context, "gunComparisonTable.density"),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor.withOpacity(.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const SizedBox(height: 5);
                      },
                    ),

                    /// top mark
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: true,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.surface.withOpacity(.95),
                                Theme.of(context).colorScheme.surface.withOpacity(.0),
                              ],
                            ),
                          ),
                          height: 80,
                        ),
                      ),
                    ),

                    /// bottom mark
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: true,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).colorScheme.surface.withOpacity(.0),
                                Theme.of(context).colorScheme.surface.withOpacity(.95),
                                Theme.of(context).colorScheme.surface,
                              ],
                            ),
                          ),
                          height: 80,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// tool
              Row(
                children: [
                  const SizedBox(width: 5),
                  Wrap(
                    children: [
                      RawChip(
                        onPressed: () => _openSelectFactions(),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.flag),
                        label: Row(
                          children: [
                            Text(FlutterI18n.translate(context, "basic.factions.${inputFactions.value}")),
                            const Icon(Icons.keyboard_arrow_down_outlined, size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      RawChip(
                        onPressed: () {
                          App.url.opEnPage(context, "/calculatingFunctionConfig").then((value) {
                            setState(() {
                              inputFactions = App.provider.ofCalc(context).currentCalculatingFunction.child.keys.first;
                            });
                          });
                        },
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.functions),
                        label: Row(
                          children: [
                            Text(calcData.currentCalculatingFunctionName),
                            const Icon(Icons.keyboard_arrow_down_outlined, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Expanded(flex: 1, child: SizedBox()),
                  IconButton(
                    onPressed: () {
                      _openSettingModal();
                    },
                    icon: const Icon(
                      Icons.settings,
                    ),
                  ),
                ],
              ),

              const Divider(height: 1, thickness: 1),

              /// 范围选择器
              AnimatedContainer(
                clipBehavior: Clip.hardEdge,
                duration: const Duration(milliseconds: 350),
                color: Theme.of(context).primaryColor.withOpacity(.2),
                padding: const EdgeInsets.only(left: 20, right: 5),
                height: rangeSelectorStatus ? null : 50,
                constraints: const BoxConstraints(maxHeight: 50 * 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Scrollbar(
                        child: ListView(
                          controller: rangeSelectorListViewController,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          physics: rangeSelectorStatus ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                          children: [
                            /// 区间首选
                            Wrap(
                              spacing: 5,
                              runSpacing: rangeSelectorStatus ? 0 : 5,
                              runAlignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              direction: Axis.horizontal,
                              clipBehavior: Clip.hardEdge,
                              children: [
                                if (!rangeSelectorStatus)
                                  const SizedBox(
                                    width: 35,
                                    height: 40,
                                    child: Icon(
                                      Icons.numbers,
                                      size: 20,
                                    ),
                                  ),

                                /// 展开文本框
                                if (rangeSelectorStatus)
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: TextField(
                                      readOnly: true,
                                      showCursor: true,
                                      decoration: InputDecoration(hintText: FlutterI18n.translate(context, "gunComparisonTable.inputHelperText"), contentPadding: const EdgeInsets.symmetric(horizontal: 10)),
                                      controller: _textController.value,
                                    ),
                                  ),

                                /// 收起的文本框
                                if (!rangeSelectorStatus)
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width - 10 - 170,
                                    child: TextField(
                                      readOnly: true,
                                      showCursor: true,
                                      decoration: InputDecoration.collapsed(hintText: FlutterI18n.translate(context, "gunComparisonTable.inputHelperText")),
                                      controller: _textController.value,
                                      onTap: () {
                                        keyboardWidgetKey.currentState?.openKeyboard();
                                      },
                                    ),
                                  ),
                                if (!rangeSelectorStatus)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _textController.value.text.isEmpty
                                        ? null
                                        : () {
                                            handleBackspace();
                                            _generateTableData();
                                          },
                                    icon: const Icon(Icons.backspace, size: 18),
                                  ),
                              ],
                            ),

                            /// 区间提示
                            if (rangeSelectorStatus)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 35,
                                    height: 40,
                                    child: Icon(
                                      Icons.lightbulb_outline,
                                      size: 20,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: const Text("区间建议"),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 2),

                            /// 区间首选
                            Wrap(
                              spacing: 10,
                              runSpacing: rangeSelectorStatus ? 0 : 5,
                              runAlignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              direction: Axis.horizontal,
                              clipBehavior: Clip.hardEdge,
                              children: [
                                /// 其他区间
                                ...getSuggestionGroups(gunCalcTable)
                                    .map((e) => ActionChip(
                                          label: Text(centerNumber(e[0], e[1]).toString()),
                                          onPressed: () {
                                            setState(() {
                                              _textController.value.text = centerNumber(e[0], e[1]).toString();
                                              _generateTableData();
                                            });
                                          },
                                          visualDensity: VisualDensity.compact,
                                        ))
                                    .toList(),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(thickness: 1),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          rangeSelectorStatus = !rangeSelectorStatus;
                        });

                        rangeSelectorListViewController.jumpTo(0);
                      },
                      icon: Icon(rangeSelectorStatus ? Icons.keyboard_arrow_down_sharp : Icons.lightbulb_outline),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 2),

              /// 键盘
              KeyboardWidget(
                key: keyboardWidgetKey,
                spatialName: "home_gun_comparison_table",
                onSubmit: () {
                  setState(() {
                    _generateTableData();
                  });
                },
                initializePackup: true,
                initializeKeyboardType: KeyboardType.IncreaseAndDecrease,
                inputFactions: inputFactions,
                controller: _textController,
              ),

              Container(
                height: MediaQuery.of(context).viewPadding.bottom,
                color: Theme.of(context).primaryColor.withOpacity(.2),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
