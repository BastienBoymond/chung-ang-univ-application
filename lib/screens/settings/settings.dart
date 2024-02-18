import 'package:cau_app_dev/screens/LoginPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../services/readfile_service.dart';
import '../../themes/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authentification = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User get user => _authentification.currentUser!;
  TextEditingController _studentIdController = TextEditingController();
  late String _studentId = '';
  late String _language = '';
  late String _theme = '';
  late Map<String, dynamic> _languageMap = {};
  late List<String> _languageList = [];

  @override
  void initState() {
    super.initState();
    _loadStudentId();
    _loadLanguage();
    _loadLanguageList();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getString('selectedTheme') == null) {
        prefs.setString('selectedTheme', 'Light');
      }
      _theme = prefs.getString('selectedTheme') ?? 'Light';
    });
  }

  Future<void> _loadStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentId = prefs.getString('studentId') ?? '';
      _studentIdController.text = _studentId;
    });
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getString('language') == null) {
        prefs.setString('language', 'English');
        prefs.setString('languageCode', 'en');
      }
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _loadLanguageList() async {
    final languageData = await getLanguageData();
    setState(() {
      _languageMap = languageData;
      _languageList = _languageMap.keys.toList();
    });
  }

  Future<void> _saveStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('studentId', _studentIdController.text);
    setState(() {
      _studentId =
          _studentIdController.text; // Update the student ID in the widget
    });
    final currentUser = _authentification.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'studentId': _studentIdController.text,
      });
    }
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Student ID saved successfully!'),
    ));
  }

  Future<void> _saveLanguage(String tempLanguage) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('language', tempLanguage);
    prefs.setString('languageCode', _languageMap[tempLanguage]);
    final currentUser = _authentification.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'languagePreference': tempLanguage,
        'languagePreferenceCode': _languageMap[tempLanguage],
      });
    }
    // ignore: use_build_context_synchronously
    setState(() {
      _language = tempLanguage;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Language saved successfully!'),
    ));
  }

  Future<void> _saveTheme(String theme, ThemeProvider themeProvider) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedTheme', theme);
    final currentUser = _authentification.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'selectedTheme': theme,
      });
    }
    // ignore: use_build_context_synchronously
    setState(() {
      _theme = theme;
      themeProvider.reloadTheme();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Theme saved successfully!'),
    ));
  }

  // Function to show the dialog for changing the student ID
  Future<void> _showChangeStudentIdDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Student ID'),
          content: TextField(
            controller: _studentIdController,
            decoration: const InputDecoration(labelText: 'New Student ID'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                _saveStudentId();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangeLanguageDialog() async {
    String _tempLanguage = _language;
    final prefs = await SharedPreferences.getInstance();

    // ignore: use_build_context_synchronously
    await showDialog(
      context: context, // Use the captured context here
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Language'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select Language"),
                  DropdownButton<String>(
                    value: _tempLanguage,
                    onChanged: (String? newValue) {
                      setState(() {
                        _tempLanguage = newValue!; // Update _tempLanguage
                      });
                    },
                    items: _languageList
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child:
                      const Text('Save', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    _saveLanguage(_tempLanguage);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showChangeThemeDialog(ThemeProvider themeProvider) async {
    String _tempTheme = _theme;
    final prefs = await SharedPreferences.getInstance();

    // ignore: use_build_context_synchronously
    await showDialog(
      context: context, // Use the captured context here
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Theme'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select Theme"),
                  DropdownButton<String>(
                    value: _tempTheme,
                    onChanged: (String? newValue) {
                      setState(() {
                        _tempTheme = newValue!; // Update _tempTheme
                      });
                    },
                    items: <String>['Light', 'Dark']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child:
                      const Text('Save', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    _saveTheme(_tempTheme, themeProvider);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Settings')),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Student ID'),
              subtitle: Text(_studentId),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showChangeStudentIdDialog();
                },
              ),
            ),
            // Selector to change language of application
            ListTile(
              title: const Text('Language'),
              subtitle: Text(_language),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showChangeLanguageDialog();
                },
              ),
            ),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(_theme),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showChangeThemeDialog(themeProvider);
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Confirm with user before clearing all notifications
                final confirm = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Clear all notifications?'),
                      content: const Text(
                          'This will delete all notifications you have created.'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        TextButton(
                          child: const Text('Confirm',
                              style: TextStyle(color: Colors.blue)),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ],
                    );
                  },
                );
                if (!confirm!) {
                  return;
                }
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setStringList('notifications', []);
                });
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setStringList('foodList', []);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification deleted.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Clear all notifications'),
            ),
            ElevatedButton(
              onPressed: () {
                _authentification.signOut();
                // navigate to login page
                // Navigator.pushReplacement(context,
                //     MaterialPageRoute(builder: (context) {
                //   return const LoginPage();
                // }));
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) =>
                      false, // Removes all existing routes from the stack
                );
              },
              child: const Text('Disconnect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
