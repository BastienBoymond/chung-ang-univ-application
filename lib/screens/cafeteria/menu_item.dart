import 'package:flutter/material.dart';

// Export the MenuItem class
export 'menu_item.dart';

class MenuItem {
  final String name;
  final String description;
  final String imageUrl;
  final String price; // Add price field
  final String building; // Add building field
  final String date; // Add date field
  final String time; // Add time field

  MenuItem({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.building,
    required this.date,
    required this.time,
  });
}

class MealNotification {
  final bool result;
  final String meal;
  final String time;
  final String building;

  MealNotification({
    required this.result,
    required this.meal,
    required this.time,
    required this.building,
  });
}
