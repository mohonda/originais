import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomMonthCalendar extends StatefulWidget {
  final DateTime initialDate;
  final List<DateTime> openDays;
  final Function(DateTime) onDateSelected;

  const CustomMonthCalendar({
    super.key,
    required this.initialDate,
    required this.openDays,
    required this.onDateSelected,
  });

  @override
  State<CustomMonthCalendar> createState() => _CustomMonthCalendarState();
}

class _CustomMonthCalendarState extends State<CustomMonthCalendar> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  bool _isSedeOpen(DateTime date) {
    return widget.openDays.any((openDate) =>
        openDate.year == date.year &&
        openDate.month == date.month &&
        openDate.day == date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startingWeekdayOffset = firstDayOfMonth.weekday % 7;
    final previousMonthLastDay = DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;
    final totalCells = ((startingWeekdayOffset + daysInMonth) / 7).ceil() * 7;
    final rowCount = totalCells ~/ 7; // Quantidade de semanas exibidas (5 ou 6)

    return Column(
      children: [
        // --- CABEÇALHO (MÊS E SETAS) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              onPressed: _previousMonth,
            ),
            Text(
              DateFormat('MMMM yyyy', 'pt_BR').format(_focusedMonth).toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.blueAccent,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              onPressed: _nextMonth,
            ),
          ],
        ),

        // --- DIAS DA SEMANA ---
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 7,
          physics: const NeverScrollableScrollPhysics(),
          children: const ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB']
              .map(
                (day) => Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),

        // --- GRADE DINÂMICA (OCUPA TODO O ESPAÇO RESTANTE) ---
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calcula a proporção exata para preencher 100% da altura disponível
              final cellWidth = constraints.maxWidth / 7;
              final cellHeight = constraints.maxHeight / rowCount;
              final dynamicAspectRatio = cellWidth / cellHeight;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: dynamicAspectRatio > 0 ? dynamicAspectRatio : 1.0,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  DateTime date;
                  bool isCurrentMonth = true;

                  if (index < startingWeekdayOffset) {
                    final day = previousMonthLastDay - (startingWeekdayOffset - index - 1);
                    date = DateTime(_focusedMonth.year, _focusedMonth.month - 1, day);
                    isCurrentMonth = false;
                  } else if (index >= startingWeekdayOffset + daysInMonth) {
                    final day = index - (startingWeekdayOffset + daysInMonth) + 1;
                    date = DateTime(_focusedMonth.year, _focusedMonth.month + 1, day);
                    isCurrentMonth = false;
                  } else {
                    final day = index - startingWeekdayOffset + 1;
                    date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                  }

                  final isSelected = _isSameDay(date, _selectedDate);
                  final isOpen = _isSedeOpen(date);
                  final isToday = _isSameDay(date, DateTime.now());

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                        if (!isCurrentMonth) {
                          _focusedMonth = DateTime(date.year, date.month);
                        }
                      });
                      widget.onDateSelected(date);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            // ? Theme.of(context).primaryColor
                            ? Colors.grey.withValues(alpha: 0.15)
                            : (isOpen && isCurrentMonth
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.grey.withValues(alpha: 0.15)
                              : (isToday
                                  ? Colors.blueAccent
                                  : (isOpen && isCurrentMonth
                                      ? Colors.green
                                      : Colors.transparent)),
                          width: isSelected || isToday ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : (isCurrentMonth
                                      ? (isOpen ? Colors.green[400] : Colors.white)
                                      : Colors.white24),
                            ),
                          ),
                          if (isOpen && isCurrentMonth) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.lightGreenAccent
                                    : Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}