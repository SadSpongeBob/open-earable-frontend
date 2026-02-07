import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:openearable/api/local_media.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/widgets/recording_grid.dart';
import 'package:openearable/features/recordings/widgets/right_bar.dart';
import 'package:openearable/features/home/widgets/project_grid.dart';
import 'package:openearable/features/home/widgets/add_project_dialog.dart';
import 'package:openearable/features/home/widgets/delete_confirm_dialog.dart';

import '../../../api/models/project/project_metadata.dart';
import '../../../app/routing/routes.dart';
import '../../../app/ui/popup_toast.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../../auth/state/session_provider.dart';
import '../controllers/home_controller.dart';
import '../widgets/project_action_bar.dart';
import '../widgets/recording_action_bar.dart';
import '../widgets/rename_project_dialog.dart';
import '../widgets/users_button.dart';
import '../widgets/users_popup.dart';
import '../widgets/move_recordings_modal.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isChoosingMoveTarget = false;
  Set<String> _recordingIdsToMove = const <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(homeControllerProvider).loadProjects());
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

    final state = ref.watch(homeStateProvider);
    final controller = ref.read(homeControllerProvider);
    final session = ref.watch(sessionProvider);

    final selectedProjectCount = state.selectedProjectIds.length;

    final openMeta = state.projects
        .where((p) => p.id == state.openProjectId)
        .cast<ProjectMetadata?>()
        .toList()
        .firstOrNull;

    final isLocalOpenProject = _isLocalProject(openMeta, state.openProjectId);

    final showUsersButton = session.isAuthenticated && !isLocalOpenProject &&
            state.openProjectId != 'default' && !_isChoosingMoveTarget;

    final canManageRecordings = controller.canManageRecordings;

    Future<void> handlePickMoveTarget(ProjectMetadata target) async {
      final targetIsLocal = _isLocalProject(target, target.id);
      final sourceIsLocal = _isLocalProject(openMeta, state.openProjectId);
      if (sourceIsLocal != targetIsLocal) {
        emitToast(ref as Ref, const ToastEvent.error('You can only move local→local or cloud→cloud'));
        return;
      }
      if (target.id == state.openProjectId) {
        emitToast(ref as Ref, const ToastEvent.error('Choose a different project'));
        return;
      }

      final ids = _recordingIdsToMove;
      _exitMoveMode();

      await controller.moveRecordings(ids, targetProjectId: target.id);

      if (!mounted) return;
      controller.exitRecordingSelectionMode();
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // PROJECTS BAR
            SizedBox(
              width: 500,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProjectBar(
                      projects: state.projects,
                      openProjectId: state.openProjectId,
                      isSelectionMode: state.isProjectSelectionMode,
                      selectedProjectIds: state.selectedProjectIds,
                      onAddProject: () async {
                        final name = await AddProjectDialog.show(context);
                        if (name == null) return;
                        await controller.createProject(name);},
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

                  if (state.isProjectSelectionMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ProjectSelectionActionBar(
                        selectedCount: selectedProjectCount,
                        onDelete: () {
                          if (selectedProjectCount == 0) return;

                          final projectIds = state.selectedProjectIds;
                          DeleteConfirmDialog.show(
                            context,
                            title: 'Do you really want to\ndelete these projects?',
                            onDelete: () async {
                              await controller.deleteProjects(projectIds);
                              if (!mounted) return;
                              controller.exitProjectSelectionMode();
                            },
                          );
                        },
                        onDuplicate: () {
                          if (selectedProjectCount == 0) return;
                          controller.duplicateProjects(state.selectedProjectIds);
                        },
                        onRename: () {
                          if (selectedProjectCount != 1) return;
                          final projectId = state.selectedProjectIds.first;
                          final project =
                          state.projects.firstWhere((p) => p.id == projectId);

                          showDialog<String>(
                            context: context,
                            builder: (_) =>
                                RenameProjectDialog(initialName: project.name),
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

            // RECORDINGS GRID
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: RecordingGrid(
                      recordings: state.recordings,
                      isSelectionMode: canManageRecordings &&
                          state.isRecordingSelectionMode &&
                          !_isChoosingMoveTarget,
                      selectedRecordingIds: state.selectedRecordingIds,
                      onTapRecording: (item) {
                        if (_isChoosingMoveTarget) {
                          _exitMoveMode();
                          return;
                        }
                        controller.handleRecordingTap(item.id);
                      },
                      onLongPressRecording: canManageRecordings
                          ? (item) {
                        if (_isChoosingMoveTarget) return;
                        controller.handleRecordingLongPress(item.id);
                      }
                          : null,
                    ),
                  ),

                  if (canManageRecordings && state.isRecordingSelectionMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: RecordingSelectionActionBar(
                        selectedCount: state.selectedRecordingIds.length,
                        onDelete: () {
                          DeleteConfirmDialog.show(
                            context,
                            title: 'Do you really want to\ndelete these recordings?',
                            onDelete: () async {
                              await controller.deleteRecordings(state.selectedRecordingIds);
                              if (!mounted) return;
                              controller.exitRecordingSelectionMode();
                            },
                          );
                        },
                        onDuplicate: () {
                          controller.duplicateRecordings(state.selectedRecordingIds);
                        },
                        onMove: () {
                          setState(() {
                            _isChoosingMoveTarget = true;
                            _recordingIdsToMove =
                            Set<String>.from(state.selectedRecordingIds);
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
                          color: Colors.black.withOpacity(0.35),
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
                      bottom: state.isRecordingSelectionMode ? 20 + 52 + 10 : 20,
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

            // RIGHT BAR
            AbsorbPointer(
              absorbing: _isChoosingMoveTarget,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isChoosingMoveTarget ? 0.4 : 1.0,
                child: HomeRecordingRightBar(
                  onSettings: () => context.go(Routes.settings),
                  onWaveSound: () {},
                  onShutter: () => context.go(Routes.recording),
                  onBluetooth: () {},
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  isRecording: false,
                  isPaused: false,
                  showFlipButton: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
extension _FirstOrNullX<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
