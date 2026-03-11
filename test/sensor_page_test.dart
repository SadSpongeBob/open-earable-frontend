import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';

import 'package:openearable/features/sensors/pages/sensor_page.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/app/widgets/bluetooth_button.dart';
import 'package:openearable/features/home/state/wearables_state.dart';
import 'package:openearable/features/sensors/state/sensor_configurations_provider.dart';
import 'package:openearable/features/home/state/wearables_provider.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';
import 'package:openearable/features/sensors/state/sensor_data_provider.dart';
import 'package:openearable/features/sensors/state/sensor_configuration_storage.dart';

// Mocks
class MockGoRouter extends Mock implements GoRouter {}
class MockWearable extends Mock implements Wearable {}
class MockSensorManager extends Mock implements SensorConfigurationManager {}
class MockSensorConfig extends Mock implements SensorConfiguration {}
class MockWearablesProvider extends Mock implements WearablesProvider {}
class MockSensorConfigurationProvider extends Mock implements SensorConfigurationProvider {}
class MockSensorDataProvider extends Mock implements SensorDataProvider {}
class MockSensor extends Mock implements Sensor {}
class MockSensorConfigurationStorage extends Mock implements SensorConfigurationStorage {}
class FakeWearable extends Fake implements Wearable {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeWearable());
    registerFallbackValue("fallback-id");
    registerFallbackValue(("id", 0));
  });

  group('SensorPage Full Integration Tests', () {
    late MockGoRouter mockRouter;
    late MockWearable mockWearable;
    late MockSensorManager mockSensorManager;
    late MockWearablesProvider mockWearablesProvider;
    late MockSensorConfigurationProvider mockConfigProvider;
    late MockSensorDataProvider mockDataProvider;
    late MockSensor mockSensor;
    late MockSensorConfigurationStorage mockStorage;

    setUp(() {
      mockRouter = MockGoRouter();
      mockWearable = MockWearable();
      mockSensorManager = MockSensorManager();
      mockWearablesProvider = MockWearablesProvider();
      mockConfigProvider = MockSensorConfigurationProvider();
      mockDataProvider = MockSensorDataProvider();
      mockSensor = MockSensor();
      mockStorage = MockSensorConfigurationStorage();

      when(() => mockRouter.push(any(), extra: any(named: 'extra')))
      .thenAnswer((_) async => null);
      when(() => mockRouter.pushNamed(any(), extra: any(named: 'extra')))
      .thenAnswer((_) async => null);

      when(() => mockRouter.go(any())).thenReturn(null);

      // Setup Wearable
      when(() => mockWearable.name).thenReturn("OpenEarable Test");
      when(() => mockWearable.deviceId).thenReturn("test-id-123");
      
      // Setup Sensor
      when(() => mockSensor.sensorName).thenReturn("Accelerometer");
      when(() => mockSensor.axisNames).thenReturn(["X", "Y", "Z"]);
      when(() => mockSensor.axisCount).thenReturn(3);
      when(() => mockSensor.axisUnits).thenReturn(["m/s²"]);
      when(() => mockSensor.timestampExponent).thenReturn(0);

      // Capability Stubs
      when(() => mockWearable.hasCapability<SensorConfigurationManager>()).thenReturn(true);
      when(() => mockWearable.requireCapability<SensorConfigurationManager>()).thenReturn(mockSensorManager);
      when(() => mockSensorManager.sensorConfigurations).thenReturn([]);

      // Provider/Storage Stubs
      when(() => mockConfigProvider.toJson()).thenReturn({"acc": "1"});
      when(() => mockConfigProvider.addListener(any())).thenReturn(null);
      when(() => mockConfigProvider.removeListener(any())).thenReturn(null);
      
      when(() => mockDataProvider.sensor).thenReturn(mockSensor);
      when(() => mockDataProvider.sensorValues).thenReturn(Queue<SensorValue>());
      when(() => mockDataProvider.addListener(any())).thenReturn(null);
      when(() => mockDataProvider.removeListener(any())).thenReturn(null);

      when(() => mockWearablesProvider.getSensorConfigurationProvider(any())).thenReturn(mockConfigProvider);
      when(() => mockWearablesProvider.getSensorDataProviders(any())).thenReturn([mockDataProvider]);
      when(() => mockWearablesProvider.addListener(any())).thenReturn(null);
      when(() => mockWearablesProvider.removeListener(any())).thenReturn(null);
      
      when(() => mockStorage.saveConfiguration(any(), any())).thenAnswer((_) async => {});
    });

    Future<void> setupSensorPage(WidgetTester tester, {
      bool isRecordingSource = false,
      List<Wearable>? wearables,
    }) async {
      when(() => mockWearablesProvider.wearables).thenReturn(wearables ?? []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wearablesProvider.overrideWith((ref) => mockWearablesProvider),
            sensorConfigurationProviderFamily("test-id-123").overrideWithValue(mockConfigProvider),
            sensorDataProviderFamily(("test-id-123", 0)).overrideWithValue(mockDataProvider),
            sensorConfigurationStorageProvider.overrideWithValue(mockStorage),
          ],
          child: MaterialApp(
            home: InheritedGoRouter(
              goRouter: mockRouter,
              child: SensorPage(isRecordingSource: isRecordingSource),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // --- 1. Common UI & Navigation (Restored) ---

    testWidgets('Displays basic layout elements', (WidgetTester tester) async {
      await setupSensorPage(tester);
      expect(find.byType(BluetoothButton), findsOneWidget);
      expect(find.text("Sensors"), findsOneWidget);
    });

    testWidgets('Go Back navigates to correct route based on isRecordingSource', (WidgetTester tester) async {
      // Test Home navigation
      await setupSensorPage(tester, isRecordingSource: false);
      await tester.tap(find.text(" Go Back"));
      verify(() => mockRouter.go(Routes.home)).called(1);

      // Test Recording navigation
      await setupSensorPage(tester, isRecordingSource: true);
      await tester.tap(find.text(" Go Back"));
      verify(() => mockRouter.go(Routes.recording)).called(1);
    });

    // --- 2. Left Side: Configuration Logic (Restored & Enhanced) ---

    testWidgets('Shows "No devices connected" in config panel when empty', (WidgetTester tester) async {
      await setupSensorPage(tester, wearables: []);
      expect(find.text("No devices connected"), findsOneWidget);
    });

    testWidgets('Saves configuration when name is provided', (WidgetTester tester) async {
      await setupSensorPage(tester, wearables: [mockWearable]);
      
      await tester.enterText(find.byType(TextField), "Test Config");
      await tester.tap(find.text("Save"));
      await tester.pumpAndSettle();

      verify(() => mockStorage.saveConfiguration("Test Config", any())).called(1);
    });

    // --- 3. Right Side: Sensor Values & Charts ---

    testWidgets('Displays Sensor Cards and Chart when connected', (WidgetTester tester) async {
      await setupSensorPage(tester, wearables: [mockWearable]);
      
      expect(find.text("Accelerometer"), findsOneWidget);
      // Ensure the chart widget is rendered
      expect(find.byType(LineChart), findsWidgets);
    });

    testWidgets('Tapping Sensor Card navigates to details page', (WidgetTester tester) async {
      await setupSensorPage(tester, wearables: [mockWearable]);

      await tester.tap(find.text("Accelerometer"));
      await tester.pumpAndSettle();

      verify(() => mockRouter.push(Routes.sensordataDetails, extra: any(named: 'extra'))).called(1);
    });
  });
}