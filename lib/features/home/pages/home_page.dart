import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
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
    Future.microtask(() {
      ref.read(homeControllerProvider.notifier).loadProjects();
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


    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);

    const defaultProjectItem = ProjectMetadata(
      id: 'default',
      name: 'Default',
      recordingAmount: 0,
      userAmount: 0
    );

    final projectItems = <ProjectMetadata>[
      defaultProjectItem,
      ...state.projects,
    ];

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
                      projects: projectItems,
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
                      child: ProjectSelectionActionBar(
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
              child: Consumer(
                builder: (context, ref, _) {
                  final session = ref.watch(sessionProvider);

                  final isAuthenticated = session.isAuthenticated;


                  final showUsersButton = isAuthenticated && state.openProjectId != 'default';

                  return Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/background.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      if (showUsersButton)
                        Positioned(
                          top: 600,
                          left: 560,
                          child: UsersButton(
                            onTap: () async {

                              if (!context.mounted) return;

                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (_) => const UsersPopup(),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
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