import 'package:flutter/material.dart';
import '../../domain/entities/workspace.entity.dart';

class DeleteWorkspaceDialog extends StatefulWidget {
  final Workspace workspace;

  const DeleteWorkspaceDialog({
    super.key,
    required this.workspace,
  });

  @override
  State<DeleteWorkspaceDialog> createState() => _DeleteWorkspaceDialogState();
}

class _DeleteWorkspaceDialogState extends State<DeleteWorkspaceDialog> {
  final _confirmationController = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _confirmationController.addListener(_checkConfirmation);
  }

  @override
  void dispose() {
    _confirmationController.removeListener(_checkConfirmation);
    _confirmationController.dispose();
    super.dispose();
  }

  void _checkConfirmation() {
    final isMatch = _confirmationController.text.trim().toLowerCase() ==
        widget.workspace.name.toLowerCase();
    if (isMatch != _canDelete) {
      setState(() {
        _canDelete = isMatch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Delete Workspace',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message
            Text(
              'Are you sure you want to delete "${widget.workspace.name}"?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone and will permanently delete:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // What will be deleted
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeleteWarningItem('All tasks and schedules'),
                  _buildDeleteWarningItem('Financial records and transactions'),
                  _buildDeleteWarningItem('Team member access and roles'),
                  _buildDeleteWarningItem('All workspace settings and data'),
                  _buildDeleteWarningItem('File attachments and documents'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Confirmation input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To confirm deletion, type the workspace name below:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.workspace.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmationController,
                  decoration: InputDecoration(
                    hintText: 'Type workspace name here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _canDelete ? Colors.red.shade400 : Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    suffixIcon: _canDelete
                        ? Icon(Icons.check, color: Colors.red.shade600)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Final warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action is irreversible. All data will be lost forever.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ElevatedButton.icon(
          onPressed: _canDelete ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canDelete ? Colors.red : Colors.grey.shade300,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: Icon(
            Icons.delete_forever,
            size: 18,
            color: _canDelete ? Colors.white : Colors.grey.shade500,
          ),
          label: Text(
            'Delete Permanently',
            style: TextStyle(
              color: _canDelete ? Colors.white : Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.close,
            size: 16,
            color: Colors.red.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}