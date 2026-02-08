import 'package:flutter/material.dart';
import 'package:openearable/app/constants/colors.dart';

class RecordingLeftBar extends StatelessWidget {
  const RecordingLeftBar({
    super.key,
    required this.onBackToProjects,
  });

  final VoidCallback onBackToProjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      color: AppColors.fifty,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [

          SizedBox(height: 15),

          _Btn(
            asset: 'assets/buttons/back_to_projects.png',
            width: 76,
            height: 67,
            onTap: onBackToProjects,
            semanticLabel: 'Back to projects',
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.asset,
    required this.onTap,
    required this.semanticLabel,
    required this.width,
    required this.height,
  });

  final String asset;
  final VoidCallback onTap;
  final String semanticLabel;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              asset,
              width: width,
              height: height,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
