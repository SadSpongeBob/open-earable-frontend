import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/services/project/project_service.dart' hide ProjectRole;
import 'package:openearable/app/utils/validators.dart';
import '../../../api/client_dio.dart';
import '../../../api/models/auth/user.dart';
import '../../../api/services/user/user_service.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/services/project/project_service.dart';
import '../../../app/ui/toast_controller.dart';
import '../../../app/ui/toast_event.dart';
import '../state/home_state.dart';

final homeControllerProvider =
StateNotifierProvider<HomeController, HomeState>((ref) {
  final projectService = ref.read(projectServiceProvider);
  final usersService = ref.read(userServiceProvider);

  void toast(ToastEvent event) => emitToast(ref, event);

  return HomeController(
    projectService: projectService,
    userService: usersService,
    toast: toast,
  );
});

typedef ToastSink = void Function(ToastEvent);

class HomeController extends StateNotifier<HomeState> {
  HomeController({
    required ProjectService projectService,
    required UserService userService,
    required ToastSink toast,
  })  : _projectService = projectService,
        _userService = userService,
        _toast = toast,
        super(HomeState.initial());

  final ProjectService _projectService;
  final UserService _userService;
  final ToastSink _toast;

  void _setLoading(bool value) =>
      state = state.copyWith(isLoading: value, clearError: value);

  void _setError(Object e, {String? userMessage}) {
    final msg = userMessage ?? e.toString();
    state = state.copyWith(isLoading: false, errorMessage: msg);
    _toast(ToastEvent.error(msg));
  }

  void _success(String message) => _toast(ToastEvent.success(message));

  bool _projectExists(String projectId, List<ProjectMetadata> projects) =>
      projects.any((p) => p.id == projectId);

  bool _nameExists(String name, {String? excludeProjectId}) {
    final normalized = name.trim().toLowerCase();
    return state.projects.any((p) {
      if (excludeProjectId != null && p.id == excludeProjectId) return false;
      return p.name.trim().toLowerCase() == normalized || normalized == 'default';
    });
  }

  ProjectMetadata? _findById(String id) {
    for (final p in state.projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> loadProjects() async {
    _setLoading(true);
    try {
      final projects = await _projectService.getProjects();

      final currentOpenId = state.openProjectId;
      final openStillValid =
          currentOpenId == 'default' || _projectExists(currentOpenId, projects);

      state = state.copyWith(
        isLoading: false,
        projects: projects,
        openProjectId: openStillValid ? currentOpenId : 'default',
      );
    } catch (e) {
      _setError(e, userMessage: 'Failed to load projects');
    }
  }

  void openProject(String projectId) {
    if (projectId != 'default') {
      final exists = _findById(projectId) != null;
      if (!exists) return;
    }

    state = state.copyWith(
      openProjectId: projectId,
      videos: const [],
      clearSelectedVideoId: true,
      clearError: true,
      isUsersLoading: false,
      projectUsers: const [],
      usersEmailInput: '',
      usersSelectedRole: ProjectRole.viewer,
      myProjectRole: null,
      clearUsersError: true,
    );
  }

  void openDefaultProject() => openProject('default');

  Future<void> createProject(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _toast(const ToastEvent.error('Project name can’t be empty'));
      return;
    }

    if (_nameExists(trimmed)) {
      _toast(const ToastEvent.error('A project with this name already exists'));
      return;
    }

    _setLoading(true);
    try {
      final created = await _projectService.createProject(trimmed);

      state = state.copyWith(
        isLoading: false,
        projects: [...state.projects, created.toMetadata()],
        openProjectId: created.id,
        clearError: true,
      );

      _success('Project "$trimmed" created');
    } catch (e) {
      _setError(e, userMessage: 'Failed to create project');
    }
  }

  Future<void> renameProject(String projectId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _toast(const ToastEvent.error('Project name can’t be empty'));
      return;
    }

    if (_nameExists(trimmed, excludeProjectId: projectId)) {
      _toast(const ToastEvent.error('A project with this name already exists'));
      return;
    }

    _setLoading(true);
    try {
      await _projectService.renameProject(projectId, trimmed);

      final updatedProjects = state.projects.map((p) {
        if (p.id != projectId) return p;
        return p.copyWith(name: trimmed);
      }).toList();

      state = state.copyWith(
        isLoading: false,
        projects: updatedProjects,
        clearError: true,
      );

      _success('Rename Successful');
    } catch (e) {
      _setError(e, userMessage: 'Failed to rename project');
    }
  }

  Future<void> deleteProject(String projectId) async {
    _setLoading(true);
    try {
      await _projectService.deleteProject(projectId);

      final updated = state.projects.where((p) => p.id != projectId).toList();
      final newOpenId =
      state.openProjectId == projectId ? 'default' : state.openProjectId;

      final nextSelected = Set<String>.from(state.selectedProjectIds)
        ..remove(projectId);

      state = state.copyWith(
        isLoading: false,
        projects: updated,
        openProjectId: newOpenId,
        selectedProjectIds: nextSelected,
        isSelectionMode: nextSelected.isNotEmpty && state.isSelectionMode,
        clearError: true,
      );

      _success('Project Deleted');
    } catch (e) {
      _setError(e, userMessage: 'Failed to delete project');
    }
  }

  void enterSelectionMode({String? initialProjectId}) {
    final ids = <String>{};
    if (initialProjectId != null && initialProjectId != 'default') {
      ids.add(initialProjectId);
    }

    state = state.copyWith(
      isSelectionMode: true,
      selectedProjectIds: ids,
      clearError: true,
    );
  }

