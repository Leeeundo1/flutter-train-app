import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// 예약 모델에서 발생하는 예외
class BookingModelException implements Exception {
  final String message;
  BookingModelException(this.message);

  @override
  String toString() => 'BookingModelException: $message';
}

/// 기차 예약 정보를 담고 있는 모델 클래스
class BookingModel {
  /// 고유 식별자
  final String id;

  /// 출발역
  final String departureStation;

  /// 도착역
  final String arrivalStation;

  /// 선택된 좌석 번호들
  final List<String> selectedSeats;

  /// 예약 생성 일시
  final DateTime bookingDate;

  BookingModel({
    String? id,
    required this.departureStation,
    required this.arrivalStation,
    required this.selectedSeats,
    DateTime? bookingDate,
  })  : this.id = id ?? const Uuid().v4(),
        this.bookingDate = bookingDate ?? DateTime.now() {
    // 유효성 검사
    _validateBookingData();
  }

  /// 예약 데이터 유효성 검사
  void _validateBookingData() {
    if (departureStation.isEmpty) {
      throw BookingModelException('출발역은 필수입니다.');
    }

    if (arrivalStation.isEmpty) {
      throw BookingModelException('도착역은 필수입니다.');
    }

    if (selectedSeats.isEmpty) {
      throw BookingModelException('최소 하나 이상의 좌석을 선택해야 합니다.');
    }

    if (departureStation == arrivalStation) {
      throw BookingModelException('출발역과 도착역이 같을 수 없습니다.');
    }
  }

  /// 객체를 맵으로 변환
  Map<String, dynamic> toMap() {
    try {
      return {
        'id': id,
        'departureStation': departureStation,
        'arrivalStation': arrivalStation,
        'selectedSeats': selectedSeats,
        'bookingDate': bookingDate.toIso8601String(),
      };
    } catch (e) {
      debugPrint('BookingModel.toMap 오류: $e');
      throw BookingModelException('예약 정보를 변환할 수 없습니다: $e');
    }
  }

  /// 맵을 객체로 변환
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    try {
      // 필수 필드 검증
      if (!map.containsKey('departureStation') ||
          !map.containsKey('arrivalStation')) {
        throw BookingModelException('역 정보가 누락되었습니다.');
      }

      // 안전한 값 추출
      final List<String> seats = _parseSeats(map);

      return BookingModel(
        id: map['id'] as String? ?? const Uuid().v4(),
        departureStation: map['departureStation'] as String? ?? '',
        arrivalStation: map['arrivalStation'] as String? ?? '',
        selectedSeats: seats,
        bookingDate: map.containsKey('bookingDate')
            ? DateTime.parse(map['bookingDate'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('BookingModel.fromMap 오류: $e');
      throw BookingModelException('예약 정보를 변환할 수 없습니다: $e');
    }
  }

  /// 좌석 목록 안전하게 파싱
  static List<String> _parseSeats(Map<String, dynamic> map) {
    try {
      if (!map.containsKey('selectedSeats')) {
        return [];
      }

      final dynamic seats = map['selectedSeats'];

      if (seats is List) {
        return seats.map((e) => e.toString()).toList();
      } else if (seats is String) {
        // JSON 문자열인 경우 디코딩
        try {
          final decodedList = jsonDecode(seats);
          if (decodedList is List) {
            return decodedList.map((e) => e.toString()).toList();
          }
        } catch (_) {
          // JSON 파싱 실패 시 빈 문자열 처리
        }
      }
      return [];
    } catch (e) {
      debugPrint('좌석 파싱 오류: $e');
      return [];
    }
  }

  /// 객체를 JSON 문자열로 변환
  String toJson() => jsonEncode(toMap());

  /// JSON 문자열을 객체로 변환
  factory BookingModel.fromJson(String source) {
    try {
      return BookingModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('BookingModel.fromJson 오류: $e');
      throw BookingModelException('JSON을 예약 정보로 변환할 수 없습니다: $e');
    }
  }

  /// 복사본 생성 (불변성 유지)
  BookingModel copyWith({
    String? id,
    String? departureStation,
    String? arrivalStation,
    List<String>? selectedSeats,
    DateTime? bookingDate,
  }) {
    try {
      return BookingModel(
        id: id ?? this.id,
        departureStation: departureStation ?? this.departureStation,
        arrivalStation: arrivalStation ?? this.arrivalStation,
        selectedSeats: selectedSeats ?? List.from(this.selectedSeats),
        bookingDate: bookingDate ?? this.bookingDate,
      );
    } catch (e) {
      debugPrint('BookingModel.copyWith 오류: $e');
      throw BookingModelException('예약 정보 복사 중 오류 발생: $e');
    }
  }

  @override
  String toString() {
    return '예약 정보(ID: $id): $departureStation → $arrivalStation, 좌석: ${selectedSeats.join(", ")}';
  }
}
