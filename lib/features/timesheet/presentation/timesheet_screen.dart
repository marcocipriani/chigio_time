import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/chigio_phrase_engine.dart';
import '../../../core/services/italian_holidays.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/timesheet_repository.dart';
import '../data/pdf_export_service.dart';
import '../data/csv_import_service.dart';
import '../data/csv_export_service.dart';
import '../domain/daily_timesheet.dart';
import '../domain/absence_kind.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_header.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/profile/data/profile_repository.dart';
import '../../../shared/widgets/monthly_summary_card.dart';
import '../../profile/presentation/profile_screen.dart'
    show showCountersCustomizer;

// ── View modes ──────────────────────────────────────────────────────────
enum _ViewMode { day, list, week, month, year }

class TimesheetScreen extends ConsumerStatefulWidget {
  const TimesheetScreen({super.key});

  @override
  ConsumerState<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends ConsumerState<TimesheetScreen> {
  late int _year;
  late int _month;
  int? _selectedDay;
  _ViewMode _viewMode = _ViewMode.day;

  // List-view scroll controller + auto-scroll-to-today guard
  final _listScrollController = ScrollController();
  String _listScrollKey = ''; // '$year-$month' — scrolled once per combo

  static const _italianMonths = AppStrings.months;
  static const _dayLabels = AppStrings.weekdayLetters;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _selectedDay = now.day;
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  void _prevMonth() => setState(() {
    if (_month == 1) {
      _month = 12;
      _year--;
    } else {
      _month--;
    }
    _selectedDay = null;
  });

  void _nextMonth() => setState(() {
    if (_month == 12) {
      _month = 1;
      _year++;
    } else {
      _month++;
    }
    _selectedDay = null;
  });

  void _prevWeek() {
    final anchor = DateTime(_year, _month, _selectedDay ?? DateTime.now().day);
    final d = anchor.subtract(const Duration(days: 7));
    setState(() {
      _year = d.year;
      _month = d.month;
      _selectedDay = d.day;
    });
  }

  void _nextWeek() {
    final anchor = DateTime(_year, _month, _selectedDay ?? DateTime.now().day);
    final d = anchor.add(const Duration(days: 7));
    setState(() {
      _year = d.year;
      _month = d.month;
      _selectedDay = d.day;
    });
  }

  String _p2(int n) => n.toString().padLeft(2, '0');
  String _fmtTime(DateTime dt) => '${_p2(dt.hour)}:${_p2(dt.minute)}';
  String _fmtNet(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${_p2(h)}:${_p2(m)}';
  }

  String _weekRangeLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    const ms = AppStrings.monthsShort;
    if (weekStart.month == weekEnd.month) {
      return '${weekStart.day}–${weekEnd.day} ${ms[weekStart.month - 1]} ${weekStart.year}';
    }
    return '${weekStart.day} ${ms[weekStart.month - 1]} – ${weekEnd.day} ${ms[weekEnd.month - 1]}';
  }

  Color _dotColor(DailyTimesheet e) {
    if (e.isRemote) return AppColors.blue600;
    if (e.isHoliday) return AppColors.amber600;
    if (e.isLeave) return AppColors.purple600;
    if (e.extraMins > 0) return AppColors.orange500;
    return AppColors.green500;
  }

  ({String emoji, String label, Color color}) _typeInfo(String? wt) =>
      switch (wt) {
        WorkType.remote => (
          emoji: '🏠',
          label: AppStrings.wtRemote,
          color: AppColors.blue600,
        ),
        WorkType.leave => (
          emoji: '🚶',
          label: AppStrings.wtLeave,
          color: AppColors.purple600,
        ),
        WorkType.holiday => (
          emoji: '🌴',
          label: AppStrings.wtHoliday,
          color: AppColors.amber600,
        ),
        _ => (
          emoji: '🏢',
          label: AppStrings.wtPresence,
          color: AppColors.green600,
        ),
      };

