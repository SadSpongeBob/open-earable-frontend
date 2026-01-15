import 'package:flutter/material.dart';

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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _Btn(
            asset: 'assets/buttons/back_to_projects.png',
            width: 76,
            height: 44,
            onTap: onBackToProjects,
            semanticLabel: 'Back to projects',
          ),

          const Text(
            "< Projects",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F1F),
            ),
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
