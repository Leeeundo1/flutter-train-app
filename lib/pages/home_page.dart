import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final Function toggleThemeMode;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.toggleThemeMode,
    required this.isDarkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 상수 선언
  static const double _stationFontSize = 30.0;
  static const double _selectionFontSize = 24.0;
  static const double _buttonFontSize = 18.0;
  static const double _containerHeight = 200.0;
  static const double _borderRadius = 20.0;
  static const Color _primaryColor = Colors.purple;

  // 상태 변수
  String? departureStation;
  String? arrivalStation;
  List<BookingModel> _bookings = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookingHistory();
  }

  /// 예약 내역 불러오기
  Future<void> _loadBookingHistory() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final bookingService = BookingService();
      final bookings = await bookingService.getBookings();

      if (mounted) {
        setState(() {
          _bookings = bookings;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('예약 내역 로드 오류: $e');
      if (mounted) {
        setState(() {
          errorMessage = '예약 내역을 불러올 수 없습니다.';
          isLoading = false;
        });
      }
    }
  }

  /// 오류 메시지를 표시합니다.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 예매 내역 다이얼로그를 표시합니다.
  void _showBookingHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예매 내역'),
        content: SizedBox(
          width: double.maxFinite,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(
                      child: Text(errorMessage!,
                          style: const TextStyle(color: Colors.red)))
                  : _bookings.isEmpty
                      ? const Center(child: Text('예매 내역이 없습니다.'))
                      : _buildBookingHistoryList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          if (errorMessage != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadBookingHistory();
              },
              child: const Text('다시 시도'),
            ),
        ],
      ),
    );
  }

  /// 예약 내역 항목 위젯 생성
  Widget _buildBookingHistoryItem(BookingModel booking) {
    final bookingDate = booking.bookingDate;
    final formattedDate = bookingDate != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(bookingDate)
        : '날짜 정보 없음';

    return ListTile(
      title: Text(
        '${booking.departureStation} → ${booking.arrivalStation}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('예약일: $formattedDate'),
          Text('좌석: ${booking.selectedSeats.join(', ')}'),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  /// 예매 내역 리스트를 구성합니다.
  Widget _buildBookingHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _bookings.length,
      itemBuilder: (context, index) =>
          _buildBookingHistoryItem(_bookings[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
      appBar: _buildAppBar(),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStationSelectionContainer(isDark),
            const SizedBox(height: 20),
            _buildSeatSelectionButton(),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 앱바를 구성합니다.
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('기차 예매'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.list),
          onPressed: _showBookingHistoryDialog,
          tooltip: '예매 내역',
        ),
        IconButton(
          icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => widget.toggleThemeMode(),
          tooltip: widget.isDarkMode ? '라이트 모드로 전환' : '다크 모드로 전환',
        ),
      ],
    );
  }

  /// 역 선택 컨테이너를 구성합니다.
  Widget _buildStationSelectionContainer(bool isDark) {
    return Container(
      height: _containerHeight,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStationSelector(
            title: '출발역',
            station: departureStation,
            isForDeparture: true,
            excludeStation: arrivalStation,
          ),
          const Icon(
            Icons.arrow_circle_right_outlined,
            size: 30,
            color: Colors.grey,
          ),
          _buildStationSelector(
            title: '도착역',
            station: arrivalStation,
            isForDeparture: false,
            excludeStation: departureStation,
          ),
        ],
      ),
    );
  }

  /// 역 선택 위젯을 구성합니다.
  Widget _buildStationSelector({
    required String title,
    required String? station,
    required bool isForDeparture,
    required String? excludeStation,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateToStationList(isForDeparture, excludeStation),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: _stationFontSize,
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              station ?? '선택',
              style: const TextStyle(fontSize: _selectionFontSize),
            ),
          ],
        ),
      ),
    );
  }

  /// 역 선택 페이지로 이동합니다.
  Future<void> _navigateToStationList(
      bool isForDeparture, String? excludeStation) async {
    try {
      final result = await Navigator.pushNamed(
        context,
        '/station_list',
        arguments: {
          'isForDeparture': isForDeparture,
          'excludeStation': excludeStation,
        },
      );

      if (result != null && result is String) {
        setState(() {
          if (isForDeparture) {
            departureStation = result;
          } else {
            arrivalStation = result;
          }
        });
      }
    } catch (e) {
      debugPrint('역 선택 화면 이동 오류: $e');
      _showErrorSnackBar('역 선택 화면으로 이동할 수 없습니다.');
    }
  }

  /// 좌석 선택 버튼을 구성합니다.
  Widget _buildSeatSelectionButton() {
    final bool canSelectSeat =
        departureStation != null && arrivalStation != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSelectSeat ? () => _navigateToSeatPage() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        child: const Text(
          '좌석 선택',
          style: TextStyle(
            color: Colors.white,
            fontSize: _buttonFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 좌석 선택 페이지로 이동합니다.
  Future<void> _navigateToSeatPage() async {
    try {
      if (departureStation == null || arrivalStation == null) {
        _showErrorSnackBar('출발역과 도착역을 모두 선택해주세요.');
        return;
      }

      await Navigator.pushNamed(
        context,
        '/seat',
        arguments: {
          'departureStation': departureStation,
          'arrivalStation': arrivalStation,
        },
      );

      // 좌석 선택 화면에서 돌아오면 예매 내역 다시 로드
      _loadBookingHistory();
    } catch (e) {
      debugPrint('좌석 선택 화면 이동 오류: $e');
      _showErrorSnackBar('좌석 선택 화면으로 이동할 수 없습니다.');
    }
  }
}
