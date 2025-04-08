import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(AquacultureDashboard());
}

class AquacultureDashboard extends StatelessWidget {
  const AquacultureDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<FlSpot> temperatureSpots = [];
  List<FlSpot> pHSpots = [];
  List<FlSpot> tdsSpots = [];
  List<FlSpot> turbiditySpots = [];
  double xValue = 0;

  double temperature = 0;
  double pH = 0;
  double tds = 0;
  double turbidity = 0;
  double mq4 = 0;
  double humidity = 0;
  double rain = 0;
  String currentTime = DateFormat('hh:mm a').format(DateTime.now());

  String aiSuggestion = ""; // New variable for storing AI suggestions

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 5), (timer) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse("https://blynk.cloud/external/api/get?token=FbQw1KDQ3w-5698oJsygi9QC13xrWxng&V0")), // TDS
        http.get(Uri.parse("https://blynk.cloud/external/api/get?token=FbQw1KDQ3w-5698oJsygi9QC13xrWxng&V1")), // Turbidity
        http.get(Uri.parse("https://blynk.cloud/external/api/get?token=FbQw1KDQ3w-5698oJsygi9QC13xrWxng&V2")), // pH
        http.get(Uri.parse("https://blynk.cloud/external/api/get?token=FbQw1KDQ3w-5698oJsygi9QC13xrWxng&V3")), // MQ4
        http.get(Uri.parse("https://blynk.cloud/external/api/get?token=FbQw1KDQ3w-5698oJsygi9QC13xrWxng&V4")), // Temperature
        http.get(Uri.parse("https://blynk.cloud/external/api/get?token=FbQw1KDQ3w-5698oJsygi9QC13xrWxng&V5")), // Humidity
        http.get(Uri.parse("https://blynk.cloud/external/api/get?token=FbQw1KDQ3w-5698oJsygi9QC13xrWxng&V6")), // Rainfall
      ]);

      setState(() {
        tds = double.tryParse(responses[0].body) ?? 0;
        turbidity = double.tryParse(responses[1].body) ?? 0;
        pH = double.tryParse(responses[2].body) ?? 0;
        mq4 = double.tryParse(responses[3].body) ?? 0;
        temperature = double.tryParse(responses[4].body) ?? 0;
        humidity = double.tryParse(responses[5].body) ?? 0;
        rain = double.tryParse(responses[6].body) ?? 0;
        currentTime = DateFormat('hh:mm a').format(DateTime.now());

        temperatureSpots.add(FlSpot(xValue, temperature));
        pHSpots.add(FlSpot(xValue, pH));
        tdsSpots.add(FlSpot(xValue, tds));
        turbiditySpots.add(FlSpot(xValue, turbidity));

        xValue += 1;

        aiSuggestion = _generateAISuggestions(); // Store AI suggestions
      });
    } catch (e) {
      // Error handling
    }
  }

  String _generateAISuggestions() {
    String suggestion = "";

// AI conditions based on the provided picture
    if (temperature < 18) {
      suggestion += "🌡 Low Temperature! Consider increasing the temperature using heating mechanisms.\n";
    } else if (temperature >= 18 && temperature < 25) {
      suggestion += "🌡 Moderate Temperature! Maintain current conditions.\n";
    } else if (temperature >= 25 && temperature <= 30) {
      suggestion += "🌡 High Temperature! Consider aerating during cooler times to reduce heat buildup.\n";
    }

    if (pH < 6.5) {
      suggestion += "🧪 Low pH! Add lime or soda ash to stabilize the pH level.\n";
    } else if (pH >= 6.5 && pH < 8) {
      suggestion += "🧪 Optimal pH! Maintain current pH levels.\n";
    } else if (pH >= 8 && pH <= 9.75) {
      suggestion += "🧪 High pH! Add carbon dioxide to balance alkalinity.\n";
    }

    if (tds < 50) {
      suggestion += "💧 Low Water Hardness (TDS)! Check for potential low mineral content and adjust accordingly.\n";
    } else if (tds >= 50 && tds < 200) {
      suggestion += "💧 Moderate Water Hardness (TDS)! Water conditions are stable.\n";
    } else if (tds >= 200 && tds <= 300) {
      suggestion += "💧 High Water Hardness (TDS)! Consider partial water replacement to reduce hardness.\n";
    }

    if (turbidity > 50) {
      suggestion += "🌊 High Turbidity! Check for algae growth or sediment build-up.\n";
    }

    if (mq4 > 500) {
      suggestion += "🚨 High Gas Level (MQ4)! Improve aeration and monitor closely.\n";
    }

    if (humidity < 40) {
      suggestion += "💦 Low Humidity! Consider increasing surface aeration.\n";
    }

    if (rain > 10) {
      suggestion += "☔ Heavy Rainfall! Monitor water levels and possible overflow.\n";
    }

    return suggestion.isNotEmpty ? suggestion : "No issues detected. Conditions are normal.";
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Aquaculture Ponds Monitoring Dashboard')),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 10),
              _buildParameterGrid(),
              SizedBox(height: 10),
              _buildLegend(),
              SizedBox(height: 10),
              Expanded(child: _buildChart()),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.notifications),
              onPressed: () {
                _showAISuggestionsDialog(aiSuggestion); // Display suggestions when pressed
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAISuggestionsDialog(String suggestion) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("AI-Based Suggestions"),
          content: Text(suggestion),
          actions: [
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        Text(
          "Data Labels",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Temperature', Colors.red),
            _buildLegendItem('pH Level', Colors.green),
            _buildLegendItem('TDS', Colors.blue),
            _buildLegendItem('Turbidity', Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        SizedBox(width: 5),
        Text(title, style: TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildParameterGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLargeCard('Temperature', '$temperature °C'),
            _buildLargeCard('pH Level', pH.toString()),
            _buildLargeCard('TDS', '$tds ppm'),
            _buildLargeCard('Turbidity', '$turbidity NTU'),
          ],
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLargeCard('Gas Level (MQ4)', '$mq4 ppm'),
            _buildLargeCard('Humidity', '$humidity%'),
            _buildLargeCard('Rainfall', '$rain mm'),
            _buildLargeCard('Time', currentTime),
          ],
        ),
      ],
    );
  }

  Widget _buildLargeCard(String title, String value) {
    return Container(
      width: 140,
      height: 100,
      margin: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (temperatureSpots.isEmpty) {
      return Center(child: Text("Fetching Sensor Data's"));
    }
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: xValue,
          minY: 0,
          maxY: 100,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: EdgeInsets.only(bottom: 1), // Adjusted for better Y-axis space
                child: Text(
                  'Sensor Readings',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: EdgeInsets.only(top: 1), // Increased X-axis padding for spacing
                child: Text(
                  'Time (Seconds)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
          ),
          lineBarsData: [
            _buildLineChartBarData(temperatureSpots, Colors.red),
            _buildLineChartBarData(pHSpots, Colors.green),
            _buildLineChartBarData(tdsSpots, Colors.blue),
            _buildLineChartBarData(turbiditySpots, Colors.orange),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
    );
  }
}
