import 'package:flutter/material.dart';

class AccountTransactionGuideScreen extends StatelessWidget {
  const AccountTransactionGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '记账指南',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('常见交易类型'),
            const SizedBox(height: 16),
            _buildCommonTransactionsCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('不常见交易说明'),
            const SizedBox(height: 16),
            _buildUncommonTransactionsCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('应避免的交易组合'),
            const SizedBox(height: 16),
            _buildAbnormalTransactionsCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('加减号显示规则'),
            const SizedBox(height: 16),
            _buildSignRulesCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildCommonTransactionsCard() {
    final commonTransactions = [
      _TransactionExample(
          '日常消费', '资产 → 费用', '银行存款 → 餐饮费用', '用银行卡支付餐费', Colors.green),
      _TransactionExample(
          '收入入账', '收入 → 资产', '工资收入 → 银行存款', '工资到账', Colors.green),
      _TransactionExample(
          '信用卡消费', '负债 → 费用', '信用卡 → 购物费用', '用信用卡购物', Colors.green),
      _TransactionExample(
          '还信用卡', '资产 → 负债', '银行存款 → 信用卡', '用储蓄卡还信用卡', Colors.green),
      _TransactionExample(
          '资产转移', '资产 → 资产', '现金 → 银行存款', '现金存入银行', Colors.green),
      _TransactionExample(
          '借款入账', '负债 → 资产', '借款 → 银行存款', '借到的钱到账', Colors.green),
    ];

    return _buildTransactionExamplesCard(commonTransactions);
  }

  Widget _buildUncommonTransactionsCard() {
    final uncommonTransactions = [
      _TransactionExample(
          '投资增资', '资产 → 权益', '银行存款 → 股票投资', '用存款买股票', Colors.orange),
      _TransactionExample(
          '提取投资', '权益 → 资产', '股票投资 → 银行存款', '卖股票获得现金', Colors.orange),
      _TransactionExample(
          '债务转移', '负债 → 负债', '信用卡A → 信用卡B', '用信用卡A还信用卡B', Colors.orange),
      _TransactionExample(
          '收入还债', '收入 → 负债', '工资收入 → 信用卡', '工资直接还信用卡', Colors.orange),
      _TransactionExample(
          '费用退款', '费用 → 资产', '餐饮费用 → 银行存款', '餐费退款到账', Colors.orange),
    ];

    return _buildTransactionExamplesCard(uncommonTransactions);
  }

  Widget _buildAbnormalTransactionsCard() {
    final abnormalTransactions = [
      _TransactionExample(
          '异常组合', '资产 → 收入', '银行存款 → 工资收入', '资产不会转入收入账户', Colors.red),
      _TransactionExample(
          '异常组合', '收入 → 费用', '工资收入 → 餐饮费用', '应该是资产支付费用', Colors.red),
      _TransactionExample(
          '异常组合', '权益 → 费用', '个人投资 → 购物费用', '权益不会直接支付费用', Colors.red),
      _TransactionExample(
          '异常组合', '费用 → 负债', '餐饮费用 → 信用卡', '费用不会转入债务', Colors.red),
      _TransactionExample(
          '异常组合', '收入 → 收入', '工资收入 → 奖金收入', '收入账户内部转移不合理', Colors.red),
    ];

    return _buildTransactionExamplesCard(abnormalTransactions);
  }

  Widget _buildTransactionExamplesCard(List<_TransactionExample> examples) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: examples.map((example) {
          final isLast = examples.indexOf(example) == examples.length - 1;
          return Column(
            children: [
              _buildTransactionExampleItem(example),
              if (!isLast) const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionExampleItem(_TransactionExample example) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                example.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(example.color),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  example.pattern,
                  style: TextStyle(
                    fontSize: 12,
                    color: example.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            example.example,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            example.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignRulesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flowm采用余额变化显示规则：',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildSignRuleItem('+ 加号', '表示该账户余额增加', Colors.green),
          _buildSignRuleItem('- 减号', '表示该账户余额减少', Colors.red),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Colors.blue.shade600, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      '举例说明',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '银行存款（-100元）→ 餐饮费用（+100元）\n这表示银行存款减少了100元，餐饮费用增加了100元',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignRuleItem(String sign, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                sign.substring(0, 1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sign,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(Color color) {
    if (color == Colors.green) return Colors.green.shade50;
    if (color == Colors.orange) return Colors.orange.shade50;
    if (color == Colors.red) return Colors.red.shade50;
    return Colors.grey.shade50;
  }
}

class _TransactionExample {
  final String title;
  final String pattern;
  final String example;
  final String description;
  final Color color;

  _TransactionExample(
      this.title, this.pattern, this.example, this.description, this.color);
}