  String? _holidayLabel(int day) =>
      ItalianHolidays.label(DateTime(_year, _month, day));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    final tsAsync = ref.watch(
      monthlyTimesheetsProvider((year: _year, month: _month)),
    );
    final profileData = ref.watch(userProfileStreamProvider).asData?.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const GlassHeader(chigioPage: ChigioPage.timesheet),
            _GlassToolbar(
              viewMode: _viewMode,
              onViewChanged: (v) => setState(() => _viewMode = v),
              onExportTap: () => _showExportSheet(context, profileData),
              onImportTap: () => _showImportSheet(context, profileData),
            ),
            Expanded(
              child: tsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text(AppStrings.errorGeneric(e))),
                data: (entries) {
                  final map = <int, DailyTimesheet>{
                    for (final e in entries) _dayOfMonth(e.dateId): e,
                  };
                  return _buildContent(
                    context,
                    isDark,
                    textMain,
                    textSub,
                    map,
                    profileData,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textSub,
    Map<int, DailyTimesheet> map,
    Map<String, dynamic>? profileData,
  ) {
    final mealThreshold =
        profileData?['mealVoucherThresholdMins'] as int? ?? 380;
    final totalNet = map.values.fold<int>(0, (s, e) => s + e.netWorkedMins);
    final totalOT = map.values.fold<int>(
      0,
      (s, e) => s + (e.extraMins > 0 ? e.extraMins : 0),
    );
    final totalMeal = map.values
        .where((e) => e.netWorkedMins >= mealThreshold)
        .length;
    final art9Mins = map.values.fold<int>(0, (s, e) => s + e.leavePauseMins);
    final sliMins = map.values.fold<int>(0, (s, e) => s + e.sliMins);
    final sboMins = map.values.fold<int>(0, (s, e) => s + e.sboMins);
    final deficitMins = map.values.fold<int>(
      0,
      (s, e) => s + (e.extraMins < 0 ? -e.extraMins : 0),
    );
    final swCount = map.values.where((e) => e.isRemote).length;
    var swYearCount = 0;
    for (var m = 1; m <= 12; m++) {
      final monthEntries =
          ref
              .watch(monthlyTimesheetsProvider((year: _year, month: m)))
              .asData
              ?.value ??
          const <DailyTimesheet>[];
      swYearCount += monthEntries.where((e) => e.isRemote).length;
    }
    final art9Cap = (profileData?['monthlyArt9Hours'] as int? ?? 0) * 60;
    final sliCap = (profileData?['monthlySliHours'] as int? ?? 0) * 60;
    final sboCap = (profileData?['monthlySboHours'] as int? ?? 0) * 60;
    final otCap = (profileData?['monthlyOvertimeHours'] as int? ?? 0) * 60;
    final visibleItems =
        (profileData?['summaryItems'] as List<dynamic>?)?.cast<String>() ??
        MonthlySummaryCard.defaultItems;
    final showProgressBars =
        profileData?['summaryShowProgress'] as bool? ?? true;

    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final firstWeekday = DateTime(_year, _month, 1).weekday;
    final selectedEntry = _selectedDay != null ? map[_selectedDay] : null;

    // Shared collapsible monthly card used in all three views
    final summaryCard = MonthlySummaryCard(
      year: _year,
      month: _month,
      totalNetMins: totalNet,
      totalOtMins: totalOT,
      totalMeal: totalMeal,
      art9Mins: art9Mins,
      sliMins: sliMins,
      sboMins: sboMins,
      deficitMins: deficitMins,
      art9Cap: art9Cap,
      sliCap: sliCap,
      sboCap: sboCap,
      overtimeCap: otCap,
      visibleItems: visibleItems,
      showProgressBars: showProgressBars,
      swCount: swCount,
      swYearCount: swYearCount,
      onPrevMonth: _prevMonth,
      onNextMonth: _nextMonth,
      onMonthTap: () => _showMonthPicker(context, isDark),
      onEditTap: () => showCountersCustomizer(context, ref, profileData ?? {}),
    );

    switch (_viewMode) {
      case _ViewMode.month:
        final isDesktop = MediaQuery.sizeOf(context).width >= 800.0;
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 260,
                child: _buildDayList(
                  context,
                  isDark,
                  textMain,
                  textSub,
                  map,
                  daysInMonth,
                  mealThreshold,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
                  children: _calendarChildren(
                    context,
                    isDark,
                    textMain,
                    textSub,
                    map,
                    daysInMonth,
                    firstWeekday,
                    selectedEntry,
                    summaryCard,
                    mealThreshold,
                  ),
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          children: _calendarChildren(
            context,
            isDark,
            textMain,
            textSub,
            map,
            daysInMonth,
            firstWeekday,
            selectedEntry,
            summaryCard,
            mealThreshold,
          ),
        );

      case _ViewMode.week:
        return _buildWeekView(
          context,
          isDark,
          textMain,
          textSub,
          map,
          selectedEntry,
          summaryCard,
          mealThreshold,
        );

      case _ViewMode.list:
        return _buildListView(
          context,
          isDark,
          textMain,
          textSub,
          map,
          daysInMonth,
          summaryCard,
          mealThreshold,
        );

      case _ViewMode.day:
        return _buildDayView(
          context,
          isDark,
          textMain,
          textSub,
          selectedEntry,
          mealThreshold,
        );

      case _ViewMode.year:
        return _YearView(
          year: _year,
          isDark: isDark,
          onPrevYear: () => setState(() => _year--),
          onNextYear: () => setState(() => _year++),
          onDayTap: (y, m, d) => setState(() {
            _year = y;
            _month = m;
            _selectedDay = d;
            _viewMode = _ViewMode.month;
          }),
        );
    }
  }

  // ── Day view ───────────────────────────────────────────────────────────
  Widget _buildDayView(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textSub,
    DailyTimesheet? selectedEntry,
    int mealThreshold,
  ) {
    final now = DateTime.now();
    final dayNum = _selectedDay ?? now.day;
    final date = DateTime(_year, _month, dayNum);
    final isWeekend = date.weekday >= DateTime.saturday;
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final dateLabel = '${_italianMonths[_month - 1]} $_year';
    final dayName = AppStrings.weekdaysFull[date.weekday - 1];
    final dateId =
        '$_year-${_month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
    final holiday = _holidayLabel(dayNum);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Day navigator ────────────────────────────────────────────
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.neutral600,
                  ),
                  onPressed: _prevDay,
                  splashRadius: 20,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: isToday ? null : _goToToday,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayName $dayNum',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isToday ? AppColors.blue600 : textMain,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          isToday ? AppStrings.oggiData(dateLabel) : dateLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isToday
                                ? AppColors.blue600.withValues(alpha: 0.7)
                                : textSub,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (holiday != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '🌴 $holiday',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.orange600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!isToday)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: _goToToday,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue600.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          AppStrings.oggi,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue600,
                          ),
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.neutral600,
                  ),
                  onPressed: _nextDay,
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Day detail ───────────────────────────────────────────────
          if (selectedEntry != null) ...[
            _DayDetailCard(
              day: dayNum,
              month: _month,
              year: _year,
              entry: selectedEntry,
              isDark: isDark,
              fmtTime: _fmtTime,
              fmtNet: _fmtNet,
              typeInfo: _typeInfo,
              mealThreshold: mealThreshold,
              onEdit: () => _showEntrySheet(
                context,
                isDark,
                preselectedDay: dayNum,
                existingEntry: selectedEntry,
              ),
              onMarkFerie: () => _showEntrySheet(
                context,
                isDark,
                preselectedDay: dayNum,
                existingEntry: selectedEntry,
                preselectedType: WorkType.holiday,
              ),
              onMarkPermesso: () => _showEntrySheet(
                context,
                isDark,
                preselectedDay: dayNum,
                existingEntry: selectedEntry,
                preselectedType: WorkType.leave,
              ),
            ),
            const SizedBox(height: 10),
            _DayNoteSection(
              dateId: dateId,
              initialNote: selectedEntry.note,
              key: ValueKey('note-$dateId'),
            ),
          ] else if (!isWeekend) ...[
            _EmptyDayQuickAdd(
              day: dayNum,
              month: _month,
              months: _italianMonths,
              isDark: isDark,
              textMain: textMain,
              onPresence: () =>
                  _showEntrySheet(context, isDark, preselectedDay: dayNum),
              onRemote: () => _showEntrySheet(
                context,
                isDark,
                preselectedDay: dayNum,
                preselectedType: WorkType.remote,
              ),
              onFerie: () => _showEntrySheet(
                context,
                isDark,
                preselectedDay: dayNum,
                preselectedType: WorkType.holiday,
              ),
              onPermesso: () => _showEntrySheet(
                context,
                isDark,
                preselectedDay: dayNum,
                preselectedType: WorkType.leave,
              ),
            ),
            const SizedBox(height: 10),
            _DayNoteSection(
              dateId: dateId,
              initialNote: null,
              key: ValueKey('note-$dateId'),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Text('🌴', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.weekend,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textSub,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _prevDay() {
    final d = DateTime(
      _year,
      _month,
      _selectedDay ?? DateTime.now().day,
    ).subtract(const Duration(days: 1));
    setState(() {
      _year = d.year;
      _month = d.month;
      _selectedDay = d.day;
    });
  }

  void _nextDay() {
    final d = DateTime(
      _year,
      _month,
      _selectedDay ?? DateTime.now().day,
    ).add(const Duration(days: 1));
    setState(() {
      _year = d.year;
      _month = d.month;
      _selectedDay = d.day;
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _year = now.year;
      _month = now.month;
      _selectedDay = now.day;
    });
  }

  // ── Month view: desktop day list ──────────────────────────────────────
  Widget _buildDayList(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textSub,
    Map<int, DailyTimesheet> map,
    int daysInMonth,
    int mealThreshold,
  ) {
    final days = List.generate(daysInMonth, (i) => i + 1)
        .where(
          (d) =>
              map.containsKey(d) ||
              DateTime(_year, _month, d).weekday < DateTime.saturday,
        )
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final day = days[i];
        final entry = map[day];
        final isSelected = day == _selectedDay;
        final isWeekend =
            DateTime(_year, _month, day).weekday >= DateTime.saturday;
        final info = entry != null ? _typeInfo(entry.workType) : null;

        return GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.blue600.withValues(alpha: 0.12)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.blue600.withValues(alpha: 0.4)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.7)),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.blue600
                          : isWeekend
                          ? textSub
                          : textMain,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (info != null)
                  Text(info.emoji, style: const TextStyle(fontSize: 16))
                else
                  Text('·', style: TextStyle(fontSize: 16, color: textSub)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry != null ? _fmtNet(entry.netWorkedMins) : '—',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: entry != null
                          ? (info?.color ?? textMain)
                          : textSub,
                    ),
                  ),
                ),
                if (entry != null && entry.netWorkedMins >= mealThreshold)
                  const Text('🍽️', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Week view ──────────────────────────────────────────────────────────
  Widget _buildWeekView(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textSub,
    Map<int, DailyTimesheet> map,
    DailyTimesheet? selectedEntry,
    Widget summaryCard,
    int mealThreshold,
  ) {
    final anchor = _selectedDay != null
        ? DateTime(_year, _month, _selectedDay!)
        : DateTime.now();
    final weekStart = anchor.subtract(Duration(days: anchor.weekday - 1));
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final today = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Monthly summary (collapsible blue card)
          summaryCard,
          const SizedBox(height: 11),

          // Week card with navigation + day pills
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MonthNavBtn(
                      icon: Icons.chevron_left_rounded,
                      isDark: isDark,
                      onTap: _prevWeek,
                    ),
                    Column(
                      children: [
                        Text(
                          AppStrings.settimanaLabel('${_isoWeek(weekStart)}'),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: textSub,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _weekRangeLabel(weekStart),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textMain,
                          ),
                        ),
                      ],
                    ),
                    _MonthNavBtn(
                      icon: Icons.chevron_right_rounded,
                      isDark: isDark,
                      onTap: _nextWeek,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: weekDays.map((d) {
                    final inMonth = d.month == _month && d.year == _year;
                    final isSelected = inMonth && d.day == _selectedDay;
                    final isToday =
                        d.day == today.day &&
                        d.month == today.month &&
                        d.year == today.year;
                    final isWeekend = d.weekday >= 6;
                    final entry = inMonth ? map[d.day] : null;
                    final entryColor = entry != null ? _dotColor(entry) : null;

                    return Expanded(
                      child: GestureDetector(
                        onTap: !isWeekend
                            ? () => setState(() {
                                _year = d.year;
                                _month = d.month;
                                _selectedDay = d.day;
                              })
                            : null,
                        child: Column(
                          children: [
                            Text(
                              _dayLabels[d.weekday - 1],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isWeekend
                                    ? textSub.withValues(alpha: 0.5)
                                    : textSub,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.blue600
                                    : entryColor != null
                                    ? entryColor.withValues(alpha: 0.18)
                                    : isToday
                                    ? AppColors.blue600.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                border: isToday && !isSelected
                                    ? Border.all(
                                        color: AppColors.blue600.withValues(alpha: 0.5),
                                        width: 1.5,
                                      )
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.blue600.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${d.day}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected || entryColor != null
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : isWeekend
                                        ? textSub.withValues(alpha: 0.4)
                                        : inMonth
                                        ? textMain
                                        : textSub,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            SizedBox(
                              height: 5,
                              child: isSelected && entryColor != null
                                  ? Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: entryColor,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // All 7 days of the week — compact rows, selected highlighted
          const SizedBox(height: 11),
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              children: weekDays.map((d) {
                final inMonth = d.month == _month && d.year == _year;
                final entry = inMonth ? map[d.day] : null;
                final entryColor = entry != null ? _dotColor(entry) : null;
                final isSelected = inMonth && d.day == _selectedDay;
                final isWeekend = d.weekday >= 6;
                final info = entry != null ? _typeInfo(entry.workType) : null;
                final subtitle = entry == null
                    ? '—'
                    : (entry.isHoliday || entry.isLeave)
                    ? info!.label
                    : '${_fmtTime(entry.startTime)}–${_fmtTime(entry.endTime)} · ${_fmtNet(entry.netWorkedMins)}';

                return GestureDetector(
                  onTap: () => setState(() {
                    _year = d.year;
                    _month = d.month;
                    _selectedDay = d.day;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.blue600.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.blue600.withValues(alpha: 0.55)
                            : Colors.transparent,
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: entryColor ?? Colors.transparent,
                            border: entryColor == null
                                ? Border.all(
                                    color: textSub.withValues(alpha: 0.35),
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: entryColor != null
                                    ? Colors.white.withValues(alpha: 0.95)
                                    : textSub,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.weekdaysFull[d.weekday - 1],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isWeekend
                                  ? textSub.withValues(alpha: 0.6)
                                  : textMain,
                            ),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: entry != null ? textMain : textSub,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Day detail / quick-add
          if (_selectedDay != null) ...[
            const SizedBox(height: 11),
            if (selectedEntry != null)
              _DayDetailCard(
                day: _selectedDay!,
                month: _month,
                year: _year,
                entry: selectedEntry,
                isDark: isDark,
                fmtTime: _fmtTime,
                fmtNet: _fmtNet,
                typeInfo: _typeInfo,
                mealThreshold: mealThreshold,
                onEdit: () => _showEntrySheet(
                  context,
                  isDark,
                  preselectedDay: _selectedDay,
                  existingEntry: selectedEntry,
                ),
                onMarkFerie: () => _showEntrySheet(
                  context,
                  isDark,
                  preselectedDay: _selectedDay,
                  existingEntry: selectedEntry,
                  preselectedType: WorkType.holiday,
                ),
                onMarkPermesso: () => _showEntrySheet(
                  context,
                  isDark,
                  preselectedDay: _selectedDay,
                  existingEntry: selectedEntry,
                  preselectedType: WorkType.leave,
                ),
              )
            else
              _EmptyDayQuickAdd(
                day: _selectedDay!,
                month: _month,
                months: _italianMonths,
                isDark: isDark,
                textMain: textMain,
                onPresence: () => _showEntrySheet(
                  context,
                  isDark,
                  preselectedDay: _selectedDay,
                ),
                onRemote: () => _showEntrySheet(
                  context,
                  isDark,
                  preselectedDay: _selectedDay,
                  preselectedType: WorkType.remote,
                ),
                onFerie: () => _showEntrySheet(
                  context,
                  isDark,
                  preselectedDay: _selectedDay,
                  preselectedType: WorkType.holiday,
                ),
                onPermesso: () => _showEntrySheet(
                  context,
                  isDark,
                  preselectedDay: _selectedDay,
                  preselectedType: WorkType.leave,
                ),
              ),
          ],

          const SizedBox(height: 12),
          const _ColorLegend(),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── List view ──────────────────────────────────────────────────────────
  Widget _buildListView(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textSub,
    Map<int, DailyTimesheet> map,
    int daysInMonth,
    Widget summaryCard,
    int mealThreshold,
  ) {
    final days = List.generate(daysInMonth, (i) => i + 1);
    final now = DateTime.now();

    // Auto-scroll to today once per month/year combo.
    final isCurrentMonth = _year == now.year && _month == now.month;
    final monthKey = '$_year-$_month';
    if (isCurrentMonth && _listScrollKey != monthKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_listScrollController.hasClients) return;
        _listScrollKey = monthKey;
        const rowH = 62.0; // approx row height + bottom margin
        final offset = ((now.day - 1) * rowH).clamp(
          0.0,
          _listScrollController.position.maxScrollExtent,
        );
        if (offset > 0) {
          _listScrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    return Column(
      children: [
        // ── Summary card pinned at top — scrolls only when user pulls ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              summaryCard,
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: _MonthNavBtn(
                  icon: Icons.add_rounded,
                  isDark: isDark,
                  onTap: () => _showEntrySheet(context, isDark),
                ),
              ),
            ],
          ),
        ),
        // ── Day rows scroll independently below ───────────────────────
        Expanded(
          child: ListView.builder(
            controller: _listScrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: days.length,
            itemBuilder: (_, i) {
              final day = days[i];
              final date = DateTime(_year, _month, day);
              final todayStart = DateTime(now.year, now.month, now.day);
              final isToday =
                  day == now.day && _month == now.month && _year == now.year;
              final isWeekend = date.weekday >= 6;
              final isPast = date.isBefore(todayStart);
              final entry = map[day];
              return _buildListRow(
                context,
                isDark,
                textMain,
                textSub,
                day,
                date,
                isWeekend,
                isToday,
                isPast,
                entry,
                mealThreshold,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListRow(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textSub,
    int day,
    DateTime date,
    bool isWeekend,
    bool isToday,
    bool isPast,
    DailyTimesheet? entry,
    int mealThreshold,
  ) {
    const weekNames = AppStrings.weekdaysShort;
    final holidayName = _holidayLabel(day);
    final isPublicHoliday = holidayName != null;
    final showWarning =
        isPast && !isWeekend && !isToday && !isPublicHoliday && entry == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: entry != null
            ? () => _showEntrySheet(
                context,
                isDark,
                preselectedDay: day,
                existingEntry: entry,
              )
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.blue600.withValues(alpha: 0.09)
                : showWarning
                ? AppColors.orange500.withValues(alpha: isDark ? 0.07 : 0.06)
                : (isDark
                      ? Colors.white.withValues(alpha: isWeekend ? 0.03 : 0.05)
                      : Colors.white.withValues(alpha: isWeekend ? 0.3 : 0.6)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isToday
                  ? AppColors.blue600.withValues(alpha: 0.25)
                  : showWarning
                  ? AppColors.orange500.withValues(alpha: 0.28)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isToday
                            ? AppColors.blue600
                            : isWeekend
                            ? textSub
                            : textMain,
                      ),
                    ),
                    Text(
                      weekNames[date.weekday - 1],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: textSub,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (entry != null)
                _buildEntryInfo(entry, textMain, textSub, mealThreshold)
              else if (isPublicHoliday)
                Expanded(
                  child: Row(
                    children: [
                      const Text('🌴', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          holidayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else if (!isWeekend) ...[
                Expanded(
                  child: Row(
                    children: [
                      _QuickAddChip(
                        emoji: '🏢',
                        label: AppStrings.wtPresence,
                        isDark: isDark,
                        onTap: () => _showEntrySheet(
                          context,
                          isDark,
                          preselectedDay: day,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _QuickAddChip(
                        emoji: '🏠',
                        label: AppStrings.swShort,
                        isDark: isDark,
                        onTap: () => _showEntrySheet(
                          context,
                          isDark,
                          preselectedDay: day,
                          preselectedType: WorkType.remote,
                        ),
                      ),
                      if (showWarning) ...[
                        const Spacer(),
                        const Text('⚠️', style: TextStyle(fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ] else
                Text('—', style: TextStyle(color: textSub, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryInfo(
    DailyTimesheet entry,
    Color textMain,
    Color textSub,
    int mealThreshold,
  ) {
    final info = _typeInfo(entry.workType);
    final hasNote = entry.note != null && entry.note!.isNotEmpty;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(info.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              if (!entry.isLeave && !entry.isHoliday)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_fmtTime(entry.startTime)} – ${_fmtTime(entry.endTime)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: textSub,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      _fmtNet(entry.netWorkedMins),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: info.color,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  info.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: info.color,
                  ),
                ),
              const Spacer(),
              if (entry.netWorkedMins >= mealThreshold)
                const Text('🍽️', style: TextStyle(fontSize: 12)),
              if (entry.extraMins > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange600.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${_fmtNet(entry.extraMins)}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange600,
                    ),
                  ),
                ),
              ],
              if (!entry.isLeave &&
                  !entry.isHoliday &&
                  !entry.isRemote &&
                  (entry.netWorkedMins > 600 ||
                      (entry.netWorkedMins > 0 &&
                          entry.netWorkedMins < 120))) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red700.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '⚠',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasNote) ...[
            const SizedBox(height: 3),
            Text(
              entry.note!,
              style: TextStyle(
                fontSize: 10,
                color: textSub,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ── Month view: calendar + summary ────────────────────────────────────
  List<Widget> _calendarChildren(
    BuildContext context,
    bool isDark,
    Color textMain,
    Color textSub,
    Map<int, DailyTimesheet> map,
    int daysInMonth,
    int firstWeekday,
    DailyTimesheet? selectedEntry,
    Widget summaryCard,
    int mealThreshold,
  ) => [
    // Collapsible monthly summary (blue header + expandable detail)
    summaryCard,

    const SizedBox(height: 11),

    GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        children: [
          // Simplified calendar header — month nav is in summaryCard above
          Align(
            alignment: Alignment.centerRight,
            child: _MonthNavBtn(
              icon: Icons.add_rounded,
              isDark: isDark,
              onTap: () => _showEntrySheet(context, isDark),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: _dayLabels
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: textSub,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 2),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.75,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
            ),
            itemCount: firstWeekday - 1 + daysInMonth,
            itemBuilder: (_, i) {
              if (i < firstWeekday - 1) return const SizedBox.shrink();
              final day = i - (firstWeekday - 1) + 1;
              final entry = map[day];
              final selected = day == _selectedDay;
              final now = DateTime.now();
              final isToday =
                  now.year == _year && now.month == _month && now.day == day;
              final isWeekend = DateTime(_year, _month, day).weekday >= 6;
              final entryColor = entry != null ? _dotColor(entry) : null;

              return GestureDetector(
                onTap: entry != null || !isWeekend
                    ? () => setState(() => _selectedDay = day)
                    : null,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entryColor ?? Colors.transparent,
                      border: selected
                          ? Border.all(color: AppColors.blue600, width: 2)
                          : isToday
                          ? Border.all(
                              color: textMain.withValues(alpha: 0.7),
                              width: 1.2,
                            )
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.blue600.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected || entryColor != null
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: entryColor != null
                              ? Colors.white.withValues(alpha: 0.95)
                              : isWeekend
                              ? textSub
                              : textMain,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),
          const _ColorLegend(),
        ],
      ),
    ),

    if (_selectedDay != null) ...[
      const SizedBox(height: 11),
      if (selectedEntry != null)
        _DayDetailCard(
          day: _selectedDay!,
          month: _month,
          year: _year,
          entry: selectedEntry,
          isDark: isDark,
          fmtTime: _fmtTime,
          fmtNet: _fmtNet,
          typeInfo: _typeInfo,
          mealThreshold: mealThreshold,
          onEdit: () => _showEntrySheet(
            context,
            isDark,
            preselectedDay: _selectedDay,
            existingEntry: selectedEntry,
          ),
          onMarkFerie: () => _showEntrySheet(
            context,
            isDark,
            preselectedDay: _selectedDay,
            existingEntry: selectedEntry,
            preselectedType: WorkType.holiday,
          ),
          onMarkPermesso: () => _showEntrySheet(
            context,
            isDark,
            preselectedDay: _selectedDay,
            existingEntry: selectedEntry,
            preselectedType: WorkType.leave,
          ),
        )
      else
        _EmptyDayQuickAdd(
          day: _selectedDay!,
          month: _month,
          months: _italianMonths,
          isDark: isDark,
          textMain: textMain,
          onPresence: () =>
              _showEntrySheet(context, isDark, preselectedDay: _selectedDay),
          onRemote: () => _showEntrySheet(
            context,
            isDark,
            preselectedDay: _selectedDay,
            preselectedType: WorkType.remote,
          ),
          onFerie: () => _showEntrySheet(
            context,
            isDark,
            preselectedDay: _selectedDay,
            preselectedType: WorkType.holiday,
          ),
          onPermesso: () => _showEntrySheet(
            context,
            isDark,
            preselectedDay: _selectedDay,
            preselectedType: WorkType.leave,
          ),
        ),
    ],

    const SizedBox(height: 12),
    const _ColorLegend(),
    const SizedBox(height: 4),
  ];

  // ── PDF export ────────────────────────────────────────────────────────
  Future<void> _exportPdf(
    BuildContext context,
    Map<String, dynamic>? profileData,
  ) async {
    final entries =
        ref
            .read(monthlyTimesheetsProvider((year: _year, month: _month)))
            .asData
            ?.value ??
        [];
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.noEntriesToExport)),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    final name =
        (profileData?['name'] as String?) ??
        user?.displayName ??
        AppStrings.defaultUserName;
    final org =
        (profileData?['administration'] as String?) ?? AppStrings.appOrg;
    final threshold = (profileData?['mealVoucherThresholdMins'] as int?) ?? 380;
    await PdfExportService.exportMonth(
      year: _year,
      month: _month,
      entries: entries,
      userName: name,
      administration: org,
      mealThresholdMins: threshold,
    );
  }

  // ── CSV export ────────────────────────────────────────────────────────
  Future<void> _exportCsv(
    BuildContext context,
    Map<String, dynamic>? profileData,
  ) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: DateTime(_year, _month, 1),
        end: DateTime(_year, _month + 1, 0),
      ),
      locale: const Locale('it'),
      helpText: AppStrings.selectExportRange,
      saveText: AppStrings.exportAction,
    );
    if (range == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text(AppStrings.preparingCsv),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final entries = await ref
          .read(timesheetRepositoryProvider)
          .fetchRange(range.start, range.end);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.noEntriesInRange)),
        );
        return;
      }

      final threshold =
          (profileData?['mealVoucherThresholdMins'] as int?) ?? 380;
      final s = range.start;
      final e = range.end;
      final base =
          'timesheet_${s.year}-${_p2(s.month)}-${_p2(s.day)}'
          '_${e.year}-${_p2(e.month)}-${_p2(e.day)}';

      await CsvExportService.exportBoth(
        entries: entries,
        fileNameBase: base,
        mealThresholdMins: threshold,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.errorGeneric(e))));
      }
    }
  }

  // ── Export sheet ──────────────────────────────────────────────────────
  void _showExportSheet(
    BuildContext context,
    Map<String, dynamic>? profileData,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExportSheet(
        isDark: isDark,
        onExportPdf: () {
          Navigator.pop(ctx);
          _exportPdf(context, profileData);
        },
        onExportCsv: () {
          Navigator.pop(ctx);
          _exportCsv(context, profileData);
        },
      ),
    );
  }

  // ── Import / template sheet ───────────────────────────────────────────
  void _showImportSheet(
    BuildContext context,
    Map<String, dynamic>? profileData,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImportSheet(
        isDark: isDark,
        onImport: () {
          Navigator.pop(ctx);
          _doImportCsv(context, profileData);
        },
        onTemplate: () {
          Navigator.pop(ctx);
          CsvExportService.downloadTemplate();
        },
      ),
    );
  }

  Future<void> _doImportCsv(
    BuildContext context,
    Map<String, dynamic>? profileData,
  ) async {
    final stdMins = (profileData?['standardDailyMins'] as int?) ?? 456;
    final result = await CsvImportService.pickAndParse(
      standardDailyMins: stdMins,
    );
    if (result == null || !context.mounted) return;

    // F5 — import robusto: niente blocco. Le righe valide vengono importate
    // (e sovrascrivono le esistenti); le righe malformate vengono saltate e
    // riportate nel riepilogo finale.
    if (result.entries.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(AppStrings.importNothingTitle),
          content: SingleChildScrollView(
            child: Text(
              result.errors.isEmpty
                  ? AppStrings.importNothingBody
                  : '${AppStrings.importNothingBody}\n\n${result.errors.join('\n')}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.close),
            ),
          ],
        ),
      );
      return;
    }

    final repo = ref.read(timesheetRepositoryProvider);
    for (final e in result.entries) {
      // Overwrite pieno: re-importare un giorno con tipo diverso non lascia
      // campi opzionali stale del record precedente.
      await repo.saveDailyTimesheet(e, fullOverwrite: true);
    }
    if (!context.mounted) return;
    setState(() {});

    // Riepilogo: righe salvate + righe saltate (con motivo).
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.importSummaryTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.importSummarySaved(result.entries.length),
                style: const TextStyle(fontSize: 13),
              ),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  AppStrings.importSummarySkipped(result.errors.length),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.errors.join('\n'),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.close),
          ),
        ],
      ),
    );
  }

  // ── Entry sheet launcher ───────────────────────────────────────────────
  void _showEntrySheet(
    BuildContext context,
    bool isDark, {
    int? preselectedDay,
    String? preselectedType,
    DailyTimesheet? existingEntry,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntrySheet(
        year: _year,
        month: _month,
        preselectedDay: preselectedDay ?? _selectedDay ?? DateTime.now().day,
        isDark: isDark,
        preselectedType: preselectedType,
        existingEntry: existingEntry,
        onSaved: () => setState(() {}),
      ),
    );
  }

  int _dayOfMonth(String dateId) => int.tryParse(dateId.split('-').last) ?? 0;

  // ISO 8601 week number
  static int _isoWeek(DateTime d) {
    final dow = d.weekday;
    final thu = d.add(Duration(days: 4 - dow));
    final jan1 = DateTime(thu.year, 1, 1);
    return ((thu.difference(jan1).inDays) / 7).floor() + 1;
  }

  void _showMonthPicker(BuildContext context, bool isDark) {
    int tempYear = _year;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setInner(() => tempYear--),
              ),
              Text(
                '$tempYear',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setInner(() => tempYear++),
              ),
            ],
          ),
          content: SizedBox(
            width: 260,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.0,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: 12,
              itemBuilder: (_, i) {
                final isSelected = tempYear == _year && i + 1 == _month;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _year = tempYear;
                      _month = i + 1;
                      _selectedDay = null;
                    });
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.blue600
                          : AppColors.blue600.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _italianMonths[i].substring(0, 3),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.blue600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass toolbar (view pills + action icons) ─────────────────────────────

class _GlassToolbar extends StatelessWidget {
  final _ViewMode viewMode;
  final ValueChanged<_ViewMode> onViewChanged;
  final VoidCallback onExportTap;
  final VoidCallback onImportTap;

  const _GlassToolbar({
    required this.viewMode,
    required this.onViewChanged,
    required this.onExportTap,
    required this.onImportTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10102A).withValues(alpha: 0.52)
                  : Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.85),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.28)
                      : const Color(0xFF002878).withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ViewPills(
                    current: viewMode,
                    onChanged: onViewChanged,
                    isDark: isDark,
                  ),
                ),
                // Thin divider
                Container(
                  width: 0.5,
                  height: 20,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                _ToolbarIconBtn(
                  icon: Icons.file_open_rounded,
                  tooltip: AppStrings.importTooltip,
                  color: AppColors.green600,
                  onTap: onImportTap,
                ),
                _ToolbarIconBtn(
                  icon: Icons.save_alt_rounded,
                  tooltip: AppStrings.exportTooltip,
                  color: AppColors.blue600,
                  onTap: onExportTap,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── View pills (inside toolbar) ───────────────────────────────────────────

class _ViewPills extends StatelessWidget {
  final _ViewMode current;
  final ValueChanged<_ViewMode> onChanged;
  final bool isDark;

  const _ViewPills({
    required this.current,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? Colors.white : AppColors.neutral900;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.40)
        : AppColors.neutral400;
    final selBg = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.92);

    return Row(
      children: [
        const SizedBox(width: 3),
        ..._ViewMode.values.map((v) {
          final selected = v == current;
          final label = switch (v) {
            _ViewMode.day => AppStrings.viewDay,
            _ViewMode.list => AppStrings.viewList,
            _ViewMode.week => AppStrings.viewWeek,
            _ViewMode.month => AppStrings.viewMonth,
            _ViewMode.year => AppStrings.viewYear,
          };
          final icon = switch (v) {
            _ViewMode.day => Icons.calendar_today_rounded,
            _ViewMode.list => Icons.list_rounded,
            _ViewMode.week => Icons.calendar_view_week_rounded,
            _ViewMode.month => Icons.calendar_month_rounded,
            _ViewMode.year => Icons.grid_view_rounded,
          };
          return Expanded(
            child: Tooltip(
              message: label,
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? selBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.18 : 0.06,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 12,
                        color: selected ? activeColor : inactiveColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? activeColor : inactiveColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 3),
      ],
    );
  }
}

// ── Toolbar icon button ───────────────────────────────────────────────────

class _ToolbarIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ToolbarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 34,
          height: 40,
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

// ── Export bottom sheet ───────────────────────────────────────────────────

class _ExportSheet extends StatelessWidget {
  final bool isDark;
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;

  const _ExportSheet({
    required this.isDark,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.90)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    return Container(
      margin: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F1028).withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.80),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.save_alt_rounded,
                size: 18,
                color: AppColors.blue600,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.exportSheetTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.exportSheetSubtitle,
            style: TextStyle(fontSize: 12, color: textSub),
          ),
          const SizedBox(height: 20),
          _SheetActionBtn(
            isDark: isDark,
            icon: Icons.picture_as_pdf_rounded,
            color: AppColors.red700,
            title: AppStrings.exportPdfTitle,
            subtitle: AppStrings.exportPdfSubtitle,
            onTap: onExportPdf,
          ),
          const SizedBox(height: 10),
          _SheetActionBtn(
            isDark: isDark,
            icon: Icons.table_chart_rounded,
            color: AppColors.green600,
            title: AppStrings.exportCsvTitle,
            subtitle: AppStrings.exportCsvSubtitle,
            onTap: onExportCsv,
          ),
        ],
      ),
    );
  }
}

// ── Import / template bottom sheet ────────────────────────────────────────

class _ImportSheet extends StatelessWidget {
  final bool isDark;
  final VoidCallback onImport;
  final VoidCallback onTemplate;

  const _ImportSheet({
    required this.isDark,
    required this.onImport,
    required this.onTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.90)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    return Container(
      margin: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F1028).withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.80),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.file_open_rounded,
                size: 18,
                color: AppColors.green600,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.importSheetTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.importSheetSubtitle,
            style: TextStyle(fontSize: 12, color: textSub),
          ),
          const SizedBox(height: 20),
          _SheetActionBtn(
            isDark: isDark,
            icon: Icons.upload_file_rounded,
            color: AppColors.blue600,
            title: AppStrings.importCsvTitle,
            subtitle: AppStrings.importCsvSubtitle,
            onTap: onImport,
          ),
          const SizedBox(height: 10),
          _SheetActionBtn(
            isDark: isDark,
            icon: Icons.file_download_rounded,
            color: AppColors.green600,
            title: AppStrings.downloadTemplateTitle,
            subtitle: AppStrings.downloadTemplateSubtitle,
            onTap: onTemplate,
          ),
        ],
      ),
    );
  }
}

// ── Sheet action button ───────────────────────────────────────────────────

class _SheetActionBtn extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetActionBtn({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.90)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: textSub),
          ],
        ),
      ),
    );
  }
}

