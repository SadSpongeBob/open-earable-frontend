enum ProjectRole {
  owner,
  editor,
  viewer;

  bool canViewVideos() {
    return true;
  }

  bool canEditVideos() {
    return this == editor || this == owner;
  }

  bool canRecord() {
    return canEditVideos();
  }

  bool canManageUsers() {
    return this == owner;
  }

  factory ProjectRole.fromString(String value) {
    return switch (value) {
      'OWNER' => ProjectRole.owner,
      'EDITOR' => ProjectRole.editor,
      'VIEWER' => ProjectRole.viewer,
      _ => throw ArgumentError.value(value, 'value', 'Invalid ProjectRole'),
    };
  }
}
