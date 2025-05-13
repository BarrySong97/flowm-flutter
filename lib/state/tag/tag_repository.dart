import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../db/app_database.dart';
import '../../db/dao/tag_dao.dart';
import '../database/database_provider.dart';

/// 标签仓库提供者，用于封装标签相关的数据库操作
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final tagDao = ref.watch(tagDaoProvider);
  return TagRepository(tagDao);
});

/// 标签仓库类
///
/// 封装与标签相关的所有数据库操作，提供更高级别的业务逻辑方法
class TagRepository {
  final TagDao _tagDao;

  TagRepository(this._tagDao);

  /// 获取所有标签
  Future<List<Tag>> getAllTags() => _tagDao.getAllTags();

  /// 获取标签详情
  Future<Tag?> getTagById(int id) => _tagDao.getTagById(id);

  /// 监听所有标签（响应式流）
  Stream<List<Tag>> watchAllTags() => _tagDao.watchAllTags();

  /// 创建新标签
  Future<int> createTag({
    required String name,
    String? displayColor,
  }) {
    return _tagDao.insertTag(TagsCompanion.insert(
      tagName: name,
      displayColor: Value(displayColor),
    ));
  }

  /// 更新标签
  Future<bool> updateTag({
    required int id,
    String? name,
    String? displayColor,
  }) {
    return _tagDao.updateTag(TagsCompanion(
      tagId: Value(id),
      tagName: name != null ? Value(name) : const Value.absent(),
      displayColor:
          displayColor != null ? Value(displayColor) : const Value.absent(),
    ));
  }

  /// 删除标签
  Future<int> deleteTag(int id) => _tagDao.deleteTag(id);

  /// 检查标签名是否已存在
  Future<bool> isTagNameExists(String name) async {
    final tags = await getAllTags();
    return tags.any((tag) => tag.tagName.toLowerCase() == name.toLowerCase());
  }

  /// 根据名称查找标签（不区分大小写）
  Future<Tag?> findTagByName(String name) async {
    final tags = await getAllTags();
    try {
      return tags
          .firstWhere((tag) => tag.tagName.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  /// 获取或创建标签
  /// 如果标签已存在，则返回现有标签的ID，否则创建新标签并返回其ID
  Future<int> getOrCreateTag(String name, {String? displayColor}) async {
    final existingTag = await findTagByName(name);
    if (existingTag != null) {
      return existingTag.tagId;
    } else {
      return createTag(name: name, displayColor: displayColor);
    }
  }
}
