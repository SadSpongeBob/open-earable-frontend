import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/features/sensors/widgets/sensor_configuration_view.dart';
import 'package:openearable/features/sensors/widgets/sensors_values.dart';
import 'package:openearable/app/widgets/bluetooth_button.dart';
import 'package:openearable/app/theme/text_styles.dart';
import '../../../app/routing/routes.dart';

class SensorPage extends StatelessWidget {
  final VoidCallback onBluetooth;
  final bool isRecordingSource;

  SensorPage({
    super.key,
    required this.onBluetooth,
    this.isRecordingSource = false,
  });

  final GlobalKey _sensorBluetoothKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFE6E6E6),
        body: Row(
          children: [
            // LEFT SIDE MENU (Configuration Panel)
            Container(
              width: 280,
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFFF2F2F2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF8F8F8F),
                    blurRadius: 30,
                    offset: Offset(-3, 0),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    child: BluetoothButton(
                      buttonKey: _sensorBluetoothKey, 
                      onPressed: onBluetooth
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SensorConfigurationView(
                      onSetConfigPressed: () {},
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (isRecordingSource) {
                            context.go(Routes.recording);
                          } else {
                            context.go(Routes.home);
                          }
                        },
                        child: SizedBox(
                          height: 120,
                          width: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                isRecordingSource
                                    ? 'assets/buttons/shutter.png'
                                    : 'assets/buttons/projects.png',
                                width: 70,
                                height: 70,
                              ),
                              const SizedBox(width: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_back_ios_new_rounded, size: 17),
                                  const Text(" Go Back", style: GlobalTextStyles.footnoteMedium),
                                ],
                              ),
                            ],
                          )
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // RIGHT SIDE CONTENT (Charts)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Sensors",
                      style: GlobalTextStyles.titleBold,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SensorValues(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
