import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'schedule_item.dart';

export 'schedule_service.dart';

List<Color> preSelectedColors = [
  Colors.blue,
  Colors.green,
  Colors.red,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.indigo,
  Colors.pink,
  Colors.amber,
  Colors.cyan,
];

int colorCounter = 0;

Future<Map<String, List<ScheduleItem>>> fetchSchedule(String studentId) async {
  const apiUrl = "https://mportal.cau.ac.kr/portlet/p006/p006List.ajax";
  const Map<String, String> headers = {
    'Content-Type': 'application/json', // Adjust the content type as needed
  };

  final Map<String, dynamic> requestBody = {
    'userId': studentId,
  };

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: headers,
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonResponse = json.decode(response.body);
    final Map<String, List<ScheduleItem>> schedule = {};
    final Map<String, Color> courseColors =
        {}; // Map to store colors based on course name
    for (int i = 0; i < 6; i++) {
      schedule["d${i + 1}"] = [];
      for (var element in jsonResponse) {
        if (element["d${i + 1}"] != null) {
          String courseName = element["d${i + 1}"].split("\n")[0];
          if (schedule["d${i + 1}"]!.isNotEmpty &&
              schedule["d${i + 1}"]!.last.name == courseName) {
            schedule["d${i + 1}"]!.last.endTime = element["tm2"];
            schedule["d${i + 1}"]!.last.time += 30;
            continue;
          }

          // Use the same color for the same course name
          Color color = courseColors[courseName] ?? chooseColorFromList();
          courseColors[courseName] = color;

          schedule["d${i + 1}"]?.add(ScheduleItem(
            name: courseName,
            building: RegExp(r'<(\d+)[^>]*>')
                    .firstMatch(element["d${i + 1}"])
                    ?.group(1) ??
                "",
            classRoom:
                RegExp(r'(\d+)호').firstMatch(element["d${i + 1}"])?.group(1) ??
                    "",
            teacherName: RegExp(r'<(\d+).+? <(.+?)>>')
                    .firstMatch(element["d${i + 1}"])
                    ?.group(2) ??
                "",
            startTime: element["tm1"],
            endTime: element["tm2"],
            time: 30,
            color: color,
          ));
        } else {
          continue;
        }
      }
    }
    return schedule;
  }
  throw Exception("Failed to load schedule");
}

Future<List<ScheduleItem>> getTodayDaySchedule(
    Map<String, List<ScheduleItem>> schedule) async {
  final now = DateTime.now();
  final today = now.weekday;
  final todaySchedule = schedule["d$today"] ?? [];
  return todaySchedule;
}

Color chooseColorFromList() {
  Color color = preSelectedColors[colorCounter % preSelectedColors.length];
  colorCounter++;

  return color;
}
