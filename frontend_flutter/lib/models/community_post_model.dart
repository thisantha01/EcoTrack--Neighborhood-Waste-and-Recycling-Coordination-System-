class PostAuthor {
  final String id;
  final String name;
  final String? profilePicture;
  final String role;

  PostAuthor({
    required this.id,
    required this.name,
    this.profilePicture,
    required this.role,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      profilePicture: json['profilePicture'],
      role: json['role'] ?? '',
    );
  }
}

class PostComment {
  final String id;
  final PostAuthor user;
  final String text;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.user,
    required this.text,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['_id']?.toString() ?? '',
      user: PostAuthor.fromJson(
        Map<String, dynamic>.from(json['user'] ?? {}),
      ),
      text: json['text'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class CommunityPost {
  final String id;
  final PostAuthor author;
  final String content;
  final String? imageUrl;
  final List<String> likes;
  final List<PostComment> comments;
  final List<String> tags;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.author,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.tags,
    required this.createdAt,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final likesList = json['likes'] as List? ?? [];
    final commentsList = json['comments'] as List? ?? [];
    final tagsList = json['tags'] as List? ?? [];

    return CommunityPost(
      id: json['_id']?.toString() ?? '',
      author: PostAuthor.fromJson(
        json['author'] is Map
            ? Map<String, dynamic>.from(json['author'])
            : {},
      ),
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      likes: likesList.map((e) => e.toString()).toList(),
      comments: commentsList
          .map((c) => PostComment.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
      tags: tagsList.map((t) => t.toString()).toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
