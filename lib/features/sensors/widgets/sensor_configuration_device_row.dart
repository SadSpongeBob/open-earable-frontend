import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/features/sensors/state/sensor_configuration_storage.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';
import 'package:openearable/features/sensors/widgets/save_config_row.dart';
import 'package:openearable/features/sensors/widgets/sensor_configuration_value_row.dart';
import 'package:openearable/app/theme/text_styles.dart';

/// A widget that displays a list of sensor configurations for a device.
class SensorConfigurationDeviceRow extends ConsumerStatefulWidget {
  final Wearable device;

  const SensorConfigurationDeviceRow({super.key, required this.device});

  @override
  ConsumerState<SensorConfigurationDeviceRow> createState() =>
      _SensorConfigurationDeviceRowState();
}

class _SensorConfigurationDeviceRowState
    extends ConsumerState<SensorConfigurationDeviceRow>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Widget> _content = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _updateContent();
      }
    });
    _content = [CircularProgressIndicator()];
    _updateContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFF2F2F2),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.device.hasCapability<SensorConfigurationManager>())
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildTabBar(context),
              ),
            ),
          ..._content,
        ],
      ),
    );
  }

  Future<void> _updateContent() async {
    final Wearable device = widget.device;

    if (!device.hasCapability<SensorConfigurationManager>()) {
      if (!mounted) return;
      setState(() {
        _content = [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("This device does not support configuring sensors."),
          ),
        ];
      });
      return;
    }

    if (_tabController.index == 0) {
      _buildNewTabContent(device);
    } else {
      await _buildLoadTabContent();
    }
  }

  void _buildNewTabContent(Wearable device) {
    SensorConfigurationManager sensorManager =
        device.requireCapability<SensorConfigurationManager>();
    final List<Widget> content = sensorManager.sensorConfigurations
        .map(
          (config) => SensorConfigurationValueRow(
            sensorConfiguration: config,
            deviceId: widget.device.deviceId,
          ),
        )
        .cast<Widget>()
        .toList();

    content.addAll([
      const Divider(),
      SaveConfigRow(deviceId: widget.device.deviceId),
    ]);

    if (!mounted) return;
    setState(() {
      _content = content;
    });
  }

  Future<void> _buildLoadTabContent() async {
    if (!mounted) return;
    setState(() {
      _content = [CircularProgressIndicator()];
    });

    final storage = ref.read(sensorConfigurationStorageProvider);
    final configKeys = await storage.listConfigurationKeys();

    if (!mounted) return;

    if (configKeys.isEmpty) {
      setState(() {
        _content = [
          ListTile(title: Text("No configurations found")),
        ];
      });
      return;
    }

    final widgets = configKeys.map((key) {
      return ListTile(
        title: Text(key),
        onTap: () async {
          final config =
              await storage.loadConfiguration(key);
          if (!mounted) return;

          final result = await ref.read(
            sensorConfigurationProviderFamily(widget.device.deviceId)
          ).restoreFromJson(config);

          if (!result && mounted) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Error"),
                content: Text("Failed to load configuration: $key"),
                actions: [
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
            return;
          }

          _tabController.index = 0;
          _updateContent();
        },
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            await storage.deleteConfiguration(key);
            if (mounted) _updateContent();
          },
        ),
      );
    }).toList();

    setState(() {
      _content = widgets;
    });
  }

  Widget? _buildTabBar(BuildContext context) {
    if (!widget.device.hasCapability<SensorConfigurationManager>()) return null;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: TabBar.secondary(
        controller: _tabController,
        labelStyle: GlobalTextStyles.footnoteMedium,
        unselectedLabelStyle: GlobalTextStyles.footnoteMedium,
        unselectedLabelColor: Color(0xFF6E6E6E),
        tabs: const [
          Tab(text: 'New'),
          Tab(text: 'Saved'),
        ],
      ),
    );
  }
}
