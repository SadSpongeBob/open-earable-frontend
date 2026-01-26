enum ProjectRole {
  owner,
  editor,
  viewer;

  factory ProjectRole.fromString(String value) {
    return switch (value) {
      'OWNER' => ProjectRole.owner,
      'EDITOR' => ProjectRole.editor,
      'VIEWER' => ProjectRole.viewer,
      _ => throw ArgumentError.value(value, 'value', 'Invalid ProjectRole'),
    };
  }
}
