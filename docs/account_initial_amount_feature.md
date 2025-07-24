# 账户创建时添加初始金额功能设计文档

## 1. 需求概述

在账户创建时，允许用户为资产和负债账户设置初始金额，系统自动生成符合复式记账原则的会计分录。

## 2. 业务场景

### 2.1 适用账户类型
- **资产账户**：银行存款、现金、支付宝、微信支付等
- **负债账户**：信用卡、花呗、白条、房贷等

### 2.2 不适用账户类型
- **收入账户**：收入类别不需要初始金额
- **支出账户**：支出类别不需要初始金额  
- **权益账户**：权益账户通常作为平衡方使用

## 3. 复式记账逻辑

### 3.1 资产账户初始金额
```
借：新建资产账户    1000.00
贷：期初余额        1000.00
```

### 3.2 负债账户初始金额
```
借：期初余额        5000.00
贷：新建负债账户    5000.00
```

### 3.3 期初余额账户
使用现有的"期初余额"权益账户（AccountType.EQUITY）作为对手方，该账户在系统初始化时已创建。

## 4. 技术实现方案

### 4.1 UI层修改

#### 4.1.1 文件：`lib/components/common/account_creation_bottom_sheet.dart`

**新增字段：**
```dart
final _initialAmountController = TextEditingController();
bool _hasInitialAmount = false;
```

**新增UI组件：**
- 初始金额开关
- 金额输入框（支持数字键盘）
- 金额格式化显示

**显示逻辑：**
- 仅在选择资产或负债账户类型时显示
- 其他账户类型隐藏初始金额选项

### 4.2 业务逻辑层修改

#### 4.2.1 文件：`lib/state/account/account_repository.dart`

**扩展方法签名：**
```dart
Future<void> addNewAccountWithInitialAmount({
  required String name,
  required AccountType type,
  required int ledgerId,
  int? parentId,
  double? initialAmount,  // 新增参数
}) async
```

**实现逻辑：**
1. 创建账户
2. 如果有初始金额，创建期初余额交易
3. 使用数据库事务确保原子性

#### 4.2.2 获取期初余额账户

**新增方法：**
```dart
Future<Account?> getOpeningBalanceAccount(int ledgerId) async {
  return await _accountDao.getAccountByNameAndType(
    ledgerId: ledgerId,
    name: '期初余额',
    type: AccountType.EQUITY,
  );
}
```

### 4.3 交易创建逻辑

**使用现有的TransactionRepository：**
```dart
await ref.read(transactionRepositoryProvider).createTransactionWithPostings(
  fromAccountId: type == AccountType.ASSET 
    ? openingBalanceAccount.id 
    : newAccount.id,
  toAccountId: type == AccountType.ASSET 
    ? newAccount.id 
    : openingBalanceAccount.id,
  amount: initialAmount,
  transactionDate: DateTime.now(),
  description: '账户期初余额 - ${accountName}',
);
```

## 5. 数据流程

### 5.1 创建资产账户（有初始金额）
```
1. 用户输入账户名称："招商银行储蓄卡"
2. 选择账户类型：资产
3. 输入初始金额：10000.00
4. 系统执行：
   - 创建账户记录
   - 创建Transaction记录
   - 创建两条Posting记录：
     * 招商银行储蓄卡 +10000.00
     * 期初余额 -10000.00
```

### 5.2 创建负债账户（有初始金额）
```
1. 用户输入账户名称："招商银行信用卡"
2. 选择账户类型：负债
3. 输入初始金额：5000.00（已使用额度）
4. 系统执行：
   - 创建账户记录
   - 创建Transaction记录
   - 创建两条Posting记录：
     * 期初余额 +5000.00
     * 招商银行信用卡 -5000.00
```

## 6. 用户界面设计

### 6.1 初始金额输入区域
```
┌─────────────────────────────────────────┐
│ □ 设置初始金额                           │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ ¥ 0.00                              │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 💡 设置此账户的当前余额                  │
└─────────────────────────────────────────┘
```

