import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherComponent extends StatefulWidget {
  @override
  _WeatherComponentState createState() => _WeatherComponentState();
}

class _WeatherComponentState extends State<WeatherComponent> {
  String cityName = '';
  Map<String, dynamic>? weatherData;
  String? error;

  Future<void> fetchWeatherData() async {
    try {
      final response = await http.get(
          Uri.parse('https://api.weatherapi.com/v1/current.json?key=e6d1c49a4e4041c1a04123138230409&q=$cityName&aqi=no'));
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        setState(() {
          error = data['error']['message'];
        });
      } else {
        setState(() {
          weatherData = data;
          error = null;
        });
      }
    } catch (err) {
      setState(() {
        error = 'Une erreur est survenue lors de la récupération des données météorologiques.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0.25,
          ),
        ],
      ),
      margin: EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xFFDDDDDD),
              hintText: 'Enter city name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onChanged: (value) {
              setState(() {
                cityName = value;
              });
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: fetchWeatherData,
            child: Text('Validate'),
            style: ElevatedButton.styleFrom(
              primary: Colors.purple,
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                error!,
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          if (weatherData != null)
            Container(
              margin: EdgeInsets.only(top: 20),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    spreadRadius: 0.25,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text('City Name: ${weatherData!['location']['name']}', style: TextStyle(fontSize: 18)),
                  Text('Country: ${weatherData!['location']['country']}', style: TextStyle(fontSize: 18)),
                  Text('Temperature: ${weatherData!['current']['temp_c']} °C', style: TextStyle(fontSize: 18)),
                  Text('Condition: ${weatherData!['current']['condition']['text']}', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
