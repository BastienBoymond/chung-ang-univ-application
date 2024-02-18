import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cau_app_dev/screens/cafeteria/menu_service.dart';
import 'package:cau_app_dev/screens/schedule/schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: Colors.teal,
        ledColor: Colors.teal,
        playSound: true,
        enableVibration: true,
        onlyAlertOnce: true,
      )
    ]);
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceived,
    );
  }

  static Future<void> onActionReceived(
      ReceivedAction receivedNotification) async {
    debugPrint('Action received: ${receivedNotification.toString()}');
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    int intervalBeforeNotification = 5,
  }) async {
    String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'basic_channel',
        title: title,
        body: body,
      ),
      schedule: NotificationInterval(
          interval: intervalBeforeNotification,
          timeZone: localTimeZone,
          repeats: false),
    );
  }

  static Future<bool> sendNotificationForLunch() async {
    final prefs = await SharedPreferences.getInstance();
    final foods = prefs.getStringList('foodList') ?? [];
    for (var food in foods) {
      final result = await searchMealNotification(food);
      if (result.result) {
        late String time = 'Morning';
        switch (result.time) {
          case '10':
            time = 'Breeakfast';
            break;
          case '20':
            time = 'Lunch';
            break;
          case '40':
            time = 'Dinner';
            break;
        }
        await NotificationService.showNotification(
            title: "There is a food you want!",
            body:
                "In the ${result.building} during the ${result.time} there is a meal with ${food} that you ask!");
      }
    }
    return Future.value(true);
  }

  static Future<bool> sendNotificationForSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final timesSchedules = prefs.getStringList('timesSchedules') ?? [];
    final studentId = prefs.getString('studentId') ?? '';

    if (studentId.isEmpty) {
      return Future.value(false);
    }
    final schedules = await fetchSchedule(studentId);
    final days = await getTodayDaySchedule(schedules);
    if (days.isEmpty) {
      return Future.value(false);
    }
    for (var day in days) {
      for (var timeInterval in timesSchedules) {
        // Convert timeInterval to seconds
        int intervalInSeconds = convertTimeIntervalToSeconds(timeInterval);

        // Parse the start time to a DateTime object
        List<String> timeParts = day.startTime.split(':');
        int hours = int.parse(timeParts[0]);
        int minutes = int.parse(timeParts[1]);

        DateTime startTime = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          hours,
          minutes,
        );

        // Calculate the time difference in seconds between now and the notification time
        int notificationTime = startTime.difference(DateTime.now()).inSeconds;

        // Adjust notification time by subtracting the interval
        notificationTime -= intervalInSeconds;

        // Schedule notification
        NotificationService.showNotification(
          title: "Upcoming Class of ${day.name}",
          body: "Your class is about to start in classroom ${day.classRoom}",
          intervalBeforeNotification: notificationTime,
        );
      }
    }
    return Future.value(true);
  }

  static int convertTimeIntervalToSeconds(String timeInterval) {
    switch (timeInterval) {
      case '5min':
        return 5 * 60;
      case '10min':
        return 10 * 60;
      case '15min':
        return 15 * 60;
      case '30min':
        return 30 * 60;
      case '1hr':
        return 60 * 60;
      default:
        return 0;
    }
  }
}