  void exitSelectionMode() {
    state = state.copyWith(
      isSelectionMode: false,
      selectedProjectIds: <String>{},
      clearError: true,
    );
  }

  void toggleProjectSelection(String projectId) {

    final next = Set<String>.from(state.selectedProjectIds);
    if (next.contains(projectId)) {
      next.remove(projectId);
    } else {
      next.add(projectId);
    }

    state = state.copyWith(
      isSelectionMode: next.isNotEmpty,
      selectedProjectIds: next,
      clearError: true,
    );
  }

  void handleProjectTap(String projectId) {
    if (state.isSelectionMode) {
      toggleProjectSelection(projectId);
      return;
    }
    openProject(projectId);
  }

  void handleProjectLongPress(String projectId) {
    if (projectId == 'default') return;
    if (!state.isSelectionMode) {
      enterSelectionMode(initialProjectId: projectId);
    }
  }

  Future<void> duplicateProject(String projectId) async {
    if (projectId == 'default') return;

    final project = _findById(projectId);
    if (project == null) {
      _toast(const ToastEvent.error('Project not found'));
      return;
    }

    String base = '${project.name} (Copy)';
    String candidate = base;
    int i = 2;
    while (_nameExists(candidate)) {
      candidate = '$base $i';
      i++;
    }

    await createProject(candidate);
  }

  void setUsersEmailInput(String value) {
    state = state.copyWith(
      usersEmailInput: value,
      clearUsersError: true,
    );
  }

  void setUsersSelectedRole(ProjectRole role) {
    state = state.copyWith(
      usersSelectedRole: role,
      clearUsersError: true,
    );
  }

  Future<void> loadUsersForOpenProject({
    required String myUserId,
  }) async {
    final projectId = state.openProjectId;
    if (projectId == null || projectId == 'default') return;

    state = state.copyWith(isUsersLoading: true, clearUsersError: true);

    try {
      final entries = await _userService.getProjectUsers(projectId);

      ProjectRole? myRole;
      for (final e in entries) {
        if (e.user.userId == myUserId) {
          myRole = e.role;
          break;
        }
      }

      state = state.copyWith(
        isUsersLoading: false,
        projectUsers: entries,
        myProjectRole: myRole,
      );
    } catch (e) {
      final msg = _mapUsersError(e);
      state = state.copyWith(
        isUsersLoading: false,
        usersErrorMessage: msg,
      );
      _toast(ToastEvent.error(msg));
    }
  }

  Future<void> addUserToOpenProject({
    required String myUserId,
  }) async {
    final projectId = state.openProjectId;
    if (projectId == null || projectId == 'default') return;

    if (state.myProjectRole != ProjectRole.owner) return;

    final email = state.usersEmailInput.trim();
    if (Validators.email(email) != null) {
      state = state.copyWith(usersErrorMessage: 'Please enter a valid email.');
      return;
    }

    state = state.copyWith(isUsersLoading: true, clearUsersError: true);

    try {
      await _userService.addUserToProject(
        projectId: projectId,
        email: email,
        role: state.usersSelectedRole,
      );

      state = state.copyWith(usersEmailInput: '');
      _toast(const ToastEvent.success('User added'));
      await loadUsersForOpenProject(myUserId: myUserId);
    } catch (e) {
      final msg = _mapUsersError(e);
      state = state.copyWith(
        isUsersLoading: false,
        usersErrorMessage: msg,
      );
      _toast(ToastEvent.error(msg));
    }
  }

  Future<void> changeUserRole({
    required String myUserId,
    required String userId,
    required ProjectRole role,
  }) async {
    final projectId = state.openProjectId;
    if (projectId == null || projectId == 'default') return;

    if (state.myProjectRole != ProjectRole.owner) return;

    final before = state.projectUsers;
    final optimistic = before
        .map((e) => e.user.userId == userId ? e.copyWith(role: role) : e)
        .toList();

    state = state.copyWith(projectUsers: optimistic, clearUsersError: true);

    try {
      await _userService.updateUserRole(
        projectId: projectId,
        userId: userId,
        role: role,
      );
      _toast(const ToastEvent.success('Role updated'));
    } catch (e) {
      state = state.copyWith(projectUsers: before);
      final msg = _mapUsersError(e);
      state = state.copyWith(usersErrorMessage: msg);
      _toast(ToastEvent.error(msg));
    }
  }

  Future<void> removeUserFromOpenProject({
    required String myUserId,
    required String userId,
  }) async {
    final projectId = state.openProjectId;
    if (projectId == null || projectId == 'default') return;

    final isOwner = state.myProjectRole == ProjectRole.owner;
    final canRemove = isOwner || userId == myUserId;
    if (!canRemove) return;

    final before = state.projectUsers;
    state = state.copyWith(
      projectUsers: before.where((e) => e.user.userId != userId).toList(),
      clearUsersError: true,
    );

    try {
      await _userService.removeUserFromProject(
        projectId: projectId,
        userId: userId,
      );
      _toast(const ToastEvent.success('User removed'));
      if (userId != myUserId) {
        await loadUsersForOpenProject(myUserId: myUserId);
      }
    } catch (e) {
      state = state.copyWith(projectUsers: before);
      final msg = _mapUsersError(e);
      state = state.copyWith(usersErrorMessage: msg);
      _toast(ToastEvent.error(msg));
    }
  }

  String _mapUsersError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('already exists') || msg.contains('duplicate')) {
      return 'This user is already added to the project.';
    }
    if (msg.contains('not found')) {
      return 'User not found.';
    }
    if (msg.contains('unauthorized') || msg.contains('forbidden')) {
      return 'You are not allowed to manage users.';
    }
    return 'Something went wrong. Please try again.';
  }
}
