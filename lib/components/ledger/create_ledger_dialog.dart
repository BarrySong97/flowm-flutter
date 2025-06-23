import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/ledger/ledger_repository.dart';
import '../../db/app_database.dart' as db;

class CreateLedgerDialog extends ConsumerStatefulWidget {
  final db.Ledger? ledger;

  const CreateLedgerDialog({super.key, this.ledger});

  @override
  ConsumerState<CreateLedgerDialog> createState() => _CreateLedgerDialogState();
}

class _CreateLedgerDialogState extends ConsumerState<CreateLedgerDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _currencySymbolController = TextEditingController();

  bool get _isEditMode => widget.ledger != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.ledger!.name;
      _descriptionController.text = widget.ledger!.description ?? '';
      _currencySymbolController.text = widget.ledger!.currencySymbol ?? '¥';
    } else {
      _currencySymbolController.text = '¥';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _currencySymbolController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    final ledgerRepo = ref.read(ledgerRepositoryProvider);
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final currencySymbol = _currencySymbolController.text.trim();

    if (_isEditMode) {
      ledgerRepo.updateLedger(
        id: widget.ledger!.ledgerId,
        name: name,
        description: description.isNotEmpty ? description : null,
        currencySymbol: currencySymbol,
        isSelected: widget.ledger!.isSelected,
      );
    } else {
      ledgerRepo.createLedger(
        name: name,
        description: description.isNotEmpty ? description : null,
        currencySymbol: currencySymbol,
        isSelected: true,
      );
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return AlertDialog(
      title: Text(_isEditMode ? '编辑账本' : '创建新账本'),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: inputDecoration.copyWith(
              labelText: '账本名称',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: inputDecoration.copyWith(
              labelText: '描述 (可选)',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _currencySymbolController,
            decoration: inputDecoration.copyWith(
              labelText: '货币符号',
              hintText: '¥',
              counterText: '',
            ),
            maxLength: 1,
          ),
        ],
      ),
      actions: [
        if (_isEditMode)
          TextButton(
            onPressed: _showDeleteConfirmation,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEditMode ? '更新' : '创建'),
        ),
      ],
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除此账本吗？所有关联的数据（包括账户、交易）都将被永久删除，此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(ledgerRepositoryProvider)
                      .deleteLedgerWithRelatedData(widget.ledger!.ledgerId);

                  if (mounted) {
                    Navigator.pop(dialogContext); // Close confirmation dialog
                    Navigator.pop(context, true); // Close edit dialog
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(dialogContext); // Close confirmation dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('删除失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('确认删除'),
            ),
          ],
        );
      },
    );
  }
}
