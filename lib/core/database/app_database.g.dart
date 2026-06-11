// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TimesheetEntriesTable extends TimesheetEntries
    with TableInfo<$TimesheetEntriesTable, TimesheetEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimesheetEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateIdMeta = const VerificationMeta('dateId');
  @override
  late final GeneratedColumn<String> dateId = GeneratedColumn<String>(
    'date_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _standardPauseMinsMeta = const VerificationMeta(
    'standardPauseMins',
  );
  @override
  late final GeneratedColumn<int> standardPauseMins = GeneratedColumn<int>(
    'standard_pause_mins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _leavePauseMinsMeta = const VerificationMeta(
    'leavePauseMins',
  );
  @override
  late final GeneratedColumn<int> leavePauseMins = GeneratedColumn<int>(
    'leave_pause_mins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lunchPauseMinsMeta = const VerificationMeta(
    'lunchPauseMins',
  );
  @override
  late final GeneratedColumn<int> lunchPauseMins = GeneratedColumn<int>(
    'lunch_pause_mins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _netWorkedMinsMeta = const VerificationMeta(
    'netWorkedMins',
  );
  @override
  late final GeneratedColumn<int> netWorkedMins = GeneratedColumn<int>(
    'net_worked_mins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extraMinsMeta = const VerificationMeta(
    'extraMins',
  );
  @override
  late final GeneratedColumn<int> extraMins = GeneratedColumn<int>(
    'extra_mins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sliMinsMeta = const VerificationMeta(
    'sliMins',
  );
  @override
  late final GeneratedColumn<int> sliMins = GeneratedColumn<int>(
    'sli_mins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sboMinsMeta = const VerificationMeta(
    'sboMins',
  );
  @override
  late final GeneratedColumn<int> sboMins = GeneratedColumn<int>(
    'sbo_mins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _workTypeMeta = const VerificationMeta(
    'workType',
  );
  @override
  late final GeneratedColumn<String> workType = GeneratedColumn<String>(
    'work_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bancaOreMinsMeta = const VerificationMeta(
    'bancaOreMins',
  );
  @override
  late final GeneratedColumn<int> bancaOreMins = GeneratedColumn<int>(
    'banca_ore_mins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _boeSlotMeta = const VerificationMeta(
    'boeSlot',
  );
  @override
  late final GeneratedColumn<String> boeSlot = GeneratedColumn<String>(
    'boe_slot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _absenceKindMeta = const VerificationMeta(
    'absenceKind',
  );
  @override
  late final GeneratedColumn<String> absenceKind = GeneratedColumn<String>(
    'absence_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _absenceUnitMeta = const VerificationMeta(
    'absenceUnit',
  );
  @override
  late final GeneratedColumn<String> absenceUnit = GeneratedColumn<String>(
    'absence_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _absenceMinsMeta = const VerificationMeta(
    'absenceMins',
  );
  @override
  late final GeneratedColumn<int> absenceMins = GeneratedColumn<int>(
    'absence_mins',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _absenceDaysMeta = const VerificationMeta(
    'absenceDays',
  );
  @override
  late final GeneratedColumn<double> absenceDays = GeneratedColumn<double>(
    'absence_days',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _periodFromMeta = const VerificationMeta(
    'periodFrom',
  );
  @override
  late final GeneratedColumn<String> periodFrom = GeneratedColumn<String>(
    'period_from',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _periodToMeta = const VerificationMeta(
    'periodTo',
  );
  @override
  late final GeneratedColumn<String> periodTo = GeneratedColumn<String>(
    'period_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quotaYearMeta = const VerificationMeta(
    'quotaYear',
  );
  @override
  late final GeneratedColumn<double> quotaYear = GeneratedColumn<double>(
    'quota_year',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensitiveMeta = const VerificationMeta(
    'sensitive',
  );
  @override
  late final GeneratedColumn<bool> sensitive = GeneratedColumn<bool>(
    'sensitive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sensitive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasDocumentationMeta = const VerificationMeta(
    'hasDocumentation',
  );
  @override
  late final GeneratedColumn<bool> hasDocumentation = GeneratedColumn<bool>(
    'has_documentation',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_documentation" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _countsAsSicknessPeriodMeta =
      const VerificationMeta('countsAsSicknessPeriod');
  @override
  late final GeneratedColumn<bool> countsAsSicknessPeriod =
      GeneratedColumn<bool>(
        'counts_as_sickness_period',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("counts_as_sickness_period" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    uid,
    dateId,
    startTime,
    endTime,
    standardPauseMins,
    leavePauseMins,
    lunchPauseMins,
    netWorkedMins,
    extraMins,
    sliMins,
    sboMins,
    workType,
    note,
    bancaOreMins,
    boeSlot,
    updatedAt,
    absenceKind,
    absenceUnit,
    absenceMins,
    absenceDays,
    periodFrom,
    periodTo,
    quotaYear,
    sensitive,
    hasDocumentation,
    countsAsSicknessPeriod,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timesheet_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimesheetEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('date_id')) {
      context.handle(
        _dateIdMeta,
        dateId.isAcceptableOrUnknown(data['date_id']!, _dateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dateIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('standard_pause_mins')) {
      context.handle(
        _standardPauseMinsMeta,
        standardPauseMins.isAcceptableOrUnknown(
          data['standard_pause_mins']!,
          _standardPauseMinsMeta,
        ),
      );
    }
    if (data.containsKey('leave_pause_mins')) {
      context.handle(
        _leavePauseMinsMeta,
        leavePauseMins.isAcceptableOrUnknown(
          data['leave_pause_mins']!,
          _leavePauseMinsMeta,
        ),
      );
    }
    if (data.containsKey('lunch_pause_mins')) {
      context.handle(
        _lunchPauseMinsMeta,
        lunchPauseMins.isAcceptableOrUnknown(
          data['lunch_pause_mins']!,
          _lunchPauseMinsMeta,
        ),
      );
    }
    if (data.containsKey('net_worked_mins')) {
      context.handle(
        _netWorkedMinsMeta,
        netWorkedMins.isAcceptableOrUnknown(
          data['net_worked_mins']!,
          _netWorkedMinsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_netWorkedMinsMeta);
    }
    if (data.containsKey('extra_mins')) {
      context.handle(
        _extraMinsMeta,
        extraMins.isAcceptableOrUnknown(data['extra_mins']!, _extraMinsMeta),
      );
    } else if (isInserting) {
      context.missing(_extraMinsMeta);
    }
    if (data.containsKey('sli_mins')) {
      context.handle(
        _sliMinsMeta,
        sliMins.isAcceptableOrUnknown(data['sli_mins']!, _sliMinsMeta),
      );
    }
    if (data.containsKey('sbo_mins')) {
      context.handle(
        _sboMinsMeta,
        sboMins.isAcceptableOrUnknown(data['sbo_mins']!, _sboMinsMeta),
      );
    }
    if (data.containsKey('work_type')) {
      context.handle(
        _workTypeMeta,
        workType.isAcceptableOrUnknown(data['work_type']!, _workTypeMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('banca_ore_mins')) {
      context.handle(
        _bancaOreMinsMeta,
        bancaOreMins.isAcceptableOrUnknown(
          data['banca_ore_mins']!,
          _bancaOreMinsMeta,
        ),
      );
    }
    if (data.containsKey('boe_slot')) {
      context.handle(
        _boeSlotMeta,
        boeSlot.isAcceptableOrUnknown(data['boe_slot']!, _boeSlotMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('absence_kind')) {
      context.handle(
        _absenceKindMeta,
        absenceKind.isAcceptableOrUnknown(
          data['absence_kind']!,
          _absenceKindMeta,
        ),
      );
    }
    if (data.containsKey('absence_unit')) {
      context.handle(
        _absenceUnitMeta,
        absenceUnit.isAcceptableOrUnknown(
          data['absence_unit']!,
          _absenceUnitMeta,
        ),
      );
    }
    if (data.containsKey('absence_mins')) {
      context.handle(
        _absenceMinsMeta,
        absenceMins.isAcceptableOrUnknown(
          data['absence_mins']!,
          _absenceMinsMeta,
        ),
      );
    }
    if (data.containsKey('absence_days')) {
      context.handle(
        _absenceDaysMeta,
        absenceDays.isAcceptableOrUnknown(
          data['absence_days']!,
          _absenceDaysMeta,
        ),
      );
    }
    if (data.containsKey('period_from')) {
      context.handle(
        _periodFromMeta,
        periodFrom.isAcceptableOrUnknown(data['period_from']!, _periodFromMeta),
      );
    }
    if (data.containsKey('period_to')) {
      context.handle(
        _periodToMeta,
        periodTo.isAcceptableOrUnknown(data['period_to']!, _periodToMeta),
      );
    }
    if (data.containsKey('quota_year')) {
      context.handle(
        _quotaYearMeta,
        quotaYear.isAcceptableOrUnknown(data['quota_year']!, _quotaYearMeta),
      );
    }
    if (data.containsKey('sensitive')) {
      context.handle(
        _sensitiveMeta,
        sensitive.isAcceptableOrUnknown(data['sensitive']!, _sensitiveMeta),
      );
    }
    if (data.containsKey('has_documentation')) {
      context.handle(
        _hasDocumentationMeta,
        hasDocumentation.isAcceptableOrUnknown(
          data['has_documentation']!,
          _hasDocumentationMeta,
        ),
      );
    }
    if (data.containsKey('counts_as_sickness_period')) {
      context.handle(
        _countsAsSicknessPeriodMeta,
        countsAsSicknessPeriod.isAcceptableOrUnknown(
          data['counts_as_sickness_period']!,
          _countsAsSicknessPeriodMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid, dateId};
  @override
  TimesheetEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimesheetEntry(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      dateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
      standardPauseMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}standard_pause_mins'],
      )!,
      leavePauseMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}leave_pause_mins'],
      )!,
      lunchPauseMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lunch_pause_mins'],
      )!,
      netWorkedMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}net_worked_mins'],
      )!,
      extraMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extra_mins'],
      )!,
      sliMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sli_mins'],
      )!,
      sboMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sbo_mins'],
      )!,
      workType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_type'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      bancaOreMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}banca_ore_mins'],
      )!,
      boeSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boe_slot'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      absenceKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}absence_kind'],
      ),
      absenceUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}absence_unit'],
      ),
      absenceMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}absence_mins'],
      ),
      absenceDays: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}absence_days'],
      ),
      periodFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_from'],
      ),
      periodTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_to'],
      ),
      quotaYear: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quota_year'],
      ),
      sensitive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sensitive'],
      )!,
      hasDocumentation: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_documentation'],
      )!,
      countsAsSicknessPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}counts_as_sickness_period'],
      )!,
    );
  }

  @override
  $TimesheetEntriesTable createAlias(String alias) {
    return $TimesheetEntriesTable(attachedDatabase, alias);
  }
}

