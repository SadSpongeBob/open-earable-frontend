import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/constants/colors.dart';

import 'package:openearable/api/local_media.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/widgets/recording_grid.dart';
import 'package:openearable/features/recordings/controllers/upload_controller.dart';
import 'package:openearable/features/recordings/widgets/right_bar.dart';
import 'package:openearable/features/home/widgets/project_grid.dart';
import 'package:openearable/features/home/widgets/add_project_dialog.dart';
import 'package:openearable/app/ui/device/devices_popup_controller.dart';
import 'package:openearable/app/widgets/devices_popup.dart';
import 'package:openearable/features/home/widgets/delete_confirm_dialog.dart';

import '../../../api/models/project/project_metadata.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';
import '../../../app/routing/routes.dart';
import '../../../app/ui/popup_toast.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../controllers/home_controller.dart';
import '../widgets/project_action_bar.dart';
import '../widgets/recording_action_bar.dart';
import '../widgets/rename_project_dialog.dart';
import '../../auth/state/session_provider.dart';
import '../widgets/users_button.dart';
import '../widgets/users_popup.dart';
import '../widgets/move_recordings_modal.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final DevicesPopupController _popupController = DevicesPopupController();
  final GlobalKey bluetoothKey = GlobalKey();
  bool _isChoosingMoveTarget = false;
  Set<String> _recordingIdsToMove = const <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_init());
    });
  }

  Future<void> _init() async {
    await ref.read(homeControllerProvider).loadProjects();
    unawaited(ref.read(uploadControllerProvider).tryUploads());
  }

  @override
  void dispose() {
    _popupController.hide();
    super.dispose();
  }

  void _exitMoveMode() {
    if (!_isChoosingMoveTarget) return;
    setState(() {
      _isChoosingMoveTarget = false;
      _recordingIdsToMove = const <String>{};
    });
  }

  bool _isLocalProject(ProjectMetadata? p, String idFallback) {
    if (idFallback == LocalMedia.defaultProjectId) return true;
    if (p == null) return false;
    return p.projectSource == ProjectSource.local;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ToastEvent?>(toastProvider, (prev, next) {
      if (next == null) return;
      PopupToast.show(context, message: next.message);
      ref.read(toastProvider.notifier).state = null;
    });

    final projects = ref.watch(homeStateProvider.select((s) => s.projects));
    final openProjectId = ref.watch(
      homeStateProvider.select((s) => s.openProjectId),
    );

    final isProjectSelectionMode = ref.watch(
      homeStateProvider.select((s) => s.isProjectSelectionMode),
    );
    final selectedProjectIds = ref.watch(
      homeStateProvider.select((s) => s.selectedProjectIds),
    );

    final recordings = ref.watch(homeStateProvider.select((s) => s.recordings));
    final isRecordingSelectionMode = ref.watch(
      homeStateProvider.select((s) => s.isRecordingSelectionMode),
    );
    final selectedRecordingIds = ref.watch(
      homeStateProvider.select((s) => s.selectedRecordingIds),
    );

    final controller = ref.read(homeControllerProvider);
    final session = ref.watch(sessionProvider);
    final chartProvider = ref.watch(recordingChartProvider);

    final selectedProjectCount = selectedProjectIds.length;

    final openMeta = projects
        .where((p) => p.id == openProjectId)
        .cast<ProjectMetadata?>()
        .toList()
        .firstOrNull;

    final isLocalOpenProject = _isLocalProject(openMeta, openProjectId);

    final showUsersButton =
        session.isAuthenticated &&
        !isLocalOpenProject &&
        openProjectId != LocalMedia.defaultProjectId &&
        !_isChoosingMoveTarget;

    Future<void> handlePickMoveTarget(ProjectMetadata target) async {

      final ids = _recordingIdsToMove;
      _exitMoveMode();

      await controller.moveRecordings(ids, targetProjectId: target.id);

      if (!mounted) return;
      controller.exitRecordingSelectionMode();
    }

    final selectionEnabled = isRecordingSelectionMode && !_isChoosingMoveTarget;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          // PROJECTS BAR
          SizedBox(
            width: 500,
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProjectBar(
                      projects: projects,
                      openProjectId: openProjectId,
                      isSelectionMode: isProjectSelectionMode,
                      selectedProjectIds: selectedProjectIds,
                      onAddProject: () async {
                        final name = await AddProjectDialog.show(context);
                        if (name == null) return;
                        await controller.createProject(name);
                      },
                      onTapProject: (item) {
                        if (_isChoosingMoveTarget) {
                          handlePickMoveTarget(item);
                        } else {
                          controller.handleProjectTap(item.id);
                        }
                      },
                      onLongPressProject: (item) =>
                          controller.handleProjectLongPress(item.id),
                    ),
                  ),

                  if (isProjectSelectionMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ProjectSelectionActionBar(
                        selectedCount: selectedProjectCount,
                        onDelete: () {
                          if (selectedProjectCount == 0) return;

                          final projectIds = selectedProjectIds;
                          DeleteConfirmDialog.show(
                            context,
                            onDelete: () async {
                              await controller.deleteProjects(projectIds);
                              if (!mounted) return;
                              controller.exitProjectSelectionMode();
                            },
                            title:
                                'Do you really want to \ndelete these projects?',
                          );
                        },
                        onDuplicate: () {
                          if (selectedProjectCount == 0) return;
                          controller.duplicateProjects(selectedProjectIds);
                        },
                        onRename: () {
                          if (selectedProjectCount != 1) return;
                          final projectId = selectedProjectIds.first;
                          final project = projects.firstWhere(
                            (p) => p.id == projectId,
                          );

                          RenameProjectDialog.show(
                            context,
                            initialName: project.name,
                          ).then((newName) {
                            if (newName != null && newName.trim().isNotEmpty) {
                              controller.renameProject(projectId, newName);
                            }
                          });
                        },
                        onDone: controller.exitProjectSelectionMode,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // RECORDINGS GRID
          Expanded(
            child: SafeArea(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: RepaintBoundary(
                      child: RecordingGrid(
                        recordings: recordings,
                        isSelectionMode: selectionEnabled,
                        selectedRecordingIds: selectedRecordingIds,
                        onTapRecording: (item) {
                          if (_isChoosingMoveTarget) {
                            _exitMoveMode();
                            return;
                          }
                          if (item.isUploading) return;

                          if (selectionEnabled) {
                            controller.handleRecordingTap(item.id);
                            return;
                          }

                          context.go(Routes.playback(item.isCloud, item.id));
                        },
                        onLongPressRecording: (item) {
                          if (_isChoosingMoveTarget) return;
                          controller.handleRecordingLongPress(item.id);
                        },
                      ),
                    ),
                  ),

                  if (selectionEnabled)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: RecordingSelectionActionBar(
                        selectedCount: selectedRecordingIds.length,
                        onDelete: () {
                          DeleteConfirmDialog.show(
                            context,
                            onDelete: () async {
                              await controller.deleteRecordings(
                                selectedRecordingIds,
                              );
                              if (!mounted) return;
                              controller.exitRecordingSelectionMode();
                            },
                            title:
                                'Do you really want to\ndelete these recordings?',
                          );
                        },
                        onDuplicate: () {
                          controller.duplicateRecordings(selectedRecordingIds);
                        },
                        onMove: () {
                          setState(() {
                            _isChoosingMoveTarget = true;
                            _recordingIdsToMove = Set<String>.from(
                              selectedRecordingIds,
                            );
                          });
                        },
                        onDone: controller.exitRecordingSelectionMode,
                      ),
                    ),

                  // MOVE MODE OVERLAY
                  if (_isChoosingMoveTarget)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _exitMoveMode,
                        child: Container(
                          color: AppColors.nineHundred.withValues(alpha: 0.35),
                          child: Center(
                            child: GestureDetector(
                              onTap: () {},
                              child: const MoveRecordingsModal(),
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (showUsersButton)
                    Positioned(
                      bottom: isRecordingSelectionMode ? 20 + 52 + 10 : 20,
                      right: 24,
                      child: UsersButton(
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (_) => const UsersPopup(),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // RIGHT BAR
          AbsorbPointer(
            absorbing: _isChoosingMoveTarget,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isChoosingMoveTarget ? 0.4 : 1.0,
              child: SafeArea(
                child: HomeRecordingRightBar(
                  onSettings: () => context.go(Routes.settings),
                  onWaveSound: () =>
                      context.go('${Routes.sensordata}?source=home'),
                  onWaveSoundLongPress: () {
                    ref.read(recordingChartProvider).toggleOverlayVisibility();
                  },
                  isWaveSoundActive: chartProvider.shouldShowOverlay,
                  onShutter: () => ref
                      .read(homeControllerProvider)
                      .handleGoToRecordingTap(
                        goToRecording: () => context.go(Routes.recording),
                      ),
                  onBluetooth: () {
                    _popupController.toggle(
                      context: context,
                      positionedPopup: const Positioned(
                        bottom: 40,
                        right: 165,
                        child: DevicesPopup(),
                      ),
                    );
                  },
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  isRecording: false,
                  isPaused: false,
                  showFlipButton: false,
                  bluetoothKey: bluetoothKey,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.fifty,
    );
  }
}

extension _FirstOrNullX<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
