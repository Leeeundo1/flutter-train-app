import 'dart:math';

/// 좌석 정보를 저장하는 모델 클래스
class Seat {
  /// 좌석 ID (예: A1, B3 등)
  final String id;

  /// 좌석의 행 번호
  final String row;

  /// 좌석의 열 (A, B, C, D)
  final String column;

  /// 좌석 선택 여부
  bool isSelected;

  /// 좌석 예약 가능 여부
  final bool isAvailable;

  /// 좌석 생성자
  ///
  /// [id] 좌석 ID (예: A1, B3 등)
  /// [row] 좌석의 행 번호
  /// [column] 좌석의 열 (A, B, C, D)
  /// [isSelected] 좌석 선택 여부 (기본값: false)
  /// [isAvailable] 좌석 예약 가능 여부 (기본값: true)
  Seat({
    required this.id,
    required this.row,
    required this.column,
    this.isSelected = false,
    this.isAvailable = true,
  });

  /// 좌석 선택 상태를 토글합니다.
  void toggleSelection() {
    if (isAvailable) {
      isSelected = !isSelected;
    }
  }

  @override
  String toString() => 'Seat($id, 선택됨: $isSelected, 예약가능: $isAvailable)';
}

/// 좌석 열 목록 (A, B, C, D)
const List<String> seatColumns = ['A', 'B', 'C', 'D'];

/// 모든 좌석 데이터를 생성합니다.
List<Seat> generateSeats() {
  final List<Seat> seats = [];
  final random = Random();

  for (int row = 1; row <= 20; row++) {
    for (String column in seatColumns) {
      // 약 10%의 좌석은 예약 불가능하게 설정
      final bool isAvailable = random.nextDouble() > 0.1;

      seats.add(
        Seat(
          id: '$column$row',
          row: row.toString(),
          column: column,
          isAvailable: isAvailable,
        ),
      );
    }
  }

  return seats;
}
