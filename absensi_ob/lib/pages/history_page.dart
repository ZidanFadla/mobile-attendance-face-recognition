import 'package:flutter/material.dart';
import 'package:absensi_ob/models/attendance_record.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/app_theme.dart';

class HistoryPage extends StatefulWidget {
  final List<AttendanceRecord> records;

  const HistoryPage({super.key, required this.records});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, List<AttendanceRecord>> _groupedRecords;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _groupRecords();
  }

  void _groupRecords() {
    _groupedRecords = {};
    for (var record in widget.records) {
      final date = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      if (_groupedRecords[date] == null) {
        _groupedRecords[date] = [];
      }
      _groupedRecords[date]!.add(record);
    }
  }

  List<AttendanceRecord> _getRecordsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _groupedRecords[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedRecords = _getRecordsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Attendance History',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: AppTheme.armyGreen,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: AppTheme.armyGreen,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: AppTheme.armyGreen.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.armyGreen,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppTheme.accentOrange,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                defaultTextStyle: const TextStyle(color: AppTheme.textDark),
                weekendTextStyle: const TextStyle(color: AppTheme.textDark),
              ),
              eventLoader: _getRecordsForDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          // Records list
          Expanded(
            child: selectedRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: AppTheme.textMuted.withValues(alpha: 0.45),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada absensi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pada tanggal ${DateFormat('dd MMM yyyy').format(_selectedDay)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: selectedRecords.length,
                    itemBuilder: (context, index) {
                      final record = selectedRecords[index];
                      return _buildRecordCard(record);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(AttendanceRecord record) {
    final isMasuk = record.type == 'Masuk';
    final color = isMasuk ? AppTheme.armyGreen : AppTheme.accentOrange;
    final bgColor = isMasuk
        ? AppTheme.armyGreen.withValues(alpha: 0.1)
        : AppTheme.accentOrange.withValues(alpha: 0.1);

    // Get day of month
    final dayOfMonth = record.timestamp.day;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayOfMonth',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(record.timestamp),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Record details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('HH:mm a').format(record.timestamp),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isMasuk ? 'Clock In' : 'Clock Out',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          record.locationName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.name} • ${record.phoneNumber}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
