import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/recordings/widgets/right_bar.dart';
import 'package:openearable/features/home/widgets/project_bar.dart';
import 'package:openearable/features/home/widgets/add_project_dialog.dart';
import 'package:openearable/features/home/widgets/delete_project_dialog.dart';
import '../../../app/routing/routes.dart';
import '../../../app/ui/popup_toast.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../controllers/home_controller.dart';
import '../widgets/rename_project_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homeControllerProvider).loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {

    // Toast event listener
    // TODO: Move to a higher level widget if needed globally
    ref.listen<ToastEvent?>(toastProvider, (prev, next) {
      if (next == null) return;

      PopupToast.show(
        context,
        message: next.message,
      );

      ref.read(toastProvider.notifier).state = null;
    });


    final state = ref.watch(homeStateProvider);
    final controller = ref.read(homeControllerProvider);

    final selectedCount = state.selectedProjectIds.length;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
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
                      onTapProject: (item) {
                        controller.handleProjectTap(item.id);
                      },
                      onLongPressProject: (item) {
                        controller.handleProjectLongPress(item.id);
                      },
                    ),
                  ),

                  if (state.isSelectionMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _ProjectSelectionActionBar(
                        selectedCount: selectedCount,

                        onDelete: () {
                          if (selectedCount == 0) return;

                          final projectIds = state.selectedProjectIds.toList();

                          DeleteProjectDialog.show(
                            context,
                            onDelete: () async {
                              for (final id in projectIds) {
                                await controller.deleteProject(id);
                              }
                              controller.exitSelectionMode();
                            },
                          );
                        },

                        onDuplicate: () {
                          if (selectedCount == 0) return;

                          for (final projectId in state.selectedProjectIds) {
                            controller.duplicateProject(projectId);
                          }
                        },

                        onRename: () {
                          if (selectedCount != 1) return;
                          final projectId = state.selectedProjectIds.first;
                          final project = state.projects.firstWhere((p) => p.id == projectId);

                          showDialog<String>(
                            context: context,
                            builder: (_) => RenameProjectDialog(
                              initialName: project.name,
                            ),
                          ).then((newName) {
                            if (newName != null && newName.isNotEmpty) {
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

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
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

class _ProjectSelectionActionBar extends StatelessWidget {
  const _ProjectSelectionActionBar({
    required this.selectedCount,
    required this.onDelete,
    required this.onDuplicate,
    required this.onRename,
    required this.onDone,
  });

  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onRename;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final showRename = selectedCount == 1;

    return Container(
      height: 52,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          TextButton(
            onPressed: selectedCount == 0 ? null : onDelete,
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),

          const SizedBox(width: 10),

          TextButton(
            onPressed: selectedCount == 0 ? null : onDuplicate,
            child: const Text(
              'Duplicate',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),

          if (showRename) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: onRename,
              child: const Text(
                'Rename',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ],

          const Spacer(),

          TextButton(
            onPressed: onDone,
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
