import 'package:flutter/material.dart';
import 'menu_item.dart';
import 'menu_service.dart';
import '../../services/translation_service.dart';
import '../../themes/theme_provider.dart';
import 'package:provider/provider.dart';

class CafeteriaScreen extends StatefulWidget {
  @override
  _CafeteriaScreenState createState() => _CafeteriaScreenState();
}

class _CafeteriaScreenState extends State<CafeteriaScreen>
    with TickerProviderStateMixin {
  String selectedMealTime = "Morning";
  late TabController _tabController;
  int _selectedBuildingIndex = 0;
  late Future<List<MenuItem>> _menuItemsFuture;
  final Color customPrimaryColor = Color.fromRGBO(12, 33, 138, 1.0);

  DateTime selectedDate = DateTime.now(); // Default to today

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedBuildingIndex = _tabController.index;
      });
    });
    _menuItemsFuture = fetchMenuItems(selectedMealTime, selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return MaterialApp(
      title: 'Cafeteria Menu',
      theme: themeProvider.currentTheme,
      // theme: ThemeData(
      //   primaryColor: customPrimaryColor,
      // ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            elevation: 4,
            backgroundColor: Theme.of(context).primaryColor,
            title: Text(
              'Cafeteria Menu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ],
            bottom: TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 4.0,
              tabs: [
                Tab(icon: Icon(Icons.wb_sunny)),
                Tab(icon: Icon(Icons.brightness_4)),
                Tab(icon: Icon(Icons.brightness_5)),
              ],
              onTap: (index) {
                setState(() {
                  switch (index) {
                    case 0:
                      selectedMealTime = "Morning";
                      break;
                    case 1:
                      selectedMealTime = "Noon";
                      break;
                    case 2:
                      selectedMealTime = "Afternoon";
                      break;
                  }
                  _selectedBuildingIndex = 0;
                  _menuItemsFuture =
                      fetchMenuItems(selectedMealTime, selectedDate);
                });
              },
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                // child: Text(
                //   "${_formatDate(selectedDate)}",
                //   style: TextStyle(
                //     fontSize: 18,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
              ),
              _buildBanner(),
              Expanded(
                child: _buildBuildingTabs(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      color: Colors.blue.withOpacity(0.2), // Adjust the color as needed
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            "Meals for Building ${_selectedBuildingIndex + 1}", // Update the text as needed
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "${_formatDate(selectedDate)}",
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingTabs() {
    return FutureBuilder<List<MenuItem>>(
      future: _menuItemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No menu items available.'));
        } else {
          final menuItems = snapshot.data!;
          final buildingNumbers = _extractBuildingNumbers(menuItems).toList();

          if (_tabController.length != buildingNumbers.length) {
            _tabController =
                TabController(length: buildingNumbers.length, vsync: this);
            _tabController.addListener(() {
              setState(() {
                _selectedBuildingIndex = _tabController.index;
              });
            });
          }

          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: buildingNumbers.map((buildingNumber) {
                    final buildingMenuItems =
                        _filterMenuItemsByBuilding(menuItems, buildingNumber);
                    return GestureDetector(
                      child: BuildingMenuScreen(
                        mealTime: _capitalize(selectedMealTime),
                        buildingNumber: buildingNumber,
                        menuItems: buildingMenuItems,
                        translateMenuItem: _translateMenuItem,
                        selectedDate: selectedDate,
                      ),
                    );
                  }).toList(),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: buildingNumbers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final buildingNumber = entry.value;
                    return GestureDetector(
                      onTap: () {
                        _tabController.animateTo(index);
                        _selectedBuildingIndex = index;
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedBuildingIndex == index
                              ? Colors.blue.withOpacity(0.5)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Tab(
                          text: buildingNumber,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  String _capitalize(String mealTime) {
    return mealTime[0].toUpperCase() + mealTime.substring(1);
  }

  Set<String> _extractBuildingNumbers(List<MenuItem> menuItems) {
    final buildingNumbers = <String>{};
    final addedNumbers = <String>{};

    for (var menuItem in menuItems) {
      final buildingName = menuItem.building;
      final regex = RegExp(r'\d+');
      final matches = regex.allMatches(buildingName);

      for (var match in matches) {
        final buildingNumber = match.group(0)!;
        if (!addedNumbers.contains(buildingNumber)) {
          addedNumbers.add(buildingNumber);
          buildingNumbers.add(buildingNumber);
        }
      }
    }

    return buildingNumbers;
  }

  List<MenuItem> _filterMenuItemsByBuilding(
      List<MenuItem> menuItems, String buildingNumber) {
    return menuItems
        .where((menuItem) => menuItem.building.contains(buildingNumber))
        .toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        _menuItemsFuture = fetchMenuItems(selectedMealTime, selectedDate);
        print("Selected date: $selectedDate");
      });
    }
  }

  Future<MenuItem> _translateMenuItem(MenuItem menuItem) async {
    final translatedName = await translateText(menuItem.name);
    final translatedDescription = await translateText(menuItem.description);
    return MenuItem(
      name: translatedName,
      description: translatedDescription,
      imageUrl: menuItem.imageUrl,
      building: menuItem.building,
      price: menuItem.price,
      date: menuItem.date,
      time: menuItem.time,
    );
  }
}

class BuildingMenuScreen extends StatelessWidget {
  final String mealTime;
  final String buildingNumber;
  final List<MenuItem> menuItems;
  final Future<MenuItem> Function(MenuItem) translateMenuItem;
  final DateTime selectedDate;

  BuildingMenuScreen({
    required this.mealTime,
    required this.buildingNumber,
    required this.menuItems,
    required this.translateMenuItem,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.builder(
        itemCount: menuItems.length,
        itemBuilder: (BuildContext context, int index) {
          final menuItem = menuItems[index];

          return FutureBuilder<MenuItem>(
            future: translateMenuItem(menuItem),
            builder: (BuildContext context, AsyncSnapshot<MenuItem> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData) {
                return Center(child: Text('Translating...'));
              } else {
                final translatedMenuItem = snapshot.data!;

                return GestureDetector(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Aligns items to the top
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    translatedMenuItem.imageUrl,
                                    fit: BoxFit.cover,
                                    height: 80,
                                    width: 80,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        translatedMenuItem.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        translatedMenuItem.description,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Colors.black,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  translatedMenuItem.time,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              "${translatedMenuItem.price}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
