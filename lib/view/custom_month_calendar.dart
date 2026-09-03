import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomMonthCalendar extends StatefulWidget {
  final DateTime initialDate;
  final List<DateTime> openDays;
  final Function(DateTime) onDateSelected;

  // 🟢 Novos parâmetros
  final DateTime? minDate; // Mês/ano limite inicial
  final DateTime? maxDate; // Mês/ano limite final
  final bool
  onlySelectPastOpenDays; // Trava seleção apenas para datas marcadas no passado

  const CustomMonthCalendar({
    super.key,
    required this.initialDate,
    required this.openDays,
    required this.onDateSelected,
    this.minDate,
    this.maxDate,
    this.onlySelectPastOpenDays = false,
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

  // 🟢 Validações de navegação de mês
  bool get _canGoPrevious {
    if (widget.minDate == null) return true;
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    final minMonth = DateTime(widget.minDate!.year, widget.minDate!.month);
    return !prevMonth.isBefore(minMonth);
  }

  bool get _canGoNext {
    if (widget.maxDate == null) return true;
    final nextMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    final maxMonth = DateTime(widget.maxDate!.year, widget.maxDate!.month);
    return !nextMonth.isAfter(maxMonth);
  }

  void _previousMonth() {
    if (_canGoPrevious) {
      setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      });
    }
  }

  void _nextMonth() {
    if (_canGoNext) {
      setState(() {
        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      });
    }
  }

  bool _isSedeOpen(DateTime date) {
    return widget.openDays.any(
      (openDate) =>
          openDate.year == date.year &&
          openDate.month == date.month &&
          openDate.day == date.day,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _getOperationalToday() {
    final now = DateTime.now();

    // Se for entre 00:00 e 06:00:00, o dia operacional ativo ainda é ONTEM
    if (now.hour < 6 || (now.hour == 6 && now.minute == 0)) {
      final ontem = now.subtract(const Duration(days: 1));
      return DateTime(ontem.year, ontem.month, ontem.day);
    }

    // Das 06:00:01 em diante, o dia operacional ativo passa a ser HOJE
    return DateTime(now.year, now.month, now.day);
  }

  // 🟢 2. Bloqueia qualquer data posterior ao Dia Operacional ativo
  bool _isFutureDate(DateTime date) {
    final opToday = _getOperationalToday();
    final targetDate = DateTime(date.year, date.month, date.day);

    return targetDate.isAfter(opToday);
  }

  // 🟢 Regra para permitir ou proibir o clique na data
  bool _isDateSelectable(DateTime date, bool isOpen) {
    if (widget.onlySelectPastOpenDays) {
      // Só é selecionável se estiver marcada (isOpen) E NÃO for futura
      if (!isOpen || _isFutureDate(date)) {
        return false;
      }
    }

    // Respeita minDate/maxDate caso informados
    if (widget.minDate != null) {
      final minDay = DateTime(
        widget.minDate!.year,
        widget.minDate!.month,
        widget.minDate!.day,
      );
      if (date.isBefore(minDay)) return false;
    }
    if (widget.maxDate != null) {
      final maxDay = DateTime(
        widget.maxDate!.year,
        widget.maxDate!.month,
        widget.maxDate!.day,
      );
      if (date.isAfter(maxDay)) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final startingWeekdayOffset = firstDayOfMonth.weekday % 7;
    final previousMonthLastDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      0,
    ).day;
    final totalCells = ((startingWeekdayOffset + daysInMonth) / 7).ceil() * 7;
    final rowCount = totalCells ~/ 7;

    return Column(
      children: [
        // --- CABEÇALHO (MÊS E SETAS) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              onPressed: _canGoPrevious
                  ? _previousMonth
                  : null, // 🟢 Desabilita a seta se minDate atingido
              color: _canGoPrevious ? null : Colors.white24,
            ),
            Text(
              DateFormat(
                'MMMM yyyy',
                'pt_BR',
              ).format(_focusedMonth).toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.blueAccent,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              onPressed: _canGoNext
                  ? _nextMonth
                  : null, // 🟢 Desabilita a seta se maxDate atingido
              color: _canGoNext ? null : Colors.white24,
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

        // --- GRADE DINÂMICA ---
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / 7;
              final cellHeight = constraints.maxHeight / rowCount;
              final dynamicAspectRatio = cellWidth / cellHeight;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: dynamicAspectRatio > 0
                      ? dynamicAspectRatio
                      : 1.0,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  DateTime date;
                  bool isCurrentMonth = true;

                  if (index < startingWeekdayOffset) {
                    final day =
                        previousMonthLastDay -
                        (startingWeekdayOffset - index - 1);
                    date = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                      day,
                    );
                    isCurrentMonth = false;
                  } else if (index >= startingWeekdayOffset + daysInMonth) {
                    final day =
                        index - (startingWeekdayOffset + daysInMonth) + 1;
                    date = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                      day,
                    );
                    isCurrentMonth = false;
                  } else {
                    final day = index - startingWeekdayOffset + 1;
                    date = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month,
                      day,
                    );
                  }

                  final isSelected = _isSameDay(date, _selectedDate);
                  final isOpen = _isSedeOpen(date);
                  final isToday = _isSameDay(date, DateTime.now());
                  final isSelectable = _isDateSelectable(
                    date,
                    isOpen,
                  ); // 🟢 Valida permissão de clique

                  return GestureDetector(
                    onTap: isSelectable
                        ? () {
                            setState(() {
                              _selectedDate = date;
                              if (!isCurrentMonth) {
                                _focusedMonth = DateTime(date.year, date.month);
                              }
                            });
                            widget.onDateSelected(date);
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.all(2),

                      // RETÂNGULO EXTERNO (Dia aberto / Hoje)
                      decoration: BoxDecoration(
                        color: (isOpen && isCurrentMonth)
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isToday
                              ? Colors.blueAccent
                              : (isOpen && isCurrentMonth
                                    ? Colors.green.withValues(alpha: 0.4)
                                    : Colors.transparent),
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 🟢 ÁREA DO NÚMERO COM A ESTRELA DE FUNDO QUANDO SELECIONADO
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 🟢 ESTRELA SUBSTIUINDO O CÍRCULO ATRÁS DO NÚMERO
                                if (isSelected)
                                  Icon(
                                    // Icons.star_rounded,
                                    Icons.sell_outlined,
                                    size: 40,
                                    color: Colors.amber.withValues(
                                      alpha: 0.4,
                                    ), // Altere a cor se preferir (ex: Colors.amber)
                                  ),

                                // NÚMERO DO DIA CENTRALIZADO
                                Text(
                                  '${date.day}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height:
                                        1.0, // Anula paddings da fonte para alinhamento perfeito
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: !isSelectable
                                        ? Colors.white12
                                        : (isSelected
                                              ? Colors.purple
                                              : (isCurrentMonth
                                                    ? (isOpen
                                                          ? Colors.green[400]
                                                          : Colors.white)
                                                    : Colors.white24)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 2),

                          // PONTO VERDE DE DIA ABERTO (MANTÉM ESPAÇAMENTO RESERVADO)
                          SizedBox(
                            height: 4,
                            child: (isOpen && isCurrentMonth && !isSelected)
                                ? Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
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
