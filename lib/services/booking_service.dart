import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';

/// 예약 서비스 관련 예외
class BookingServiceException implements Exception {
  final String message;
  BookingServiceException(this.message);

  @override
  String toString() => 'BookingServiceException: $message';
}

/// 예약 정보를 관리하는 서비스
class BookingService {
  static const String _bookingsKey = 'bookings';

  /// 새로운 예약 정보 저장
  Future<bool> saveBooking(BookingModel booking) async {
    try {
      // 유효성 검사
      if (booking.departureStation.isEmpty) {
        throw BookingServiceException('출발역이 선택되지 않았습니다.');
      }

      if (booking.arrivalStation.isEmpty) {
        throw BookingServiceException('도착역이 선택되지 않았습니다.');
      }

      if (booking.selectedSeats.isEmpty) {
        throw BookingServiceException('좌석이 선택되지 않았습니다.');
      }

      // 기존 예약 정보 가져오기
      final bookings = await getBookings();

      // 새 예약 추가
      bookings.add(booking);

      // 저장
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = bookings.map((b) => b.toJson()).toList();
      final result = await prefs.setStringList(_bookingsKey, bookingsJson);

      if (!result) {
        throw BookingServiceException('예약 정보 저장 실패');
      }

      debugPrint('예약 정보 저장 성공: ${booking.toString()}');
      return true;
    } catch (e) {
      debugPrint('예약 정보 저장 오류: $e');
      if (e is BookingServiceException || e is BookingModelException) {
        rethrow;
      }
      throw BookingServiceException('예약 정보 저장 중 오류가 발생했습니다: $e');
    }
  }

  /// 모든 예약 정보 가져오기
  Future<List<BookingModel>> getBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getStringList(_bookingsKey) ?? [];

      final bookings = <BookingModel>[];

      // 각 JSON 문자열을 BookingModel로 변환
      for (final jsonStr in bookingsJson) {
        try {
          final booking = BookingModel.fromJson(jsonStr);
          bookings.add(booking);
        } catch (e) {
          // 오류가 있는 항목은 건너뜀
          debugPrint('손상된 예약 정보 건너뜀: $e');
        }
      }

      debugPrint('${bookings.length}개의 예약 레코드 로드됨');
      return bookings;
    } catch (e) {
      debugPrint('예약 정보 로드 오류: $e');
      throw BookingServiceException('예약 기록을 불러올 수 없습니다: $e');
    }
  }

  /// 모든 예약 정보 삭제
  Future<bool> clearBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(_bookingsKey);

      if (!result) {
        throw BookingServiceException('예약 기록 삭제 실패');
      }

      debugPrint('모든 예약 기록 삭제됨');
      return true;
    } catch (e) {
      debugPrint('예약 기록 삭제 오류: $e');
      throw BookingServiceException('예약 기록 삭제 중 오류가 발생했습니다: $e');
    }
  }
}