class TimesheetEntry extends DataClass implements Insertable<TimesheetEntry> {
  final String uid;
  final String dateId;
  final String startTime;
  final String endTime;
  final int standardPauseMins;
  final int leavePauseMins;
  final int lunchPauseMins;
  final int netWorkedMins;
  final int extraMins;
  final int sliMins;
  final int sboMins;
  final String? workType;
  final String? note;
  final int bancaOreMins;
  final String? boeSlot;
  final String updatedAt;
  final String? absenceKind;
  final String? absenceUnit;
  final int? absenceMins;
  final double? absenceDays;
  final String? periodFrom;
  final String? periodTo;
  final double? quotaYear;
  final bool sensitive;
  final bool hasDocumentation;
  final bool countsAsSicknessPeriod;
  const TimesheetEntry({
    required this.uid,
    required this.dateId,
    required this.startTime,
    required this.endTime,
    required this.standardPauseMins,
    required this.leavePauseMins,
    required this.lunchPauseMins,
    required this.netWorkedMins,
    required this.extraMins,
    required this.sliMins,
    required this.sboMins,
    this.workType,
    this.note,
    required this.bancaOreMins,
    this.boeSlot,
    required this.updatedAt,
    this.absenceKind,
    this.absenceUnit,
    this.absenceMins,
    this.absenceDays,
    this.periodFrom,
    this.periodTo,
    this.quotaYear,
    required this.sensitive,
    required this.hasDocumentation,
    required this.countsAsSicknessPeriod,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['date_id'] = Variable<String>(dateId);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    map['standard_pause_mins'] = Variable<int>(standardPauseMins);
    map['leave_pause_mins'] = Variable<int>(leavePauseMins);
    map['lunch_pause_mins'] = Variable<int>(lunchPauseMins);
    map['net_worked_mins'] = Variable<int>(netWorkedMins);
    map['extra_mins'] = Variable<int>(extraMins);
    map['sli_mins'] = Variable<int>(sliMins);
    map['sbo_mins'] = Variable<int>(sboMins);
    if (!nullToAbsent || workType != null) {
      map['work_type'] = Variable<String>(workType);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['banca_ore_mins'] = Variable<int>(bancaOreMins);
    if (!nullToAbsent || boeSlot != null) {
      map['boe_slot'] = Variable<String>(boeSlot);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || absenceKind != null) {
      map['absence_kind'] = Variable<String>(absenceKind);
    }
    if (!nullToAbsent || absenceUnit != null) {
      map['absence_unit'] = Variable<String>(absenceUnit);
    }
    if (!nullToAbsent || absenceMins != null) {
      map['absence_mins'] = Variable<int>(absenceMins);
    }
    if (!nullToAbsent || absenceDays != null) {
      map['absence_days'] = Variable<double>(absenceDays);
    }
    if (!nullToAbsent || periodFrom != null) {
      map['period_from'] = Variable<String>(periodFrom);
    }
    if (!nullToAbsent || periodTo != null) {
      map['period_to'] = Variable<String>(periodTo);
    }
    if (!nullToAbsent || quotaYear != null) {
      map['quota_year'] = Variable<double>(quotaYear);
    }
    map['sensitive'] = Variable<bool>(sensitive);
    map['has_documentation'] = Variable<bool>(hasDocumentation);
    map['counts_as_sickness_period'] = Variable<bool>(countsAsSicknessPeriod);
    return map;
  }

  TimesheetEntriesCompanion toCompanion(bool nullToAbsent) {
    return TimesheetEntriesCompanion(
      uid: Value(uid),
      dateId: Value(dateId),
      startTime: Value(startTime),
      endTime: Value(endTime),
      standardPauseMins: Value(standardPauseMins),
      leavePauseMins: Value(leavePauseMins),
      lunchPauseMins: Value(lunchPauseMins),
      netWorkedMins: Value(netWorkedMins),
      extraMins: Value(extraMins),
      sliMins: Value(sliMins),
      sboMins: Value(sboMins),
      workType: workType == null && nullToAbsent
          ? const Value.absent()
          : Value(workType),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      bancaOreMins: Value(bancaOreMins),
      boeSlot: boeSlot == null && nullToAbsent
          ? const Value.absent()
          : Value(boeSlot),
      updatedAt: Value(updatedAt),
      absenceKind: absenceKind == null && nullToAbsent
          ? const Value.absent()
          : Value(absenceKind),
      absenceUnit: absenceUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(absenceUnit),
      absenceMins: absenceMins == null && nullToAbsent
          ? const Value.absent()
          : Value(absenceMins),
      absenceDays: absenceDays == null && nullToAbsent
          ? const Value.absent()
          : Value(absenceDays),
      periodFrom: periodFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(periodFrom),
      periodTo: periodTo == null && nullToAbsent
          ? const Value.absent()
          : Value(periodTo),
      quotaYear: quotaYear == null && nullToAbsent
          ? const Value.absent()
          : Value(quotaYear),
      sensitive: Value(sensitive),
      hasDocumentation: Value(hasDocumentation),
      countsAsSicknessPeriod: Value(countsAsSicknessPeriod),
    );
  }

  factory TimesheetEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimesheetEntry(
      uid: serializer.fromJson<String>(json['uid']),
      dateId: serializer.fromJson<String>(json['dateId']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      standardPauseMins: serializer.fromJson<int>(json['standardPauseMins']),
      leavePauseMins: serializer.fromJson<int>(json['leavePauseMins']),
      lunchPauseMins: serializer.fromJson<int>(json['lunchPauseMins']),
      netWorkedMins: serializer.fromJson<int>(json['netWorkedMins']),
      extraMins: serializer.fromJson<int>(json['extraMins']),
      sliMins: serializer.fromJson<int>(json['sliMins']),
      sboMins: serializer.fromJson<int>(json['sboMins']),
      workType: serializer.fromJson<String?>(json['workType']),
      note: serializer.fromJson<String?>(json['note']),
      bancaOreMins: serializer.fromJson<int>(json['bancaOreMins']),
      boeSlot: serializer.fromJson<String?>(json['boeSlot']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      absenceKind: serializer.fromJson<String?>(json['absenceKind']),
      absenceUnit: serializer.fromJson<String?>(json['absenceUnit']),
      absenceMins: serializer.fromJson<int?>(json['absenceMins']),
      absenceDays: serializer.fromJson<double?>(json['absenceDays']),
      periodFrom: serializer.fromJson<String?>(json['periodFrom']),
      periodTo: serializer.fromJson<String?>(json['periodTo']),
      quotaYear: serializer.fromJson<double?>(json['quotaYear']),
      sensitive: serializer.fromJson<bool>(json['sensitive']),
      hasDocumentation: serializer.fromJson<bool>(json['hasDocumentation']),
      countsAsSicknessPeriod: serializer.fromJson<bool>(
        json['countsAsSicknessPeriod'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'dateId': serializer.toJson<String>(dateId),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'standardPauseMins': serializer.toJson<int>(standardPauseMins),
      'leavePauseMins': serializer.toJson<int>(leavePauseMins),
      'lunchPauseMins': serializer.toJson<int>(lunchPauseMins),
      'netWorkedMins': serializer.toJson<int>(netWorkedMins),
      'extraMins': serializer.toJson<int>(extraMins),
      'sliMins': serializer.toJson<int>(sliMins),
      'sboMins': serializer.toJson<int>(sboMins),
      'workType': serializer.toJson<String?>(workType),
      'note': serializer.toJson<String?>(note),
      'bancaOreMins': serializer.toJson<int>(bancaOreMins),
      'boeSlot': serializer.toJson<String?>(boeSlot),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'absenceKind': serializer.toJson<String?>(absenceKind),
      'absenceUnit': serializer.toJson<String?>(absenceUnit),
      'absenceMins': serializer.toJson<int?>(absenceMins),
      'absenceDays': serializer.toJson<double?>(absenceDays),
      'periodFrom': serializer.toJson<String?>(periodFrom),
      'periodTo': serializer.toJson<String?>(periodTo),
      'quotaYear': serializer.toJson<double?>(quotaYear),
      'sensitive': serializer.toJson<bool>(sensitive),
      'hasDocumentation': serializer.toJson<bool>(hasDocumentation),
      'countsAsSicknessPeriod': serializer.toJson<bool>(countsAsSicknessPeriod),
    };
  }

  TimesheetEntry copyWith({
    String? uid,
    String? dateId,
    String? startTime,
    String? endTime,
    int? standardPauseMins,
    int? leavePauseMins,
    int? lunchPauseMins,
    int? netWorkedMins,
    int? extraMins,
    int? sliMins,
    int? sboMins,
    Value<String?> workType = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? bancaOreMins,
    Value<String?> boeSlot = const Value.absent(),
    String? updatedAt,
    Value<String?> absenceKind = const Value.absent(),
    Value<String?> absenceUnit = const Value.absent(),
    Value<int?> absenceMins = const Value.absent(),
    Value<double?> absenceDays = const Value.absent(),
    Value<String?> periodFrom = const Value.absent(),
    Value<String?> periodTo = const Value.absent(),
    Value<double?> quotaYear = const Value.absent(),
    bool? sensitive,
    bool? hasDocumentation,
    bool? countsAsSicknessPeriod,
  }) => TimesheetEntry(
    uid: uid ?? this.uid,
    dateId: dateId ?? this.dateId,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    standardPauseMins: standardPauseMins ?? this.standardPauseMins,
    leavePauseMins: leavePauseMins ?? this.leavePauseMins,
    lunchPauseMins: lunchPauseMins ?? this.lunchPauseMins,
    netWorkedMins: netWorkedMins ?? this.netWorkedMins,
    extraMins: extraMins ?? this.extraMins,
    sliMins: sliMins ?? this.sliMins,
    sboMins: sboMins ?? this.sboMins,
    workType: workType.present ? workType.value : this.workType,
    note: note.present ? note.value : this.note,
    bancaOreMins: bancaOreMins ?? this.bancaOreMins,
    boeSlot: boeSlot.present ? boeSlot.value : this.boeSlot,
    updatedAt: updatedAt ?? this.updatedAt,
    absenceKind: absenceKind.present ? absenceKind.value : this.absenceKind,
    absenceUnit: absenceUnit.present ? absenceUnit.value : this.absenceUnit,
    absenceMins: absenceMins.present ? absenceMins.value : this.absenceMins,
    absenceDays: absenceDays.present ? absenceDays.value : this.absenceDays,
    periodFrom: periodFrom.present ? periodFrom.value : this.periodFrom,
    periodTo: periodTo.present ? periodTo.value : this.periodTo,
    quotaYear: quotaYear.present ? quotaYear.value : this.quotaYear,
    sensitive: sensitive ?? this.sensitive,
    hasDocumentation: hasDocumentation ?? this.hasDocumentation,
    countsAsSicknessPeriod:
        countsAsSicknessPeriod ?? this.countsAsSicknessPeriod,
  );
  TimesheetEntry copyWithCompanion(TimesheetEntriesCompanion data) {
    return TimesheetEntry(
      uid: data.uid.present ? data.uid.value : this.uid,
      dateId: data.dateId.present ? data.dateId.value : this.dateId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      standardPauseMins: data.standardPauseMins.present
          ? data.standardPauseMins.value
          : this.standardPauseMins,
      leavePauseMins: data.leavePauseMins.present
          ? data.leavePauseMins.value
          : this.leavePauseMins,
      lunchPauseMins: data.lunchPauseMins.present
          ? data.lunchPauseMins.value
          : this.lunchPauseMins,
      netWorkedMins: data.netWorkedMins.present
          ? data.netWorkedMins.value
          : this.netWorkedMins,
      extraMins: data.extraMins.present ? data.extraMins.value : this.extraMins,
      sliMins: data.sliMins.present ? data.sliMins.value : this.sliMins,
      sboMins: data.sboMins.present ? data.sboMins.value : this.sboMins,
      workType: data.workType.present ? data.workType.value : this.workType,
      note: data.note.present ? data.note.value : this.note,
      bancaOreMins: data.bancaOreMins.present
          ? data.bancaOreMins.value
          : this.bancaOreMins,
      boeSlot: data.boeSlot.present ? data.boeSlot.value : this.boeSlot,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      absenceKind: data.absenceKind.present
          ? data.absenceKind.value
          : this.absenceKind,
      absenceUnit: data.absenceUnit.present
          ? data.absenceUnit.value
          : this.absenceUnit,
      absenceMins: data.absenceMins.present
          ? data.absenceMins.value
          : this.absenceMins,
      absenceDays: data.absenceDays.present
          ? data.absenceDays.value
          : this.absenceDays,
      periodFrom: data.periodFrom.present
          ? data.periodFrom.value
          : this.periodFrom,
      periodTo: data.periodTo.present ? data.periodTo.value : this.periodTo,
      quotaYear: data.quotaYear.present ? data.quotaYear.value : this.quotaYear,
      sensitive: data.sensitive.present ? data.sensitive.value : this.sensitive,
      hasDocumentation: data.hasDocumentation.present
          ? data.hasDocumentation.value
          : this.hasDocumentation,
      countsAsSicknessPeriod: data.countsAsSicknessPeriod.present
          ? data.countsAsSicknessPeriod.value
          : this.countsAsSicknessPeriod,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimesheetEntry(')
          ..write('uid: $uid, ')
          ..write('dateId: $dateId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('standardPauseMins: $standardPauseMins, ')
          ..write('leavePauseMins: $leavePauseMins, ')
          ..write('lunchPauseMins: $lunchPauseMins, ')
          ..write('netWorkedMins: $netWorkedMins, ')
          ..write('extraMins: $extraMins, ')
          ..write('sliMins: $sliMins, ')
          ..write('sboMins: $sboMins, ')
          ..write('workType: $workType, ')
          ..write('note: $note, ')
          ..write('bancaOreMins: $bancaOreMins, ')
          ..write('boeSlot: $boeSlot, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('absenceKind: $absenceKind, ')
          ..write('absenceUnit: $absenceUnit, ')
          ..write('absenceMins: $absenceMins, ')
          ..write('absenceDays: $absenceDays, ')
          ..write('periodFrom: $periodFrom, ')
          ..write('periodTo: $periodTo, ')
          ..write('quotaYear: $quotaYear, ')
          ..write('sensitive: $sensitive, ')
          ..write('hasDocumentation: $hasDocumentation, ')
          ..write('countsAsSicknessPeriod: $countsAsSicknessPeriod')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    uid,
    dateId,
    startTime,
    endTime,
    standardPauseMins,
    leavePauseMins,
    lunchPauseMins,
    netWorkedMins,
    extraMins,
    sliMins,
    sboMins,
    workType,
    note,
    bancaOreMins,
    boeSlot,
    updatedAt,
    absenceKind,
    absenceUnit,
    absenceMins,
    absenceDays,
    periodFrom,
    periodTo,
    quotaYear,
    sensitive,
    hasDocumentation,
    countsAsSicknessPeriod,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimesheetEntry &&
          other.uid == this.uid &&
          other.dateId == this.dateId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.standardPauseMins == this.standardPauseMins &&
          other.leavePauseMins == this.leavePauseMins &&
          other.lunchPauseMins == this.lunchPauseMins &&
          other.netWorkedMins == this.netWorkedMins &&
          other.extraMins == this.extraMins &&
          other.sliMins == this.sliMins &&
          other.sboMins == this.sboMins &&
          other.workType == this.workType &&
          other.note == this.note &&
          other.bancaOreMins == this.bancaOreMins &&
          other.boeSlot == this.boeSlot &&
          other.updatedAt == this.updatedAt &&
          other.absenceKind == this.absenceKind &&
          other.absenceUnit == this.absenceUnit &&
          other.absenceMins == this.absenceMins &&
          other.absenceDays == this.absenceDays &&
          other.periodFrom == this.periodFrom &&
          other.periodTo == this.periodTo &&
          other.quotaYear == this.quotaYear &&
          other.sensitive == this.sensitive &&
          other.hasDocumentation == this.hasDocumentation &&
          other.countsAsSicknessPeriod == this.countsAsSicknessPeriod);
}

class TimesheetEntriesCompanion extends UpdateCompanion<TimesheetEntry> {
  final Value<String> uid;
  final Value<String> dateId;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<int> standardPauseMins;
  final Value<int> leavePauseMins;
  final Value<int> lunchPauseMins;
  final Value<int> netWorkedMins;
  final Value<int> extraMins;
  final Value<int> sliMins;
  final Value<int> sboMins;
  final Value<String?> workType;
  final Value<String?> note;
  final Value<int> bancaOreMins;
  final Value<String?> boeSlot;
  final Value<String> updatedAt;
  final Value<String?> absenceKind;
  final Value<String?> absenceUnit;
  final Value<int?> absenceMins;
  final Value<double?> absenceDays;
  final Value<String?> periodFrom;
  final Value<String?> periodTo;
  final Value<double?> quotaYear;
  final Value<bool> sensitive;
  final Value<bool> hasDocumentation;
  final Value<bool> countsAsSicknessPeriod;
  final Value<int> rowid;
  const TimesheetEntriesCompanion({
    this.uid = const Value.absent(),
    this.dateId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.standardPauseMins = const Value.absent(),
    this.leavePauseMins = const Value.absent(),
    this.lunchPauseMins = const Value.absent(),
    this.netWorkedMins = const Value.absent(),
    this.extraMins = const Value.absent(),
    this.sliMins = const Value.absent(),
    this.sboMins = const Value.absent(),
    this.workType = const Value.absent(),
    this.note = const Value.absent(),
    this.bancaOreMins = const Value.absent(),
    this.boeSlot = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.absenceKind = const Value.absent(),
    this.absenceUnit = const Value.absent(),
    this.absenceMins = const Value.absent(),
    this.absenceDays = const Value.absent(),
    this.periodFrom = const Value.absent(),
    this.periodTo = const Value.absent(),
    this.quotaYear = const Value.absent(),
    this.sensitive = const Value.absent(),
    this.hasDocumentation = const Value.absent(),
    this.countsAsSicknessPeriod = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimesheetEntriesCompanion.insert({
    required String uid,
    required String dateId,
    required String startTime,
    required String endTime,
    this.standardPauseMins = const Value.absent(),
    this.leavePauseMins = const Value.absent(),
    this.lunchPauseMins = const Value.absent(),
    required int netWorkedMins,
    required int extraMins,
    this.sliMins = const Value.absent(),
    this.sboMins = const Value.absent(),
    this.workType = const Value.absent(),
    this.note = const Value.absent(),
    this.bancaOreMins = const Value.absent(),
    this.boeSlot = const Value.absent(),
    required String updatedAt,
    this.absenceKind = const Value.absent(),
    this.absenceUnit = const Value.absent(),
    this.absenceMins = const Value.absent(),
    this.absenceDays = const Value.absent(),
    this.periodFrom = const Value.absent(),
    this.periodTo = const Value.absent(),
    this.quotaYear = const Value.absent(),
    this.sensitive = const Value.absent(),
    this.hasDocumentation = const Value.absent(),
    this.countsAsSicknessPeriod = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       dateId = Value(dateId),
       startTime = Value(startTime),
       endTime = Value(endTime),
       netWorkedMins = Value(netWorkedMins),
       extraMins = Value(extraMins),
       updatedAt = Value(updatedAt);
  static Insertable<TimesheetEntry> custom({
    Expression<String>? uid,
    Expression<String>? dateId,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<int>? standardPauseMins,
    Expression<int>? leavePauseMins,
    Expression<int>? lunchPauseMins,
    Expression<int>? netWorkedMins,
    Expression<int>? extraMins,
    Expression<int>? sliMins,
    Expression<int>? sboMins,
    Expression<String>? workType,
    Expression<String>? note,
    Expression<int>? bancaOreMins,
    Expression<String>? boeSlot,
    Expression<String>? updatedAt,
    Expression<String>? absenceKind,
    Expression<String>? absenceUnit,
    Expression<int>? absenceMins,
    Expression<double>? absenceDays,
    Expression<String>? periodFrom,
    Expression<String>? periodTo,
    Expression<double>? quotaYear,
    Expression<bool>? sensitive,
    Expression<bool>? hasDocumentation,
    Expression<bool>? countsAsSicknessPeriod,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (dateId != null) 'date_id': dateId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (standardPauseMins != null) 'standard_pause_mins': standardPauseMins,
      if (leavePauseMins != null) 'leave_pause_mins': leavePauseMins,
      if (lunchPauseMins != null) 'lunch_pause_mins': lunchPauseMins,
      if (netWorkedMins != null) 'net_worked_mins': netWorkedMins,
      if (extraMins != null) 'extra_mins': extraMins,
      if (sliMins != null) 'sli_mins': sliMins,
      if (sboMins != null) 'sbo_mins': sboMins,
      if (workType != null) 'work_type': workType,
      if (note != null) 'note': note,
      if (bancaOreMins != null) 'banca_ore_mins': bancaOreMins,
      if (boeSlot != null) 'boe_slot': boeSlot,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (absenceKind != null) 'absence_kind': absenceKind,
      if (absenceUnit != null) 'absence_unit': absenceUnit,
      if (absenceMins != null) 'absence_mins': absenceMins,
      if (absenceDays != null) 'absence_days': absenceDays,
      if (periodFrom != null) 'period_from': periodFrom,
      if (periodTo != null) 'period_to': periodTo,
      if (quotaYear != null) 'quota_year': quotaYear,
      if (sensitive != null) 'sensitive': sensitive,
      if (hasDocumentation != null) 'has_documentation': hasDocumentation,
      if (countsAsSicknessPeriod != null)
        'counts_as_sickness_period': countsAsSicknessPeriod,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimesheetEntriesCompanion copyWith({
    Value<String>? uid,
    Value<String>? dateId,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<int>? standardPauseMins,
    Value<int>? leavePauseMins,
    Value<int>? lunchPauseMins,
    Value<int>? netWorkedMins,
    Value<int>? extraMins,
    Value<int>? sliMins,
    Value<int>? sboMins,
    Value<String?>? workType,
    Value<String?>? note,
    Value<int>? bancaOreMins,
    Value<String?>? boeSlot,
    Value<String>? updatedAt,
    Value<String?>? absenceKind,
    Value<String?>? absenceUnit,
    Value<int?>? absenceMins,
    Value<double?>? absenceDays,
    Value<String?>? periodFrom,
    Value<String?>? periodTo,
    Value<double?>? quotaYear,
    Value<bool>? sensitive,
    Value<bool>? hasDocumentation,
    Value<bool>? countsAsSicknessPeriod,
    Value<int>? rowid,
  }) {
    return TimesheetEntriesCompanion(
      uid: uid ?? this.uid,
      dateId: dateId ?? this.dateId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      standardPauseMins: standardPauseMins ?? this.standardPauseMins,
      leavePauseMins: leavePauseMins ?? this.leavePauseMins,
      lunchPauseMins: lunchPauseMins ?? this.lunchPauseMins,
      netWorkedMins: netWorkedMins ?? this.netWorkedMins,
      extraMins: extraMins ?? this.extraMins,
      sliMins: sliMins ?? this.sliMins,
      sboMins: sboMins ?? this.sboMins,
      workType: workType ?? this.workType,
      note: note ?? this.note,
      bancaOreMins: bancaOreMins ?? this.bancaOreMins,
      boeSlot: boeSlot ?? this.boeSlot,
      updatedAt: updatedAt ?? this.updatedAt,
      absenceKind: absenceKind ?? this.absenceKind,
      absenceUnit: absenceUnit ?? this.absenceUnit,
      absenceMins: absenceMins ?? this.absenceMins,
      absenceDays: absenceDays ?? this.absenceDays,
      periodFrom: periodFrom ?? this.periodFrom,
      periodTo: periodTo ?? this.periodTo,
      quotaYear: quotaYear ?? this.quotaYear,
      sensitive: sensitive ?? this.sensitive,
      hasDocumentation: hasDocumentation ?? this.hasDocumentation,
      countsAsSicknessPeriod:
          countsAsSicknessPeriod ?? this.countsAsSicknessPeriod,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (dateId.present) {
      map['date_id'] = Variable<String>(dateId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (standardPauseMins.present) {
      map['standard_pause_mins'] = Variable<int>(standardPauseMins.value);
    }
    if (leavePauseMins.present) {
      map['leave_pause_mins'] = Variable<int>(leavePauseMins.value);
    }
    if (lunchPauseMins.present) {
      map['lunch_pause_mins'] = Variable<int>(lunchPauseMins.value);
    }
    if (netWorkedMins.present) {
      map['net_worked_mins'] = Variable<int>(netWorkedMins.value);
    }
    if (extraMins.present) {
      map['extra_mins'] = Variable<int>(extraMins.value);
    }
    if (sliMins.present) {
      map['sli_mins'] = Variable<int>(sliMins.value);
    }
    if (sboMins.present) {
      map['sbo_mins'] = Variable<int>(sboMins.value);
    }
    if (workType.present) {
      map['work_type'] = Variable<String>(workType.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (bancaOreMins.present) {
      map['banca_ore_mins'] = Variable<int>(bancaOreMins.value);
    }
    if (boeSlot.present) {
      map['boe_slot'] = Variable<String>(boeSlot.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (absenceKind.present) {
      map['absence_kind'] = Variable<String>(absenceKind.value);
    }
    if (absenceUnit.present) {
      map['absence_unit'] = Variable<String>(absenceUnit.value);
    }
    if (absenceMins.present) {
      map['absence_mins'] = Variable<int>(absenceMins.value);
    }
    if (absenceDays.present) {
      map['absence_days'] = Variable<double>(absenceDays.value);
    }
    if (periodFrom.present) {
      map['period_from'] = Variable<String>(periodFrom.value);
    }
    if (periodTo.present) {
      map['period_to'] = Variable<String>(periodTo.value);
    }
    if (quotaYear.present) {
      map['quota_year'] = Variable<double>(quotaYear.value);
    }
    if (sensitive.present) {
      map['sensitive'] = Variable<bool>(sensitive.value);
    }
    if (hasDocumentation.present) {
      map['has_documentation'] = Variable<bool>(hasDocumentation.value);
    }
    if (countsAsSicknessPeriod.present) {
      map['counts_as_sickness_period'] = Variable<bool>(
        countsAsSicknessPeriod.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimesheetEntriesCompanion(')
          ..write('uid: $uid, ')
          ..write('dateId: $dateId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('standardPauseMins: $standardPauseMins, ')
          ..write('leavePauseMins: $leavePauseMins, ')
          ..write('lunchPauseMins: $lunchPauseMins, ')
          ..write('netWorkedMins: $netWorkedMins, ')
          ..write('extraMins: $extraMins, ')
          ..write('sliMins: $sliMins, ')
          ..write('sboMins: $sboMins, ')
          ..write('workType: $workType, ')
          ..write('note: $note, ')
          ..write('bancaOreMins: $bancaOreMins, ')
          ..write('boeSlot: $boeSlot, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('absenceKind: $absenceKind, ')
          ..write('absenceUnit: $absenceUnit, ')
          ..write('absenceMins: $absenceMins, ')
          ..write('absenceDays: $absenceDays, ')
          ..write('periodFrom: $periodFrom, ')
          ..write('periodTo: $periodTo, ')
          ..write('quotaYear: $quotaYear, ')
          ..write('sensitive: $sensitive, ')
          ..write('hasDocumentation: $hasDocumentation, ')
          ..write('countsAsSicknessPeriod: $countsAsSicknessPeriod, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PcmOfficeLocationsTable extends PcmOfficeLocations
    with TableInfo<$PcmOfficeLocationsTable, PcmOfficeLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PcmOfficeLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _structureNameMeta = const VerificationMeta(
    'structureName',
  );
  @override
  late final GeneratedColumn<String> structureName = GeneratedColumn<String>(
    'structure_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Roma'),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    locationName,
    structureName,
    address,
    city,
    latitude,
    longitude,
    sortOrder,
    isActive,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pcm_office_locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PcmOfficeLocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locationNameMeta);
    }
    if (data.containsKey('structure_name')) {
      context.handle(
        _structureNameMeta,
        structureName.isAcceptableOrUnknown(
          data['structure_name']!,
          _structureNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_structureNameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PcmOfficeLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PcmOfficeLocation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      )!,
      structureName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}structure_name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PcmOfficeLocationsTable createAlias(String alias) {
    return $PcmOfficeLocationsTable(attachedDatabase, alias);
  }
}

class PcmOfficeLocation extends DataClass
    implements Insertable<PcmOfficeLocation> {
  final String id;
  final String locationName;
  final String structureName;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final int sortOrder;
  final bool isActive;
  final String updatedAt;
  const PcmOfficeLocation({
    required this.id,
    required this.locationName,
    required this.structureName,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.sortOrder,
    required this.isActive,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['location_name'] = Variable<String>(locationName);
    map['structure_name'] = Variable<String>(structureName);
    map['address'] = Variable<String>(address);
    map['city'] = Variable<String>(city);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  PcmOfficeLocationsCompanion toCompanion(bool nullToAbsent) {
    return PcmOfficeLocationsCompanion(
      id: Value(id),
      locationName: Value(locationName),
      structureName: Value(structureName),
      address: Value(address),
      city: Value(city),
      latitude: Value(latitude),
      longitude: Value(longitude),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory PcmOfficeLocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PcmOfficeLocation(
      id: serializer.fromJson<String>(json['id']),
      locationName: serializer.fromJson<String>(json['locationName']),
      structureName: serializer.fromJson<String>(json['structureName']),
      address: serializer.fromJson<String>(json['address']),
      city: serializer.fromJson<String>(json['city']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'locationName': serializer.toJson<String>(locationName),
      'structureName': serializer.toJson<String>(structureName),
      'address': serializer.toJson<String>(address),
      'city': serializer.toJson<String>(city),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  PcmOfficeLocation copyWith({
    String? id,
    String? locationName,
    String? structureName,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    int? sortOrder,
    bool? isActive,
    String? updatedAt,
  }) => PcmOfficeLocation(
    id: id ?? this.id,
    locationName: locationName ?? this.locationName,
    structureName: structureName ?? this.structureName,
    address: address ?? this.address,
    city: city ?? this.city,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PcmOfficeLocation copyWithCompanion(PcmOfficeLocationsCompanion data) {
    return PcmOfficeLocation(
      id: data.id.present ? data.id.value : this.id,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      structureName: data.structureName.present
          ? data.structureName.value
          : this.structureName,
      address: data.address.present ? data.address.value : this.address,
      city: data.city.present ? data.city.value : this.city,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PcmOfficeLocation(')
          ..write('id: $id, ')
          ..write('locationName: $locationName, ')
          ..write('structureName: $structureName, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    locationName,
    structureName,
    address,
    city,
    latitude,
    longitude,
    sortOrder,
    isActive,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PcmOfficeLocation &&
          other.id == this.id &&
          other.locationName == this.locationName &&
          other.structureName == this.structureName &&
          other.address == this.address &&
          other.city == this.city &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class PcmOfficeLocationsCompanion extends UpdateCompanion<PcmOfficeLocation> {
  final Value<String> id;
  final Value<String> locationName;
  final Value<String> structureName;
  final Value<String> address;
  final Value<String> city;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const PcmOfficeLocationsCompanion({
    this.id = const Value.absent(),
    this.locationName = const Value.absent(),
    this.structureName = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PcmOfficeLocationsCompanion.insert({
    required String id,
    required String locationName,
    required String structureName,
    required String address,
    this.city = const Value.absent(),
    required double latitude,
    required double longitude,
    required int sortOrder,
    this.isActive = const Value.absent(),
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       locationName = Value(locationName),
       structureName = Value(structureName),
       address = Value(address),
       latitude = Value(latitude),
       longitude = Value(longitude),
       sortOrder = Value(sortOrder),
       updatedAt = Value(updatedAt);
  static Insertable<PcmOfficeLocation> custom({
    Expression<String>? id,
    Expression<String>? locationName,
    Expression<String>? structureName,
    Expression<String>? address,
    Expression<String>? city,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (locationName != null) 'location_name': locationName,
      if (structureName != null) 'structure_name': structureName,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PcmOfficeLocationsCompanion copyWith({
    Value<String>? id,
    Value<String>? locationName,
    Value<String>? structureName,
    Value<String>? address,
    Value<String>? city,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<int>? sortOrder,
    Value<bool>? isActive,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return PcmOfficeLocationsCompanion(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      structureName: structureName ?? this.structureName,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (structureName.present) {
      map['structure_name'] = Variable<String>(structureName.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PcmOfficeLocationsCompanion(')
          ..write('id: $id, ')
          ..write('locationName: $locationName, ')
          ..write('structureName: $structureName, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TimesheetEntriesTable timesheetEntries = $TimesheetEntriesTable(
    this,
  );
  late final $PcmOfficeLocationsTable pcmOfficeLocations =
      $PcmOfficeLocationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    timesheetEntries,
    pcmOfficeLocations,
  ];
}

typedef $$TimesheetEntriesTableCreateCompanionBuilder =
    TimesheetEntriesCompanion Function({
      required String uid,
      required String dateId,
      required String startTime,
      required String endTime,
      Value<int> standardPauseMins,
      Value<int> leavePauseMins,
      Value<int> lunchPauseMins,
      required int netWorkedMins,
      required int extraMins,
      Value<int> sliMins,
      Value<int> sboMins,
      Value<String?> workType,
      Value<String?> note,
      Value<int> bancaOreMins,
      Value<String?> boeSlot,
      required String updatedAt,
      Value<String?> absenceKind,
      Value<String?> absenceUnit,
      Value<int?> absenceMins,
      Value<double?> absenceDays,
      Value<String?> periodFrom,
      Value<String?> periodTo,
      Value<double?> quotaYear,
      Value<bool> sensitive,
      Value<bool> hasDocumentation,
      Value<bool> countsAsSicknessPeriod,
      Value<int> rowid,
    });
typedef $$TimesheetEntriesTableUpdateCompanionBuilder =
    TimesheetEntriesCompanion Function({
      Value<String> uid,
      Value<String> dateId,
      Value<String> startTime,
      Value<String> endTime,
      Value<int> standardPauseMins,
      Value<int> leavePauseMins,
      Value<int> lunchPauseMins,
      Value<int> netWorkedMins,
      Value<int> extraMins,
      Value<int> sliMins,
      Value<int> sboMins,
      Value<String?> workType,
      Value<String?> note,
      Value<int> bancaOreMins,
      Value<String?> boeSlot,
      Value<String> updatedAt,
      Value<String?> absenceKind,
      Value<String?> absenceUnit,
      Value<int?> absenceMins,
      Value<double?> absenceDays,
      Value<String?> periodFrom,
      Value<String?> periodTo,
      Value<double?> quotaYear,
      Value<bool> sensitive,
      Value<bool> hasDocumentation,
      Value<bool> countsAsSicknessPeriod,
      Value<int> rowid,
    });

class $$TimesheetEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TimesheetEntriesTable> {
  $$TimesheetEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateId => $composableBuilder(
    column: $table.dateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get standardPauseMins => $composableBuilder(
    column: $table.standardPauseMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leavePauseMins => $composableBuilder(
    column: $table.leavePauseMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lunchPauseMins => $composableBuilder(
    column: $table.lunchPauseMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get netWorkedMins => $composableBuilder(
    column: $table.netWorkedMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extraMins => $composableBuilder(
    column: $table.extraMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sliMins => $composableBuilder(
    column: $table.sliMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sboMins => $composableBuilder(
    column: $table.sboMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workType => $composableBuilder(
    column: $table.workType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bancaOreMins => $composableBuilder(
    column: $table.bancaOreMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boeSlot => $composableBuilder(
    column: $table.boeSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get absenceKind => $composableBuilder(
    column: $table.absenceKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get absenceUnit => $composableBuilder(
    column: $table.absenceUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get absenceMins => $composableBuilder(
    column: $table.absenceMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get absenceDays => $composableBuilder(
    column: $table.absenceDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodFrom => $composableBuilder(
    column: $table.periodFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodTo => $composableBuilder(
    column: $table.periodTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quotaYear => $composableBuilder(
    column: $table.quotaYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sensitive => $composableBuilder(
    column: $table.sensitive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasDocumentation => $composableBuilder(
    column: $table.hasDocumentation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get countsAsSicknessPeriod => $composableBuilder(
    column: $table.countsAsSicknessPeriod,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimesheetEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimesheetEntriesTable> {
  $$TimesheetEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateId => $composableBuilder(
    column: $table.dateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get standardPauseMins => $composableBuilder(
    column: $table.standardPauseMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leavePauseMins => $composableBuilder(
    column: $table.leavePauseMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lunchPauseMins => $composableBuilder(
    column: $table.lunchPauseMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get netWorkedMins => $composableBuilder(
    column: $table.netWorkedMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extraMins => $composableBuilder(
    column: $table.extraMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sliMins => $composableBuilder(
    column: $table.sliMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sboMins => $composableBuilder(
    column: $table.sboMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workType => $composableBuilder(
    column: $table.workType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bancaOreMins => $composableBuilder(
    column: $table.bancaOreMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boeSlot => $composableBuilder(
    column: $table.boeSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get absenceKind => $composableBuilder(
    column: $table.absenceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get absenceUnit => $composableBuilder(
    column: $table.absenceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get absenceMins => $composableBuilder(
    column: $table.absenceMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get absenceDays => $composableBuilder(
    column: $table.absenceDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodFrom => $composableBuilder(
    column: $table.periodFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodTo => $composableBuilder(
    column: $table.periodTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quotaYear => $composableBuilder(
    column: $table.quotaYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sensitive => $composableBuilder(
    column: $table.sensitive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasDocumentation => $composableBuilder(
    column: $table.hasDocumentation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get countsAsSicknessPeriod => $composableBuilder(
    column: $table.countsAsSicknessPeriod,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimesheetEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimesheetEntriesTable> {
  $$TimesheetEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get dateId =>
      $composableBuilder(column: $table.dateId, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<int> get standardPauseMins => $composableBuilder(
    column: $table.standardPauseMins,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leavePauseMins => $composableBuilder(
    column: $table.leavePauseMins,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lunchPauseMins => $composableBuilder(
    column: $table.lunchPauseMins,
    builder: (column) => column,
  );

  GeneratedColumn<int> get netWorkedMins => $composableBuilder(
    column: $table.netWorkedMins,
    builder: (column) => column,
  );

  GeneratedColumn<int> get extraMins =>
      $composableBuilder(column: $table.extraMins, builder: (column) => column);

  GeneratedColumn<int> get sliMins =>
      $composableBuilder(column: $table.sliMins, builder: (column) => column);

  GeneratedColumn<int> get sboMins =>
      $composableBuilder(column: $table.sboMins, builder: (column) => column);

  GeneratedColumn<String> get workType =>
      $composableBuilder(column: $table.workType, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get bancaOreMins => $composableBuilder(
    column: $table.bancaOreMins,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boeSlot =>
      $composableBuilder(column: $table.boeSlot, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get absenceKind => $composableBuilder(
    column: $table.absenceKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get absenceUnit => $composableBuilder(
    column: $table.absenceUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get absenceMins => $composableBuilder(
    column: $table.absenceMins,
    builder: (column) => column,
  );

  GeneratedColumn<double> get absenceDays => $composableBuilder(
    column: $table.absenceDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodFrom => $composableBuilder(
    column: $table.periodFrom,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodTo =>
      $composableBuilder(column: $table.periodTo, builder: (column) => column);

  GeneratedColumn<double> get quotaYear =>
      $composableBuilder(column: $table.quotaYear, builder: (column) => column);

  GeneratedColumn<bool> get sensitive =>
      $composableBuilder(column: $table.sensitive, builder: (column) => column);

  GeneratedColumn<bool> get hasDocumentation => $composableBuilder(
    column: $table.hasDocumentation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get countsAsSicknessPeriod => $composableBuilder(
    column: $table.countsAsSicknessPeriod,
    builder: (column) => column,
  );
}

class $$TimesheetEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimesheetEntriesTable,
          TimesheetEntry,
          $$TimesheetEntriesTableFilterComposer,
          $$TimesheetEntriesTableOrderingComposer,
          $$TimesheetEntriesTableAnnotationComposer,
          $$TimesheetEntriesTableCreateCompanionBuilder,
          $$TimesheetEntriesTableUpdateCompanionBuilder,
          (
            TimesheetEntry,
            BaseReferences<
              _$AppDatabase,
              $TimesheetEntriesTable,
              TimesheetEntry
            >,
          ),
          TimesheetEntry,
          PrefetchHooks Function()
        > {
  $$TimesheetEntriesTableTableManager(
    _$AppDatabase db,
    $TimesheetEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimesheetEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimesheetEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimesheetEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> dateId = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String> endTime = const Value.absent(),
                Value<int> standardPauseMins = const Value.absent(),
                Value<int> leavePauseMins = const Value.absent(),
                Value<int> lunchPauseMins = const Value.absent(),
                Value<int> netWorkedMins = const Value.absent(),
                Value<int> extraMins = const Value.absent(),
                Value<int> sliMins = const Value.absent(),
                Value<int> sboMins = const Value.absent(),
                Value<String?> workType = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> bancaOreMins = const Value.absent(),
                Value<String?> boeSlot = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> absenceKind = const Value.absent(),
                Value<String?> absenceUnit = const Value.absent(),
                Value<int?> absenceMins = const Value.absent(),
                Value<double?> absenceDays = const Value.absent(),
                Value<String?> periodFrom = const Value.absent(),
                Value<String?> periodTo = const Value.absent(),
                Value<double?> quotaYear = const Value.absent(),
                Value<bool> sensitive = const Value.absent(),
                Value<bool> hasDocumentation = const Value.absent(),
                Value<bool> countsAsSicknessPeriod = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimesheetEntriesCompanion(
                uid: uid,
                dateId: dateId,
                startTime: startTime,
                endTime: endTime,
                standardPauseMins: standardPauseMins,
                leavePauseMins: leavePauseMins,
                lunchPauseMins: lunchPauseMins,
                netWorkedMins: netWorkedMins,
                extraMins: extraMins,
                sliMins: sliMins,
                sboMins: sboMins,
                workType: workType,
                note: note,
                bancaOreMins: bancaOreMins,
                boeSlot: boeSlot,
                updatedAt: updatedAt,
                absenceKind: absenceKind,
                absenceUnit: absenceUnit,
                absenceMins: absenceMins,
                absenceDays: absenceDays,
                periodFrom: periodFrom,
                periodTo: periodTo,
                quotaYear: quotaYear,
                sensitive: sensitive,
                hasDocumentation: hasDocumentation,
                countsAsSicknessPeriod: countsAsSicknessPeriod,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String dateId,
                required String startTime,
                required String endTime,
                Value<int> standardPauseMins = const Value.absent(),
                Value<int> leavePauseMins = const Value.absent(),
                Value<int> lunchPauseMins = const Value.absent(),
                required int netWorkedMins,
                required int extraMins,
                Value<int> sliMins = const Value.absent(),
                Value<int> sboMins = const Value.absent(),
                Value<String?> workType = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> bancaOreMins = const Value.absent(),
                Value<String?> boeSlot = const Value.absent(),
                required String updatedAt,
                Value<String?> absenceKind = const Value.absent(),
                Value<String?> absenceUnit = const Value.absent(),
                Value<int?> absenceMins = const Value.absent(),
                Value<double?> absenceDays = const Value.absent(),
                Value<String?> periodFrom = const Value.absent(),
                Value<String?> periodTo = const Value.absent(),
                Value<double?> quotaYear = const Value.absent(),
                Value<bool> sensitive = const Value.absent(),
                Value<bool> hasDocumentation = const Value.absent(),
                Value<bool> countsAsSicknessPeriod = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimesheetEntriesCompanion.insert(
                uid: uid,
                dateId: dateId,
                startTime: startTime,
                endTime: endTime,
                standardPauseMins: standardPauseMins,
                leavePauseMins: leavePauseMins,
                lunchPauseMins: lunchPauseMins,
                netWorkedMins: netWorkedMins,
                extraMins: extraMins,
                sliMins: sliMins,
                sboMins: sboMins,
                workType: workType,
                note: note,
                bancaOreMins: bancaOreMins,
                boeSlot: boeSlot,
                updatedAt: updatedAt,
                absenceKind: absenceKind,
                absenceUnit: absenceUnit,
                absenceMins: absenceMins,
                absenceDays: absenceDays,
                periodFrom: periodFrom,
                periodTo: periodTo,
                quotaYear: quotaYear,
                sensitive: sensitive,
                hasDocumentation: hasDocumentation,
                countsAsSicknessPeriod: countsAsSicknessPeriod,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimesheetEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimesheetEntriesTable,
      TimesheetEntry,
      $$TimesheetEntriesTableFilterComposer,
      $$TimesheetEntriesTableOrderingComposer,
      $$TimesheetEntriesTableAnnotationComposer,
      $$TimesheetEntriesTableCreateCompanionBuilder,
      $$TimesheetEntriesTableUpdateCompanionBuilder,
      (
        TimesheetEntry,
        BaseReferences<_$AppDatabase, $TimesheetEntriesTable, TimesheetEntry>,
      ),
      TimesheetEntry,
      PrefetchHooks Function()
    >;
typedef $$PcmOfficeLocationsTableCreateCompanionBuilder =
    PcmOfficeLocationsCompanion Function({
      required String id,
      required String locationName,
      required String structureName,
      required String address,
      Value<String> city,
      required double latitude,
      required double longitude,
      required int sortOrder,
      Value<bool> isActive,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$PcmOfficeLocationsTableUpdateCompanionBuilder =
    PcmOfficeLocationsCompanion Function({
      Value<String> id,
      Value<String> locationName,
      Value<String> structureName,
      Value<String> address,
      Value<String> city,
      Value<double> latitude,
      Value<double> longitude,
      Value<int> sortOrder,
      Value<bool> isActive,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$PcmOfficeLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $PcmOfficeLocationsTable> {
  $$PcmOfficeLocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get structureName => $composableBuilder(
    column: $table.structureName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PcmOfficeLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PcmOfficeLocationsTable> {
  $$PcmOfficeLocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get structureName => $composableBuilder(
    column: $table.structureName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PcmOfficeLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PcmOfficeLocationsTable> {
  $$PcmOfficeLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get structureName => $composableBuilder(
    column: $table.structureName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PcmOfficeLocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PcmOfficeLocationsTable,
          PcmOfficeLocation,
          $$PcmOfficeLocationsTableFilterComposer,
          $$PcmOfficeLocationsTableOrderingComposer,
          $$PcmOfficeLocationsTableAnnotationComposer,
          $$PcmOfficeLocationsTableCreateCompanionBuilder,
          $$PcmOfficeLocationsTableUpdateCompanionBuilder,
          (
            PcmOfficeLocation,
            BaseReferences<
              _$AppDatabase,
              $PcmOfficeLocationsTable,
              PcmOfficeLocation
            >,
          ),
          PcmOfficeLocation,
          PrefetchHooks Function()
        > {
  $$PcmOfficeLocationsTableTableManager(
    _$AppDatabase db,
    $PcmOfficeLocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PcmOfficeLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PcmOfficeLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PcmOfficeLocationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> locationName = const Value.absent(),
                Value<String> structureName = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PcmOfficeLocationsCompanion(
                id: id,
                locationName: locationName,
                structureName: structureName,
                address: address,
                city: city,
                latitude: latitude,
                longitude: longitude,
                sortOrder: sortOrder,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String locationName,
                required String structureName,
                required String address,
                Value<String> city = const Value.absent(),
                required double latitude,
                required double longitude,
                required int sortOrder,
                Value<bool> isActive = const Value.absent(),
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PcmOfficeLocationsCompanion.insert(
                id: id,
                locationName: locationName,
                structureName: structureName,
                address: address,
                city: city,
                latitude: latitude,
                longitude: longitude,
                sortOrder: sortOrder,
                isActive: isActive,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PcmOfficeLocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PcmOfficeLocationsTable,
      PcmOfficeLocation,
      $$PcmOfficeLocationsTableFilterComposer,
      $$PcmOfficeLocationsTableOrderingComposer,
      $$PcmOfficeLocationsTableAnnotationComposer,
      $$PcmOfficeLocationsTableCreateCompanionBuilder,
      $$PcmOfficeLocationsTableUpdateCompanionBuilder,
      (
        PcmOfficeLocation,
        BaseReferences<
          _$AppDatabase,
          $PcmOfficeLocationsTable,
          PcmOfficeLocation
        >,
      ),
      PcmOfficeLocation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TimesheetEntriesTableTableManager get timesheetEntries =>
      $$TimesheetEntriesTableTableManager(_db, _db.timesheetEntries);
  $$PcmOfficeLocationsTableTableManager get pcmOfficeLocations =>
      $$PcmOfficeLocationsTableTableManager(_db, _db.pcmOfficeLocations);
}
