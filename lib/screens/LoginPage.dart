import 'package:cau_app_dev/main.dart';
import 'package:cau_app_dev/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'RegisterPage.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        // TRY THIS: Try changing the color of the AppBar. Notice that the
        // status bar color changes to match. This is because the AppBar's
        // default backgroundColor is transparent. If you want to avoid this,
        // you can set the AppBar's backgroundColor to Colors.transparent.
        // backgroundColor: Colors.green,
      ),
      body: LoginForm(),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _authentification = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              onChanged: (value) {
                email = value;
              },
            ),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              onChanged: (value) {
                password = value;
                ;
              },
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                onPressed: () async {
                  try {
                    final themeProvider =
                        Provider.of<ThemeProvider>(context, listen: false);
                    final currentUser =
                        await _authentification.signInWithEmailAndPassword(
                            email: email, password: password);
                    if (currentUser.user != null) {
                      _formKey.currentState!.reset();
                      DocumentSnapshot querySnapshot = await FirebaseFirestore
                          .instance
                          .collection('users')
                          .doc(currentUser.user!.uid)
                          .get();
                      if (querySnapshot.exists) {
                        Map<String, dynamic> data =
                            querySnapshot.data() as Map<String, dynamic>;
                        print(data);
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.setString(
                            'languageCode', data['languagePreferenceCode']);
                        prefs.setString("studentId", data['studentId']);
                        prefs.setString('selectedTheme', data["selectedTheme"]);
                        prefs.setString('language', data['languagePreference']);
                        themeProvider.reloadTheme();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => MyHomePage()),
                          (route) =>
                              false, // Removes all existing routes from the stack
                        );
                      }
                    }
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Text('Enter')),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("If you did not register"),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterPage()));
                  },
                  child: const Text('Register your email'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
