import 'package:flutter/material.dart';

export 'custom_tab.dart';

class CustomBuildingTabBar extends StatelessWidget {
  final List<String> buildingNumbers;
  final int selectedBuildingIndex;
  final ValueChanged<int> onBuildingTabSelected;

  CustomBuildingTabBar({
    required this.buildingNumbers,
    required this.selectedBuildingIndex,
    required this.onBuildingTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey, // Customize the background color
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            buildingNumbers.length,
            (index) => InkWell(
              onTap: () => onBuildingTabSelected(index),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: index == selectedBuildingIndex
                    ? Colors.white
                    : Colors.transparent,
                child: Text(
                  'Building ${buildingNumbers[index]}',
                  style: TextStyle(
                    color: index == selectedBuildingIndex
                        ? Colors.blue
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}