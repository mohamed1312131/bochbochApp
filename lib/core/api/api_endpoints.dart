abstract final class ApiEndpoints {
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // ── Auth ────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String loginGoogle = '/auth/login/google';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String verifyPhone = '/auth/verify-phone';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';

  // ── Products ────────────────────────────────────────────
  static const String products = '/products';
  static String product(String id) => '/products/$id';
  static String productStock(String id) => '/products/$id/stock';
  static String productImages(String id) => '/products/$id/images';
  static String productImage(String productId, String imageId) =>
      '/products/$productId/images/$imageId';

  // Legacy image upload (still referenced by product_repository.dart).
  // Retained for compat with Step 5 product flow.
  static const String imageUpload = '/images/upload';

  // ── Orders ──────────────────────────────────────────────
  static const String orders = '/orders';
  static String order(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';
  static String orderReturns(String id) => '/orders/$id/returns';
  static String orderReturn(String orderId, String returnId) =>
      '/orders/$orderId/returns/$returnId';
  static String orderInvoice(String id) => '/orders/$id/invoice';

  // ── Customers ───────────────────────────────────────────
  static const String customers = '/customers';
  static String customer(String id) => '/customers/$id';
  static String customerOrders(String id) => '/customers/$id/orders';
  static String customerStats(String id) => '/customers/$id/stats';

  // ── Dashboard & Profit ──────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String profitSummary = '/profit/summary';
  static const String profitByProduct = '/profit/by-product';
  static const String profitTrend = '/profit/trend';

  // ── AI Studio ───────────────────────────────────────────
  // Session lifecycle
  static const String aiSessions = '/ai/sessions';
  static String aiSession(String id) => '/ai/sessions/$id';
  static String aiSessionAbandon(String id) => '/ai/sessions/$id/abandon';

  // Photos (multipart upload per photo)
  static String aiSessionPhotos(String sessionId) =>
      '/ai/sessions/$sessionId/photos';

  // Analysis (Gemini — quota gated)
  static String aiSessionAnalyze(String sessionId) =>
      '/ai/sessions/$sessionId/analyze';

  // Captions (Gemini — quota gated, requires prior analyze)
  static String aiSessionCaptions(String sessionId) =>
      '/ai/sessions/$sessionId/captions';

  // Future: enhance, whatsapp, ad-creative

  // Mark a generation as used (moves assets from temp → permanent)
  static String aiGenerationUsed(String generationId) =>
      '/ai/generations/$generationId/used';

  // ── Notifications ────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationToken = '/notifications/token';
  static const String notificationPreferences = '/notifications/preferences';

  // ── Subscription ─────────────────────────────────────────
  static const String subscription = '/subscription';
  static const String subscriptionUpgrade = '/subscription/upgrade';

  // ── User ────────────────────────────────────────────────
  static const String userProfile = '/user/profile';
}
