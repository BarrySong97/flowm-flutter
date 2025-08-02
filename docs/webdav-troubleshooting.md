# WebDAV 同步常见问题解决方案

## 1. HTTP 409 错误：父目录不存在

### 问题描述
错误信息：`HTTP 409 - AncestorsNotFound: The ancestors of this location does not found`

这是坚果云等 WebDAV 服务器的常见问题。当尝试上传文件到不存在的目录时会出现此错误。

### 解决方案
系统已自动实现目录创建机制：

1. **自动检测**：在上传文件前自动检查父目录
2. **逐级创建**：使用 MKCOL 方法逐级创建所需目录
3. **智能重试**：忽略已存在目录的错误，继续创建流程

### 技术实现
```dart
// 上传前确保目录存在
await ensureDirectoryExists(remotePath);

// 逐级创建目录结构
Future<void> ensureDirectoryExists(String remotePath) async {
  final pathSegments = remotePath.split('/');
  String currentPath = '';
  for (int i = 0; i < pathSegments.length - 1; i++) {
    if (pathSegments[i].isNotEmpty) {
      currentPath += '/${pathSegments[i]}';
      try {
        await createDirectory(currentPath.substring(1));
      } catch (e) {
        // 忽略已存在的目录
      }
    }
  }
}
```

## 2. 其他常见 WebDAV 错误

### 401 Unauthorized
- **原因**：用户名或密码错误
- **解决**：检查 WebDAV 配置中的认证信息

### 403 Forbidden  
- **原因**：权限不足或服务器禁止操作
- **解决**：确认用户有读写权限，或联系服务器管理员

### 404 Not Found
- **原因**：文件或目录不存在
- **处理**：系统自动返回 null，表示文件不存在

### 405 Method Not Allowed
- **原因**：服务器不支持某种 HTTP 方法
- **解决**：系统使用多种备用方法（如用 OPTIONS 替代 HEAD）

### 507 Insufficient Storage
- **原因**：服务器存储空间不足
- **解决**：清理服务器空间或联系服务提供商

## 3. 网络相关错误

### 连接超时
- **设置**：所有请求都有 30 秒超时限制
- **建议**：在稳定网络环境下进行同步

### DNS 解析失败
- **检查**：确认 WebDAV URL 正确且可访问
- **测试**：使用连接测试功能验证配置

## 4. 坚果云特定问题

### 应用专用密码
坚果云需要为第三方应用生成专用密码：

1. 登录坚果云网页版
2. 进入"账户信息" → "安全选项" 
3. 生成"第三方应用密码"
4. 在应用中使用此密码而非登录密码

### URL 格式
坚果云 WebDAV 地址格式：
```
https://dav.jianguoyun.com/dav/
```

### 文件路径
- 根目录对应坚果云的"同步文件夹"
- 建议在根目录下创建专用文件夹存放数据库文件

## 5. 故障排除步骤

1. **测试连接**：使用"测试连接"功能验证基本配置
2. **检查权限**：确认用户有读写权限
3. **验证路径**：确保 WebDAV URL 和文件路径正确
4. **网络检查**：确认网络连接稳定
5. **查看错误**：查看详细错误信息确定具体问题

## 6. 最佳实践

- **稳定网络**：在 WiFi 环境下进行同步操作
- **定期备份**：系统会自动创建本地备份
- **小文件优先**：数据库文件通常较小，传输速度快
- **错误重试**：遇到网络错误时可以重试操作

---

*如果遇到其他问题，请检查 WebDAV 服务器的日志或联系服务提供商获取支持。*