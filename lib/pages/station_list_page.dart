import 'package:flutter/material.dart';
import '../data/station_list.dart';

class StationListPage extends StatelessWidget {
  const StationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 인자 처리 및 예외 처리
    Map<String, dynamic>? args;
    try {
      args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('인자 형식 오류: $e');
      // 오류 시 기본값 사용
    }

    final isForDeparture = args?['isForDeparture'] as bool? ?? true;
    final excludeStation = args?['excludeStation'] as String?;
    final title = isForDeparture ? '출발역 선택' : '도착역 선택';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 제외할 역이 있으면 목록에서 제외
    List<String> filteredStations;
    try {
      if (stationList.isEmpty) {
        throw Exception('역 목록이 비어있습니다.');
      }

      filteredStations = excludeStation != null && excludeStation.isNotEmpty
          ? stationList.where((station) => station != excludeStation).toList()
          : List.from(stationList);
    } catch (e) {
      debugPrint('역 목록 필터링 오류: $e');
      // 오류 시 빈 리스트
      filteredStations = [];
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: filteredStations.isEmpty
          ? _buildEmptyStationList(context)
          : _buildStationListView(context, filteredStations, isDark),
    );
  }

  /// 역 목록이 비어있는 경우 표시
  Widget _buildEmptyStationList(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.train_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '역 목록을 불러올 수 없습니다.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  /// 역 목록 리스트뷰
  Widget _buildStationListView(
      BuildContext context, List<String> stations, bool isDark) {
    return SafeArea(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: stations.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark ? Colors.grey[700] : Colors.grey[300],
        ),
        itemBuilder: (context, index) {
          final station = stations[index];
          return ListTile(
            tileColor: isDark ? Colors.grey[850] : Colors.white,
            title: Text(
              station,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _selectStation(context, station),
          );
        },
      ),
    );
  }

  /// 역 선택 처리
  void _selectStation(BuildContext context, String station) {
    try {
      // 역 선택 시 이전 화면으로 결과 전달
      Navigator.pop(context, station);
    } catch (e) {
      debugPrint('역 선택 오류: $e');
      // 오류 시 단순히 뒤로 가기
      Navigator.pop(context);
    }
  }
}
