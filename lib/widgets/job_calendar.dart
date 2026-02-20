import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_model.dart';

class JobCalendar extends StatefulWidget {
  final List<Job> jobs;
  final Color brandColor;

  const JobCalendar({
    super.key,
    required this.jobs,
    this.brandColor = const Color(0xFF2E7D6A),
  });

  @override
  State<JobCalendar> createState() => _JobCalendarState();
}

class _JobCalendarState extends State<JobCalendar> {
  DateTime _focusedDay = DateTime.now();
  final Color purpleHighlight = const Color(0xFF696CFF);

  List<DateTime> _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];
    
    // Add padding for start of month
    final firstWeekday = first.weekday; // 1 (Mon) to 7 (Sun)
    for (var i = 1; i < firstWeekday; i++) {
       days.add(first.subtract(Duration(days: firstWeekday - i)));
    }
    
    for (var i = 1; i <= last.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth(_focusedDay);
    final monthName = DateFormat('MMMM').format(_focusedDay);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(monthName),
          const SizedBox(height: 16),
          _buildWeekdayHeaders(),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.2,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isOutsideMonth = day.month != _focusedDay.month;
              return _buildDayCell(day, isOutsideMonth);
            },
          ),
          const SizedBox(height: 32),
          _buildDueInMonthSection(monthName),
        ],
      ),
    );
  }

  Widget _buildHeader(String monthName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
          icon: const Icon(Icons.chevron_left, color: Color(0xFF4B5563)),
        ),
        Text(
          monthName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
              icon: const Icon(Icons.chevron_right, color: Color(0xFF4B5563)),
            ),
            TextButton(
              onPressed: () => setState(() => _focusedDay = DateTime.now()),
              child: const Text('Today', style: TextStyle(color: Color(0xFF696CFF), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((d) => Expanded(
        child: Center(
          child: Text(
            d,
            style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDayCell(DateTime day, bool isOutsideMonth) {
    if (isOutsideMonth) return const SizedBox.shrink();

    final dayStart = DateTime(day.year, day.month, day.day);
    
    // Simple filter for completed jobs on this exact day
    final jobsOnDay = widget.jobs.where((j) {
      final jobDate = DateTime.tryParse(j.date);
      if (jobDate == null) return false;
      return jobDate.year == day.year && 
             jobDate.month == day.month && 
             jobDate.day == day.day && 
             j.status == 'completed';
    }).toList();
    
    final hasJob = jobsOnDay.isNotEmpty;
    final totalPrice = jobsOnDay.fold(0.0, (sum, j) => sum + (j.price ?? 0));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: hasJob ? FontWeight.w500 : FontWeight.normal,
            color: hasJob ? const Color(0xFF1F2937) : const Color(0xFF4B5563),
          ),
        ),
        if (hasJob && totalPrice > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '€${totalPrice.round()}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF696CFF),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDueInMonthSection(String monthName) {
    final jobsInMonth = widget.jobs.where((j) {
      final jobDate = DateTime.tryParse(j.date);
      if (jobDate == null) return false;
      return jobDate.year == _focusedDay.year && jobDate.month == _focusedDay.month && j.status == 'pending';
    }).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Due in $monthName',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 16),
        if (jobsInMonth.isEmpty)
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 20),
             child: Center(child: Text('No pending services this month', style: TextStyle(color: Colors.grey[500]))),
           )
        else
          ...jobsInMonth.map((job) => _buildDueJobItem(job)),
      ],
    );
  }

  Widget _buildDueJobItem(Job job) {
    final date = DateTime.tryParse(job.date) ?? DateTime.now();
    final dayStr = DateFormat('d').format(date);
    final monthStr = DateFormat('MMM').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(monthStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(dayStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              job.serviceName ?? 'Unnamed Service',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
          ),
        ],
      ),
    );
  }
}
