// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $QuotesTable extends Quotes with TableInfo<$QuotesTable, Quote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<QuoteCategory, int> category =
      GeneratedColumn<int>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<QuoteCategory>($QuotesTable.$convertercategory);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    author,
    source,
    category,
    tags,
    isFavorite,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quotes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Quote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Quote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Quote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      category: $QuotesTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QuotesTable createAlias(String alias) {
    return $QuotesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<QuoteCategory, int, int> $convertercategory =
      const EnumIndexConverter<QuoteCategory>(QuoteCategory.values);
}

class Quote extends DataClass implements Insertable<Quote> {
  final int id;
  final String content;
  final String author;
  final String? source;
  final QuoteCategory category;
  final String tags;
  final bool isFavorite;
  final DateTime createdAt;
  const Quote({
    required this.id,
    required this.content,
    required this.author,
    this.source,
    required this.category,
    required this.tags,
    required this.isFavorite,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['author'] = Variable<String>(author);
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    {
      map['category'] = Variable<int>(
        $QuotesTable.$convertercategory.toSql(category),
      );
    }
    map['tags'] = Variable<String>(tags);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QuotesCompanion toCompanion(bool nullToAbsent) {
    return QuotesCompanion(
      id: Value(id),
      content: Value(content),
      author: Value(author),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      category: Value(category),
      tags: Value(tags),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
    );
  }

  factory Quote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Quote(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      author: serializer.fromJson<String>(json['author']),
      source: serializer.fromJson<String?>(json['source']),
      category: $QuotesTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      tags: serializer.fromJson<String>(json['tags']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'author': serializer.toJson<String>(author),
      'source': serializer.toJson<String?>(source),
      'category': serializer.toJson<int>(
        $QuotesTable.$convertercategory.toJson(category),
      ),
      'tags': serializer.toJson<String>(tags),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Quote copyWith({
    int? id,
    String? content,
    String? author,
    Value<String?> source = const Value.absent(),
    QuoteCategory? category,
    String? tags,
    bool? isFavorite,
    DateTime? createdAt,
  }) => Quote(
    id: id ?? this.id,
    content: content ?? this.content,
    author: author ?? this.author,
    source: source.present ? source.value : this.source,
    category: category ?? this.category,
    tags: tags ?? this.tags,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt ?? this.createdAt,
  );
  Quote copyWithCompanion(QuotesCompanion data) {
    return Quote(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      author: data.author.present ? data.author.value : this.author,
      source: data.source.present ? data.source.value : this.source,
      category: data.category.present ? data.category.value : this.category,
      tags: data.tags.present ? data.tags.value : this.tags,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Quote(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('author: $author, ')
          ..write('source: $source, ')
          ..write('category: $category, ')
          ..write('tags: $tags, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    content,
    author,
    source,
    category,
    tags,
    isFavorite,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Quote &&
          other.id == this.id &&
          other.content == this.content &&
          other.author == this.author &&
          other.source == this.source &&
          other.category == this.category &&
          other.tags == this.tags &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt);
}

class QuotesCompanion extends UpdateCompanion<Quote> {
  final Value<int> id;
  final Value<String> content;
  final Value<String> author;
  final Value<String?> source;
  final Value<QuoteCategory> category;
  final Value<String> tags;
  final Value<bool> isFavorite;
  final Value<DateTime> createdAt;
  const QuotesCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.author = const Value.absent(),
    this.source = const Value.absent(),
    this.category = const Value.absent(),
    this.tags = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  QuotesCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    required String author,
    this.source = const Value.absent(),
    required QuoteCategory category,
    this.tags = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : content = Value(content),
       author = Value(author),
       category = Value(category);
  static Insertable<Quote> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<String>? author,
    Expression<String>? source,
    Expression<int>? category,
    Expression<String>? tags,
    Expression<bool>? isFavorite,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (author != null) 'author': author,
      if (source != null) 'source': source,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  QuotesCompanion copyWith({
    Value<int>? id,
    Value<String>? content,
    Value<String>? author,
    Value<String?>? source,
    Value<QuoteCategory>? category,
    Value<String>? tags,
    Value<bool>? isFavorite,
    Value<DateTime>? createdAt,
  }) {
    return QuotesCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      source: source ?? this.source,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $QuotesTable.$convertercategory.toSql(category.value),
      );
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuotesCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('author: $author, ')
          ..write('source: $source, ')
          ..write('category: $category, ')
          ..write('tags: $tags, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuotesTable quotes = $QuotesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [quotes];
}

typedef $$QuotesTableCreateCompanionBuilder =
    QuotesCompanion Function({
      Value<int> id,
      required String content,
      required String author,
      Value<String?> source,
      required QuoteCategory category,
      Value<String> tags,
      Value<bool> isFavorite,
      Value<DateTime> createdAt,
    });
typedef $$QuotesTableUpdateCompanionBuilder =
    QuotesCompanion Function({
      Value<int> id,
      Value<String> content,
      Value<String> author,
      Value<String?> source,
      Value<QuoteCategory> category,
      Value<String> tags,
      Value<bool> isFavorite,
      Value<DateTime> createdAt,
    });

class $$QuotesTableFilterComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<QuoteCategory, QuoteCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuotesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuotesTable> {
  $$QuotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumnWithTypeConverter<QuoteCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QuotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuotesTable,
          Quote,
          $$QuotesTableFilterComposer,
          $$QuotesTableOrderingComposer,
          $$QuotesTableAnnotationComposer,
          $$QuotesTableCreateCompanionBuilder,
          $$QuotesTableUpdateCompanionBuilder,
          (Quote, BaseReferences<_$AppDatabase, $QuotesTable, Quote>),
          Quote,
          PrefetchHooks Function()
        > {
  $$QuotesTableTableManager(_$AppDatabase db, $QuotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<QuoteCategory> category = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => QuotesCompanion(
                id: id,
                content: content,
                author: author,
                source: source,
                category: category,
                tags: tags,
                isFavorite: isFavorite,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String content,
                required String author,
                Value<String?> source = const Value.absent(),
                required QuoteCategory category,
                Value<String> tags = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => QuotesCompanion.insert(
                id: id,
                content: content,
                author: author,
                source: source,
                category: category,
                tags: tags,
                isFavorite: isFavorite,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuotesTable,
      Quote,
      $$QuotesTableFilterComposer,
      $$QuotesTableOrderingComposer,
      $$QuotesTableAnnotationComposer,
      $$QuotesTableCreateCompanionBuilder,
      $$QuotesTableUpdateCompanionBuilder,
      (Quote, BaseReferences<_$AppDatabase, $QuotesTable, Quote>),
      Quote,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuotesTableTableManager get quotes =>
      $$QuotesTableTableManager(_db, _db.quotes);
}
