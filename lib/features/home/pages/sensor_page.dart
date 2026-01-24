import 'package:flutter/material.dart';
import 'package:openearable/features/home/pages/sensor_configuration_view.dart';
import 'package:openearable/features/home/pages/sensors_values_page.dart';

class SensorPage extends StatelessWidget {
  const SensorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // LEFT SIDE MENU (Configuration Panel)
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: SensorConfigurationView(
                    onSetConfigPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          // RIGHT SIDE CONTENT (Charts)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sensors",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: SensorValuesPage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
