import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class ScheduleNotificationScreen extends StatefulWidget {
  const ScheduleNotificationScreen({Key? key}) : super(key: key);

  @override
  _ScheduleNotificationScreenState createState() =>
      _ScheduleNotificationScreenState();
}

class _ScheduleNotificationScreenState
    extends State<ScheduleNotificationScreen> {
  String dropdownValue = '5min';
  String _notificationName = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Notification'),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 16,
          ),
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Name of the notification',
            ),
            onChanged: (notificationName) {
              setState(() {
                _notificationName = notificationName;
              });
            },
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Expanded(
                  child: Text(
                    "How many times before the course starts do you want to be notified?",
                  ),
                ),
                DropdownButton<String>(
                  value: dropdownValue,
                  items: <String>['5min', '10min', '15min', '30min', '1hr']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      dropdownValue = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 128,
          ),
          ElevatedButton(
              onPressed: () async {
                await _addNotification();
                Navigator.pop(context);
              },
              child: const Text('Create Notification'))
        ],
      ),
    );
  }

  Future<void> _addNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final array = prefs.getStringList('notifications') ?? [];
    final timesArray = prefs.getStringList('timesSchedules') ?? [];
    Map<String, dynamic> data = {
      'notificationName': _notificationName,
      'time': dropdownValue,
      'type': 'schedule',
    };
    String jsonData = jsonEncode(data);

    timesArray.add(dropdownValue);
    array.add(jsonData);
    await prefs.setStringList('notifications', array);
  }
}