// ── Empty day quick-add card ──────────────────────────────────────────────

class _EmptyDayQuickAdd extends StatelessWidget {
  final int day, month;
  final List<String> months;
  final bool isDark;
  final Color textMain;
  final VoidCallback onPresence;
  final VoidCallback onRemote;
  final VoidCallback onFerie;
  final VoidCallback onPermesso;

  const _EmptyDayQuickAdd({
    required this.day,
    required this.month,
    required this.months,
    required this.isDark,
    required this.textMain,
    required this.onPresence,
    required this.onRemote,
    required this.onFerie,
    required this.onPermesso,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$day ${months[month - 1]}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textMain,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickAddChip(
                emoji: '🏢',
                label: AppStrings.wtPresence,
                isDark: isDark,
                onTap: onPresence,
              ),
              _QuickAddChip(
                emoji: '🏠',
                label: AppStrings.swShort,
                isDark: isDark,
                onTap: onRemote,
              ),
              _QuickAddChip(
                emoji: '🌴',
                label: 'Ferie',
                isDark: isDark,
                onTap: onFerie,
              ),
              _QuickAddChip(
                emoji: '🚶',
                label: 'Permesso',
                isDark: isDark,
                onTap: onPermesso,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick-add chip ─────────────────────────────────────────────────────────

class _QuickAddChip extends StatelessWidget {
  final String emoji, label;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickAddChip({
    required this.emoji,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.09)
              : AppColors.blue600.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : AppColors.blue100,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.blue600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day detail card ───────────────────────────────────────────────────────

class _DayDetailCard extends StatelessWidget {
  final int day, month, year;
  final DailyTimesheet entry;
  final bool isDark;
  final String Function(DateTime) fmtTime;
  final String Function(int) fmtNet;
  final ({String emoji, String label, Color color}) Function(String?) typeInfo;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkFerie;
  final VoidCallback? onMarkPermesso;
  final int mealThreshold;

  static const _months = AppStrings.months;

  const _DayDetailCard({
    required this.day,
    required this.month,
    required this.year,
    required this.entry,
    required this.isDark,
    required this.fmtTime,
    required this.fmtNet,
    required this.typeInfo,
    required this.mealThreshold,
    this.onEdit,
    this.onMarkFerie,
    this.onMarkPermesso,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    final info = typeInfo(entry.workType);
    // Mostra Ferie/Permesso anche sui giorni NON Presenza/SW (es. già Ferie o
    // Permesso) per poter convertire il tipo; si nasconde solo il bottone del
    // tipo già attivo.
    final showFerie = onMarkFerie != null && !entry.isHoliday;
    final showPermesso = onMarkPermesso != null && !entry.isLeave;

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$day ${_months[month - 1]} $year',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                ),
              ),
              const Spacer(),
              if (onEdit != null) ...[
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blue600.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 13,
                      color: AppColors.blue600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(info.emoji, style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      info.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: info.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.netWorkedMins >= mealThreshold) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🍽️', style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DetailStat(
                label: AppStrings.entrata,
                value: fmtTime(entry.startTime),
                color: AppColors.blue600,
              ),
              _DetailStat(
                label: AppStrings.lavorato,
                value: fmtNet(entry.netWorkedMins),
                color: AppColors.blue600,
              ),
              _DetailStat(
                label: AppStrings.uscita,
                value: fmtTime(entry.endTime),
                color: AppColors.blue600,
              ),
            ],
          ),
          if (showFerie || showPermesso) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (showFerie)
                  Expanded(
                    child: GestureDetector(
                      onTap: onMarkFerie,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.amber600.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🌴', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              'Ferie',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amber600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (showFerie && showPermesso) const SizedBox(width: 8),
                if (showPermesso)
                  Expanded(
                    child: GestureDetector(
                      onTap: onMarkPermesso,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.purple600.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🚶', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              'Permesso',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.purple600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (!entry.isLeave && !entry.isHoliday) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    Flexible(
                      flex: entry.netWorkedMins,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: entry.isRemote
                                ? [AppColors.blue400, AppColors.blue600]
                                : [AppColors.green500, AppColors.green600],
                          ),
                        ),
                      ),
                    ),
                    if (entry.extraMins > 0)
                      Flexible(
                        flex: entry.extraMins,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.orange500,
                                AppColors.orange600,
                              ],
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      flex:
                          (456 -
                                  entry.netWorkedMins -
                                  (entry.extraMins > 0 ? entry.extraMins : 0))
                              .clamp(0, 456)
                              .toInt(),
                      child: Container(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (entry.extraMins > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange600.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppStrings.straordinarioDetail(fmtNet(entry.extraMins)),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Manual entry bottom sheet ─────────────────────────────────────────────

class _EntrySheet extends ConsumerStatefulWidget {
  final int year, month, preselectedDay;
  final bool isDark;
  final String? preselectedType;
  final DailyTimesheet? existingEntry;
  final VoidCallback onSaved;

  const _EntrySheet({
    required this.year,
    required this.month,
    required this.preselectedDay,
    required this.isDark,
    required this.onSaved,
    this.preselectedType,
    this.existingEntry,
  });

  @override
  ConsumerState<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<_EntrySheet> {
  late int _day;
  late String _workType;
  TimeOfDay _entry = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _exit = const TimeOfDay(hour: 17, minute: 6);
  bool _saving = false;

  // Dettaglio assenza (visibile quando _workType == WorkType.leave)
  String? _absenceKind;
  String _absenceUnit = AbsenceUnit.hourly;
  TimeOfDay _absenceDuration = const TimeOfDay(hour: 1, minute: 0);
  double _absenceDays = 1;
  DateTime? _periodStart;
  DateTime? _periodEnd;
  bool _absenceSensitive = false;
  bool _absenceHasDocs = false;
  late TextEditingController _absenceNoteCtrl;

  static const _types = [
    (value: WorkType.presence, label: AppStrings.wtPresence, emoji: '🏢'),
    (value: WorkType.remote, label: AppStrings.wtRemote, emoji: '🏠'),
    (value: WorkType.leave, label: AppStrings.wtLeave, emoji: '🚶'),
    (value: WorkType.holiday, label: AppStrings.wtHoliday, emoji: '🌴'),
  ];

  static const _months = AppStrings.monthsShort;

  @override
  void initState() {
    super.initState();
    _day = widget.preselectedDay;
    final existing = widget.existingEntry;
    _absenceNoteCtrl = TextEditingController(
      text: existing?.personalNote ?? '',
    );
    if (existing != null) {
      _workType = existing.workType ?? WorkType.presence;
      _entry = TimeOfDay.fromDateTime(existing.startTime);
      _exit = TimeOfDay.fromDateTime(existing.endTime);
      _absenceKind = existing.absenceKind;
      _absenceUnit = existing.absenceUnit ?? AbsenceUnit.hourly;
      if (existing.absenceMins > 0) {
        _absenceDuration = TimeOfDay(
          hour: existing.absenceMins ~/ 60,
          minute: existing.absenceMins % 60,
        );
      }
      if (existing.absenceDays > 0) _absenceDays = existing.absenceDays;
      _periodStart = existing.periodStart != null
          ? DateTime.tryParse(existing.periodStart!)
          : null;
      _periodEnd = existing.periodEnd != null
          ? DateTime.tryParse(existing.periodEnd!)
          : null;
      _absenceSensitive = existing.sensitive;
      _absenceHasDocs = existing.hasDocumentation;
    } else {
      _workType = widget.preselectedType ?? WorkType.presence;
    }
  }

  @override
  void dispose() {
    _absenceNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(timesheetRepositoryProvider);
      final profileData = ref.read(userProfileStreamProvider).asData?.value;
      final base = DateTime(widget.year, widget.month, _day);
      final stdMins = profileData != null
          ? AppConstants.stdMinsForDate(profileData, base)
          : 456;
      final dateId =
          '${widget.year}-'
          '${widget.month.toString().padLeft(2, '0')}-'
          '${_day.toString().padLeft(2, '0')}';

      if (_workType == WorkType.remote) {
        // Fix: save for selected day, not today
        final start = DateTime(base.year, base.month, base.day, 9, 0);
        final end = start.add(Duration(minutes: stdMins + 30));
        await repo.saveDailyTimesheet(
          DailyTimesheet(
            dateId: dateId,
            startTime: start,
            endTime: end,
            standardPauseMins: 0,
            lunchPauseMins: 30,
            netWorkedMins: stdMins,
            extraMins: 0,
            workType: WorkType.remote,
          ),
        );
      } else {
        final start = DateTime(
          base.year,
          base.month,
          base.day,
          _entry.hour,
          _entry.minute,
        );
        final end = DateTime(
          base.year,
          base.month,
          base.day,
          _exit.hour,
          _exit.minute,
        );
        final elapsed = end.difference(start).inMinutes;
        const lunchMins = 30;
        final netMins = _workType == WorkType.presence
            ? (elapsed - lunchMins).clamp(0, 9999).toInt()
            : 0;

        final isLeaveDetail =
            _workType == WorkType.leave && _absenceKind != null;
        final note = _absenceNoteCtrl.text.trim();

        await repo.saveDailyTimesheet(
          DailyTimesheet(
            dateId: dateId,
            startTime: start,
            endTime: end,
            standardPauseMins: 0,
            lunchPauseMins: _workType == WorkType.presence ? lunchMins : 0,
            netWorkedMins: netMins,
            extraMins: netMins > stdMins ? netMins - stdMins : 0,
            workType: _workType,
            absenceKind: isLeaveDetail ? _absenceKind : null,
            absenceUnit: isLeaveDetail ? _absenceUnit : null,
            absenceMins: isLeaveDetail && _absenceUnit == AbsenceUnit.hourly
                ? _absenceDuration.hour * 60 + _absenceDuration.minute
                : 0,
            absenceDays: isLeaveDetail && _absenceUnit == AbsenceUnit.daily
                ? _absenceDays
                : 0,
            periodStart:
                isLeaveDetail &&
                    _absenceUnit == AbsenceUnit.period &&
                    _periodStart != null
                ? _periodStart!.toIso8601String().split('T').first
                : null,
            periodEnd:
                isLeaveDetail &&
                    _absenceUnit == AbsenceUnit.period &&
                    _periodEnd != null
                ? _periodEnd!.toIso8601String().split('T').first
                : null,
            quotaYear: isLeaveDetail ? base.year : null,
            countsAsSicknessPeriod:
                isLeaveDetail &&
                (_absenceKind == AbsenceKind.sickness ||
                    _absenceKind == AbsenceKind.workInjury),
            sensitive: isLeaveDetail && _absenceSensitive,
            personalNote: isLeaveDetail && note.isNotEmpty ? note : null,
            hasDocumentation: isLeaveDetail && _absenceHasDocs,
          ),
        );
      }

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorGeneric(e)),
            backgroundColor: AppColors.red700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.eliminaGiornata),
        content: const Text(AppStrings.eliminaGiornataConferma),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppStrings.eliminaGiornata,
              style: const TextStyle(color: AppColors.red700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final dateId =
          '${widget.year}-'
          '${widget.month.toString().padLeft(2, '0')}-'
          '${_day.toString().padLeft(2, '0')}';
      await ref.read(timesheetRepositoryProvider).deleteDailyTimesheet(dateId);

      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.giornataEliminata)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorGeneric(e)),
            backgroundColor: AppColors.red700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;

    final keyboardH = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardH),
      child: Container(
        margin: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + (keyboardH == 0 ? safeBottom : 0),
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F1028).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existingEntry != null
                        ? AppStrings.modificaGiornata
                        : AppStrings.aggiungiGiornata,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                ),
                if (widget.existingEntry != null)
                  Tooltip(
                    message: AppStrings.eliminaGiornata,
                    child: IconButton(
                      onPressed: _saving ? null : _resetEntry,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.red700,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Day picker
            Row(
              children: [
                Text(
                  AppStrings.giorno,
                  style: TextStyle(fontSize: 13, color: textSub),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(widget.year, widget.month, _day),
                      firstDate: DateTime(widget.year, widget.month, 1),
                      lastDate: DateTime(widget.year, widget.month + 1, 0),
                    );
                    if (picked != null) setState(() => _day = picked.day);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blue600.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.blue100),
                    ),
                    child: Text(
                      '$_day ${_months[widget.month - 1]} ${widget.year}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // WorkType chips
            Text(
              AppStrings.dayType,
              style: TextStyle(fontSize: 13, color: textSub),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                final selected = _workType == t.value;
                return GestureDetector(
                  onTap: () => setState(() => _workType = t.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.blue600.withValues(alpha: 0.12)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.blue600
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected ? AppColors.blue600 : textSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // Dettaglio causale assenza — solo per "Permesso/assenza"
            if (_workType == WorkType.leave) ...[
              const SizedBox(height: 14),
              Text(
                AppStrings.causale,
                style: TextStyle(fontSize: 13, color: textSub),
              ),
              const SizedBox(height: 8),
              ...AbsenceKind.groups.entries.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: group.value.map((kind) {
                      final selected = _absenceKind == kind;
                      return GestureDetector(
                        onTap: () => setState(
                          () => _absenceKind = selected ? null : kind,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.blue600.withValues(alpha: 0.12)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.blue600
                                  : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            AbsenceKind.labelFor(kind),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected ? AppColors.blue600 : textSub,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              if (_absenceKind != null) ...[
                const SizedBox(height: 10),
                Text(
                  AppStrings.unitaLabel,
                  style: TextStyle(fontSize: 13, color: textSub),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _UnitChip(
                      label: AppStrings.unitaOre,
                      selected: _absenceUnit == AbsenceUnit.hourly,
                      onTap: () =>
                          setState(() => _absenceUnit = AbsenceUnit.hourly),
                    ),
                    _UnitChip(
                      label: AppStrings.unitaGiorni,
                      selected: _absenceUnit == AbsenceUnit.daily,
                      onTap: () =>
                          setState(() => _absenceUnit = AbsenceUnit.daily),
                    ),
                    _UnitChip(
                      label: AppStrings.unitaPeriodo,
                      selected: _absenceUnit == AbsenceUnit.period,
                      onTap: () =>
                          setState(() => _absenceUnit = AbsenceUnit.period),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_absenceUnit == AbsenceUnit.hourly)
                  _TimeTile(
                    label: AppStrings.durataLabel,
                    time: _absenceDuration,
                    isDark: isDark,
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _absenceDuration,
                      );
                      if (t != null) setState(() => _absenceDuration = t);
                    },
                  ),

                if (_absenceUnit == AbsenceUnit.daily)
                  Row(
                    children: [
                      Text(
                        AppStrings.giorniPrefix,
                        style: TextStyle(fontSize: 13, color: textSub),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: _absenceDays > 0.5
                            ? () => setState(() => _absenceDays -= 0.5)
                            : null,
                      ),
                      Text(
                        _absenceDays.toStringAsFixed(
                          _absenceDays.truncateToDouble() == _absenceDays
                              ? 0
                              : 1,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textMain,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () => setState(() => _absenceDays += 0.5),
                      ),
                    ],
                  ),

                if (_absenceUnit == AbsenceUnit.period)
                  Row(
                    children: [
                      Expanded(
                        child: _DateTile(
                          label: AppStrings.periodoDal,
                          date: _periodStart,
                          isDark: isDark,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  _periodStart ??
                                  DateTime(widget.year, widget.month, _day),
                              firstDate: DateTime(widget.year - 2),
                              lastDate: DateTime(widget.year + 2),
                            );
                            if (picked != null) {
                              setState(() => _periodStart = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateTile(
                          label: AppStrings.periodoAl,
                          date: _periodEnd,
                          isDark: isDark,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  _periodEnd ??
                                  _periodStart ??
                                  DateTime(widget.year, widget.month, _day),
                              firstDate: DateTime(widget.year - 2),
                              lastDate: DateTime(widget.year + 2),
                            );
                            if (picked != null) {
                              setState(() => _periodEnd = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    AppStrings.assenzaRiservata,
                    style: TextStyle(fontSize: 13, color: textMain),
                  ),
                  subtitle: Text(
                    AppStrings.assenzaRiservataHint,
                    style: TextStyle(fontSize: 11, color: textSub),
                  ),
                  value: _absenceSensitive,
                  onChanged: (v) => setState(() => _absenceSensitive = v),
                ),
                if (_absenceKind == AbsenceKind.specialistVisit ||
                    _absenceKind == AbsenceKind.sickness)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      AppStrings.documentazionePresente,
                      style: TextStyle(fontSize: 13, color: textMain),
                    ),
                    value: _absenceHasDocs,
                    onChanged: (v) => setState(() => _absenceHasDocs = v),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _absenceNoteCtrl,
                  maxLines: 2,
                  style: TextStyle(fontSize: 13, color: textMain),
                  decoration: InputDecoration(
                    hintText: AppStrings.notaPrivataHint,
                    hintStyle: TextStyle(fontSize: 12, color: textSub),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],

            // Time pickers — presence only
            if (_workType == WorkType.presence) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: AppStrings.entrata,
                      time: _entry,
                      isDark: isDark,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _entry,
                        );
                        if (t != null) setState(() => _entry = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TimeTile(
                      label: AppStrings.uscita,
                      time: _exit,
                      isDark: isDark,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _exit,
                        );
                        if (t != null) setState(() => _exit = t);
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            GlassBtn(
              label: AppStrings.saveDay,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day note section (editable note for any past day) ──────────────────────

class _DayNoteSection extends ConsumerStatefulWidget {
  final String dateId;
  final String? initialNote;

  const _DayNoteSection({super.key, required this.dateId, this.initialNote});

  @override
  ConsumerState<_DayNoteSection> createState() => _DayNoteSectionState();
}

class _DayNoteSectionState extends ConsumerState<_DayNoteSection> {
  late TextEditingController _ctrl;
  late String _savedText;
  bool _saving = false;
  bool _saved = false;

  bool get _dirty => _ctrl.text != _savedText;

  @override
  void initState() {
    super.initState();
    _savedText = widget.initialNote ?? '';
    _ctrl = TextEditingController(text: _savedText);
  }

  @override
  void didUpdateWidget(_DayNoteSection old) {
    super.didUpdateWidget(old);
    if (old.dateId != widget.dateId) {
      _savedText = widget.initialNote ?? '';
      _ctrl.text = _savedText;
      _saved = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      await ref
          .read(timesheetRepositoryProvider)
          .saveNote(widget.dateId, _ctrl.text);
      if (mounted) {
        setState(() {
          _savedText = _ctrl.text;
          _saved = true;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                AppStrings.noteLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textMain,
                ),
              ),
              const Spacer(),
              if (_saved)
                Text(
                  AppStrings.saved,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 4,
              maxLength: 500,
              scrollPadding: const EdgeInsets.only(bottom: 220),
              style: TextStyle(fontSize: 13, color: textMain),
              decoration: InputDecoration(
                hintText: AppStrings.notePlaceholder,
                hintStyle: TextStyle(fontSize: 13, color: textSub),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                counterText: '',
              ),
              onChanged: (_) {
                // Rebuild so the save button reflects the dirty state.
                setState(() {
                  if (_saved) _saved = false;
                });
              },
            ),
          ),
          if (_dirty) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: _saving
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xE60055A5), Color(0xF2003D8F)],
                        ),
                  color: _saving ? Colors.grey : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        AppStrings.save,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }
}

// ── Helper widgets ──────────────────────────────────────────────────────────

class _MonthNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _MonthNavBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : AppColors.neutral600,
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _DetailStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.4)
                : AppColors.neutral400,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final textSub = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.35)
        : AppColors.neutral400;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: textSub,
          ),
        ),
      ],
    );
  }
}

class _ColorLegend extends StatelessWidget {
  const _ColorLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: const [
        _LegendDot(color: AppColors.green500, label: 'Presenza'),
        _LegendDot(color: AppColors.blue600, label: 'Smart working'),
        _LegendDot(color: AppColors.purple600, label: 'Permesso'),
        _LegendDot(color: AppColors.amber600, label: 'Ferie/Festività'),
        _LegendDot(color: AppColors.orange500, label: 'Con straordinari'),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  final bool isDark;
  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral600;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textSub,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textMain,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _UnitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue600.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.blue600 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.blue600 : textSub,
          ),
        ),
      ),
    );
  }
}

// ── Year view ──────────────────────────────────────────────────────────────

class _YearView extends ConsumerWidget {
  final int year;
  final bool isDark;
  final VoidCallback onPrevYear;
  final VoidCallback onNextYear;
  final void Function(int year, int month, int day) onDayTap;

  const _YearView({
    required this.year,
    required this.isDark,
    required this.onPrevYear,
    required this.onNextYear,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral400;

    final allEntries = <int, Map<int, DailyTimesheet>>{};
    for (var m = 1; m <= 12; m++) {
      final entries =
          ref
              .watch(monthlyTimesheetsProvider((year: year, month: m)))
              .asData
              ?.value ??
          [];
      allEntries[m] = {
        for (final e in entries)
          int.tryParse(e.dateId.split('-').last) ?? 0: e,
      };
    }

    // Responsive: su desktop i mesi sono troppo grandi a 2 colonne.
    // 3 colonne da 800px, 4 da 1200px; resta a 2 su mobile.
    final width = MediaQuery.sizeOf(context).width;
    final yearCols = width >= 1200
        ? 4
        : width >= 800
        ? 3
        : 2;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onPrevYear,
                child: Icon(Icons.chevron_left_rounded, color: textSub, size: 28),
              ),
              Row(
                children: [
                  Text(
                    '$year',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                  Builder(
                    builder: (_) {
                      final swYear = allEntries.values
                          .expand((m) => m.values)
                          .where((e) => e.isRemote)
                          .length;
                      if (swYear == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue600.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🖥 $swYear SW',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              GestureDetector(
                onTap: onNextYear,
                child: Icon(Icons.chevron_right_rounded, color: textSub, size: 28),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: yearCols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: 12,
            itemBuilder: (_, i) {
              final month = i + 1;
              return _MiniMonthGrid(
                year: year,
                month: month,
                entries: allEntries[month] ?? {},
                isDark: isDark,
                onDayTap: (d) => onDayTap(year, month, d),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniMonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final Map<int, DailyTimesheet> entries;
  final bool isDark;
  final ValueChanged<int> onDayTap;

  const _MiniMonthGrid({
    required this.year,
    required this.month,
    required this.entries,
    required this.isDark,
    required this.onDayTap,
  });

  Color _dayColor(int day) {
    final e = entries[day];
    if (e == null) {
      return ItalianHolidays.label(DateTime(year, month, day)) != null
          ? AppColors.amber600.withValues(alpha: 0.5)
          : Colors.transparent;
    }
    if (e.isHoliday) return AppColors.amber600;
    if (e.isLeave) return AppColors.purple600;
    if (e.isRemote) return AppColors.blue600;
    return AppColors.green600;
  }

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : AppColors.neutral300;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.7);

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;
    final today = DateTime.now();
    final isCurrentMonth = today.year == year && today.month == month;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.months[month - 1],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                  ),
                ),
              ),
              Builder(
                builder: (_) {
                  final sw = entries.values.where((e) => e.isRemote).length;
                  if (sw == 0) return const SizedBox.shrink();
                  return Text(
                    '🖥 $sw',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue600,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: ['L', 'M', 'M', 'G', 'V', 'S', 'D'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(d, style: TextStyle(fontSize: 6, color: textSub)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) {
                final cellSize = constraints.maxWidth / 7;
                final rows = ((firstWeekday - 1 + daysInMonth) / 7).ceil();
                return Column(
                  children: List.generate(rows, (row) {
                    return Expanded(
                      child: Row(
                        children: List.generate(7, (col) {
                          final day = row * 7 + col - (firstWeekday - 1) + 1;
                          if (day < 1 || day > daysInMonth) {
                            return const Expanded(child: SizedBox.shrink());
                          }
                          final color = _dayColor(day);
                          final isToday = isCurrentMonth && day == today.day;
                          final hasEntry = color != Colors.transparent;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => onDayTap(day),
                              child: Center(
                                child: Container(
                                  width: cellSize * 0.62,
                                  height: cellSize * 0.62,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isToday
                                        ? Border.all(
                                            color: textMain,
                                            width: 1.2,
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: TextStyle(
                                        fontSize: cellSize * 0.27,
                                        fontWeight: FontWeight.w600,
                                        color: hasEntry
                                            ? Colors.white.withValues(
                                                alpha: 0.92,
                                              )
                                            : textSub,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool isDark;
  final VoidCallback onTap;
  const _DateTile({
    required this.label,
    required this.date,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppColors.neutral600;
    final text = date == null
        ? '—'
        : '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textSub,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
