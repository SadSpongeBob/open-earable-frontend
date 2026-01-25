class Video {
  final String id;
  final String? name;

  const Video({required this.id, this.name});

  factory Video.fromJson(Map<String, dynamic> json) => Video(
    id: json['id'] as String,
    name: json['name'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}