### 6.2 交互逻辑
- 默认初始金额开关关闭
- 开启时显示金额输入框
- 支持数字键盘输入
- 自动格式化为货币格式
- 账户类型切换时重置状态

## 7. 错误处理

### 7.1 验证规则
- 初始金额必须大于0
- 初始金额不能超过合理范围（如1,000,000,000）
- 期初余额账户必须存在

### 7.2 异常情况
- 找不到期初余额账户时提示错误
- 数据库操作失败时回滚事务
- 网络异常时保留用户输入

## 8. 系统账户保护机制

### 8.1 期初余额账户保护
为确保复式记账系统的完整性，需要对"期初余额"权益账户实施保护措施：

#### 8.1.1 删除保护
- **保护对象**：名称为"期初余额"或"Opening Balance"的权益账户
- **保护机制**：在账户删除时进行检查，如果是期初余额账户则禁止删除
- **错误类型**：新增 `DeleteAccountResult.isSystemAccount` 枚举值

#### 8.1.2 实现逻辑
```dart
// 在 deleteAccount 方法中添加检查
if (account.accountType == AccountType.EQUITY && 
    (account.accountName == '期初余额' || account.accountName == 'Opening Balance')) {
  return DeleteAccountResult.isSystemAccount;
}
```

#### 8.1.3 用户提示
- **中文提示**：无法删除系统账户"期初余额"，该账户用于维护复式记账平衡
- **英文提示**：Cannot delete system account "Opening Balance", this account is required for double-entry bookkeeping

### 8.2 编辑保护（可选）
考虑是否需要限制对期初余额账户的编辑操作：
- 禁止修改账户名称
- 禁止修改账户类型
- 允许修改其他属性（如显示状态）

## 9. 测试场景

### 9.1 功能测试
- 创建资产账户（有/无初始金额）
- 创建负债账户（有/无初始金额）  
- 创建其他类型账户（不显示初始金额选项）
- 金额输入验证和格式化

### 9.2 数据一致性测试
- 验证生成的交易记录正确性
- 验证借贷平衡
- 验证账户余额计算正确

### 9.3 边界测试
- 零金额处理
- 超大金额处理
- 期初余额账户不存在的情况

### 9.4 系统保护测试
- 尝试删除期初余额账户（应被阻止）
- 验证删除保护的错误提示
- 测试有交易记录的期初余额账户删除保护

## 10. 后续优化

### 10.1 功能扩展
- 支持多币种初始金额
- 批量导入账户和初始金额
- 初始金额的审计日志

### 10.2 用户体验
- 添加金额计算器
- 支持语音输入金额
- 智能金额建议

### 10.3 安全性增强
- 更多系统账户保护（如个人资本等权益账户）
- 账户操作日志记录
- 数据完整性验证

## 11. 实现优先级

### 11.1 P0（必须实现）
- 基础的初始金额输入和保存
- 正确的复式记账逻辑
- 期初余额账户删除保护
- 基本的错误处理

### 11.2 P1（建议实现）
- 金额格式化和验证
- 用户界面优化
- 完整的测试覆盖
- 系统账户编辑保护

### 11.3 P2（未来考虑）
- 高级功能和优化项
- 多币种支持
- 批量操作功能
- 更完善的系统账户保护机制

## 12. 代码变更清单

### 12.1 核心功能文件
- `lib/components/common/account_creation_bottom_sheet.dart` - 添加初始金额输入
- `lib/state/account/account_repository.dart` - 扩展账户创建方法，添加删除保护
- `lib/state/transaction/transaction_repository.dart` - 复用现有交易创建逻辑

### 12.2 数据模型文件
- `lib/state/account/account_repository.dart` - 扩展 `DeleteAccountResult` 枚举

### 12.3 UI处理文件
- `lib/components/common/account_update_bottom_sheet.dart` - 更新删除错误处理

### 12.4 测试文件
- 添加初始金额功能的单元测试
- 添加系统账户保护的测试用例