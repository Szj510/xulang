// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_database.dart';

// ignore_for_file: type=lint
class $ExhibitionCategoriesTable extends ExhibitionCategories
    with TableInfo<$ExhibitionCategoriesTable, ExhibitionCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExhibitionCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exhibition_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExhibitionCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  ExhibitionCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExhibitionCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExhibitionCategoriesTable createAlias(String alias) {
    return $ExhibitionCategoriesTable(attachedDatabase, alias);
  }
}

class ExhibitionCategory extends DataClass
    implements Insertable<ExhibitionCategory> {
  final String id;
  final String title;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ExhibitionCategory({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExhibitionCategoriesCompanion toCompanion(bool nullToAbsent) {
    return ExhibitionCategoriesCompanion(
      id: Value(id),
      title: Value(title),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ExhibitionCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExhibitionCategory(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ExhibitionCategory copyWith({
    String? id,
    String? title,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ExhibitionCategory(
    id: id ?? this.id,
    title: title ?? this.title,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ExhibitionCategory copyWithCompanion(ExhibitionCategoriesCompanion data) {
    return ExhibitionCategory(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExhibitionCategory(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExhibitionCategory &&
          other.id == this.id &&
          other.title == this.title &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExhibitionCategoriesCompanion
    extends UpdateCompanion<ExhibitionCategory> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExhibitionCategoriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExhibitionCategoriesCompanion.insert({
    required String id,
    required String title,
    required int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ExhibitionCategory> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExhibitionCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ExhibitionCategoriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExhibitionCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsRowsTable extends AppSettingsRows
    with TableInfo<$AppSettingsRowsTable, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordingShowChapterTitleMeta =
      const VerificationMeta('recordingShowChapterTitle');
  @override
  late final GeneratedColumn<bool> recordingShowChapterTitle =
      GeneratedColumn<bool>(
        'recording_show_chapter_title',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("recording_show_chapter_title" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _recordingDelaySecondsMeta =
      const VerificationMeta('recordingDelaySeconds');
  @override
  late final GeneratedColumn<int> recordingDelaySeconds = GeneratedColumn<int>(
    'recording_delay_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mediaImportModeMeta = const VerificationMeta(
    'mediaImportMode',
  );
  @override
  late final GeneratedColumn<String> mediaImportMode = GeneratedColumn<String>(
    'media_import_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('copyIntoApp'),
  );
  static const VerificationMeta _recordingSpeedMeta = const VerificationMeta(
    'recordingSpeed',
  );
  @override
  late final GeneratedColumn<double> recordingSpeed = GeneratedColumn<double>(
    'recording_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(6.0),
  );
  static const VerificationMeta _recordingUseMusicMeta = const VerificationMeta(
    'recordingUseMusic',
  );
  @override
  late final GeneratedColumn<bool> recordingUseMusic = GeneratedColumn<bool>(
    'recording_use_music',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("recording_use_music" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _recordingChapterModeMeta =
      const VerificationMeta('recordingChapterMode');
  @override
  late final GeneratedColumn<String> recordingChapterMode =
      GeneratedColumn<String>(
        'recording_chapter_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('current'),
      );
  static const VerificationMeta _recordingQualityMeta = const VerificationMeta(
    'recordingQuality',
  );
  @override
  late final GeneratedColumn<String> recordingQuality = GeneratedColumn<String>(
    'recording_quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('high'),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recordingShowChapterTitle,
    recordingDelaySeconds,
    mediaImportMode,
    recordingSpeed,
    recordingUseMusic,
    recordingChapterMode,
    recordingQuality,
    themeMode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recording_show_chapter_title')) {
      context.handle(
        _recordingShowChapterTitleMeta,
        recordingShowChapterTitle.isAcceptableOrUnknown(
          data['recording_show_chapter_title']!,
          _recordingShowChapterTitleMeta,
        ),
      );
    }
    if (data.containsKey('recording_delay_seconds')) {
      context.handle(
        _recordingDelaySecondsMeta,
        recordingDelaySeconds.isAcceptableOrUnknown(
          data['recording_delay_seconds']!,
          _recordingDelaySecondsMeta,
        ),
      );
    }
    if (data.containsKey('media_import_mode')) {
      context.handle(
        _mediaImportModeMeta,
        mediaImportMode.isAcceptableOrUnknown(
          data['media_import_mode']!,
          _mediaImportModeMeta,
        ),
      );
    }
    if (data.containsKey('recording_speed')) {
      context.handle(
        _recordingSpeedMeta,
        recordingSpeed.isAcceptableOrUnknown(
          data['recording_speed']!,
          _recordingSpeedMeta,
        ),
      );
    }
    if (data.containsKey('recording_use_music')) {
      context.handle(
        _recordingUseMusicMeta,
        recordingUseMusic.isAcceptableOrUnknown(
          data['recording_use_music']!,
          _recordingUseMusicMeta,
        ),
      );
    }
    if (data.containsKey('recording_chapter_mode')) {
      context.handle(
        _recordingChapterModeMeta,
        recordingChapterMode.isAcceptableOrUnknown(
          data['recording_chapter_mode']!,
          _recordingChapterModeMeta,
        ),
      );
    }
    if (data.containsKey('recording_quality')) {
      context.handle(
        _recordingQualityMeta,
        recordingQuality.isAcceptableOrUnknown(
          data['recording_quality']!,
          _recordingQualityMeta,
        ),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordingShowChapterTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}recording_show_chapter_title'],
      )!,
      recordingDelaySeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recording_delay_seconds'],
      )!,
      mediaImportMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_import_mode'],
      )!,
      recordingSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recording_speed'],
      )!,
      recordingUseMusic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}recording_use_music'],
      )!,
      recordingChapterMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording_chapter_mode'],
      )!,
      recordingQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recording_quality'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
    );
  }

  @override
  $AppSettingsRowsTable createAlias(String alias) {
    return $AppSettingsRowsTable(attachedDatabase, alias);
  }
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final String id;
  final bool recordingShowChapterTitle;
  final int recordingDelaySeconds;
  final String mediaImportMode;
  final double recordingSpeed;
  final bool recordingUseMusic;
  final String recordingChapterMode;
  final String recordingQuality;
  final String themeMode;
  const AppSettingsRow({
    required this.id,
    required this.recordingShowChapterTitle,
    required this.recordingDelaySeconds,
    required this.mediaImportMode,
    required this.recordingSpeed,
    required this.recordingUseMusic,
    required this.recordingChapterMode,
    required this.recordingQuality,
    required this.themeMode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recording_show_chapter_title'] = Variable<bool>(
      recordingShowChapterTitle,
    );
    map['recording_delay_seconds'] = Variable<int>(recordingDelaySeconds);
    map['media_import_mode'] = Variable<String>(mediaImportMode);
    map['recording_speed'] = Variable<double>(recordingSpeed);
    map['recording_use_music'] = Variable<bool>(recordingUseMusic);
    map['recording_chapter_mode'] = Variable<String>(recordingChapterMode);
    map['recording_quality'] = Variable<String>(recordingQuality);
    map['theme_mode'] = Variable<String>(themeMode);
    return map;
  }

  AppSettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsRowsCompanion(
      id: Value(id),
      recordingShowChapterTitle: Value(recordingShowChapterTitle),
      recordingDelaySeconds: Value(recordingDelaySeconds),
      mediaImportMode: Value(mediaImportMode),
      recordingSpeed: Value(recordingSpeed),
      recordingUseMusic: Value(recordingUseMusic),
      recordingChapterMode: Value(recordingChapterMode),
      recordingQuality: Value(recordingQuality),
      themeMode: Value(themeMode),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<String>(json['id']),
      recordingShowChapterTitle: serializer.fromJson<bool>(
        json['recordingShowChapterTitle'],
      ),
      recordingDelaySeconds: serializer.fromJson<int>(
        json['recordingDelaySeconds'],
      ),
      mediaImportMode: serializer.fromJson<String>(json['mediaImportMode']),
      recordingSpeed: serializer.fromJson<double>(json['recordingSpeed']),
      recordingUseMusic: serializer.fromJson<bool>(json['recordingUseMusic']),
      recordingChapterMode: serializer.fromJson<String>(
        json['recordingChapterMode'],
      ),
      recordingQuality: serializer.fromJson<String>(json['recordingQuality']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordingShowChapterTitle': serializer.toJson<bool>(
        recordingShowChapterTitle,
      ),
      'recordingDelaySeconds': serializer.toJson<int>(recordingDelaySeconds),
      'mediaImportMode': serializer.toJson<String>(mediaImportMode),
      'recordingSpeed': serializer.toJson<double>(recordingSpeed),
      'recordingUseMusic': serializer.toJson<bool>(recordingUseMusic),
      'recordingChapterMode': serializer.toJson<String>(recordingChapterMode),
      'recordingQuality': serializer.toJson<String>(recordingQuality),
      'themeMode': serializer.toJson<String>(themeMode),
    };
  }

  AppSettingsRow copyWith({
    String? id,
    bool? recordingShowChapterTitle,
    int? recordingDelaySeconds,
    String? mediaImportMode,
    double? recordingSpeed,
    bool? recordingUseMusic,
    String? recordingChapterMode,
    String? recordingQuality,
    String? themeMode,
  }) => AppSettingsRow(
    id: id ?? this.id,
    recordingShowChapterTitle:
        recordingShowChapterTitle ?? this.recordingShowChapterTitle,
    recordingDelaySeconds: recordingDelaySeconds ?? this.recordingDelaySeconds,
    mediaImportMode: mediaImportMode ?? this.mediaImportMode,
    recordingSpeed: recordingSpeed ?? this.recordingSpeed,
    recordingUseMusic: recordingUseMusic ?? this.recordingUseMusic,
    recordingChapterMode: recordingChapterMode ?? this.recordingChapterMode,
    recordingQuality: recordingQuality ?? this.recordingQuality,
    themeMode: themeMode ?? this.themeMode,
  );
  AppSettingsRow copyWithCompanion(AppSettingsRowsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      recordingShowChapterTitle: data.recordingShowChapterTitle.present
          ? data.recordingShowChapterTitle.value
          : this.recordingShowChapterTitle,
      recordingDelaySeconds: data.recordingDelaySeconds.present
          ? data.recordingDelaySeconds.value
          : this.recordingDelaySeconds,
      mediaImportMode: data.mediaImportMode.present
          ? data.mediaImportMode.value
          : this.mediaImportMode,
      recordingSpeed: data.recordingSpeed.present
          ? data.recordingSpeed.value
          : this.recordingSpeed,
      recordingUseMusic: data.recordingUseMusic.present
          ? data.recordingUseMusic.value
          : this.recordingUseMusic,
      recordingChapterMode: data.recordingChapterMode.present
          ? data.recordingChapterMode.value
          : this.recordingChapterMode,
      recordingQuality: data.recordingQuality.present
          ? data.recordingQuality.value
          : this.recordingQuality,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('recordingShowChapterTitle: $recordingShowChapterTitle, ')
          ..write('recordingDelaySeconds: $recordingDelaySeconds, ')
          ..write('mediaImportMode: $mediaImportMode, ')
          ..write('recordingSpeed: $recordingSpeed, ')
          ..write('recordingUseMusic: $recordingUseMusic, ')
          ..write('recordingChapterMode: $recordingChapterMode, ')
          ..write('recordingQuality: $recordingQuality, ')
          ..write('themeMode: $themeMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recordingShowChapterTitle,
    recordingDelaySeconds,
    mediaImportMode,
    recordingSpeed,
    recordingUseMusic,
    recordingChapterMode,
    recordingQuality,
    themeMode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.recordingShowChapterTitle == this.recordingShowChapterTitle &&
          other.recordingDelaySeconds == this.recordingDelaySeconds &&
          other.mediaImportMode == this.mediaImportMode &&
          other.recordingSpeed == this.recordingSpeed &&
          other.recordingUseMusic == this.recordingUseMusic &&
          other.recordingChapterMode == this.recordingChapterMode &&
          other.recordingQuality == this.recordingQuality &&
          other.themeMode == this.themeMode);
}

class AppSettingsRowsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<String> id;
  final Value<bool> recordingShowChapterTitle;
  final Value<int> recordingDelaySeconds;
  final Value<String> mediaImportMode;
  final Value<double> recordingSpeed;
  final Value<bool> recordingUseMusic;
  final Value<String> recordingChapterMode;
  final Value<String> recordingQuality;
  final Value<String> themeMode;
  final Value<int> rowid;
  const AppSettingsRowsCompanion({
    this.id = const Value.absent(),
    this.recordingShowChapterTitle = const Value.absent(),
    this.recordingDelaySeconds = const Value.absent(),
    this.mediaImportMode = const Value.absent(),
    this.recordingSpeed = const Value.absent(),
    this.recordingUseMusic = const Value.absent(),
    this.recordingChapterMode = const Value.absent(),
    this.recordingQuality = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsRowsCompanion.insert({
    required String id,
    this.recordingShowChapterTitle = const Value.absent(),
    this.recordingDelaySeconds = const Value.absent(),
    this.mediaImportMode = const Value.absent(),
    this.recordingSpeed = const Value.absent(),
    this.recordingUseMusic = const Value.absent(),
    this.recordingChapterMode = const Value.absent(),
    this.recordingQuality = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<AppSettingsRow> custom({
    Expression<String>? id,
    Expression<bool>? recordingShowChapterTitle,
    Expression<int>? recordingDelaySeconds,
    Expression<String>? mediaImportMode,
    Expression<double>? recordingSpeed,
    Expression<bool>? recordingUseMusic,
    Expression<String>? recordingChapterMode,
    Expression<String>? recordingQuality,
    Expression<String>? themeMode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordingShowChapterTitle != null)
        'recording_show_chapter_title': recordingShowChapterTitle,
      if (recordingDelaySeconds != null)
        'recording_delay_seconds': recordingDelaySeconds,
      if (mediaImportMode != null) 'media_import_mode': mediaImportMode,
      if (recordingSpeed != null) 'recording_speed': recordingSpeed,
      if (recordingUseMusic != null) 'recording_use_music': recordingUseMusic,
      if (recordingChapterMode != null)
        'recording_chapter_mode': recordingChapterMode,
      if (recordingQuality != null) 'recording_quality': recordingQuality,
      if (themeMode != null) 'theme_mode': themeMode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsRowsCompanion copyWith({
    Value<String>? id,
    Value<bool>? recordingShowChapterTitle,
    Value<int>? recordingDelaySeconds,
    Value<String>? mediaImportMode,
    Value<double>? recordingSpeed,
    Value<bool>? recordingUseMusic,
    Value<String>? recordingChapterMode,
    Value<String>? recordingQuality,
    Value<String>? themeMode,
    Value<int>? rowid,
  }) {
    return AppSettingsRowsCompanion(
      id: id ?? this.id,
      recordingShowChapterTitle:
          recordingShowChapterTitle ?? this.recordingShowChapterTitle,
      recordingDelaySeconds:
          recordingDelaySeconds ?? this.recordingDelaySeconds,
      mediaImportMode: mediaImportMode ?? this.mediaImportMode,
      recordingSpeed: recordingSpeed ?? this.recordingSpeed,
      recordingUseMusic: recordingUseMusic ?? this.recordingUseMusic,
      recordingChapterMode: recordingChapterMode ?? this.recordingChapterMode,
      recordingQuality: recordingQuality ?? this.recordingQuality,
      themeMode: themeMode ?? this.themeMode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recordingShowChapterTitle.present) {
      map['recording_show_chapter_title'] = Variable<bool>(
        recordingShowChapterTitle.value,
      );
    }
    if (recordingDelaySeconds.present) {
      map['recording_delay_seconds'] = Variable<int>(
        recordingDelaySeconds.value,
      );
    }
    if (mediaImportMode.present) {
      map['media_import_mode'] = Variable<String>(mediaImportMode.value);
    }
    if (recordingSpeed.present) {
      map['recording_speed'] = Variable<double>(recordingSpeed.value);
    }
    if (recordingUseMusic.present) {
      map['recording_use_music'] = Variable<bool>(recordingUseMusic.value);
    }
    if (recordingChapterMode.present) {
      map['recording_chapter_mode'] = Variable<String>(
        recordingChapterMode.value,
      );
    }
    if (recordingQuality.present) {
      map['recording_quality'] = Variable<String>(recordingQuality.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('recordingShowChapterTitle: $recordingShowChapterTitle, ')
          ..write('recordingDelaySeconds: $recordingDelaySeconds, ')
          ..write('mediaImportMode: $mediaImportMode, ')
          ..write('recordingSpeed: $recordingSpeed, ')
          ..write('recordingUseMusic: $recordingUseMusic, ')
          ..write('recordingChapterMode: $recordingChapterMode, ')
          ..write('recordingQuality: $recordingQuality, ')
          ..write('themeMode: $themeMode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExhibitionsTable extends Exhibitions
    with TableInfo<$ExhibitionsTable, Exhibition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExhibitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverMediaIdMeta = const VerificationMeta(
    'coverMediaId',
  );
  @override
  late final GeneratedColumn<String> coverMediaId = GeneratedColumn<String>(
    'cover_media_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exhibition_categories (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canvasBackgroundPathMeta =
      const VerificationMeta('canvasBackgroundPath');
  @override
  late final GeneratedColumn<String> canvasBackgroundPath =
      GeneratedColumn<String>(
        'canvas_background_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _canvasBackgroundOpacityMeta =
      const VerificationMeta('canvasBackgroundOpacity');
  @override
  late final GeneratedColumn<double> canvasBackgroundOpacity =
      GeneratedColumn<double>(
        'canvas_background_opacity',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.32),
      );
  static const VerificationMeta _musicPathMeta = const VerificationMeta(
    'musicPath',
  );
  @override
  late final GeneratedColumn<String> musicPath = GeneratedColumn<String>(
    'music_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _musicTitleMeta = const VerificationMeta(
    'musicTitle',
  );
  @override
  late final GeneratedColumn<String> musicTitle = GeneratedColumn<String>(
    'music_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _showChapterTitleInPlaybackMeta =
      const VerificationMeta('showChapterTitleInPlayback');
  @override
  late final GeneratedColumn<bool> showChapterTitleInPlayback =
      GeneratedColumn<bool>(
        'show_chapter_title_in_playback',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_chapter_title_in_playback" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _playbackDelaySecondsMeta =
      const VerificationMeta('playbackDelaySeconds');
  @override
  late final GeneratedColumn<int> playbackDelaySeconds = GeneratedColumn<int>(
    'playback_delay_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    coverMediaId,
    categoryId,
    theme,
    canvasBackgroundPath,
    canvasBackgroundOpacity,
    musicPath,
    musicTitle,
    showChapterTitleInPlayback,
    playbackDelaySeconds,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exhibitions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exhibition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover_media_id')) {
      context.handle(
        _coverMediaIdMeta,
        coverMediaId.isAcceptableOrUnknown(
          data['cover_media_id']!,
          _coverMediaIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeMeta);
    }
    if (data.containsKey('canvas_background_path')) {
      context.handle(
        _canvasBackgroundPathMeta,
        canvasBackgroundPath.isAcceptableOrUnknown(
          data['canvas_background_path']!,
          _canvasBackgroundPathMeta,
        ),
      );
    }
    if (data.containsKey('canvas_background_opacity')) {
      context.handle(
        _canvasBackgroundOpacityMeta,
        canvasBackgroundOpacity.isAcceptableOrUnknown(
          data['canvas_background_opacity']!,
          _canvasBackgroundOpacityMeta,
        ),
      );
    }
    if (data.containsKey('music_path')) {
      context.handle(
        _musicPathMeta,
        musicPath.isAcceptableOrUnknown(data['music_path']!, _musicPathMeta),
      );
    }
    if (data.containsKey('music_title')) {
      context.handle(
        _musicTitleMeta,
        musicTitle.isAcceptableOrUnknown(data['music_title']!, _musicTitleMeta),
      );
    }
    if (data.containsKey('show_chapter_title_in_playback')) {
      context.handle(
        _showChapterTitleInPlaybackMeta,
        showChapterTitleInPlayback.isAcceptableOrUnknown(
          data['show_chapter_title_in_playback']!,
          _showChapterTitleInPlaybackMeta,
        ),
      );
    }
    if (data.containsKey('playback_delay_seconds')) {
      context.handle(
        _playbackDelaySecondsMeta,
        playbackDelaySeconds.isAcceptableOrUnknown(
          data['playback_delay_seconds']!,
          _playbackDelaySecondsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  Exhibition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exhibition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      coverMediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_media_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      canvasBackgroundPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canvas_background_path'],
      ),
      canvasBackgroundOpacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}canvas_background_opacity'],
      )!,
      musicPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}music_path'],
      ),
      musicTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}music_title'],
      ),
      showChapterTitleInPlayback: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_chapter_title_in_playback'],
      )!,
      playbackDelaySeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playback_delay_seconds'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ExhibitionsTable createAlias(String alias) {
    return $ExhibitionsTable(attachedDatabase, alias);
  }
}

class Exhibition extends DataClass implements Insertable<Exhibition> {
  final String id;
  final String title;
  final String? coverMediaId;
  final String? categoryId;
  final String theme;
  final String? canvasBackgroundPath;
  final double canvasBackgroundOpacity;
  final String? musicPath;
  final String? musicTitle;
  final bool showChapterTitleInPlayback;
  final int playbackDelaySeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Exhibition({
    required this.id,
    required this.title,
    this.coverMediaId,
    this.categoryId,
    required this.theme,
    this.canvasBackgroundPath,
    required this.canvasBackgroundOpacity,
    this.musicPath,
    this.musicTitle,
    required this.showChapterTitleInPlayback,
    required this.playbackDelaySeconds,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || coverMediaId != null) {
      map['cover_media_id'] = Variable<String>(coverMediaId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['theme'] = Variable<String>(theme);
    if (!nullToAbsent || canvasBackgroundPath != null) {
      map['canvas_background_path'] = Variable<String>(canvasBackgroundPath);
    }
    map['canvas_background_opacity'] = Variable<double>(
      canvasBackgroundOpacity,
    );
    if (!nullToAbsent || musicPath != null) {
      map['music_path'] = Variable<String>(musicPath);
    }
    if (!nullToAbsent || musicTitle != null) {
      map['music_title'] = Variable<String>(musicTitle);
    }
    map['show_chapter_title_in_playback'] = Variable<bool>(
      showChapterTitleInPlayback,
    );
    map['playback_delay_seconds'] = Variable<int>(playbackDelaySeconds);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ExhibitionsCompanion toCompanion(bool nullToAbsent) {
    return ExhibitionsCompanion(
      id: Value(id),
      title: Value(title),
      coverMediaId: coverMediaId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverMediaId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      theme: Value(theme),
      canvasBackgroundPath: canvasBackgroundPath == null && nullToAbsent
          ? const Value.absent()
          : Value(canvasBackgroundPath),
      canvasBackgroundOpacity: Value(canvasBackgroundOpacity),
      musicPath: musicPath == null && nullToAbsent
          ? const Value.absent()
          : Value(musicPath),
      musicTitle: musicTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(musicTitle),
      showChapterTitleInPlayback: Value(showChapterTitleInPlayback),
      playbackDelaySeconds: Value(playbackDelaySeconds),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Exhibition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exhibition(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      coverMediaId: serializer.fromJson<String?>(json['coverMediaId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      theme: serializer.fromJson<String>(json['theme']),
      canvasBackgroundPath: serializer.fromJson<String?>(
        json['canvasBackgroundPath'],
      ),
      canvasBackgroundOpacity: serializer.fromJson<double>(
        json['canvasBackgroundOpacity'],
      ),
      musicPath: serializer.fromJson<String?>(json['musicPath']),
      musicTitle: serializer.fromJson<String?>(json['musicTitle']),
      showChapterTitleInPlayback: serializer.fromJson<bool>(
        json['showChapterTitleInPlayback'],
      ),
      playbackDelaySeconds: serializer.fromJson<int>(
        json['playbackDelaySeconds'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'coverMediaId': serializer.toJson<String?>(coverMediaId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'theme': serializer.toJson<String>(theme),
      'canvasBackgroundPath': serializer.toJson<String?>(canvasBackgroundPath),
      'canvasBackgroundOpacity': serializer.toJson<double>(
        canvasBackgroundOpacity,
      ),
      'musicPath': serializer.toJson<String?>(musicPath),
      'musicTitle': serializer.toJson<String?>(musicTitle),
      'showChapterTitleInPlayback': serializer.toJson<bool>(
        showChapterTitleInPlayback,
      ),
      'playbackDelaySeconds': serializer.toJson<int>(playbackDelaySeconds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Exhibition copyWith({
    String? id,
    String? title,
    Value<String?> coverMediaId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    String? theme,
    Value<String?> canvasBackgroundPath = const Value.absent(),
    double? canvasBackgroundOpacity,
    Value<String?> musicPath = const Value.absent(),
    Value<String?> musicTitle = const Value.absent(),
    bool? showChapterTitleInPlayback,
    int? playbackDelaySeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Exhibition(
    id: id ?? this.id,
    title: title ?? this.title,
    coverMediaId: coverMediaId.present ? coverMediaId.value : this.coverMediaId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    theme: theme ?? this.theme,
    canvasBackgroundPath: canvasBackgroundPath.present
        ? canvasBackgroundPath.value
        : this.canvasBackgroundPath,
    canvasBackgroundOpacity:
        canvasBackgroundOpacity ?? this.canvasBackgroundOpacity,
    musicPath: musicPath.present ? musicPath.value : this.musicPath,
    musicTitle: musicTitle.present ? musicTitle.value : this.musicTitle,
    showChapterTitleInPlayback:
        showChapterTitleInPlayback ?? this.showChapterTitleInPlayback,
    playbackDelaySeconds: playbackDelaySeconds ?? this.playbackDelaySeconds,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Exhibition copyWithCompanion(ExhibitionsCompanion data) {
    return Exhibition(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      coverMediaId: data.coverMediaId.present
          ? data.coverMediaId.value
          : this.coverMediaId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      theme: data.theme.present ? data.theme.value : this.theme,
      canvasBackgroundPath: data.canvasBackgroundPath.present
          ? data.canvasBackgroundPath.value
          : this.canvasBackgroundPath,
      canvasBackgroundOpacity: data.canvasBackgroundOpacity.present
          ? data.canvasBackgroundOpacity.value
          : this.canvasBackgroundOpacity,
      musicPath: data.musicPath.present ? data.musicPath.value : this.musicPath,
      musicTitle: data.musicTitle.present
          ? data.musicTitle.value
          : this.musicTitle,
      showChapterTitleInPlayback: data.showChapterTitleInPlayback.present
          ? data.showChapterTitleInPlayback.value
          : this.showChapterTitleInPlayback,
      playbackDelaySeconds: data.playbackDelaySeconds.present
          ? data.playbackDelaySeconds.value
          : this.playbackDelaySeconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exhibition(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('coverMediaId: $coverMediaId, ')
          ..write('categoryId: $categoryId, ')
          ..write('theme: $theme, ')
          ..write('canvasBackgroundPath: $canvasBackgroundPath, ')
          ..write('canvasBackgroundOpacity: $canvasBackgroundOpacity, ')
          ..write('musicPath: $musicPath, ')
          ..write('musicTitle: $musicTitle, ')
          ..write('showChapterTitleInPlayback: $showChapterTitleInPlayback, ')
          ..write('playbackDelaySeconds: $playbackDelaySeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    coverMediaId,
    categoryId,
    theme,
    canvasBackgroundPath,
    canvasBackgroundOpacity,
    musicPath,
    musicTitle,
    showChapterTitleInPlayback,
    playbackDelaySeconds,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exhibition &&
          other.id == this.id &&
          other.title == this.title &&
          other.coverMediaId == this.coverMediaId &&
          other.categoryId == this.categoryId &&
          other.theme == this.theme &&
          other.canvasBackgroundPath == this.canvasBackgroundPath &&
          other.canvasBackgroundOpacity == this.canvasBackgroundOpacity &&
          other.musicPath == this.musicPath &&
          other.musicTitle == this.musicTitle &&
          other.showChapterTitleInPlayback == this.showChapterTitleInPlayback &&
          other.playbackDelaySeconds == this.playbackDelaySeconds &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ExhibitionsCompanion extends UpdateCompanion<Exhibition> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> coverMediaId;
  final Value<String?> categoryId;
  final Value<String> theme;
  final Value<String?> canvasBackgroundPath;
  final Value<double> canvasBackgroundOpacity;
  final Value<String?> musicPath;
  final Value<String?> musicTitle;
  final Value<bool> showChapterTitleInPlayback;
  final Value<int> playbackDelaySeconds;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ExhibitionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.coverMediaId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.theme = const Value.absent(),
    this.canvasBackgroundPath = const Value.absent(),
    this.canvasBackgroundOpacity = const Value.absent(),
    this.musicPath = const Value.absent(),
    this.musicTitle = const Value.absent(),
    this.showChapterTitleInPlayback = const Value.absent(),
    this.playbackDelaySeconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExhibitionsCompanion.insert({
    required String id,
    required String title,
    this.coverMediaId = const Value.absent(),
    this.categoryId = const Value.absent(),
    required String theme,
    this.canvasBackgroundPath = const Value.absent(),
    this.canvasBackgroundOpacity = const Value.absent(),
    this.musicPath = const Value.absent(),
    this.musicTitle = const Value.absent(),
    this.showChapterTitleInPlayback = const Value.absent(),
    this.playbackDelaySeconds = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       theme = Value(theme),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Exhibition> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? coverMediaId,
    Expression<String>? categoryId,
    Expression<String>? theme,
    Expression<String>? canvasBackgroundPath,
    Expression<double>? canvasBackgroundOpacity,
    Expression<String>? musicPath,
    Expression<String>? musicTitle,
    Expression<bool>? showChapterTitleInPlayback,
    Expression<int>? playbackDelaySeconds,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (coverMediaId != null) 'cover_media_id': coverMediaId,
      if (categoryId != null) 'category_id': categoryId,
      if (theme != null) 'theme': theme,
      if (canvasBackgroundPath != null)
        'canvas_background_path': canvasBackgroundPath,
      if (canvasBackgroundOpacity != null)
        'canvas_background_opacity': canvasBackgroundOpacity,
      if (musicPath != null) 'music_path': musicPath,
      if (musicTitle != null) 'music_title': musicTitle,
      if (showChapterTitleInPlayback != null)
        'show_chapter_title_in_playback': showChapterTitleInPlayback,
      if (playbackDelaySeconds != null)
        'playback_delay_seconds': playbackDelaySeconds,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExhibitionsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? coverMediaId,
    Value<String?>? categoryId,
    Value<String>? theme,
    Value<String?>? canvasBackgroundPath,
    Value<double>? canvasBackgroundOpacity,
    Value<String?>? musicPath,
    Value<String?>? musicTitle,
    Value<bool>? showChapterTitleInPlayback,
    Value<int>? playbackDelaySeconds,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ExhibitionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      coverMediaId: coverMediaId ?? this.coverMediaId,
      categoryId: categoryId ?? this.categoryId,
      theme: theme ?? this.theme,
      canvasBackgroundPath: canvasBackgroundPath ?? this.canvasBackgroundPath,
      canvasBackgroundOpacity:
          canvasBackgroundOpacity ?? this.canvasBackgroundOpacity,
      musicPath: musicPath ?? this.musicPath,
      musicTitle: musicTitle ?? this.musicTitle,
      showChapterTitleInPlayback:
          showChapterTitleInPlayback ?? this.showChapterTitleInPlayback,
      playbackDelaySeconds: playbackDelaySeconds ?? this.playbackDelaySeconds,
      createdAt: createdAt ?? this.createdAt,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (coverMediaId.present) {
      map['cover_media_id'] = Variable<String>(coverMediaId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (canvasBackgroundPath.present) {
      map['canvas_background_path'] = Variable<String>(
        canvasBackgroundPath.value,
      );
    }
    if (canvasBackgroundOpacity.present) {
      map['canvas_background_opacity'] = Variable<double>(
        canvasBackgroundOpacity.value,
      );
    }
    if (musicPath.present) {
      map['music_path'] = Variable<String>(musicPath.value);
    }
    if (musicTitle.present) {
      map['music_title'] = Variable<String>(musicTitle.value);
    }
    if (showChapterTitleInPlayback.present) {
      map['show_chapter_title_in_playback'] = Variable<bool>(
        showChapterTitleInPlayback.value,
      );
    }
    if (playbackDelaySeconds.present) {
      map['playback_delay_seconds'] = Variable<int>(playbackDelaySeconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExhibitionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('coverMediaId: $coverMediaId, ')
          ..write('categoryId: $categoryId, ')
          ..write('theme: $theme, ')
          ..write('canvasBackgroundPath: $canvasBackgroundPath, ')
          ..write('canvasBackgroundOpacity: $canvasBackgroundOpacity, ')
          ..write('musicPath: $musicPath, ')
          ..write('musicTitle: $musicTitle, ')
          ..write('showChapterTitleInPlayback: $showChapterTitleInPlayback, ')
          ..write('playbackDelaySeconds: $playbackDelaySeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters with TableInfo<$ChaptersTable, Chapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exhibitionIdMeta = const VerificationMeta(
    'exhibitionId',
  );
  @override
  late final GeneratedColumn<String> exhibitionId = GeneratedColumn<String>(
    'exhibition_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exhibitions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _layoutMeta = const VerificationMeta('layout');
  @override
  late final GeneratedColumn<String> layout = GeneratedColumn<String>(
    'layout',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _motionMeta = const VerificationMeta('motion');
  @override
  late final GeneratedColumn<String> motion = GeneratedColumn<String>(
    'motion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathStyleMeta = const VerificationMeta(
    'pathStyle',
  );
  @override
  late final GeneratedColumn<String> pathStyle = GeneratedColumn<String>(
    'path_style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('solid'),
  );
  static const VerificationMeta _customPathDataMeta = const VerificationMeta(
    'customPathData',
  );
  @override
  late final GeneratedColumn<String> customPathData = GeneratedColumn<String>(
    'custom_path_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exhibitionId,
    title,
    caption,
    sortOrder,
    layout,
    motion,
    pathStyle,
    customPathData,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chapter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exhibition_id')) {
      context.handle(
        _exhibitionIdMeta,
        exhibitionId.isAcceptableOrUnknown(
          data['exhibition_id']!,
          _exhibitionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exhibitionIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    } else if (isInserting) {
      context.missing(_captionMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('layout')) {
      context.handle(
        _layoutMeta,
        layout.isAcceptableOrUnknown(data['layout']!, _layoutMeta),
      );
    } else if (isInserting) {
      context.missing(_layoutMeta);
    }
    if (data.containsKey('motion')) {
      context.handle(
        _motionMeta,
        motion.isAcceptableOrUnknown(data['motion']!, _motionMeta),
      );
    } else if (isInserting) {
      context.missing(_motionMeta);
    }
    if (data.containsKey('path_style')) {
      context.handle(
        _pathStyleMeta,
        pathStyle.isAcceptableOrUnknown(data['path_style']!, _pathStyleMeta),
      );
    }
    if (data.containsKey('custom_path_data')) {
      context.handle(
        _customPathDataMeta,
        customPathData.isAcceptableOrUnknown(
          data['custom_path_data']!,
          _customPathDataMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chapter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      exhibitionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exhibition_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      layout: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout'],
      )!,
      motion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motion'],
      )!,
      pathStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path_style'],
      )!,
      customPathData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_path_data'],
      ),
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class Chapter extends DataClass implements Insertable<Chapter> {
  final String id;
  final String exhibitionId;
  final String title;
  final String caption;
  final int sortOrder;
  final String layout;
  final String motion;
  final String pathStyle;
  final String? customPathData;
  const Chapter({
    required this.id,
    required this.exhibitionId,
    required this.title,
    required this.caption,
    required this.sortOrder,
    required this.layout,
    required this.motion,
    required this.pathStyle,
    this.customPathData,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exhibition_id'] = Variable<String>(exhibitionId);
    map['title'] = Variable<String>(title);
    map['caption'] = Variable<String>(caption);
    map['sort_order'] = Variable<int>(sortOrder);
    map['layout'] = Variable<String>(layout);
    map['motion'] = Variable<String>(motion);
    map['path_style'] = Variable<String>(pathStyle);
    if (!nullToAbsent || customPathData != null) {
      map['custom_path_data'] = Variable<String>(customPathData);
    }
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      exhibitionId: Value(exhibitionId),
      title: Value(title),
      caption: Value(caption),
      sortOrder: Value(sortOrder),
      layout: Value(layout),
      motion: Value(motion),
      pathStyle: Value(pathStyle),
      customPathData: customPathData == null && nullToAbsent
          ? const Value.absent()
          : Value(customPathData),
    );
  }

  factory Chapter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chapter(
      id: serializer.fromJson<String>(json['id']),
      exhibitionId: serializer.fromJson<String>(json['exhibitionId']),
      title: serializer.fromJson<String>(json['title']),
      caption: serializer.fromJson<String>(json['caption']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      layout: serializer.fromJson<String>(json['layout']),
      motion: serializer.fromJson<String>(json['motion']),
      pathStyle: serializer.fromJson<String>(json['pathStyle']),
      customPathData: serializer.fromJson<String?>(json['customPathData']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'exhibitionId': serializer.toJson<String>(exhibitionId),
      'title': serializer.toJson<String>(title),
      'caption': serializer.toJson<String>(caption),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'layout': serializer.toJson<String>(layout),
      'motion': serializer.toJson<String>(motion),
      'pathStyle': serializer.toJson<String>(pathStyle),
      'customPathData': serializer.toJson<String?>(customPathData),
    };
  }

  Chapter copyWith({
    String? id,
    String? exhibitionId,
    String? title,
    String? caption,
    int? sortOrder,
    String? layout,
    String? motion,
    String? pathStyle,
    Value<String?> customPathData = const Value.absent(),
  }) => Chapter(
    id: id ?? this.id,
    exhibitionId: exhibitionId ?? this.exhibitionId,
    title: title ?? this.title,
    caption: caption ?? this.caption,
    sortOrder: sortOrder ?? this.sortOrder,
    layout: layout ?? this.layout,
    motion: motion ?? this.motion,
    pathStyle: pathStyle ?? this.pathStyle,
    customPathData: customPathData.present
        ? customPathData.value
        : this.customPathData,
  );
  Chapter copyWithCompanion(ChaptersCompanion data) {
    return Chapter(
      id: data.id.present ? data.id.value : this.id,
      exhibitionId: data.exhibitionId.present
          ? data.exhibitionId.value
          : this.exhibitionId,
      title: data.title.present ? data.title.value : this.title,
      caption: data.caption.present ? data.caption.value : this.caption,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      layout: data.layout.present ? data.layout.value : this.layout,
      motion: data.motion.present ? data.motion.value : this.motion,
      pathStyle: data.pathStyle.present ? data.pathStyle.value : this.pathStyle,
      customPathData: data.customPathData.present
          ? data.customPathData.value
          : this.customPathData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chapter(')
          ..write('id: $id, ')
          ..write('exhibitionId: $exhibitionId, ')
          ..write('title: $title, ')
          ..write('caption: $caption, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('layout: $layout, ')
          ..write('motion: $motion, ')
          ..write('pathStyle: $pathStyle, ')
          ..write('customPathData: $customPathData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exhibitionId,
    title,
    caption,
    sortOrder,
    layout,
    motion,
    pathStyle,
    customPathData,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chapter &&
          other.id == this.id &&
          other.exhibitionId == this.exhibitionId &&
          other.title == this.title &&
          other.caption == this.caption &&
          other.sortOrder == this.sortOrder &&
          other.layout == this.layout &&
          other.motion == this.motion &&
          other.pathStyle == this.pathStyle &&
          other.customPathData == this.customPathData);
}

class ChaptersCompanion extends UpdateCompanion<Chapter> {
  final Value<String> id;
  final Value<String> exhibitionId;
  final Value<String> title;
  final Value<String> caption;
  final Value<int> sortOrder;
  final Value<String> layout;
  final Value<String> motion;
  final Value<String> pathStyle;
  final Value<String?> customPathData;
  final Value<int> rowid;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.exhibitionId = const Value.absent(),
    this.title = const Value.absent(),
    this.caption = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.layout = const Value.absent(),
    this.motion = const Value.absent(),
    this.pathStyle = const Value.absent(),
    this.customPathData = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChaptersCompanion.insert({
    required String id,
    required String exhibitionId,
    required String title,
    required String caption,
    required int sortOrder,
    required String layout,
    required String motion,
    this.pathStyle = const Value.absent(),
    this.customPathData = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       exhibitionId = Value(exhibitionId),
       title = Value(title),
       caption = Value(caption),
       sortOrder = Value(sortOrder),
       layout = Value(layout),
       motion = Value(motion);
  static Insertable<Chapter> custom({
    Expression<String>? id,
    Expression<String>? exhibitionId,
    Expression<String>? title,
    Expression<String>? caption,
    Expression<int>? sortOrder,
    Expression<String>? layout,
    Expression<String>? motion,
    Expression<String>? pathStyle,
    Expression<String>? customPathData,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exhibitionId != null) 'exhibition_id': exhibitionId,
      if (title != null) 'title': title,
      if (caption != null) 'caption': caption,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (layout != null) 'layout': layout,
      if (motion != null) 'motion': motion,
      if (pathStyle != null) 'path_style': pathStyle,
      if (customPathData != null) 'custom_path_data': customPathData,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChaptersCompanion copyWith({
    Value<String>? id,
    Value<String>? exhibitionId,
    Value<String>? title,
    Value<String>? caption,
    Value<int>? sortOrder,
    Value<String>? layout,
    Value<String>? motion,
    Value<String>? pathStyle,
    Value<String?>? customPathData,
    Value<int>? rowid,
  }) {
    return ChaptersCompanion(
      id: id ?? this.id,
      exhibitionId: exhibitionId ?? this.exhibitionId,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      sortOrder: sortOrder ?? this.sortOrder,
      layout: layout ?? this.layout,
      motion: motion ?? this.motion,
      pathStyle: pathStyle ?? this.pathStyle,
      customPathData: customPathData ?? this.customPathData,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exhibitionId.present) {
      map['exhibition_id'] = Variable<String>(exhibitionId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (layout.present) {
      map['layout'] = Variable<String>(layout.value);
    }
    if (motion.present) {
      map['motion'] = Variable<String>(motion.value);
    }
    if (pathStyle.present) {
      map['path_style'] = Variable<String>(pathStyle.value);
    }
    if (customPathData.present) {
      map['custom_path_data'] = Variable<String>(customPathData.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('exhibitionId: $exhibitionId, ')
          ..write('title: $title, ')
          ..write('caption: $caption, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('layout: $layout, ')
          ..write('motion: $motion, ')
          ..write('pathStyle: $pathStyle, ')
          ..write('customPathData: $customPathData, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaAssetsTable extends MediaAssets
    with TableInfo<$MediaAssetsTable, MediaAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exhibitionIdMeta = const VerificationMeta(
    'exhibitionId',
  );
  @override
  late final GeneratedColumn<String> exhibitionId = GeneratedColumn<String>(
    'exhibition_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exhibitions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _originalPathMeta = const VerificationMeta(
    'originalPath',
  );
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
    'original_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exhibitionId,
    originalPath,
    thumbnailPath,
    width,
    height,
    contentHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaAsset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exhibition_id')) {
      context.handle(
        _exhibitionIdMeta,
        exhibitionId.isAcceptableOrUnknown(
          data['exhibition_id']!,
          _exhibitionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exhibitionIdMeta);
    }
    if (data.containsKey('original_path')) {
      context.handle(
        _originalPathMeta,
        originalPath.isAcceptableOrUnknown(
          data['original_path']!,
          _originalPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalPathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_thumbnailPathMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaAsset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      exhibitionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exhibition_id'],
      )!,
      originalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_path'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
    );
  }

  @override
  $MediaAssetsTable createAlias(String alias) {
    return $MediaAssetsTable(attachedDatabase, alias);
  }
}

class MediaAsset extends DataClass implements Insertable<MediaAsset> {
  final String id;
  final String exhibitionId;
  final String originalPath;
  final String thumbnailPath;
  final int width;
  final int height;
  final String contentHash;
  const MediaAsset({
    required this.id,
    required this.exhibitionId,
    required this.originalPath,
    required this.thumbnailPath,
    required this.width,
    required this.height,
    required this.contentHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exhibition_id'] = Variable<String>(exhibitionId);
    map['original_path'] = Variable<String>(originalPath);
    map['thumbnail_path'] = Variable<String>(thumbnailPath);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['content_hash'] = Variable<String>(contentHash);
    return map;
  }

  MediaAssetsCompanion toCompanion(bool nullToAbsent) {
    return MediaAssetsCompanion(
      id: Value(id),
      exhibitionId: Value(exhibitionId),
      originalPath: Value(originalPath),
      thumbnailPath: Value(thumbnailPath),
      width: Value(width),
      height: Value(height),
      contentHash: Value(contentHash),
    );
  }

  factory MediaAsset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaAsset(
      id: serializer.fromJson<String>(json['id']),
      exhibitionId: serializer.fromJson<String>(json['exhibitionId']),
      originalPath: serializer.fromJson<String>(json['originalPath']),
      thumbnailPath: serializer.fromJson<String>(json['thumbnailPath']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'exhibitionId': serializer.toJson<String>(exhibitionId),
      'originalPath': serializer.toJson<String>(originalPath),
      'thumbnailPath': serializer.toJson<String>(thumbnailPath),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'contentHash': serializer.toJson<String>(contentHash),
    };
  }

  MediaAsset copyWith({
    String? id,
    String? exhibitionId,
    String? originalPath,
    String? thumbnailPath,
    int? width,
    int? height,
    String? contentHash,
  }) => MediaAsset(
    id: id ?? this.id,
    exhibitionId: exhibitionId ?? this.exhibitionId,
    originalPath: originalPath ?? this.originalPath,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    width: width ?? this.width,
    height: height ?? this.height,
    contentHash: contentHash ?? this.contentHash,
  );
  MediaAsset copyWithCompanion(MediaAssetsCompanion data) {
    return MediaAsset(
      id: data.id.present ? data.id.value : this.id,
      exhibitionId: data.exhibitionId.present
          ? data.exhibitionId.value
          : this.exhibitionId,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaAsset(')
          ..write('id: $id, ')
          ..write('exhibitionId: $exhibitionId, ')
          ..write('originalPath: $originalPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('contentHash: $contentHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    exhibitionId,
    originalPath,
    thumbnailPath,
    width,
    height,
    contentHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaAsset &&
          other.id == this.id &&
          other.exhibitionId == this.exhibitionId &&
          other.originalPath == this.originalPath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.width == this.width &&
          other.height == this.height &&
          other.contentHash == this.contentHash);
}

class MediaAssetsCompanion extends UpdateCompanion<MediaAsset> {
  final Value<String> id;
  final Value<String> exhibitionId;
  final Value<String> originalPath;
  final Value<String> thumbnailPath;
  final Value<int> width;
  final Value<int> height;
  final Value<String> contentHash;
  final Value<int> rowid;
  const MediaAssetsCompanion({
    this.id = const Value.absent(),
    this.exhibitionId = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaAssetsCompanion.insert({
    required String id,
    required String exhibitionId,
    required String originalPath,
    required String thumbnailPath,
    required int width,
    required int height,
    required String contentHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       exhibitionId = Value(exhibitionId),
       originalPath = Value(originalPath),
       thumbnailPath = Value(thumbnailPath),
       width = Value(width),
       height = Value(height),
       contentHash = Value(contentHash);
  static Insertable<MediaAsset> custom({
    Expression<String>? id,
    Expression<String>? exhibitionId,
    Expression<String>? originalPath,
    Expression<String>? thumbnailPath,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? contentHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exhibitionId != null) 'exhibition_id': exhibitionId,
      if (originalPath != null) 'original_path': originalPath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (contentHash != null) 'content_hash': contentHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaAssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? exhibitionId,
    Value<String>? originalPath,
    Value<String>? thumbnailPath,
    Value<int>? width,
    Value<int>? height,
    Value<String>? contentHash,
    Value<int>? rowid,
  }) {
    return MediaAssetsCompanion(
      id: id ?? this.id,
      exhibitionId: exhibitionId ?? this.exhibitionId,
      originalPath: originalPath ?? this.originalPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      width: width ?? this.width,
      height: height ?? this.height,
      contentHash: contentHash ?? this.contentHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exhibitionId.present) {
      map['exhibition_id'] = Variable<String>(exhibitionId.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaAssetsCompanion(')
          ..write('id: $id, ')
          ..write('exhibitionId: $exhibitionId, ')
          ..write('originalPath: $originalPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('contentHash: $contentHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlacementsTable extends Placements
    with TableInfo<$PlacementsTable, Placement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<String> mediaId = GeneratedColumn<String>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_assets (id)',
    ),
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
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<String> size = GeneratedColumn<String>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frameMeta = const VerificationMeta('frame');
  @override
  late final GeneratedColumn<String> frame = GeneratedColumn<String>(
    'frame',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _focalXMeta = const VerificationMeta('focalX');
  @override
  late final GeneratedColumn<double> focalX = GeneratedColumn<double>(
    'focal_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _focalYMeta = const VerificationMeta('focalY');
  @override
  late final GeneratedColumn<double> focalY = GeneratedColumn<double>(
    'focal_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zoomMeta = const VerificationMeta('zoom');
  @override
  late final GeneratedColumn<double> zoom = GeneratedColumn<double>(
    'zoom',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<double> scale = GeneratedColumn<double>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _offsetXMeta = const VerificationMeta(
    'offsetX',
  );
  @override
  late final GeneratedColumn<double> offsetX = GeneratedColumn<double>(
    'offset_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _offsetYMeta = const VerificationMeta(
    'offsetY',
  );
  @override
  late final GeneratedColumn<double> offsetY = GeneratedColumn<double>(
    'offset_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frameCaptionMeta = const VerificationMeta(
    'frameCaption',
  );
  @override
  late final GeneratedColumn<String> frameCaption = GeneratedColumn<String>(
    'frame_caption',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    chapterId,
    mediaId,
    sortOrder,
    size,
    frame,
    focalX,
    focalY,
    zoom,
    scale,
    offsetX,
    offsetY,
    rotation,
    caption,
    frameCaption,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'placements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Placement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('frame')) {
      context.handle(
        _frameMeta,
        frame.isAcceptableOrUnknown(data['frame']!, _frameMeta),
      );
    } else if (isInserting) {
      context.missing(_frameMeta);
    }
    if (data.containsKey('focal_x')) {
      context.handle(
        _focalXMeta,
        focalX.isAcceptableOrUnknown(data['focal_x']!, _focalXMeta),
      );
    } else if (isInserting) {
      context.missing(_focalXMeta);
    }
    if (data.containsKey('focal_y')) {
      context.handle(
        _focalYMeta,
        focalY.isAcceptableOrUnknown(data['focal_y']!, _focalYMeta),
      );
    } else if (isInserting) {
      context.missing(_focalYMeta);
    }
    if (data.containsKey('zoom')) {
      context.handle(
        _zoomMeta,
        zoom.isAcceptableOrUnknown(data['zoom']!, _zoomMeta),
      );
    } else if (isInserting) {
      context.missing(_zoomMeta);
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('offset_x')) {
      context.handle(
        _offsetXMeta,
        offsetX.isAcceptableOrUnknown(data['offset_x']!, _offsetXMeta),
      );
    }
    if (data.containsKey('offset_y')) {
      context.handle(
        _offsetYMeta,
        offsetY.isAcceptableOrUnknown(data['offset_y']!, _offsetYMeta),
      );
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    } else if (isInserting) {
      context.missing(_captionMeta);
    }
    if (data.containsKey('frame_caption')) {
      context.handle(
        _frameCaptionMeta,
        frameCaption.isAcceptableOrUnknown(
          data['frame_caption']!,
          _frameCaptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Placement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Placement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}size'],
      )!,
      frame: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frame'],
      )!,
      focalX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}focal_x'],
      )!,
      focalY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}focal_y'],
      )!,
      zoom: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}zoom'],
      )!,
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scale'],
      )!,
      offsetX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}offset_x'],
      )!,
      offsetY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}offset_y'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rotation'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      )!,
      frameCaption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frame_caption'],
      )!,
    );
  }

  @override
  $PlacementsTable createAlias(String alias) {
    return $PlacementsTable(attachedDatabase, alias);
  }
}

class Placement extends DataClass implements Insertable<Placement> {
  final String id;
  final String chapterId;
  final String mediaId;
  final int sortOrder;
  final String size;
  final String frame;
  final double focalX;
  final double focalY;
  final double zoom;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double rotation;
  final String caption;
  final String frameCaption;
  const Placement({
    required this.id,
    required this.chapterId,
    required this.mediaId,
    required this.sortOrder,
    required this.size,
    required this.frame,
    required this.focalX,
    required this.focalY,
    required this.zoom,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.rotation,
    required this.caption,
    required this.frameCaption,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['chapter_id'] = Variable<String>(chapterId);
    map['media_id'] = Variable<String>(mediaId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['size'] = Variable<String>(size);
    map['frame'] = Variable<String>(frame);
    map['focal_x'] = Variable<double>(focalX);
    map['focal_y'] = Variable<double>(focalY);
    map['zoom'] = Variable<double>(zoom);
    map['scale'] = Variable<double>(scale);
    map['offset_x'] = Variable<double>(offsetX);
    map['offset_y'] = Variable<double>(offsetY);
    map['rotation'] = Variable<double>(rotation);
    map['caption'] = Variable<String>(caption);
    map['frame_caption'] = Variable<String>(frameCaption);
    return map;
  }

  PlacementsCompanion toCompanion(bool nullToAbsent) {
    return PlacementsCompanion(
      id: Value(id),
      chapterId: Value(chapterId),
      mediaId: Value(mediaId),
      sortOrder: Value(sortOrder),
      size: Value(size),
      frame: Value(frame),
      focalX: Value(focalX),
      focalY: Value(focalY),
      zoom: Value(zoom),
      scale: Value(scale),
      offsetX: Value(offsetX),
      offsetY: Value(offsetY),
      rotation: Value(rotation),
      caption: Value(caption),
      frameCaption: Value(frameCaption),
    );
  }

  factory Placement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Placement(
      id: serializer.fromJson<String>(json['id']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      mediaId: serializer.fromJson<String>(json['mediaId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      size: serializer.fromJson<String>(json['size']),
      frame: serializer.fromJson<String>(json['frame']),
      focalX: serializer.fromJson<double>(json['focalX']),
      focalY: serializer.fromJson<double>(json['focalY']),
      zoom: serializer.fromJson<double>(json['zoom']),
      scale: serializer.fromJson<double>(json['scale']),
      offsetX: serializer.fromJson<double>(json['offsetX']),
      offsetY: serializer.fromJson<double>(json['offsetY']),
      rotation: serializer.fromJson<double>(json['rotation']),
      caption: serializer.fromJson<String>(json['caption']),
      frameCaption: serializer.fromJson<String>(json['frameCaption']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'chapterId': serializer.toJson<String>(chapterId),
      'mediaId': serializer.toJson<String>(mediaId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'size': serializer.toJson<String>(size),
      'frame': serializer.toJson<String>(frame),
      'focalX': serializer.toJson<double>(focalX),
      'focalY': serializer.toJson<double>(focalY),
      'zoom': serializer.toJson<double>(zoom),
      'scale': serializer.toJson<double>(scale),
      'offsetX': serializer.toJson<double>(offsetX),
      'offsetY': serializer.toJson<double>(offsetY),
      'rotation': serializer.toJson<double>(rotation),
      'caption': serializer.toJson<String>(caption),
      'frameCaption': serializer.toJson<String>(frameCaption),
    };
  }

  Placement copyWith({
    String? id,
    String? chapterId,
    String? mediaId,
    int? sortOrder,
    String? size,
    String? frame,
    double? focalX,
    double? focalY,
    double? zoom,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotation,
    String? caption,
    String? frameCaption,
  }) => Placement(
    id: id ?? this.id,
    chapterId: chapterId ?? this.chapterId,
    mediaId: mediaId ?? this.mediaId,
    sortOrder: sortOrder ?? this.sortOrder,
    size: size ?? this.size,
    frame: frame ?? this.frame,
    focalX: focalX ?? this.focalX,
    focalY: focalY ?? this.focalY,
    zoom: zoom ?? this.zoom,
    scale: scale ?? this.scale,
    offsetX: offsetX ?? this.offsetX,
    offsetY: offsetY ?? this.offsetY,
    rotation: rotation ?? this.rotation,
    caption: caption ?? this.caption,
    frameCaption: frameCaption ?? this.frameCaption,
  );
  Placement copyWithCompanion(PlacementsCompanion data) {
    return Placement(
      id: data.id.present ? data.id.value : this.id,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      size: data.size.present ? data.size.value : this.size,
      frame: data.frame.present ? data.frame.value : this.frame,
      focalX: data.focalX.present ? data.focalX.value : this.focalX,
      focalY: data.focalY.present ? data.focalY.value : this.focalY,
      zoom: data.zoom.present ? data.zoom.value : this.zoom,
      scale: data.scale.present ? data.scale.value : this.scale,
      offsetX: data.offsetX.present ? data.offsetX.value : this.offsetX,
      offsetY: data.offsetY.present ? data.offsetY.value : this.offsetY,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      caption: data.caption.present ? data.caption.value : this.caption,
      frameCaption: data.frameCaption.present
          ? data.frameCaption.value
          : this.frameCaption,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Placement(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('mediaId: $mediaId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('size: $size, ')
          ..write('frame: $frame, ')
          ..write('focalX: $focalX, ')
          ..write('focalY: $focalY, ')
          ..write('zoom: $zoom, ')
          ..write('scale: $scale, ')
          ..write('offsetX: $offsetX, ')
          ..write('offsetY: $offsetY, ')
          ..write('rotation: $rotation, ')
          ..write('caption: $caption, ')
          ..write('frameCaption: $frameCaption')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    chapterId,
    mediaId,
    sortOrder,
    size,
    frame,
    focalX,
    focalY,
    zoom,
    scale,
    offsetX,
    offsetY,
    rotation,
    caption,
    frameCaption,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Placement &&
          other.id == this.id &&
          other.chapterId == this.chapterId &&
          other.mediaId == this.mediaId &&
          other.sortOrder == this.sortOrder &&
          other.size == this.size &&
          other.frame == this.frame &&
          other.focalX == this.focalX &&
          other.focalY == this.focalY &&
          other.zoom == this.zoom &&
          other.scale == this.scale &&
          other.offsetX == this.offsetX &&
          other.offsetY == this.offsetY &&
          other.rotation == this.rotation &&
          other.caption == this.caption &&
          other.frameCaption == this.frameCaption);
}

class PlacementsCompanion extends UpdateCompanion<Placement> {
  final Value<String> id;
  final Value<String> chapterId;
  final Value<String> mediaId;
  final Value<int> sortOrder;
  final Value<String> size;
  final Value<String> frame;
  final Value<double> focalX;
  final Value<double> focalY;
  final Value<double> zoom;
  final Value<double> scale;
  final Value<double> offsetX;
  final Value<double> offsetY;
  final Value<double> rotation;
  final Value<String> caption;
  final Value<String> frameCaption;
  final Value<int> rowid;
  const PlacementsCompanion({
    this.id = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.size = const Value.absent(),
    this.frame = const Value.absent(),
    this.focalX = const Value.absent(),
    this.focalY = const Value.absent(),
    this.zoom = const Value.absent(),
    this.scale = const Value.absent(),
    this.offsetX = const Value.absent(),
    this.offsetY = const Value.absent(),
    this.rotation = const Value.absent(),
    this.caption = const Value.absent(),
    this.frameCaption = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlacementsCompanion.insert({
    required String id,
    required String chapterId,
    required String mediaId,
    required int sortOrder,
    required String size,
    required String frame,
    required double focalX,
    required double focalY,
    required double zoom,
    this.scale = const Value.absent(),
    this.offsetX = const Value.absent(),
    this.offsetY = const Value.absent(),
    this.rotation = const Value.absent(),
    required String caption,
    this.frameCaption = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       chapterId = Value(chapterId),
       mediaId = Value(mediaId),
       sortOrder = Value(sortOrder),
       size = Value(size),
       frame = Value(frame),
       focalX = Value(focalX),
       focalY = Value(focalY),
       zoom = Value(zoom),
       caption = Value(caption);
  static Insertable<Placement> custom({
    Expression<String>? id,
    Expression<String>? chapterId,
    Expression<String>? mediaId,
    Expression<int>? sortOrder,
    Expression<String>? size,
    Expression<String>? frame,
    Expression<double>? focalX,
    Expression<double>? focalY,
    Expression<double>? zoom,
    Expression<double>? scale,
    Expression<double>? offsetX,
    Expression<double>? offsetY,
    Expression<double>? rotation,
    Expression<String>? caption,
    Expression<String>? frameCaption,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (chapterId != null) 'chapter_id': chapterId,
      if (mediaId != null) 'media_id': mediaId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (size != null) 'size': size,
      if (frame != null) 'frame': frame,
      if (focalX != null) 'focal_x': focalX,
      if (focalY != null) 'focal_y': focalY,
      if (zoom != null) 'zoom': zoom,
      if (scale != null) 'scale': scale,
      if (offsetX != null) 'offset_x': offsetX,
      if (offsetY != null) 'offset_y': offsetY,
      if (rotation != null) 'rotation': rotation,
      if (caption != null) 'caption': caption,
      if (frameCaption != null) 'frame_caption': frameCaption,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlacementsCompanion copyWith({
    Value<String>? id,
    Value<String>? chapterId,
    Value<String>? mediaId,
    Value<int>? sortOrder,
    Value<String>? size,
    Value<String>? frame,
    Value<double>? focalX,
    Value<double>? focalY,
    Value<double>? zoom,
    Value<double>? scale,
    Value<double>? offsetX,
    Value<double>? offsetY,
    Value<double>? rotation,
    Value<String>? caption,
    Value<String>? frameCaption,
    Value<int>? rowid,
  }) {
    return PlacementsCompanion(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      mediaId: mediaId ?? this.mediaId,
      sortOrder: sortOrder ?? this.sortOrder,
      size: size ?? this.size,
      frame: frame ?? this.frame,
      focalX: focalX ?? this.focalX,
      focalY: focalY ?? this.focalY,
      zoom: zoom ?? this.zoom,
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      rotation: rotation ?? this.rotation,
      caption: caption ?? this.caption,
      frameCaption: frameCaption ?? this.frameCaption,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<String>(mediaId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (size.present) {
      map['size'] = Variable<String>(size.value);
    }
    if (frame.present) {
      map['frame'] = Variable<String>(frame.value);
    }
    if (focalX.present) {
      map['focal_x'] = Variable<double>(focalX.value);
    }
    if (focalY.present) {
      map['focal_y'] = Variable<double>(focalY.value);
    }
    if (zoom.present) {
      map['zoom'] = Variable<double>(zoom.value);
    }
    if (scale.present) {
      map['scale'] = Variable<double>(scale.value);
    }
    if (offsetX.present) {
      map['offset_x'] = Variable<double>(offsetX.value);
    }
    if (offsetY.present) {
      map['offset_y'] = Variable<double>(offsetY.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (frameCaption.present) {
      map['frame_caption'] = Variable<String>(frameCaption.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacementsCompanion(')
          ..write('id: $id, ')
          ..write('chapterId: $chapterId, ')
          ..write('mediaId: $mediaId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('size: $size, ')
          ..write('frame: $frame, ')
          ..write('focalX: $focalX, ')
          ..write('focalY: $focalY, ')
          ..write('zoom: $zoom, ')
          ..write('scale: $scale, ')
          ..write('offsetX: $offsetX, ')
          ..write('offsetY: $offsetY, ')
          ..write('rotation: $rotation, ')
          ..write('caption: $caption, ')
          ..write('frameCaption: $frameCaption, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$GalleryDatabase extends GeneratedDatabase {
  _$GalleryDatabase(QueryExecutor e) : super(e);
  $GalleryDatabaseManager get managers => $GalleryDatabaseManager(this);
  late final $ExhibitionCategoriesTable exhibitionCategories =
      $ExhibitionCategoriesTable(this);
  late final $AppSettingsRowsTable appSettingsRows = $AppSettingsRowsTable(
    this,
  );
  late final $ExhibitionsTable exhibitions = $ExhibitionsTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $MediaAssetsTable mediaAssets = $MediaAssetsTable(this);
  late final $PlacementsTable placements = $PlacementsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exhibitionCategories,
    appSettingsRows,
    exhibitions,
    chapters,
    mediaAssets,
    placements,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exhibition_categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exhibitions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exhibitions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exhibitions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('media_assets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chapters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('placements', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ExhibitionCategoriesTableCreateCompanionBuilder =
    ExhibitionCategoriesCompanion Function({
      required String id,
      required String title,
      required int sortOrder,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ExhibitionCategoriesTableUpdateCompanionBuilder =
    ExhibitionCategoriesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ExhibitionCategoriesTableReferences
    extends
        BaseReferences<
          _$GalleryDatabase,
          $ExhibitionCategoriesTable,
          ExhibitionCategory
        > {
  $$ExhibitionCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ExhibitionsTable, List<Exhibition>>
  _exhibitionsRefsTable(_$GalleryDatabase db) => MultiTypedResultKey.fromTable(
    db.exhibitions,
    aliasName: 'exhibition_categories__id__exhibitions__category_id',
  );

  $$ExhibitionsTableProcessedTableManager get exhibitionsRefs {
    final manager = $$ExhibitionsTableTableManager(
      $_db,
      $_db.exhibitions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_exhibitionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExhibitionCategoriesTableFilterComposer
    extends Composer<_$GalleryDatabase, $ExhibitionCategoriesTable> {
  $$ExhibitionCategoriesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> exhibitionsRefs(
    Expression<bool> Function($$ExhibitionsTableFilterComposer f) f,
  ) {
    final $$ExhibitionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exhibitions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExhibitionsTableFilterComposer(
            $db: $db,
            $table: $db.exhibitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExhibitionCategoriesTableOrderingComposer
    extends Composer<_$GalleryDatabase, $ExhibitionCategoriesTable> {
  $$ExhibitionCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExhibitionCategoriesTableAnnotationComposer
    extends Composer<_$GalleryDatabase, $ExhibitionCategoriesTable> {
  $$ExhibitionCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> exhibitionsRefs<T extends Object>(
    Expression<T> Function($$ExhibitionsTableAnnotationComposer a) f,
  ) {
    final $$ExhibitionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exhibitions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExhibitionsTableAnnotationComposer(
            $db: $db,
            $table: $db.exhibitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExhibitionCategoriesTableTableManager
    extends
        RootTableManager<
          _$GalleryDatabase,
          $ExhibitionCategoriesTable,
          ExhibitionCategory,
          $$ExhibitionCategoriesTableFilterComposer,
          $$ExhibitionCategoriesTableOrderingComposer,
          $$ExhibitionCategoriesTableAnnotationComposer,
          $$ExhibitionCategoriesTableCreateCompanionBuilder,
          $$ExhibitionCategoriesTableUpdateCompanionBuilder,
          (ExhibitionCategory, $$ExhibitionCategoriesTableReferences),
          ExhibitionCategory,
          PrefetchHooks Function({bool exhibitionsRefs})
        > {
  $$ExhibitionCategoriesTableTableManager(
    _$GalleryDatabase db,
    $ExhibitionCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExhibitionCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExhibitionCategoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExhibitionCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExhibitionCategoriesCompanion(
                id: id,
                title: title,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int sortOrder,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExhibitionCategoriesCompanion.insert(
                id: id,
                title: title,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExhibitionCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exhibitionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (exhibitionsRefs) db.exhibitions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exhibitionsRefs)
                    await $_getPrefetchedData<
                      ExhibitionCategory,
                      $ExhibitionCategoriesTable,
                      Exhibition
                    >(
                      currentTable: table,
                      referencedTable: $$ExhibitionCategoriesTableReferences
                          ._exhibitionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ExhibitionCategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).exhibitionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ExhibitionCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$GalleryDatabase,
      $ExhibitionCategoriesTable,
      ExhibitionCategory,
      $$ExhibitionCategoriesTableFilterComposer,
      $$ExhibitionCategoriesTableOrderingComposer,
      $$ExhibitionCategoriesTableAnnotationComposer,
      $$ExhibitionCategoriesTableCreateCompanionBuilder,
      $$ExhibitionCategoriesTableUpdateCompanionBuilder,
      (ExhibitionCategory, $$ExhibitionCategoriesTableReferences),
      ExhibitionCategory,
      PrefetchHooks Function({bool exhibitionsRefs})
    >;
typedef $$AppSettingsRowsTableCreateCompanionBuilder =
    AppSettingsRowsCompanion Function({
      required String id,
      Value<bool> recordingShowChapterTitle,
      Value<int> recordingDelaySeconds,
      Value<String> mediaImportMode,
      Value<double> recordingSpeed,
      Value<bool> recordingUseMusic,
      Value<String> recordingChapterMode,
      Value<String> recordingQuality,
      Value<String> themeMode,
      Value<int> rowid,
    });
typedef $$AppSettingsRowsTableUpdateCompanionBuilder =
    AppSettingsRowsCompanion Function({
      Value<String> id,
      Value<bool> recordingShowChapterTitle,
      Value<int> recordingDelaySeconds,
      Value<String> mediaImportMode,
      Value<double> recordingSpeed,
      Value<bool> recordingUseMusic,
      Value<String> recordingChapterMode,
      Value<String> recordingQuality,
      Value<String> themeMode,
      Value<int> rowid,
    });

class $$AppSettingsRowsTableFilterComposer
    extends Composer<_$GalleryDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableFilterComposer({
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

  ColumnFilters<bool> get recordingShowChapterTitle => $composableBuilder(
    column: $table.recordingShowChapterTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordingDelaySeconds => $composableBuilder(
    column: $table.recordingDelaySeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaImportMode => $composableBuilder(
    column: $table.mediaImportMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get recordingSpeed => $composableBuilder(
    column: $table.recordingSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get recordingUseMusic => $composableBuilder(
    column: $table.recordingUseMusic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordingChapterMode => $composableBuilder(
    column: $table.recordingChapterMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordingQuality => $composableBuilder(
    column: $table.recordingQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsRowsTableOrderingComposer
    extends Composer<_$GalleryDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableOrderingComposer({
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

  ColumnOrderings<bool> get recordingShowChapterTitle => $composableBuilder(
    column: $table.recordingShowChapterTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordingDelaySeconds => $composableBuilder(
    column: $table.recordingDelaySeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaImportMode => $composableBuilder(
    column: $table.mediaImportMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get recordingSpeed => $composableBuilder(
    column: $table.recordingSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get recordingUseMusic => $composableBuilder(
    column: $table.recordingUseMusic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordingChapterMode => $composableBuilder(
    column: $table.recordingChapterMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordingQuality => $composableBuilder(
    column: $table.recordingQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsRowsTableAnnotationComposer
    extends Composer<_$GalleryDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get recordingShowChapterTitle => $composableBuilder(
    column: $table.recordingShowChapterTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordingDelaySeconds => $composableBuilder(
    column: $table.recordingDelaySeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaImportMode => $composableBuilder(
    column: $table.mediaImportMode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get recordingSpeed => $composableBuilder(
    column: $table.recordingSpeed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get recordingUseMusic => $composableBuilder(
    column: $table.recordingUseMusic,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordingChapterMode => $composableBuilder(
    column: $table.recordingChapterMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordingQuality => $composableBuilder(
    column: $table.recordingQuality,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);
}

class $$AppSettingsRowsTableTableManager
    extends
        RootTableManager<
          _$GalleryDatabase,
          $AppSettingsRowsTable,
          AppSettingsRow,
          $$AppSettingsRowsTableFilterComposer,
          $$AppSettingsRowsTableOrderingComposer,
          $$AppSettingsRowsTableAnnotationComposer,
          $$AppSettingsRowsTableCreateCompanionBuilder,
          $$AppSettingsRowsTableUpdateCompanionBuilder,
          (
            AppSettingsRow,
            BaseReferences<
              _$GalleryDatabase,
              $AppSettingsRowsTable,
              AppSettingsRow
            >,
          ),
          AppSettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsRowsTableTableManager(
    _$GalleryDatabase db,
    $AppSettingsRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> recordingShowChapterTitle = const Value.absent(),
                Value<int> recordingDelaySeconds = const Value.absent(),
                Value<String> mediaImportMode = const Value.absent(),
                Value<double> recordingSpeed = const Value.absent(),
                Value<bool> recordingUseMusic = const Value.absent(),
                Value<String> recordingChapterMode = const Value.absent(),
                Value<String> recordingQuality = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsRowsCompanion(
                id: id,
                recordingShowChapterTitle: recordingShowChapterTitle,
                recordingDelaySeconds: recordingDelaySeconds,
                mediaImportMode: mediaImportMode,
                recordingSpeed: recordingSpeed,
                recordingUseMusic: recordingUseMusic,
                recordingChapterMode: recordingChapterMode,
                recordingQuality: recordingQuality,
                themeMode: themeMode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> recordingShowChapterTitle = const Value.absent(),
                Value<int> recordingDelaySeconds = const Value.absent(),
                Value<String> mediaImportMode = const Value.absent(),
                Value<double> recordingSpeed = const Value.absent(),
                Value<bool> recordingUseMusic = const Value.absent(),
                Value<String> recordingChapterMode = const Value.absent(),
                Value<String> recordingQuality = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsRowsCompanion.insert(
                id: id,
                recordingShowChapterTitle: recordingShowChapterTitle,
                recordingDelaySeconds: recordingDelaySeconds,
                mediaImportMode: mediaImportMode,
                recordingSpeed: recordingSpeed,
                recordingUseMusic: recordingUseMusic,
                recordingChapterMode: recordingChapterMode,
                recordingQuality: recordingQuality,
                themeMode: themeMode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$GalleryDatabase,
      $AppSettingsRowsTable,
      AppSettingsRow,
      $$AppSettingsRowsTableFilterComposer,
      $$AppSettingsRowsTableOrderingComposer,
      $$AppSettingsRowsTableAnnotationComposer,
      $$AppSettingsRowsTableCreateCompanionBuilder,
      $$AppSettingsRowsTableUpdateCompanionBuilder,
      (
        AppSettingsRow,
        BaseReferences<
          _$GalleryDatabase,
          $AppSettingsRowsTable,
          AppSettingsRow
        >,
      ),
      AppSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$ExhibitionsTableCreateCompanionBuilder =
    ExhibitionsCompanion Function({
      required String id,
      required String title,
      Value<String?> coverMediaId,
      Value<String?> categoryId,
      required String theme,
      Value<String?> canvasBackgroundPath,
      Value<double> canvasBackgroundOpacity,
      Value<String?> musicPath,
      Value<String?> musicTitle,
      Value<bool> showChapterTitleInPlayback,
      Value<int> playbackDelaySeconds,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ExhibitionsTableUpdateCompanionBuilder =
    ExhibitionsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> coverMediaId,
      Value<String?> categoryId,
      Value<String> theme,
      Value<String?> canvasBackgroundPath,
      Value<double> canvasBackgroundOpacity,
      Value<String?> musicPath,
      Value<String?> musicTitle,
      Value<bool> showChapterTitleInPlayback,
      Value<int> playbackDelaySeconds,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ExhibitionsTableReferences
    extends BaseReferences<_$GalleryDatabase, $ExhibitionsTable, Exhibition> {
  $$ExhibitionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExhibitionCategoriesTable _categoryIdTable(_$GalleryDatabase db) => db
      .exhibitionCategories
      .createAlias('exhibitions__category_id__exhibition_categories__id');

  $$ExhibitionCategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$ExhibitionCategoriesTableTableManager(
      $_db,
      $_db.exhibitionCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ChaptersTable, List<Chapter>> _chaptersRefsTable(
    _$GalleryDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.chapters,
    aliasName: 'exhibitions__id__chapters__exhibition_id',
  );

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.exhibitionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MediaAssetsTable, List<MediaAsset>>
  _mediaAssetsRefsTable(_$GalleryDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaAssets,
    aliasName: 'exhibitions__id__media_assets__exhibition_id',
  );

  $$MediaAssetsTableProcessedTableManager get mediaAssetsRefs {
    final manager = $$MediaAssetsTableTableManager(
      $_db,
      $_db.mediaAssets,
    ).filter((f) => f.exhibitionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaAssetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExhibitionsTableFilterComposer
    extends Composer<_$GalleryDatabase, $ExhibitionsTable> {
  $$ExhibitionsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverMediaId => $composableBuilder(
    column: $table.coverMediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canvasBackgroundPath => $composableBuilder(
    column: $table.canvasBackgroundPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get canvasBackgroundOpacity => $composableBuilder(
    column: $table.canvasBackgroundOpacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get musicPath => $composableBuilder(
    column: $table.musicPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get musicTitle => $composableBuilder(
    column: $table.musicTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showChapterTitleInPlayback => $composableBuilder(
    column: $table.showChapterTitleInPlayback,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playbackDelaySeconds => $composableBuilder(
    column: $table.playbackDelaySeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ExhibitionCategoriesTableFilterComposer get categoryId {
    final $$ExhibitionCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.exhibitionCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExhibitionCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.exhibitionCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> chaptersRefs(
    Expression<bool> Function($$ChaptersTableFilterComposer f) f,
  ) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.exhibitionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mediaAssetsRefs(
    Expression<bool> Function($$MediaAssetsTableFilterComposer f) f,
  ) {
    final $$MediaAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.exhibitionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableFilterComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExhibitionsTableOrderingComposer
    extends Composer<_$GalleryDatabase, $ExhibitionsTable> {
  $$ExhibitionsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverMediaId => $composableBuilder(
    column: $table.coverMediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canvasBackgroundPath => $composableBuilder(
    column: $table.canvasBackgroundPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get canvasBackgroundOpacity => $composableBuilder(
    column: $table.canvasBackgroundOpacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musicPath => $composableBuilder(
    column: $table.musicPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musicTitle => $composableBuilder(
    column: $table.musicTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showChapterTitleInPlayback => $composableBuilder(
    column: $table.showChapterTitleInPlayback,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playbackDelaySeconds => $composableBuilder(
    column: $table.playbackDelaySeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExhibitionCategoriesTableOrderingComposer get categoryId {
    final $$ExhibitionCategoriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.exhibitionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExhibitionCategoriesTableOrderingComposer(
                $db: $db,
                $table: $db.exhibitionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExhibitionsTableAnnotationComposer
    extends Composer<_$GalleryDatabase, $ExhibitionsTable> {
  $$ExhibitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get coverMediaId => $composableBuilder(
    column: $table.coverMediaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get canvasBackgroundPath => $composableBuilder(
    column: $table.canvasBackgroundPath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get canvasBackgroundOpacity => $composableBuilder(
    column: $table.canvasBackgroundOpacity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get musicPath =>
      $composableBuilder(column: $table.musicPath, builder: (column) => column);

  GeneratedColumn<String> get musicTitle => $composableBuilder(
    column: $table.musicTitle,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showChapterTitleInPlayback => $composableBuilder(
    column: $table.showChapterTitleInPlayback,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playbackDelaySeconds => $composableBuilder(
    column: $table.playbackDelaySeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ExhibitionCategoriesTableAnnotationComposer get categoryId {
    final $$ExhibitionCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.exhibitionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExhibitionCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.exhibitionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> chaptersRefs<T extends Object>(
    Expression<T> Function($$ChaptersTableAnnotationComposer a) f,
  ) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.exhibitionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mediaAssetsRefs<T extends Object>(
    Expression<T> Function($$MediaAssetsTableAnnotationComposer a) f,
  ) {
    final $$MediaAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.exhibitionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExhibitionsTableTableManager
    extends
        RootTableManager<
          _$GalleryDatabase,
          $ExhibitionsTable,
          Exhibition,
          $$ExhibitionsTableFilterComposer,
          $$ExhibitionsTableOrderingComposer,
          $$ExhibitionsTableAnnotationComposer,
          $$ExhibitionsTableCreateCompanionBuilder,
          $$ExhibitionsTableUpdateCompanionBuilder,
          (Exhibition, $$ExhibitionsTableReferences),
          Exhibition,
          PrefetchHooks Function({
            bool categoryId,
            bool chaptersRefs,
            bool mediaAssetsRefs,
          })
        > {
  $$ExhibitionsTableTableManager(_$GalleryDatabase db, $ExhibitionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExhibitionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExhibitionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExhibitionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> coverMediaId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String?> canvasBackgroundPath = const Value.absent(),
                Value<double> canvasBackgroundOpacity = const Value.absent(),
                Value<String?> musicPath = const Value.absent(),
                Value<String?> musicTitle = const Value.absent(),
                Value<bool> showChapterTitleInPlayback = const Value.absent(),
                Value<int> playbackDelaySeconds = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExhibitionsCompanion(
                id: id,
                title: title,
                coverMediaId: coverMediaId,
                categoryId: categoryId,
                theme: theme,
                canvasBackgroundPath: canvasBackgroundPath,
                canvasBackgroundOpacity: canvasBackgroundOpacity,
                musicPath: musicPath,
                musicTitle: musicTitle,
                showChapterTitleInPlayback: showChapterTitleInPlayback,
                playbackDelaySeconds: playbackDelaySeconds,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> coverMediaId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required String theme,
                Value<String?> canvasBackgroundPath = const Value.absent(),
                Value<double> canvasBackgroundOpacity = const Value.absent(),
                Value<String?> musicPath = const Value.absent(),
                Value<String?> musicTitle = const Value.absent(),
                Value<bool> showChapterTitleInPlayback = const Value.absent(),
                Value<int> playbackDelaySeconds = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExhibitionsCompanion.insert(
                id: id,
                title: title,
                coverMediaId: coverMediaId,
                categoryId: categoryId,
                theme: theme,
                canvasBackgroundPath: canvasBackgroundPath,
                canvasBackgroundOpacity: canvasBackgroundOpacity,
                musicPath: musicPath,
                musicTitle: musicTitle,
                showChapterTitleInPlayback: showChapterTitleInPlayback,
                playbackDelaySeconds: playbackDelaySeconds,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExhibitionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                chaptersRefs = false,
                mediaAssetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (chaptersRefs) db.chapters,
                    if (mediaAssetsRefs) db.mediaAssets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$ExhibitionsTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$ExhibitionsTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (chaptersRefs)
                        await $_getPrefetchedData<
                          Exhibition,
                          $ExhibitionsTable,
                          Chapter
                        >(
                          currentTable: table,
                          referencedTable: $$ExhibitionsTableReferences
                              ._chaptersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExhibitionsTableReferences(
                                db,
                                table,
                                p0,
                              ).chaptersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exhibitionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (mediaAssetsRefs)
                        await $_getPrefetchedData<
                          Exhibition,
                          $ExhibitionsTable,
                          MediaAsset
                        >(
                          currentTable: table,
                          referencedTable: $$ExhibitionsTableReferences
                              ._mediaAssetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExhibitionsTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaAssetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exhibitionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExhibitionsTableProcessedTableManager =
    ProcessedTableManager<
      _$GalleryDatabase,
      $ExhibitionsTable,
      Exhibition,
      $$ExhibitionsTableFilterComposer,
      $$ExhibitionsTableOrderingComposer,
      $$ExhibitionsTableAnnotationComposer,
      $$ExhibitionsTableCreateCompanionBuilder,
      $$ExhibitionsTableUpdateCompanionBuilder,
      (Exhibition, $$ExhibitionsTableReferences),
      Exhibition,
      PrefetchHooks Function({
        bool categoryId,
        bool chaptersRefs,
        bool mediaAssetsRefs,
      })
    >;
typedef $$ChaptersTableCreateCompanionBuilder =
    ChaptersCompanion Function({
      required String id,
      required String exhibitionId,
      required String title,
      required String caption,
      required int sortOrder,
      required String layout,
      required String motion,
      Value<String> pathStyle,
      Value<String?> customPathData,
      Value<int> rowid,
    });
typedef $$ChaptersTableUpdateCompanionBuilder =
    ChaptersCompanion Function({
      Value<String> id,
      Value<String> exhibitionId,
      Value<String> title,
      Value<String> caption,
      Value<int> sortOrder,
      Value<String> layout,
      Value<String> motion,
      Value<String> pathStyle,
      Value<String?> customPathData,
      Value<int> rowid,
    });

final class $$ChaptersTableReferences
    extends BaseReferences<_$GalleryDatabase, $ChaptersTable, Chapter> {
  $$ChaptersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExhibitionsTable _exhibitionIdTable(_$GalleryDatabase db) =>
      db.exhibitions.createAlias('chapters__exhibition_id__exhibitions__id');

  $$ExhibitionsTableProcessedTableManager get exhibitionId {
    final $_column = $_itemColumn<String>('exhibition_id')!;

    final manager = $$ExhibitionsTableTableManager(
      $_db,
      $_db.exhibitions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exhibitionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlacementsTable, List<Placement>>
  _placementsRefsTable(_$GalleryDatabase db) => MultiTypedResultKey.fromTable(
    db.placements,
    aliasName: 'chapters__id__placements__chapter_id',
  );

  $$PlacementsTableProcessedTableManager get placementsRefs {
    final manager = $$PlacementsTableTableManager(
      $_db,
      $_db.placements,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_placementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChaptersTableFilterComposer
    extends Composer<_$GalleryDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motion => $composableBuilder(
    column: $table.motion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pathStyle => $composableBuilder(
    column: $table.pathStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customPathData => $composableBuilder(
    column: $table.customPathData,
    builder: (column) => ColumnFilters(column),
  );

  $$ExhibitionsTableFilterComposer get exhibitionId {
    final $$ExhibitionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exhibitionId,
      referencedTable: $db.exhibitions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExhibitionsTableFilterComposer(
            $db: $db,
            $table: $db.exhibitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> placementsRefs(
    Expression<bool> Function($$PlacementsTableFilterComposer f) f,
  ) {
    final $$PlacementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.placements,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacementsTableFilterComposer(
            $db: $db,
            $table: $db.placements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$GalleryDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motion => $composableBuilder(
    column: $table.motion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pathStyle => $composableBuilder(
    column: $table.pathStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customPathData => $composableBuilder(
    column: $table.customPathData,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExhibitionsTableOrderingComposer get exhibitionId {
    final $$ExhibitionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exhibitionId,
      referencedTable: $db.exhibitions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExhibitionsTableOrderingComposer(
            $db: $db,
            $table: $db.exhibitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$GalleryDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get layout =>
      $composableBuilder(column: $table.layout, builder: (column) => column);

  GeneratedColumn<String> get motion =>
      $composableBuilder(column: $table.motion, builder: (column) => column);

  GeneratedColumn<String> get pathStyle =>
      $composableBuilder(column: $table.pathStyle, builder: (column) => column);

  GeneratedColumn<String> get customPathData => $composableBuilder(
    column: $table.customPathData,
    builder: (column) => column,
  );

  $$ExhibitionsTableAnnotationComposer get exhibitionId {
    final $$ExhibitionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exhibitionId,
      referencedTable: $db.exhibitions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExhibitionsTableAnnotationComposer(
            $db: $db,
            $table: $db.exhibitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> placementsRefs<T extends Object>(
    Expression<T> Function($$PlacementsTableAnnotationComposer a) f,
  ) {
    final $$PlacementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.placements,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacementsTableAnnotationComposer(
            $db: $db,
            $table: $db.placements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableTableManager
    extends
        RootTableManager<
          _$GalleryDatabase,
          $ChaptersTable,
          Chapter,
          $$ChaptersTableFilterComposer,
          $$ChaptersTableOrderingComposer,
          $$ChaptersTableAnnotationComposer,
          $$ChaptersTableCreateCompanionBuilder,
          $$ChaptersTableUpdateCompanionBuilder,
          (Chapter, $$ChaptersTableReferences),
          Chapter,
          PrefetchHooks Function({bool exhibitionId, bool placementsRefs})
        > {
  $$ChaptersTableTableManager(_$GalleryDatabase db, $ChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> exhibitionId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> caption = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> layout = const Value.absent(),
                Value<String> motion = const Value.absent(),
                Value<String> pathStyle = const Value.absent(),
                Value<String?> customPathData = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion(
                id: id,
                exhibitionId: exhibitionId,
                title: title,
                caption: caption,
                sortOrder: sortOrder,
                layout: layout,
                motion: motion,
                pathStyle: pathStyle,
                customPathData: customPathData,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String exhibitionId,
                required String title,
                required String caption,
                required int sortOrder,
                required String layout,
                required String motion,
                Value<String> pathStyle = const Value.absent(),
                Value<String?> customPathData = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion.insert(
                id: id,
                exhibitionId: exhibitionId,
                title: title,
                caption: caption,
                sortOrder: sortOrder,
                layout: layout,
                motion: motion,
                pathStyle: pathStyle,
                customPathData: customPathData,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChaptersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({exhibitionId = false, placementsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (placementsRefs) db.placements],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (exhibitionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.exhibitionId,
                                    referencedTable: $$ChaptersTableReferences
                                        ._exhibitionIdTable(db),
                                    referencedColumn: $$ChaptersTableReferences
                                        ._exhibitionIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (placementsRefs)
                        await $_getPrefetchedData<
                          Chapter,
                          $ChaptersTable,
                          Placement
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._placementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).placementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$GalleryDatabase,
      $ChaptersTable,
      Chapter,
      $$ChaptersTableFilterComposer,
      $$ChaptersTableOrderingComposer,
      $$ChaptersTableAnnotationComposer,
      $$ChaptersTableCreateCompanionBuilder,
      $$ChaptersTableUpdateCompanionBuilder,
      (Chapter, $$ChaptersTableReferences),
      Chapter,
      PrefetchHooks Function({bool exhibitionId, bool placementsRefs})
    >;
typedef $$MediaAssetsTableCreateCompanionBuilder =
    MediaAssetsCompanion Function({
      required String id,
      required String exhibitionId,
      required String originalPath,
      required String thumbnailPath,
      required int width,
      required int height,
      required String contentHash,
      Value<int> rowid,
    });
typedef $$MediaAssetsTableUpdateCompanionBuilder =
    MediaAssetsCompanion Function({
      Value<String> id,
      Value<String> exhibitionId,
      Value<String> originalPath,
      Value<String> thumbnailPath,
      Value<int> width,
      Value<int> height,
      Value<String> contentHash,
      Value<int> rowid,
    });

final class $$MediaAssetsTableReferences
    extends BaseReferences<_$GalleryDatabase, $MediaAssetsTable, MediaAsset> {
  $$MediaAssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExhibitionsTable _exhibitionIdTable(_$GalleryDatabase db) => db
      .exhibitions
      .createAlias('media_assets__exhibition_id__exhibitions__id');

  $$ExhibitionsTableProcessedTableManager get exhibitionId {
    final $_column = $_itemColumn<String>('exhibition_id')!;

    final manager = $$ExhibitionsTableTableManager(
      $_db,
      $_db.exhibitions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exhibitionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlacementsTable, List<Placement>>
  _placementsRefsTable(_$GalleryDatabase db) => MultiTypedResultKey.fromTable(
    db.placements,
    aliasName: 'media_assets__id__placements__media_id',
  );

  $$PlacementsTableProcessedTableManager get placementsRefs {
    final manager = $$PlacementsTableTableManager(
      $_db,
      $_db.placements,
    ).filter((f) => f.mediaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_placementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MediaAssetsTableFilterComposer
    extends Composer<_$GalleryDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableFilterComposer({
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

  ColumnFilters<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  $$ExhibitionsTableFilterComposer get exhibitionId {
    final $$ExhibitionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exhibitionId,
      referencedTable: $db.exhibitions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExhibitionsTableFilterComposer(
            $db: $db,
            $table: $db.exhibitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> placementsRefs(
    Expression<bool> Function($$PlacementsTableFilterComposer f) f,
  ) {
    final $$PlacementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.placements,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacementsTableFilterComposer(
            $db: $db,
            $table: $db.placements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaAssetsTableOrderingComposer
    extends Composer<_$GalleryDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableOrderingComposer({
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

  ColumnOrderings<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExhibitionsTableOrderingComposer get exhibitionId {
    final $$ExhibitionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exhibitionId,
      referencedTable: $db.exhibitions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExhibitionsTableOrderingComposer(
            $db: $db,
            $table: $db.exhibitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaAssetsTableAnnotationComposer
    extends Composer<_$GalleryDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  $$ExhibitionsTableAnnotationComposer get exhibitionId {
    final $$ExhibitionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exhibitionId,
      referencedTable: $db.exhibitions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExhibitionsTableAnnotationComposer(
            $db: $db,
            $table: $db.exhibitions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> placementsRefs<T extends Object>(
    Expression<T> Function($$PlacementsTableAnnotationComposer a) f,
  ) {
    final $$PlacementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.placements,
      getReferencedColumn: (t) => t.mediaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacementsTableAnnotationComposer(
            $db: $db,
            $table: $db.placements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaAssetsTableTableManager
    extends
        RootTableManager<
          _$GalleryDatabase,
          $MediaAssetsTable,
          MediaAsset,
          $$MediaAssetsTableFilterComposer,
          $$MediaAssetsTableOrderingComposer,
          $$MediaAssetsTableAnnotationComposer,
          $$MediaAssetsTableCreateCompanionBuilder,
          $$MediaAssetsTableUpdateCompanionBuilder,
          (MediaAsset, $$MediaAssetsTableReferences),
          MediaAsset,
          PrefetchHooks Function({bool exhibitionId, bool placementsRefs})
        > {
  $$MediaAssetsTableTableManager(_$GalleryDatabase db, $MediaAssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> exhibitionId = const Value.absent(),
                Value<String> originalPath = const Value.absent(),
                Value<String> thumbnailPath = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaAssetsCompanion(
                id: id,
                exhibitionId: exhibitionId,
                originalPath: originalPath,
                thumbnailPath: thumbnailPath,
                width: width,
                height: height,
                contentHash: contentHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String exhibitionId,
                required String originalPath,
                required String thumbnailPath,
                required int width,
                required int height,
                required String contentHash,
                Value<int> rowid = const Value.absent(),
              }) => MediaAssetsCompanion.insert(
                id: id,
                exhibitionId: exhibitionId,
                originalPath: originalPath,
                thumbnailPath: thumbnailPath,
                width: width,
                height: height,
                contentHash: contentHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaAssetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({exhibitionId = false, placementsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (placementsRefs) db.placements],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (exhibitionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.exhibitionId,
                                    referencedTable:
                                        $$MediaAssetsTableReferences
                                            ._exhibitionIdTable(db),
                                    referencedColumn:
                                        $$MediaAssetsTableReferences
                                            ._exhibitionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (placementsRefs)
                        await $_getPrefetchedData<
                          MediaAsset,
                          $MediaAssetsTable,
                          Placement
                        >(
                          currentTable: table,
                          referencedTable: $$MediaAssetsTableReferences
                              ._placementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaAssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).placementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MediaAssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$GalleryDatabase,
      $MediaAssetsTable,
      MediaAsset,
      $$MediaAssetsTableFilterComposer,
      $$MediaAssetsTableOrderingComposer,
      $$MediaAssetsTableAnnotationComposer,
      $$MediaAssetsTableCreateCompanionBuilder,
      $$MediaAssetsTableUpdateCompanionBuilder,
      (MediaAsset, $$MediaAssetsTableReferences),
      MediaAsset,
      PrefetchHooks Function({bool exhibitionId, bool placementsRefs})
    >;
typedef $$PlacementsTableCreateCompanionBuilder =
    PlacementsCompanion Function({
      required String id,
      required String chapterId,
      required String mediaId,
      required int sortOrder,
      required String size,
      required String frame,
      required double focalX,
      required double focalY,
      required double zoom,
      Value<double> scale,
      Value<double> offsetX,
      Value<double> offsetY,
      Value<double> rotation,
      required String caption,
      Value<String> frameCaption,
      Value<int> rowid,
    });
typedef $$PlacementsTableUpdateCompanionBuilder =
    PlacementsCompanion Function({
      Value<String> id,
      Value<String> chapterId,
      Value<String> mediaId,
      Value<int> sortOrder,
      Value<String> size,
      Value<String> frame,
      Value<double> focalX,
      Value<double> focalY,
      Value<double> zoom,
      Value<double> scale,
      Value<double> offsetX,
      Value<double> offsetY,
      Value<double> rotation,
      Value<String> caption,
      Value<String> frameCaption,
      Value<int> rowid,
    });

final class $$PlacementsTableReferences
    extends BaseReferences<_$GalleryDatabase, $PlacementsTable, Placement> {
  $$PlacementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChaptersTable _chapterIdTable(_$GalleryDatabase db) =>
      db.chapters.createAlias('placements__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<String>('chapter_id')!;

    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MediaAssetsTable _mediaIdTable(_$GalleryDatabase db) =>
      db.mediaAssets.createAlias('placements__media_id__media_assets__id');

  $$MediaAssetsTableProcessedTableManager get mediaId {
    final $_column = $_itemColumn<String>('media_id')!;

    final manager = $$MediaAssetsTableTableManager(
      $_db,
      $_db.mediaAssets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlacementsTableFilterComposer
    extends Composer<_$GalleryDatabase, $PlacementsTable> {
  $$PlacementsTableFilterComposer({
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

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frame => $composableBuilder(
    column: $table.frame,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get focalX => $composableBuilder(
    column: $table.focalX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get focalY => $composableBuilder(
    column: $table.focalY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get zoom => $composableBuilder(
    column: $table.zoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get offsetX => $composableBuilder(
    column: $table.offsetX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get offsetY => $composableBuilder(
    column: $table.offsetY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frameCaption => $composableBuilder(
    column: $table.frameCaption,
    builder: (column) => ColumnFilters(column),
  );

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaAssetsTableFilterComposer get mediaId {
    final $$MediaAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableFilterComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacementsTableOrderingComposer
    extends Composer<_$GalleryDatabase, $PlacementsTable> {
  $$PlacementsTableOrderingComposer({
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

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frame => $composableBuilder(
    column: $table.frame,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get focalX => $composableBuilder(
    column: $table.focalX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get focalY => $composableBuilder(
    column: $table.focalY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zoom => $composableBuilder(
    column: $table.zoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get offsetX => $composableBuilder(
    column: $table.offsetX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get offsetY => $composableBuilder(
    column: $table.offsetY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frameCaption => $composableBuilder(
    column: $table.frameCaption,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaAssetsTableOrderingComposer get mediaId {
    final $$MediaAssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableOrderingComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacementsTableAnnotationComposer
    extends Composer<_$GalleryDatabase, $PlacementsTable> {
  $$PlacementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get frame =>
      $composableBuilder(column: $table.frame, builder: (column) => column);

  GeneratedColumn<double> get focalX =>
      $composableBuilder(column: $table.focalX, builder: (column) => column);

  GeneratedColumn<double> get focalY =>
      $composableBuilder(column: $table.focalY, builder: (column) => column);

  GeneratedColumn<double> get zoom =>
      $composableBuilder(column: $table.zoom, builder: (column) => column);

  GeneratedColumn<double> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<double> get offsetX =>
      $composableBuilder(column: $table.offsetX, builder: (column) => column);

  GeneratedColumn<double> get offsetY =>
      $composableBuilder(column: $table.offsetY, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<String> get frameCaption => $composableBuilder(
    column: $table.frameCaption,
    builder: (column) => column,
  );

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaAssetsTableAnnotationComposer get mediaId {
    final $$MediaAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaId,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacementsTableTableManager
    extends
        RootTableManager<
          _$GalleryDatabase,
          $PlacementsTable,
          Placement,
          $$PlacementsTableFilterComposer,
          $$PlacementsTableOrderingComposer,
          $$PlacementsTableAnnotationComposer,
          $$PlacementsTableCreateCompanionBuilder,
          $$PlacementsTableUpdateCompanionBuilder,
          (Placement, $$PlacementsTableReferences),
          Placement,
          PrefetchHooks Function({bool chapterId, bool mediaId})
        > {
  $$PlacementsTableTableManager(_$GalleryDatabase db, $PlacementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> chapterId = const Value.absent(),
                Value<String> mediaId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> size = const Value.absent(),
                Value<String> frame = const Value.absent(),
                Value<double> focalX = const Value.absent(),
                Value<double> focalY = const Value.absent(),
                Value<double> zoom = const Value.absent(),
                Value<double> scale = const Value.absent(),
                Value<double> offsetX = const Value.absent(),
                Value<double> offsetY = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<String> caption = const Value.absent(),
                Value<String> frameCaption = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlacementsCompanion(
                id: id,
                chapterId: chapterId,
                mediaId: mediaId,
                sortOrder: sortOrder,
                size: size,
                frame: frame,
                focalX: focalX,
                focalY: focalY,
                zoom: zoom,
                scale: scale,
                offsetX: offsetX,
                offsetY: offsetY,
                rotation: rotation,
                caption: caption,
                frameCaption: frameCaption,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String chapterId,
                required String mediaId,
                required int sortOrder,
                required String size,
                required String frame,
                required double focalX,
                required double focalY,
                required double zoom,
                Value<double> scale = const Value.absent(),
                Value<double> offsetX = const Value.absent(),
                Value<double> offsetY = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                required String caption,
                Value<String> frameCaption = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlacementsCompanion.insert(
                id: id,
                chapterId: chapterId,
                mediaId: mediaId,
                sortOrder: sortOrder,
                size: size,
                frame: frame,
                focalX: focalX,
                focalY: focalY,
                zoom: zoom,
                scale: scale,
                offsetX: offsetX,
                offsetY: offsetY,
                rotation: rotation,
                caption: caption,
                frameCaption: frameCaption,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlacementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chapterId = false, mediaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (chapterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.chapterId,
                                referencedTable: $$PlacementsTableReferences
                                    ._chapterIdTable(db),
                                referencedColumn: $$PlacementsTableReferences
                                    ._chapterIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (mediaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.mediaId,
                                referencedTable: $$PlacementsTableReferences
                                    ._mediaIdTable(db),
                                referencedColumn: $$PlacementsTableReferences
                                    ._mediaIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlacementsTableProcessedTableManager =
    ProcessedTableManager<
      _$GalleryDatabase,
      $PlacementsTable,
      Placement,
      $$PlacementsTableFilterComposer,
      $$PlacementsTableOrderingComposer,
      $$PlacementsTableAnnotationComposer,
      $$PlacementsTableCreateCompanionBuilder,
      $$PlacementsTableUpdateCompanionBuilder,
      (Placement, $$PlacementsTableReferences),
      Placement,
      PrefetchHooks Function({bool chapterId, bool mediaId})
    >;

class $GalleryDatabaseManager {
  final _$GalleryDatabase _db;
  $GalleryDatabaseManager(this._db);
  $$ExhibitionCategoriesTableTableManager get exhibitionCategories =>
      $$ExhibitionCategoriesTableTableManager(_db, _db.exhibitionCategories);
  $$AppSettingsRowsTableTableManager get appSettingsRows =>
      $$AppSettingsRowsTableTableManager(_db, _db.appSettingsRows);
  $$ExhibitionsTableTableManager get exhibitions =>
      $$ExhibitionsTableTableManager(_db, _db.exhibitions);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$MediaAssetsTableTableManager get mediaAssets =>
      $$MediaAssetsTableTableManager(_db, _db.mediaAssets);
  $$PlacementsTableTableManager get placements =>
      $$PlacementsTableTableManager(_db, _db.placements);
}
