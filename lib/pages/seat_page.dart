import 'package:flutter/material.dart';
import '../models/seat_model.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class SeatPage extends StatefulWidget {
  const SeatPage({super.key});

  @override
  State<SeatPage> createState() => _SeatPageState();
}

class _SeatPageState extends State<SeatPage> {
  // 상수 정의
  static const double _titleFontSize = 30.0;
  static const double _headerFontSize = 18.0;
  static const double _buttonFontSize = 18.0;
  static const double _seatSize = 50.0;
  static const double _statusIndicatorSize = 24.0;
  static const double _borderRadius = 8.0;
  static const Color _primaryColor = Colors.purple;

  // 상태 변수
  late final List<Seat> seats;
  final List<Seat> selectedSeats = [];
  bool isLoading = false;
  String? errorMessage;

  // 역 정보 상태
  String? departureStation;
  String? arrivalStation;

  @override
  void initState() {
    super.initState();
    try {
      seats = generateSeats();
    } catch (e) {
      debugPrint('좌석 생성 오류: $e');
      // 기본값으로 빈 목록 설정
      seats = [];
      if (mounted) {
        setState(() {
          errorMessage = '좌석 정보를 불러올 수 없습니다.';
        });
      }
    }
  }

  /// 예약 정보 저장
  Future<bool> _saveBookingInfo() async {
    if (selectedSeats.isEmpty) {
      _showErrorSnackBar('좌석을 선택해주세요.');
      return false;
    }

    if (departureStation == null || departureStation!.isEmpty) {
      _showErrorSnackBar('출발역을 선택해주세요.');
      return false;
    }

    if (arrivalStation == null || arrivalStation!.isEmpty) {
      _showErrorSnackBar('도착역을 선택해주세요.');
      return false;
    }

    final selectedSeatNumbers = selectedSeats.map((seat) => seat.id).toList();

    setState(() {
      isLoading = true;
    });

    try {
      final booking = BookingModel(
        departureStation: departureStation!,
        arrivalStation: arrivalStation!,
        selectedSeats: selectedSeatNumbers,
      );

      final bookingService = BookingService();
      final success = await bookingService.saveBooking(booking);

      if (success) {
        if (mounted) {
          _showSuccessAndNavigateBack('예약이 완료되었습니다.');
        }
        return true;
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = '예약 저장에 실패했습니다.';
          });
        }
        return false;
      }
    } catch (e) {
      debugPrint('예약 저장 오류: $e');
      String errorMsg = '예약 처리 중 오류가 발생했습니다.';

      if (e is BookingModelException) {
        errorMsg = e.message;
      } else if (e is BookingServiceException) {
        errorMsg = e.message;
      }

      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = errorMsg;
        });
        _showErrorSnackBar(errorMessage!);
      }
      return false;
    }
  }

  /// 성공 메시지를 표시합니다.
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 오류 메시지를 표시합니다.
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // 인자 검증
    if (args == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar('출발역과 도착역 정보가 없습니다.');
        Navigator.of(context).pop();
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 역 정보 상태 업데이트
    departureStation = args['departureStation'] as String? ?? '';
    arrivalStation = args['arrivalStation'] as String? ?? '';

    if (departureStation!.isEmpty || arrivalStation!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar('출발역 또는 도착역이 선택되지 않았습니다.');
        Navigator.of(context).pop();
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('좌석 선택'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildStationHeader(departureStation!, arrivalStation!),
              _buildSeatStatusIndicators(isDark),
              errorMessage != null
                  ? _buildErrorMessage()
                  : seats.isEmpty
                      ? _buildNoSeatsMessage()
                      : _buildSeatGridSection(isDark),
              _buildBookingButton(departureStation!, arrivalStation!),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  /// 오류 메시지 위젯을 구성합니다.
  Widget _buildErrorMessage() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? '오류가 발생했습니다.',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    try {
                      seats.clear();
                      seats.addAll(generateSeats());
                      errorMessage = null;
                    } catch (e) {
                      errorMessage = '좌석 정보를 다시 불러올 수 없습니다.';
                    }
                  });
                }
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  /// 좌석 없음 메시지 위젯을 구성합니다.
  Widget _buildNoSeatsMessage() {
    return const Expanded(
      child: Center(
        child: Text(
          '좌석 정보를 불러올 수 없습니다.\n다시 시도해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// 출발역-도착역 헤더를 구성합니다.
  Widget _buildStationHeader(String departureStation, String arrivalStation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            departureStation,
            style: const TextStyle(
              fontSize: _titleFontSize,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.arrow_circle_right_outlined,
            size: 30,
            color: Colors.grey,
          ),
          const SizedBox(width: 10),
          Text(
            arrivalStation,
            style: const TextStyle(
              fontSize: _titleFontSize,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 좌석 상태 표시 영역을 구성합니다.
  Widget _buildSeatStatusIndicators(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatusIndicator(
            color: _primaryColor,
            label: '선택됨',
            isDark: isDark,
          ),
          const SizedBox(width: 20),
          _buildStatusIndicator(
            color: Colors.grey[300]!,
            label: '선택안됨',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// 개별 상태 표시기를 구성합니다.
  Widget _buildStatusIndicator({
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: _statusIndicatorSize,
          height: _statusIndicatorSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  /// 좌석 그리드 섹션을 구성합니다.
  Widget _buildSeatGridSection(bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildColumnHeaders(isDark),
            Expanded(
              child: _buildSeatGrid(isDark),
            ),
          ],
        ),
      ),
    );
  }

  /// 열 헤더(A, B, C, D)를 구성합니다.
  Widget _buildColumnHeaders(bool isDark) {
    final textStyle = TextStyle(
      fontSize: _headerFontSize,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // A, B 열 헤더
          SizedBox(
            width: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('A', style: textStyle),
                Text('B', style: textStyle),
              ],
            ),
          ),

          // 중앙 공간
          const Spacer(),

          // C, D 열 헤더
          SizedBox(
            width: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('C', style: textStyle),
                Text('D', style: textStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 좌석 그리드를 구성합니다.
  Widget _buildSeatGrid(bool isDark) {
    try {
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 10,
        itemBuilder: (context, rowIndex) => _buildSeatRow(rowIndex + 1, isDark),
      );
    } catch (e) {
      debugPrint('좌석 그리드 구성 오류: $e');
      return Center(
        child: Text(
          '좌석 정보를 표시할 수 없습니다.',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      );
    }
  }

  /// 개별 좌석 행을 구성합니다.
  Widget _buildSeatRow(int rowNumber, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // A, B 열 좌석
          _buildSeatGroupForColumns(['A', 'B'], rowNumber, isDark),

          // 중앙에 행 번호 표시
          Expanded(
            child: Center(
              child: Text(
                rowNumber.toString(),
                style: TextStyle(
                  fontSize: _headerFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),

          // C, D 열 좌석
          _buildSeatGroupForColumns(['C', 'D'], rowNumber, isDark),
        ],
      ),
    );
  }

  /// 특정 열 그룹의 좌석들을 구성합니다.
  Widget _buildSeatGroupForColumns(
      List<String> columns, int rowNumber, bool isDark) {
    return SizedBox(
      width: 130,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: columns.map((column) {
          try {
            return _buildSeat(column, rowNumber, isDark);
          } catch (e) {
            debugPrint('좌석 생성 오류 ($column$rowNumber): $e');
            // 오류 시 빈 컨테이너 반환
            return Container(
              width: _seatSize,
              height: _seatSize,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  /// 개별 좌석을 구성합니다.
  Widget _buildSeat(String column, int rowNumber, bool isDark) {
    // 안전하게 좌석 찾기
    Seat? seat;
    try {
      seat = seats.firstWhere(
        (s) => s.row == rowNumber.toString() && s.column == column,
      );
    } catch (e) {
      debugPrint('좌석을 찾을 수 없음 ($column$rowNumber): $e');
      // 좌석을 찾을 수 없는 경우 기본 좌석 생성
      seat = Seat(
        id: '$column$rowNumber',
        row: rowNumber.toString(),
        column: column,
        isAvailable: false,
      );
    }

    return GestureDetector(
      onTap: () => _toggleSeatSelection(seat!),
      child: Container(
        width: _seatSize,
        height: _seatSize,
        decoration: BoxDecoration(
          color: _getSeatColor(seat!),
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        child: !seat.isAvailable
            ? const Icon(Icons.close, color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  /// 좌석 선택 상태를 토글합니다.
  void _toggleSeatSelection(Seat seat) {
    if (!seat.isAvailable) {
      _showErrorSnackBar('이미 예약된 좌석입니다.');
      return;
    }

    setState(() {
      seat.toggleSelection();
      if (seat.isSelected) {
        selectedSeats.add(seat);
      } else {
        selectedSeats.remove(seat);
      }
    });
  }

  /// 좌석 상태에 따른 색상을 반환합니다.
  Color _getSeatColor(Seat seat) {
    if (!seat.isAvailable) {
      return Colors.grey;
    }
    return seat.isSelected ? _primaryColor : Colors.grey[300]!;
  }

  /// 예매 버튼을 구성합니다.
  Widget _buildBookingButton(String departureStation, String arrivalStation) {
    return Container(
      width: double.infinity,
      height: 56,
      color: _primaryColor,
      child: TextButton(
        onPressed: (selectedSeats.isEmpty || isLoading)
            ? null
            : () => _showBookingConfirmDialog(
                context, departureStation, arrivalStation),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withOpacity(0.6),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                '예매 하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _buttonFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// 예매 확인 다이얼로그를 표시합니다.
  void _showBookingConfirmDialog(
      BuildContext context, String departureStation, String arrivalStation) {
    if (selectedSeats.isEmpty) {
      _showErrorSnackBar('최소 한 개 이상의 좌석을 선택해주세요.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) => WillPopScope(
        onWillPop: () async => !isLoading,
        child: AlertDialog(
          title: const Text('예매 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('출발역: $departureStation'),
              Text('도착역: $arrivalStation'),
              const SizedBox(height: 8),
              Text('선택한 좌석: ${selectedSeats.map((s) => s.id).join(', ')}'),
            ],
          ),
          actions: [
            if (!isLoading)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => _completeBooking(
                      context, departureStation, arrivalStation),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  /// 예매를 완료합니다.
  Future<void> _completeBooking(BuildContext context, String departureStation,
      String arrivalStation) async {
    // 예매 정보 저장
    final success = await _saveBookingInfo();

    if (success) {
      // 첫 화면으로 돌아감
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      // 다이얼로그만 닫음
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showSuccessAndNavigateBack(String message) {
    if (mounted) {
      _showSuccessSnackBar(message);
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
