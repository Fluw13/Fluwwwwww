/// Why a request failed. Server codes come from the API v1 contract; the
/// others are detected on the device.
enum ApiErrorKind {
  network(
    'Không kết nối được máy chủ Fluw. Vui lòng kiểm tra mạng rồi thử lại.',
  ),
  timeout('Máy chủ phản hồi quá lâu. Vui lòng thử lại.'),
  cancelled('Yêu cầu đã được hủy.'),
  serverUnavailable('Máy chủ đang tạm lỗi. Vui lòng thử lại sau ít phút.'),
  invalidResponse('Dữ liệu máy chủ trả về không hợp lệ. Vui lòng thử lại sau.'),
  invalidQuery('Từ khóa tìm kiếm cần từ 2 đến 100 ký tự.'),
  invalidBarcode('Mã vạch không hợp lệ. Vui lòng quét hoặc nhập lại.'),
  badRequest('Yêu cầu không hợp lệ. Vui lòng thử lại.'),
  routeNotFound(
    'Phiên bản ứng dụng này gọi một địa chỉ máy chủ không còn tồn tại. Vui lòng cập nhật ứng dụng.',
  ),
  productNotFound('Không tìm thấy sản phẩm này trên Open Food Facts.'),
  rateLimited('Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.'),
  upstreamRateLimited(
    'Fluw đang tạm giới hạn số lượt tra cứu tới Open Food Facts. Vui lòng thử lại sau.',
  ),
  upstreamTimeout('Open Food Facts phản hồi quá lâu. Vui lòng thử lại.'),
  upstreamUnavailable(
    'Chưa kết nối được tới Open Food Facts. Vui lòng thử lại sau.',
  ),
  internalError('Máy chủ gặp lỗi. Vui lòng thử lại sau.'),
  unexpected('Máy chủ gặp lỗi không xác định. Vui lòng thử lại sau.');

  const ApiErrorKind(this.defaultMessage);

  final String defaultMessage;

  /// False when sending the same request again cannot give another result.
  bool get canRetry => switch (this) {
    cancelled ||
    invalidQuery ||
    invalidBarcode ||
    badRequest ||
    routeNotFound ||
    productNotFound => false,
    _ => true,
  };

  static ApiErrorKind? fromCode(String? code) => switch (code) {
    'INVALID_QUERY' => invalidQuery,
    'INVALID_BARCODE' => invalidBarcode,
    'BAD_REQUEST' => badRequest,
    'ROUTE_NOT_FOUND' => routeNotFound,
    'PRODUCT_NOT_FOUND' => productNotFound,
    'RATE_LIMITED' => rateLimited,
    'UPSTREAM_RATE_LIMITED' => upstreamRateLimited,
    'UPSTREAM_TIMEOUT' => upstreamTimeout,
    'UPSTREAM_UNAVAILABLE' => upstreamUnavailable,
    'INTERNAL_ERROR' => internalError,
    _ => null,
  };

  /// Used when the body carries no known code, e.g. a proxy's own error.
  static ApiErrorKind fromStatus(int statusCode) => switch (statusCode) {
    400 => badRequest,
    429 => rateLimited,
    500 => internalError,
    502 || 503 || 504 => serverUnavailable,
    >= 520 && <= 530 => serverUnavailable,
    _ => unexpected,
  };
}
