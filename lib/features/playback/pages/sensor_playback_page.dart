import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/app/widgets/app_button.dart';

class SensorPlaybackPage extends StatefulWidget {
  final Sensor sensor;

  const SensorPlaybackPage({super.key, required this.sensor});

  @override
  State<SensorPlaybackPage> createState() => _SensorPlaybackPageState();
}

class _SensorPlaybackPageState extends State<SensorPlaybackPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
          child: Row(
            children: [
              AppButton.dangerGhost(
                text: 'Back',
                onPressed: context.pop,
                fullWidth: false,
                textStyle: AppTextStyles.footerMedium,
              ),
              const Spacer(),
              Text(widget.sensor.name, style: AppTextStyles.titleBold),
              const Spacer(),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: Expanded(
          child: Scaffold(
            backgroundColor: AppColors.hundred,
            body: SafeArea(
              child: SizedBox()
            ),
          ),
        ),
      ),
    );
  }
}
