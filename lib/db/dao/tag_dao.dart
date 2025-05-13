import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tag_table.dart';

part 'tag_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(AppDatabase db) : super(db);

  // Get all tags
  Future<List<Tag>> getAllTags() => select(tags).get();

  // Get tag by ID
  Future<Tag?> getTagById(int id) =>
      (select(tags)..where((t) => t.tagId.equals(id))).getSingleOrNull();

  // Watch all tags (reactive stream)
  Stream<List<Tag>> watchAllTags() => select(tags).watch();

  // Insert tag
  Future<int> insertTag(TagsCompanion tag) => into(tags).insert(tag);

  // Update tag
  Future<bool> updateTag(TagsCompanion tag) => update(tags).replace(tag);

  // Delete tag
  Future<int> deleteTag(int id) =>
      (delete(tags)..where((t) => t.tagId.equals(id))).go();
}
