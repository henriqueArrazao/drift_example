import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'schema.g.dart';

class Todo extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Todo])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  static String fileName = 'db.sqlite';

  static Future<Directory> databaseDirectory() async {
    return getApplicationDocumentsDirectory();
  }

  Stream<List<TodoData>> watchAllTodos() {
    return select(todo).watch();
  }

  @override
  int get schemaVersion => 1;
}

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final directory = await AppDatabase.databaseDirectory();
    return NativeDatabase(File(p.join(directory.path, AppDatabase.fileName)));
  });
}
