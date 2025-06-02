// lib/pages/attendance_history.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import '../services/auth_service.dart';

class AttendanceHistoryPage extends StatefulWidget {
  @override
  _AttendanceHistoryPageState createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String? _errorMessage;
  final Color _primaryColor = Color(0xFF143CFF);

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _setDefaultRange();
    _fetchHistory();
  }

  void _setDefaultRange() {
    // Get current time in Jakarta timezone
    final jakartaTime = DateTime.now().toUtc().add(Duration(hours: 7));
    
    // Find Monday of current week
    final startOfWeek = jakartaTime.subtract(Duration(days: jakartaTime.weekday - 1));
    // Set end to Saturday (Monday + 5 days)
    final endOfWeek = startOfWeek.add(Duration(days: 5));
    
    // Ensure we're working with date-only (no time component)
    _rangeStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    _rangeEnd = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
    
    print('Jakarta time: $jakartaTime');
    print('Week range: ${DateFormat('yyyy-MM-dd').format(_rangeStart!)} to ${DateFormat('yyyy-MM-dd').format(_rangeEnd!)}');
    print('Range start: $_rangeStart');
    print('Range end: $_rangeEnd');
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userId = AuthService.getUserId();
      if (userId == null) {
        setState(() {
          _errorMessage = 'User ID tidak ditemukan';
          _loading = false;
        });
        return;
      }

      if (_rangeStart == null || _rangeEnd == null) {
        setState(() {
          _errorMessage = 'Rentang tanggal tidak valid';
          _loading = false;
        });
        return;
      }

      final start = DateFormat('yyyy-MM-dd').format(_rangeStart!);
      final end = DateFormat('yyyy-MM-dd').format(_rangeEnd!);

      print('Fetching attendance history for user $userId from $start to $end');

      final history = await AuthService.getAttendanceHistory(
        userId,
        start,
        end,
      );

      // Get current Jakarta time (UTC+7)
      final jakartaTime = DateTime.now().toUtc().add(Duration(hours: 7));
      final todayOnly = DateTime(jakartaTime.year, jakartaTime.month, jakartaTime.day);
      
      // Filter to show only dates up to today (not future dates)
      final filteredHistory = history.where((item) {
        final itemDate = DateTime.parse(item['tgl_absen']);
        final itemDateOnly = DateTime(itemDate.year, itemDate.month, itemDate.day);
        return itemDateOnly.isBefore(todayOnly) || itemDateOnly.isAtSameMomentAs(todayOnly);
      }).toList();

      print('Jakarta current time: $jakartaTime');
      print('Today date only: $todayOnly');
      print('Total history received: ${history.length}');
      print('Filtered history (up to today): ${filteredHistory.length}');

      setState(() {
        _history = filteredHistory;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching attendance history: $e');
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _loading = false;
      });
    }
  }

  String _formatDay(DateTime date) {
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return '${days[date.weekday - 1]}, ${DateFormat('d MMMM yyyy', 'id_ID').format(date)}';
  }

  String _getStatusDisplay(String? status) {
    switch (status?.toLowerCase()) {
      case 'hadir':
        return 'Hadir';
      case 'terlambat':
        return 'Terlambat';
      case 'izin':
        return 'Izin';
      case 'sakit':
        return 'Sakit';
      case 'tidak hadir':
        return 'Tidak Hadir';
      default:
        return 'Tidak Hadir';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'hadir':
        return Colors.green;
      case 'terlambat':
        return Colors.orange;
      case 'izin':
        return Colors.blue;
      case 'sakit':
        return Colors.red;
      case 'tidak hadir':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'hadir':
        return HugeIcons.strokeRoundedFingerPrintCheck;
      case 'terlambat':
        return HugeIcons.strokeRoundedTimeQuarter02;
      case 'izin':
        return HugeIcons.strokeRoundedInformationCircle;
      case 'sakit':
        return HugeIcons.strokeRoundedMedicalFile;
      case 'tidak hadir':
        return HugeIcons.strokeRoundedHelpCircle;
      default:
        return HugeIcons.strokeRoundedHelpCircle;
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty || time == '00:00:00') {
      return '--:--';
    }

    try {
      // Parse time and format to HH:mm
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
    } catch (e) {
      print('Error formatting time: $e');
    }

    return '--:--';
  }

  Widget _buildSummaryStats() {
    if (_history.isEmpty) return SizedBox.shrink();

    int hadir = 0;
    int terlambat = 0;
    int tidakHadir = 0;
    int izin = 0;
    int sakit = 0;

    for (var item in _history) {
      switch (item['status']?.toString()?.toLowerCase()) {
        case 'hadir':
          hadir++;
          break;
        case 'terlambat':
          terlambat++;
          break;
        case 'tidak hadir':
          tidakHadir++;
          break;
        case 'izin':
          izin++;
          break;
        case 'sakit':
          sakit++;
          break;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 16,
            cornerSmoothing: 1,
          ),
          side: BorderSide(color: Colors.grey.shade100, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Absensi',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatItem('Hadir', hadir, Colors.green)),
              Expanded(
                child: _buildStatItem('Terlambat', terlambat, Colors.orange),
              ),
              Expanded(
                child: _buildStatItem('Tidak Hadir', tidakHadir, Colors.grey),
              ),
            ],
          ),
          if (izin > 0 || sakit > 0) ...[
            SizedBox(height: 8),
            Row(
              children: [
                if (izin > 0)
                  Expanded(child: _buildStatItem('Izin', izin, Colors.blue)),
                if (sakit > 0)
                  Expanded(child: _buildStatItem('Sakit', sakit, Colors.red)),
                if (izin == 0 || sakit == 0) Expanded(child: SizedBox()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: ShapeDecoration(
        color: color.withOpacity(0.1),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(cornerRadius: 8, cornerSmoothing: 1),
        ),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(32),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 20,
              cornerSmoothing: 1,
            ),
            side: BorderSide(color: Colors.grey.shade100, width: 2),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: ShapeDecoration(
                color: Colors.grey.shade100,
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 20,
                    cornerSmoothing: 1,
                  ),
                ),
              ),
              child: Icon(
                HugeIcons.strokeRoundedCalendarCheckOut01,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada data absensi',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pilih periode yang berbeda untuk melihat riwayat',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 20,
            cornerSmoothing: 1,
          ),
          side: BorderSide(
            color: Colors.grey.shade100,
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _history.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade100,
              thickness: 2,
            ),
            itemBuilder: (context, index) {
              final item = _history[index];
              final date = DateTime.parse(item['tgl_absen']);
              final status = item['status']?.toString();
              final statusDisplay = _getStatusDisplay(status);
              final statusColor = _getStatusColor(status);
              final statusIcon = _getStatusIcon(status);
              final jamIn = _formatTime(item['jam_in']?.toString());
              final jamOut = _formatTime(item['jam_out']?.toString());

              return ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: ShapeDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 10,
                        cornerSmoothing: 1,
                      ),
                    ),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  _formatDay(date),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Masuk: $jamIn · Keluar: $jamOut',
                    style: GoogleFonts.outfit(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: ShapeDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 6,
                        cornerSmoothing: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    statusDisplay,
                    style: GoogleFonts.outfit(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Riwayat Absensi',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        color: _primaryColor,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Enhanced Calendar Container
              Container(
                margin: EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 20,
                      cornerSmoothing: 1,
                    ),
                    side: BorderSide(color: Colors.grey.shade100, width: 2),
                  ),
                ),
                child: Column(
                  children: [
                    // Calendar Header
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: ShapeDecoration(
                        color: _primaryColor.withOpacity(0.05),
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                            cornerRadius: 20,
                            cornerSmoothing: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: ShapeDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              shape: SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius(
                                  cornerRadius: 10,
                                  cornerSmoothing: 1,
                                ),
                              ),
                            ),
                            child: Icon(
                              HugeIcons.strokeRoundedCalendar03,
                              color: _primaryColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pilih Periode',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Tap tanggal untuk memilih rentang',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Calendar Widget
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: TableCalendar<dynamic>(
                        locale: 'id_ID',
                        firstDay: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          1,
                        ),
                        lastDay: DateTime(
                          DateTime.now().year,
                          DateTime.now().month + 1,
                          0,
                        ),
                        focusedDay: _focusedDay,
                        rangeStartDay: _rangeStart,
                        rangeEndDay: _rangeEnd,
                        calendarFormat: CalendarFormat.month,
                        rangeSelectionMode: RangeSelectionMode.toggledOn,
                        onRangeSelected: (start, end, _) {
                          setState(() {
                            _rangeStart = start;
                            _rangeEnd = end ?? start;
                          });
                          _fetchHistory();
                        },
                        selectedDayPredicate: (day) {
                          if (_rangeStart == null || _rangeEnd == null) return false;
                          
                          // Don't select Sundays
                          if (day.weekday == 7) return false;
                          
                          // Check if day is within the selected range (inclusive)
                          return (day.isAfter(_rangeStart!.subtract(Duration(days: 1))) &&
                                  day.isBefore(_rangeEnd!.add(Duration(days: 1))));
                        },
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: Icon(
                            HugeIcons.strokeRoundedArrowLeft01,
                            color: _primaryColor,
                            size: 20,
                          ),
                          rightChevronIcon: Icon(
                            HugeIcons.strokeRoundedArrowRight01,
                            color: _primaryColor,
                            size: 20,
                          ),
                          titleTextStyle: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          headerPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          weekendTextStyle: GoogleFonts.outfit(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          holidayTextStyle: GoogleFonts.outfit(
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                          defaultTextStyle: GoogleFonts.outfit(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          selectedDecoration: ShapeDecoration(
                            color: _primaryColor,
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                cornerRadius: 8,
                                cornerSmoothing: 1,
                              ),
                              // side: BorderSide(color: _primaryColor, width: 2),
                            ),
                          ),
                          rangeStartDecoration: ShapeDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                cornerRadius: 8,
                                cornerSmoothing: 1,
                              ),
                              side: BorderSide(color: _primaryColor, width: 2),
                            ),
                          ),
                          rangeEndDecoration: ShapeDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                cornerRadius: 8,
                                cornerSmoothing: 1,
                              ),
                              side: BorderSide(color: _primaryColor, width: 2),
                            ),
                          ),
                          withinRangeDecoration: ShapeDecoration(
                            color: _primaryColor.withOpacity(0.05),
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                cornerRadius: 8,
                                cornerSmoothing: 1,
                              ),
                            ),
                          ),
                          todayDecoration: ShapeDecoration(
                            color: _primaryColor,
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                cornerRadius: 8,
                                cornerSmoothing: 1,
                              ),
                              // side: BorderSide(color: _primaryColor.withOpacity(0.5), width: 1),
                            ),
                          ),
                          rangeHighlightColor: _primaryColor,
                          tablePadding: EdgeInsets.zero,
                          cellMargin: EdgeInsets.all(4),
                        ),

                        // Updated DaysOfWeekStyle to handle Sunday as red
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: GoogleFonts.outfit(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          weekendStyle: GoogleFonts.outfit(
                            color: Colors.black54, // Saturday is normal
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),

                        // Add this method to customize day builder for Sunday specifically
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            // Make Sunday red
                            if (day.weekday == 7) {
                              return Container(
                                margin: EdgeInsets.all(4),
                                alignment: Alignment.center,
                                child: Text(
                                  '${day.day}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.red.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return null; // Use default for other days
                          },
                        ),

                      ),
                    ),
                  ],
                ),
              ),

              // Period Info Card
              if (_rangeStart != null && _rangeEnd != null)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: ShapeDecoration(
                    color: _primaryColor.withOpacity(0.05),
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 12,
                        cornerSmoothing: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        HugeIcons.strokeRoundedCalendarCheckIn01,
                        color: _primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Periode: ${DateFormat('d MMM', 'id_ID').format(_rangeStart!)} - ${DateFormat('d MMM yyyy', 'id_ID').format(_rangeEnd!)}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Summary Stats
              if (!_loading && _errorMessage == null) _buildSummaryStats(),

              SizedBox(height: 8),

              // Loading State
              if (_loading)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(32),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 20,
                        cornerSmoothing: 1,
                      ),
                      side: BorderSide(color: Colors.grey.shade100, width: 2),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: _primaryColor,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Memuat riwayat absensi...',
                        style: GoogleFonts.outfit(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Error State
              if (_errorMessage != null)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(32),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 20,
                        cornerSmoothing: 1,
                      ),
                      side: BorderSide(color: Colors.grey.shade100, width: 2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: ShapeDecoration(
                          color: Colors.red.shade50,
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 20,
                              cornerSmoothing: 1,
                            ),
                          ),
                        ),
                        child: Icon(
                          HugeIcons.strokeRoundedAlert02,
                          size: 48,
                          color: Colors.red.shade400,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Terjadi Kesalahan',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.black38,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),

              // History List
              if (!_loading && _errorMessage == null) _buildHistoryList(),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}