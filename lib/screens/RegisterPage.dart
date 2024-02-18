import 'package:cau_app_dev/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: RegisterForm(),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({Key? key}) : super(key: key);

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _authentification = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String studentID = ''; // New variable for studentID

  @override
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
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              onChanged: (value) {
                password = value;
              },
            ),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Student ID',
              ),
              onChanged: (value) {
                studentID = value;
              },
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final newUser =
                      await _authentification.createUserWithEmailAndPassword(
                          email: email, password: password);
                  if (newUser.user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(newUser.user!.uid)
                        .set({
                      'uid': newUser.user!.uid,
                      'studentId': studentID, // Save studentID
                      'selectedTheme': 'Light',
                      'languagePreferenceCode': 'en',
                      'languagePreference': 'English',
                    });
                    await _authentification.signOut();
                    if (!mounted) return;
                    _formKey.currentState!.reset();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully registered'),
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  print(e);
                }
              },
              child: const Text('Enter'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("If you already registered"),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('log with your email'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
