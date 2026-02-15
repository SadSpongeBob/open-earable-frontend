import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart' hide logger;
import 'package:openearable/features/sensors/state/sensor_state.dart';

class SensorChart extends ConsumerStatefulWidget {
  final bool allowToggleAxes;
  final String deviceId;
  final int sensorIndex;

  const SensorChart({
    super.key,
    this.allowToggleAxes = true,
    required this.deviceId,
    required this.sensorIndex,
  });

  @override
  ConsumerState<SensorChart> createState() => _SensorChartState();
}

class _SensorChartState extends ConsumerState<SensorChart> {
  late Map<String, bool> _axisEnabled;

  @override
  void initState() {
    super.initState();
    final provider = ref.read(sensorDataProviderFamily((widget.deviceId, widget.sensorIndex)));
    _axisEnabled = { for (var axis in provider.sensor.axisNames) axis: true };
  }

  void _toggleAxis(String axisName, bool value) {
    setState(() {
      _axisEnabled[axisName] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sensorData = ref.watch(
      sensorDataProviderFamily((widget.deviceId, widget.sensorIndex)),
    );
    final sensor = sensorData.sensor;
    final enabledAxes = sensor.axisNames
        .where((axis) => _axisEnabled[axis] ?? false)
        .toList();
    final axisData = _buildAxisData(sensorData.sensor, sensorData.sensorValues);
    
    return Column(
      children: [
        if (widget.allowToggleAxes)
          Wrap(
            spacing: 8,
            children: sensor.axisNames.map((axisName) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _axisEnabled[axisName],
                    checkColor: Colors.white,
                    activeColor: _axisColor(axisName, sensor),
                    onChanged: (value) =>
                        _toggleAxis(axisName, value ?? false),
                  ),
                  Text(axisName),
                ],
              );
            }).toList(),
          ),
        Expanded(
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(enabled: true),
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: Text(sensor.axisUnits.first),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: Text('Time (s)'),
                  axisNameSize: 30,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: enabledAxes.map((axisName) {
                return LineChartBarData(
                  spots: axisData[axisName] ?? [],
                  isCurved: false,
                  barWidth: 2,
                  color: _axisColor(axisName, sensor),
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 0),
          ),
        ),
      ],
    );
  }

  Map<String, List<FlSpot>> _buildAxisData(Sensor sensor, Queue<SensorValue> buffer) {
    if (buffer.isEmpty) return { for (var axis in sensor.axisNames) axis: [] };

    final scale = pow(10, -sensor.timestampExponent).toDouble();

    return {
      for (int i = 0; i < sensor.axisCount; i++)
        sensor.axisNames[i]: buffer.map((v) {
          final x = v.timestamp.toDouble() / scale;
          final y = v is SensorDoubleValue
              ? v.values[i]
              : (v as SensorIntValue).values[i].toDouble();
          return FlSpot(x, y);
        }).toList(),
    };
  }

  Color _axisColor(String axisName, Sensor sensor) {
    final index = sensor.axisNames.indexOf(axisName);

    final appPalette = [
    Colors.blue,       
    Colors.red,        
    Colors.purple,     
    Colors.pink,       
    Colors.cyan,       
    Colors.deepPurple,
    Colors.indigoAccent,
    ];

    return appPalette[index % appPalette.length];
  }
}
