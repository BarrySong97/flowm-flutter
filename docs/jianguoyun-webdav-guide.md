# 坚果云 WebDAV 路径配置指南

## 常见的坚果云 WebDAV 路径问题

坚果云的 WebDAV 服务有一些特殊的路径要求：

### 1. 基本 URL
```
https://dav.jianguoyun.com/dav/
```

### 2. 可能的工作路径

根据坚果云的文档和用户反馈，以下路径通常可以工作：

#### 选项 1: 根目录下的文件夹
```
flowm-app/flowm_database.sqlite
```

#### 选项 2: 在 "我的坚果云" 下创建文件夹
```
apps/flowm/flowm_database.sqlite
```

#### 选项 3: 直接在同步文件夹根目录
```
flowm_database.sqlite
```

### 3. 修改建议

在 `database_sync_service.dart` 中尝试这些路径：

```dart
String get _remoteDatabasePath {
  // 选项1：应用文件夹（推荐）
  return 'flowm-app/$_databaseFileName';
  
  // 选项2：apps目录
  // return 'apps/flowm/$_databaseFileName';
  
  // 选项3：根目录
  // return _databaseFileName;
}
```

### 4. 坚果云 WebDAV 特性

- ✅ 支持创建目录 (MKCOL)
- ✅ 支持文件上传 (PUT)
- ✅ 支持文件下载 (GET)
- ✅ 支持属性查询 (PROPFIND)
- ⚠️ 根目录可能有写入限制
- ⚠️ 需要正确的第三方应用密码

### 5. 调试步骤

1. 确认使用第三方应用密码
2. 测试连接是否成功
3. 尝试创建测试目录
4. 尝试上传小文件
5. 检查文件是否出现在坚果云网页端

### 6. 网页端验证

上传成功后，文件应该出现在：
- 坚果云网页版
- 对应的同步文件夹路径
- 手机/桌面客户端

如果文件没有出现，说明路径配置有问题。