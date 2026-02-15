import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/recording.dart';

import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/widgets/recording_grid.dart';
import 'package:openearable/features/recordings/widgets/right_bar.dart';
import 'package:openearable/features/home/widgets/project_bar.dart';
import 'package:openearable/features/home/widgets/add_project_dialog.dart';
import 'package:openearable/features/home/widgets/delete_project_dialog.dart';

import '../../../app/routing/routes.dart';
import '../../../app/ui/popup_toast.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../../auth/state/session_provider.dart';
import '../controllers/home_controller.dart';
import '../widgets/project_action_bar.dart';
import '../widgets/rename_project_dialog.dart';
import '../widgets/users_button.dart';
import '../widgets/users_popup.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(homeControllerProvider).loadProjects());
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

    final selectedCount = state.selectedProjectIds.length;

    final showUsersButton =
        session.isAuthenticated && state.openProjectId != 'default';

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
                      isSelectionMode: state.isSelectionMode,
                      selectedProjectIds: state.selectedProjectIds,
                      onAddProject: () async {
                        final name = await AddProjectDialog.show(context);
                        if (name == null) return;
                        await controller.createProject(name);
                      },
                      onTapProject: (item) =>
                          controller.handleProjectTap(item.id),
                      onLongPressProject: (item) =>
                          controller.handleProjectLongPress(item.id),
                    ),
                  ),

                  if (state.isSelectionMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ProjectSelectionActionBar(
                        selectedCount: selectedCount,
                        onDelete: () {
                          if (selectedCount == 0) return;

                          final projectIds = state.selectedProjectIds;
                          DeleteProjectDialog.show(
                            context,
                            onDelete: () async {
                              await controller.deleteProjects(projectIds);
                              controller.exitSelectionMode();
                            },
                          );
                        },
                        onDuplicate: () {
                          if (selectedCount == 0) return;
                          controller.duplicateProjects(
                            state.selectedProjectIds,
                          );
                        },
                        onRename: () {
                          if (selectedCount != 1) return;
                          final projectId = state.selectedProjectIds.first;
                          final project = state.projects.firstWhere(
                            (p) => p.id == projectId,
                          );

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
                        onDone: controller.exitSelectionMode,
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
                      recordings: state.videos,
                      isSelectionMode: false,
                      selectedRecordingIds: const <String>{},
                      onTapRecording: (item) async {
                        if (item.isUploading || item.isUploaded) return;
                        context.go(Routes.playback(item.isCloud, item.id));
                      },
                      onLongPressRecording: (item) {},
                    ),
                  ),

                  if (showUsersButton)
                    Positioned(
                      bottom: 20,
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

            HomeRecordingRightBar(
              onSettings: () => context.go(Routes.settings),
              onWaveSound: () {},
              onShutter: () => context.go(Routes.recording),
              onBluetooth: () {},
              padding: const EdgeInsets.symmetric(vertical: 24),
              isRecording: false,
              isPaused: false,
              showFlipButton: false,
            ),
          ],
        ),
      ),
    );
  }
}
