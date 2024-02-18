import 'dart:convert';

import 'package:cau_app_dev/screens/home/lunch_notification_screen.dart';
import 'package:cau_app_dev/services/notification_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cau_app_dev/themes/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'schedule_notification_screen.dart';
export 'home_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/scheduleNotification': (context) =>
            const ScheduleNotificationScreen(),
        '/lunchNotification': (context) => const LunchNotificationScreen(),
      },
      theme: Provider.of<ThemeProvider>(context).currentTheme,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List> notificationCreatedFuture;

  @override
  void initState() {
    super.initState();
    notificationCreatedFuture = loadNotificationCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Home')),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          formRegisterNotification(),
          // line to separate
          const Divider(
            height: 20,
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          SizedBox(
            height: 20,
          ),
          FutureBuilder(
            future: notificationCreatedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                if (snapshot.data!.isEmpty) {
                  return const Text('No notification created');
                } else {
                  return listCreatedNotification(snapshot.data!);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget formRegisterNotification() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(
            height: 16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/scheduleNotification');
                  setState(() {
                    notificationCreatedFuture = loadNotificationCreated();
                  });
                },
                child: const Text('Schedule Notification'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/lunchNotification');
                  setState(() {
                    notificationCreatedFuture = loadNotificationCreated();
                  });
                },
                child: const Text('Lunch Notification'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List> loadNotificationCreated() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationCreated = prefs.getStringList('notifications') ?? [];

    // Convert the JSON Strings back to Maps
    print(notificationCreated);
    List notifications = notificationCreated.map((jsonString) {
      return jsonDecode(jsonString);
    }).toList();

    return notifications;
  }

  Widget listCreatedNotification(List notificationCreated) {
    return Expanded(
      child: notificationCreated.isEmpty
          ? const Center(
              child: Text(
                'No notifications created.',
                style: TextStyle(fontSize: 16.0),
              ),
            )
          : ListView.separated(
              itemCount: notificationCreated.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key('$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    alignment: Alignment.centerRight,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) async {
                    final prefs = await SharedPreferences.getInstance();
                    Workmanager().cancelByUniqueName(
                        notificationCreated[index]['notificationName']);

                    if (notificationCreated[index]['type'] == 'lunch') {
                      final foodList = prefs.getStringList('foodList') ?? [];
                      foodList.remove(notificationCreated[index]['food']);
                      prefs.setStringList('foodList', foodList);
                    }
                    setState(() {
                      notificationCreated.removeAt(index);
                      // Convert the Maps back to JSON Strings
                      List<String> jsonStringList =
                          notificationCreated.map((notification) {
                        return jsonEncode(notification);
                      }).toList();

                      prefs.setStringList('notifications', jsonStringList);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification deleted.'),
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text(notificationCreated[index]['notificationName']),
                    // Add other ListTile properties as needed
                  ),
                );
              },
            ),
    );
  }
}
