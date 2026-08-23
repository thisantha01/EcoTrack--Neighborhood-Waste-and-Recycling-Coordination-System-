import '../config/api_config.dart';
import '../models/community_post_model.dart';
import 'api_service.dart';

class CommunityService {
  final ApiService _api = ApiService();

  // ---- POSTS ----

  Future<List<CommunityPost>> getPosts({int page = 1}) async {
    final response = await _api.get(
      '${ApiConfig.communityPosts}?page=$page&limit=20',
      authenticated: true,
    );
    final postsList = response['posts'] as List? ?? [];
    return postsList
        .map((p) => CommunityPost.fromJson(Map<String, dynamic>.from(p)))
        .toList();
  }

  Future<CommunityPost> createPost({
    required String content,
    String? imageUrl,
    List<String> tags = const [],
  }) async {
    final response = await _api.post(
      ApiConfig.communityPosts,
      {
        'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'tags': tags,
      },
      authenticated: true,
    );
    return CommunityPost.fromJson(
      Map<String, dynamic>.from(response['post']),
    );
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    return await _api.post(
      ApiConfig.communityPostLike(postId),
      {},
      authenticated: true,
    );
  }

  Future<Map<String, dynamic>> addComment(String postId, String text) async {
    return await _api.post(
      ApiConfig.communityPostComment(postId),
      {'text': text},
      authenticated: true,
    );
  }

  Future<void> deletePost(String postId) async {
    await _api.delete(
      ApiConfig.communityPostDelete(postId),
      authenticated: true,
    );
  }
}
