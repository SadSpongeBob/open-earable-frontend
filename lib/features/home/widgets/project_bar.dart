import 'package:flutter/material.dart';
import 'package:openearable/api/models/project/project_metadata.dart';

class ProjectBar extends StatelessWidget {
  const ProjectBar({
    super.key,
    required this.projects,
    required this.openProjectId,
    required this.isSelectionMode,
    required this.selectedProjectIds,
    this.onAddProject,
    this.onTapProject,
    this.onLongPressProject,
  });

  final List<ProjectMetadata> projects;
  final String openProjectId;

  final bool isSelectionMode;
  final Set<String> selectedProjectIds;

  final VoidCallback? onAddProject;
  final ValueChanged<ProjectMetadata>? onTapProject;
  final ValueChanged<ProjectMetadata>? onLongPressProject;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 181.5 / 149.0,
            ),
            itemCount: projects.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _AddProjectTile(onTap: onAddProject);
              }

              final project = projects[index - 1];
              final isOpen= project.id == openProjectId;
              final isSelectable = project.id != 'default';
              final isChecked = selectedProjectIds.contains(project.id);
              return _ProjectTile(
                name: project.name,
                isOpen: isOpen,
                showSelectionCircle: isSelectionMode && isSelectable,
                isChecked: isChecked,
                onTap: () => onTapProject?.call(project),
                onLongPress: () => onLongPressProject?.call(project),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AddProjectTile extends StatelessWidget {
  const _AddProjectTile({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset('assets/buttons/home/add_folder.png'),
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.name,
    required this.isOpen,
    required this.showSelectionCircle,
    required this.isChecked,
    required this.onTap,
    required this.onLongPress,
  });

  final String name;
  final bool isOpen;

  final bool showSelectionCircle;
  final bool isChecked;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final iconAsset = isOpen
        ? 'assets/buttons/home/open_folder.png'
        : 'assets/buttons/home/folder.png';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Image.asset(iconAsset, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // selection circle overlay
            if (showSelectionCircle)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: _SelectionCircle(isChecked: isChecked, isOpen: isOpen),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({
    required this.isChecked,
    required this.isOpen,
  });

  final bool isChecked;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: 2, color: isOpen ? Colors.pink.shade600 : Colors.grey.shade700),
        color: isChecked
            ? (isOpen ? Colors.pink.shade600 : Colors.grey.shade700)
            : Colors.transparent,
      ),
      child: isChecked ? const Center(
        child: Icon(
          Icons.check,
          size: 30,
          color: Colors.white,
        ),
      )
          : null,
    );
  }
}
