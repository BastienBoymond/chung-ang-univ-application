import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class LunchNotificationScreen extends StatefulWidget {
  const LunchNotificationScreen({Key? key}) : super(key: key);

  @override
  _LunchNotificationScreenState createState() =>
      _LunchNotificationScreenState();
}

class _LunchNotificationScreenState extends State<LunchNotificationScreen> {
  String _notificationName = '';
  String _foodSearch = '';

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
          const SizedBox(
            height: 16,
          ),
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Food you want to be notified about',
            ),
            onChanged: (food) {
              setState(() {
                _foodSearch = food;
              });
            },
          ),
          ElevatedButton(
              onPressed: () async {
                await addScheduleFood();
                Navigator.pop(context);
              },
              child: const Text('Lunch Notification')),
        ],
      ),
    );
  }

  Future<void> addScheduleFood() async {
    final prefs = await SharedPreferences.getInstance();
    final foods = prefs.getStringList('foodList') ?? [];
    foods.add(_foodSearch);
    await prefs.setStringList('foodList', foods);

    final array = prefs.getStringList('notifications') ?? [];
    Map<String, dynamic> data = {
      'notificationName': _notificationName,
      'food': _foodSearch,
      'type': 'lunch',
    };

    // Convert the Map to a JSON String
    String jsonData = jsonEncode(data);

    array.add(jsonData);
    await prefs.setStringList('notifications', array);
  }
}
