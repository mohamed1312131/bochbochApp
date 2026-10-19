abstract final class ApiEndpoints {
  /// API base URL — set per-flavor via `--dart-define=API_BASE_URL=...`
  /// or `--dart-define-from-file=dart_defines/<flavor>.json`.
  ///
  /// Defaults to `http://localhost:3000/api/v1` for local development.
  /// Production builds MUST pass an HTTPS URL (release builds will
  /// otherwise leak tokens over plain HTTP).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

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
  static String orderExchanges(String id) => '/orders/$id/exchanges';
  static String orderIssues(String id) => '/orders/$id/issues';
  static String orderRto(String id) => '/orders/$id/rto';
  static String orderPartialFulfill(String id) =>
      '/orders/$id/partial-fulfill';
  static const String ordersBulkStatus = '/orders/bulk/status';
  static const String ordersBulkCancel = '/orders/bulk/cancel';

  // ── Customers ───────────────────────────────────────────
  static const String customers = '/customers';
  static String customer(String id) => '/customers/$id';
  static String customerOrders(String id) => '/customers/$id/orders';
  static String customerStats(String id) => '/customers/$id/stats';
  static String customerToggles(String id) => '/customers/$id/toggles';
  static String customerProfile(String id) => '/customers/$id/profile';
  static String customerRisk(String id) => '/customers/$id/risk';
  static String customerNotes(String id) => '/customers/$id/notes';
  static String customerNote(String customerId, String noteId) =>
      '/customers/$customerId/notes/$noteId';
  static String customerAddresses(String id) => '/customers/$id/addresses';
  static String customerAddress(String customerId, String addrId) =>
      '/customers/$customerId/addresses/$addrId';
  static String customerAddressDefault(String customerId, String addrId) =>
      '/customers/$customerId/addresses/$addrId/default';

  // ── Dashboard & Profit ──────────────────────────────────
  static const String dashboard = '/dashboard';
  static const String profitSummary = '/profit/summary';
  static const String profitByProduct = '/profit/by-product';
  static const String profitTrend = '/profit/trend';

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
