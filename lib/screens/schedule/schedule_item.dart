import 'package:flutter/material.dart';

export 'schedule_item.dart';

class ScheduleItem {
  final String name;
  final String building;
  final String teacherName;
  final String classRoom;
  final String startTime;
  final Color color;
  late String endTime;
  late int time;

  ScheduleItem({
    required this.name,
    required this.building,
    required this.teacherName,
    required this.classRoom,
    required this.startTime,
    required this.endTime,
    required this.time,
    required this.color,
  });
}
