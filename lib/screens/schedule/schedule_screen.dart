import 'package:cau_app_dev/screens/schedule/schedule_item.dart';
import 'package:cau_app_dev/screens/schedule/schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../themes/theme_provider.dart';

class ScheduleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return MaterialApp(
      title: 'Schedule',
      theme: themeProvider.currentTheme,
      home: FutureBuilder<int>(
        future: _getDefaultTabIndex(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return DefaultTabController(
              length: 6,
              initialIndex: snapshot.data ?? 0, // Set the default tab index
              child: Scaffold(
                appBar: AppBar(
                  title: const Center(child: Text('Schedule')),
                  backgroundColor: Theme.of(context).primaryColor,
                  actions: [
                    IconButton(
                      onPressed: () {
                        // Clear the student ID and reload the widget
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.remove('studentId');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScheduleScreen(),
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.refresh),
                    )
                  ],
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'M'),
                      Tab(text: 'T'),
                      Tab(text: 'W'),
                      Tab(text: 'T'),
                      Tab(text: 'F'),
                      Tab(text: 'S'),
                    ],
                  ),
                ),
                body: FutureBuilder<String>(
                  future: getStudentId(),
                  builder: ((context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      final studentId =
                          snapshot.data ?? ''; // Get the String value
                      if (studentId.isEmpty) {
                        return Column(
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Enter your student ID',
                              ),
                              onChanged: (value) async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString('studentId', value);
                              },
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Reload the widget
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScheduleScreen(),
                                  ),
                                );
                              },
                              child: const Text('Submit'),
                            ),
                          ],
                        );
                      }
                      return loadSchedule(studentId);
                    }
                  }),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<int> _getDefaultTabIndex() async {
    // Get the current day and calculate the corresponding tab index
    final now = DateTime.now();
    return (now.weekday - 1) % 6;
  }

  Future<String> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('studentId') ?? "";
  }

  Widget loadSchedule(String studentId) {
    return FutureBuilder<Map<String, List<ScheduleItem>>>(
      future: fetchSchedule(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return _buildSchedule(snapshot.data!);
        }
      },
    );
  }

  Widget _buildSchedule(Map<String, List<ScheduleItem>> schedule) {
    return TabBarView(
      children: [
        _buildScheduleList(schedule['d1']!),
        _buildScheduleList(schedule['d2']!),
        _buildScheduleList(schedule['d3']!),
        _buildScheduleList(schedule['d4']!),
        _buildScheduleList(schedule['d5']!),
        _buildScheduleList(schedule['d6']!),
      ],
    );
  }

  Widget _buildScheduleList(List<ScheduleItem> scheduleItems) {
    if (scheduleItems.isEmpty) {
      return const Center(child: Text('No classes today'));
    }
    return ListView.builder(
      itemCount: scheduleItems.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            _buildScheduleStartEnd(context, scheduleItems[index], true),
            _buildScheduleItem(scheduleItems[index]),
          ],
        );
      },
    );
  }

  Widget _buildScheduleStartEnd(
      BuildContext context, ScheduleItem item, bool isStart) {
    if (isStart) {
      return ListTile(
        title: Text(item.startTime),
        tileColor: item.color,
      );
    }
    return ListTile(
      title: Text(item.endTime),
    );
  }

  Widget _buildScheduleItem(ScheduleItem item) {
    return ListTile(
      title: Text(item.name),
      subtitle:
          Text('Building: ${item.building}, Classroom: ${item.classRoom}'),
      trailing: Text(item.teacherName),
      tileColor: item.color,
    );
  }
}
