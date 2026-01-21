import 'package:flutter/material.dart';

@immutable
class FolderItem {
  final String id;
  final String name;
  final String assetPath;
  final bool isDefault;
  final bool canRename;
  final bool canDelete;

  const FolderItem({
    required this.id,
    required this.name,
    required this.assetPath,
    this.isDefault = false,
    this.canRename = true,
    this.canDelete = true,
  });

  FolderItem copyWith({String? name}) => FolderItem(
    id: id,
    name: name ?? this.name,
    assetPath: assetPath,
    isDefault: isDefault,
    canRename: canRename,
    canDelete: canDelete,
  );
}

class ProjectBar extends StatelessWidget {
  const ProjectBar({
    super.key,
    required this.folders,
    this.selectedFolderId,
    this.onAddFolder,
    this.onSelectFolder,
    this.onRenameFolder,
    this.onDeleteFolder,
  });

  final List<FolderItem> folders;
  final String? selectedFolderId;

  final VoidCallback? onAddFolder;
  final ValueChanged<FolderItem>? onSelectFolder;
  final ValueChanged<FolderItem>? onRenameFolder;
  final ValueChanged<FolderItem>? onDeleteFolder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _FolderGrid(
            folders: folders,
            selectedFolderId: selectedFolderId,
            onAddFolder: onAddFolder,
            onSelectFolder: onSelectFolder,
            onRenameFolder: onRenameFolder,
            onDeleteFolder: onDeleteFolder,
          ),
        ),
      ),
    );
  }
}

class _FolderGrid extends StatelessWidget {
  const _FolderGrid({
    required this.folders,
    required this.selectedFolderId,
    required this.onAddFolder,
    required this.onSelectFolder,
    required this.onRenameFolder,
    required this.onDeleteFolder,
  });

  final List<FolderItem> folders;
  final String? selectedFolderId;

  final VoidCallback? onAddFolder;
  final ValueChanged<FolderItem>? onSelectFolder;
  final ValueChanged<FolderItem>? onRenameFolder;
  final ValueChanged<FolderItem>? onDeleteFolder;

  static const _crossAxisCount = 2;
  static const _spacing = 16.0;

  @override
  Widget build(BuildContext context) {
    final itemCount = folders.length + 1;

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        mainAxisSpacing: _spacing,
        crossAxisSpacing: _spacing,
        childAspectRatio: 181.5 / 149.0,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _AddFolderTile(onTap: onAddFolder);
        }

        final folder = folders[index - 1];
        final isSelected = folder.id == selectedFolderId;

        return _FolderTile(
          folder: folder,
          isSelected: isSelected,
          onTap: () => onSelectFolder?.call(folder),
          onRename: folder.canRename ? () => onRenameFolder?.call(folder) : null,
          onDelete: folder.canDelete ? () => onDeleteFolder?.call(folder) : null,
        );
      },
    );
  }
}

class _AddFolderTile extends StatelessWidget {
  const _AddFolderTile({required this.onTap});

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

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.folder,
    required this.isSelected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final FolderItem folder;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? Colors.black87 : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset(folder.assetPath),
              ),

              if (onRename != null || onDelete != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: _FolderMenuButton(
                    onRename: onRename,
                    onDelete: onDelete,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderMenuButton extends StatelessWidget {
  const _FolderMenuButton({this.onRename, this.onDelete});

  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_FolderMenuAction>(
      tooltip: 'Folder actions',
      icon: const Icon(Icons.more_vert, size: 18),
      padding: EdgeInsets.zero,
      itemBuilder: (context) {
        final items = <PopupMenuEntry<_FolderMenuAction>>[];
        if (onRename != null) {
          items.add(
            const PopupMenuItem(
              value: _FolderMenuAction.rename,
              child: Text('Rename'),
            ),
          );
        }
        if (onDelete != null) {
          items.add(
            const PopupMenuItem(
              value: _FolderMenuAction.delete,
              child: Text('Delete'),
            ),
          );
        }
        return items;
      },
      onSelected: (action) {
        switch (action) {
          case _FolderMenuAction.rename:
            onRename?.call();
            break;
          case _FolderMenuAction.delete:
            onDelete?.call();
            break;
        }
      },
    );
  }
}

enum _FolderMenuAction { rename, delete }
