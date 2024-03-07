import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import 'CalcResult.dart';
import 'CalculatingFunction.dart';
import 'Factions.dart';

part 'Collect.g.dart';

@JsonSerializable()
class CollectItemData extends CalcResult {
  late String id;

  // 标题
  String title;

  // 备注
  String remark;

  // 更新时间
  DateTime? updateTime;

  CollectItemData({
    String id = "",
    this.title = "",
    this.remark = "",
    this.updateTime,
  }) {
    this.id = const Uuid().v4();
  }

  as(CalcResult? calcResult) {
    if (calcResult != null) {
      inputFactions = calcResult.inputFactions;
      inputValue = calcResult.inputValue;
      outputValue = calcResult.outputValue;
      creationTime = calcResult.creationTime;
      calculatingFunctionInfo = calcResult.calculatingFunctionInfo;
      result = calcResult.result;
      updateTime = calcResult.creationTime;
    }
  }

  factory CollectItemData.fromJson(Map<String, dynamic> json) => _$CollectItemDataFromJson(json);

  Map<String, dynamic> toJson() => _$CollectItemDataToJson(this);
}