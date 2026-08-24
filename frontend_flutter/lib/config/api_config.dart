import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://192.168.8.104:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  // Auth
  static String get register => '$baseUrl/auth/register';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get verifyResetOtp => '$baseUrl/auth/verify-reset-otp';
  static String get resetPassword => '$baseUrl/auth/reset-password';
  static String get me => '$baseUrl/auth/me';

  // Profile
  static String get profile => '$baseUrl/profile';

  // Community Posts
  static String get communityPosts => '$baseUrl/community/posts';
  static String communityPostLike(String id) => '$baseUrl/community/posts/$id/like';
  static String communityPostComment(String id) => '$baseUrl/community/posts/$id/comments';
  static String communityPostDelete(String id) => '$baseUrl/community/posts/$id';

  // Cleanup Events
  static String get cleanupEvents => '$baseUrl/community/events';
  static String cleanupEvent(String id) => '$baseUrl/community/events/$id';
  static String cleanupEventJoin(String id) => '$baseUrl/community/events/$id/join';
  static String cleanupEventStatus(String id) => '$baseUrl/community/events/$id/status';

  // Announcements
  static String get announcements => '$baseUrl/community/announcements';
  static String announcement(String id) => '$baseUrl/community/announcements/$id';

  // Community Reports
  static String get communityReports => '$baseUrl/community/reports';
  static String communityReport(String id) => '$baseUrl/community/reports/$id';
  static String communityReportUpvote(String id) => '$baseUrl/community/reports/$id/upvote';
  static String communityReportInfo(String id) => '$baseUrl/community/reports/$id/info';
  static String communityReportStatus(String id) => '$baseUrl/community/reports/$id/status';

  // Collection Requests
  static String get collectionRequests => '$baseUrl/collection-requests';
  static String get myCollectionRequests => '$baseUrl/collection-requests/my';
  static String get allCollectionRequests => '$baseUrl/collection-requests/all';
  static String collectionRequest(String id) => '$baseUrl/collection-requests/$id';
  static String collectionRequestStatus(String id) => '$baseUrl/collection-requests/$id/status';
  static String collectionRequestCancel(String id) => '$baseUrl/collection-requests/$id/cancel';

  // Engagement
  static String get myEngagement => '$baseUrl/community/engagement/me';
  static String get leaderboard => '$baseUrl/community/engagement/leaderboard';
  static String get communityStats => '$baseUrl/community/engagement/stats';

  // Manager - Collection Requests
  static String get managerCollectionRequests => '$baseUrl/manager/collection-requests';
  static String managerRequestDetail(String id) => '$baseUrl/manager/collection-requests/$id';
  static String managerAssignDriver(String id) => '$baseUrl/manager/collection-requests/$id/assign-driver';

  // Manager - Drivers
  static String get managerAvailableDrivers => '$baseUrl/manager/drivers/available';
}