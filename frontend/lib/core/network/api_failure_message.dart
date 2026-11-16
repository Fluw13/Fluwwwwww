import 'package:fluw/core/network/api_failure.dart';

String apiFailureMessage(ApiFailure failure) => switch (failure) {
  NetworkFailure() => 'Không kết nối được máy chủ. Hãy kiểm tra mạng rồi thử lại.',
  TimeoutFailure() => 'Máy chủ phản hồi quá lâu. Hãy thử lại sau ít phút.',
  ServerFailure(:final message) => message,
  InvalidResponseFailure() => 'Máy chủ trả dữ liệu không đọc được. Hãy thử lại sau.',
};
