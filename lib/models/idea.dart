class Idea {
  final String id;
  final String title;
  final String description;
  final bool filled;
  final int index;
  final String tag;
  final double x;
  final double y;
  final bool visible;
  final int upvotes; // New field for upvotes
  final List<String> comments; // New field for comments

  Idea({
    required this.id,
    required this.title,
    required this.description,
    required this.filled,
    required this.index,
    required this.tag,
    this.x = 0.0,
    this.y = 0.0,
    this.visible = true,
    this.upvotes = 0,
    this.comments = const [],
  });

  Idea copyWith({
    String? id,
    String? title,
    String? description,
    bool? filled,
    int? index,
    String? tag,
    double? x,
    double? y,
    bool? visible,
    int? upvotes,
    List<String>? comments,
  }) {
    return Idea(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      filled: filled ?? this.filled,
      index: index ?? this.index,
      tag: tag ?? this.tag,
      x: x ?? this.x,
      y: y ?? this.y,
      visible: visible ?? this.visible,
      upvotes: upvotes ?? this.upvotes,
      comments: comments ?? this.comments,
    );
  }
}
