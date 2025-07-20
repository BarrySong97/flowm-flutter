import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制到剪贴板: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      appBar: AppBar(
        title: const Text(
          '开发者',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color(0xFFF5F6FB),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            spacing: 20,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.0),
                        child: Image.asset(
                          'assets/icon.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '4RE△L Studio',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '专注于创造优质的应用体验',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // About Us Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '关于我们',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '4RE△L Studio',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Flowm 是一款专注于个人财务管理的应用程序，采用复式记账原理帮助用户更好地管理资产、负债、收入和支出。我们致力于为用户提供简洁、高效的财务管理体验。',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),

              // Social Media Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '社交媒体账户',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Twitter
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Twitter'),
                      subtitle: const Text('@4realstudio'),
                      trailing: const Icon(Icons.copy),
                      onTap: () => _copyToClipboard(context, '@4realstudio'),
                    ),

                    const SizedBox(height: 16),

                    // 小红书
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('小红书'),
                      subtitle: const Text('4RE△L Studio'),
                      trailing: const Icon(Icons.copy),
                      onTap: () => _copyToClipboard(context, '4RE△L Studio'),
                    ),
                  ],
                ),
              ),

              // Contact Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '联系我们',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '如果您有任何问题、建议或反馈，欢迎通过以下方式联系我们。我们很乐意听到您的声音！',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('邮箱'),
                      subtitle: const Text('contact@4realstudio.com'),
                      trailing: const Icon(Icons.copy),
                      onTap: () =>
                          _copyToClipboard(context, 'contact@4realstudio.com'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
