import 'dart:convert';
import 'package:cau_app_dev/services/translation_service.dart';
import 'package:http/http.dart' as http;
import 'menu_item.dart'; // Import the MenuItem class

export 'menu_service.dart';

Future<List<MenuItem>> fetchMenuItems(
    String mealTime, DateTime selectedDate) async {
  final apiUrl =
      'https://mportal.cau.ac.kr/portlet/p005/p005.ajax'; // Replace with your API URL

  // Define the request headers, if needed
  final Map<String, String> headers = {
    'Content-Type': 'application/json', // Adjust the content type as needed
  };

  // Calculate the difference in days between the selected date and today
  final differenceInDays = selectedDate.difference(DateTime.now()).inDays;

  print("TODAY IS ${DateTime.now()}");
  print("SELECTED DATE IS ${selectedDate}");
  final DateTime today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final DateTime selectedDay =
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

  // Adjust the 'daily' value based on the date
  final Map<String, dynamic> requestBody = {
    'daily':
        '${today.isBefore(selectedDay) ? differenceInDays + 1 : differenceInDays}',
    'tabs': '1',
    'tabs2': '20',
  };

  // Adjust the 'daily' value based on the date
  print('$mealTime');
  switch (mealTime) {
    case "Morning":
      requestBody["tabs2"] = '10';
      break;
    case "Noon":
      requestBody["tabs2"] = '20';
      break;
    case "Afternoon":
      requestBody["tabs2"] = '40'; // Update to 'Afternoon'
      break;
  }

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: headers,
    body: jsonEncode(requestBody),
  );

  print('Request Body $requestBody');

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = json.decode(response.body);

    // Create a List of MenuItem objects by iterating through the buildings
    final List<MenuItem> menuItems = [];
    // print("response : $jsonResponse");

    jsonResponse.forEach((buildingKey, buildingValue) {
      if (buildingValue is List<dynamic>) {
        for (var item in buildingValue) {
          if (item['course'] != null && item['menuDetail'] != null) {
            menuItems.add(MenuItem(
              name: item['course'],
              description: item['menuDetail'],
              imageUrl: item['picPath'],
              price: item['price'],
              building: item['rest'],
              date: item['date'], // Include the date in MenuItem
              time: item['time'], // Include the time in MenuItem
            ));
          }
        }
      }
    });

    // Print the menuItems list for debugging purposes
    for (var menuItem in menuItems) {
      print('Name: ${menuItem.name}');
      print('Description: ${menuItem.description}');
      print('Image URL: ${menuItem.imageUrl}');
      print('Price: ${menuItem.price}');
      print('Building: ${menuItem.building}');
      print('Date: ${menuItem.date}'); // Print the date
      print('Time: ${menuItem.time}'); // Print the time
      print('---');
    }

    return menuItems;
  } else {
    throw Exception('Failed to load menu items');
  }
}

Future<MealNotification> searchMealNotification(String meal) async {
  final apiUrl = 'https://mportal.cau.ac.kr/portlet/p005/p005.ajax';
  final Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  final Map<String, dynamic> requestBody = {
    'daily': '0',
    'tabs': '1',
    'tabs2': '20',
  };
  final array = ['10', '20', '40'];
  for (var i = 0; i < array.length; i++) {
    requestBody['tabs2'] = array[i];
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: jsonEncode(requestBody),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      for (var buildingKey in jsonResponse.keys) {
        var buildingValue = jsonResponse[buildingKey];

        if (buildingValue is List<dynamic>) {
          for (var item in buildingValue) {
            if (item['course'] != null && item['menuDetail'] != null) {
              final name = await translateText(item['course']);
              final description = await translateText(item['menuDetail']);
              if (name.contains(meal) || description.contains(meal)) {
                return Future.value(MealNotification(
                    result: true,
                    meal: name,
                    time: item['time'],
                    building: item['rest']));
              }
            }
          }
        }
      }
    }
  }
  return Future.value(
      MealNotification(result: false, meal: '', time: '', building: ''));
}
