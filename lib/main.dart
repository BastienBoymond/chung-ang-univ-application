import 'dart:convert';

import 'package:cau_app_dev/screens/LoginPage.dart';
import 'package:cau_app_dev/screens/cafeteria/menu_service.dart';
import 'package:cau_app_dev/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '/screens/home/home_screen.dart';
import '/screens/cafeteria/cafeteria_screen.dart';
import '/screens/schedule/schedule_screen.dart';
import '/screens/settings/settings.dart';
import '../themes/theme_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  print("Callback Dispatcher called");

  Workmanager().executeTask((task, inputData) async {
    print("Native called background task: $task");
    if (task == "simplePeriodicTaskSchedule") {
      await NotificationService.sendNotificationForSchedule();
      return Future.value(true);
    }
    if (task.contains("foodPeriodicSearch")) {
      return NotificationService.sendNotificationForLunch();
    }
    return Future.value(false);
  });
}

bool shouldUseFirestoreEmulator = false;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  if (shouldUseFirestoreEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  print("Initializing Workmanager");
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  print("Initialized Notification Service");
  NotificationService.initializeNotification();
  FlutterNativeSplash.remove();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            theme: themeProvider.currentTheme,
            home: StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return MyHomePage();
                } else {
                  return const LoginPage();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    ScheduleScreen(),
    CafeteriaScreen(),
    SettingsPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.5),
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Theme.of(context).primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
            backgroundColor: Theme.of(context).primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Cafeteria',
            backgroundColor: Theme.of(context).primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Use UTC time to avoid issues with daylight saving time
    DateTime nowUtc = DateTime.now().toUtc();
    DateTime tomorrowAt10AM =
        DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day + 1, 10, 0);
    Duration initialDelayLunch = tomorrowAt10AM.difference(nowUtc);
    DateTime tomorrowAt8AM =
        DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day + 1, 8, 0);
    Duration initialDelay = tomorrowAt8AM.difference(nowUtc);

    print("Registering periodic tasks");
    Workmanager().registerPeriodicTask(
      'NotificationSchedule',
      "simplePeriodicTaskSchedule",
      frequency: const Duration(days: 1),
      initialDelay: initialDelay,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    Workmanager().registerPeriodicTask(
      'NotificationFood',
      "foodPeriodicSearch",
      frequency: const Duration(days: 1),
      initialDelay: initialDelayLunch,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
