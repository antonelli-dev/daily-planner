import 'package:flutter/material.dart';
import '../../domain/entities/workspace.entity.dart';

class QuickEditWorkspaceDialog extends StatefulWidget {
  final Workspace workspace;

  const QuickEditWorkspaceDialog({
    super.key,
    required this.workspace,
  });

  @override
  State<QuickEditWorkspaceDialog> createState() => _QuickEditWorkspaceDialogState();
}

class _QuickEditWorkspaceDialogState extends State<QuickEditWorkspaceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workspace.name);
    _descriptionController = TextEditingController(text: widget.workspace.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    // Check if anything changed
    if (name == widget.workspace.name &&
        description == (widget.workspace.description ?? '')) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop({
      'name': name,
      'description': description.isEmpty ? null : description,
    });
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
              gradient: LinearGradient(
                colors: widget.workspace.isPersonal
                    ? [Colors.green.shade300, Colors.blue.shade300]
                    : [Colors.purple.shade300, Colors.pink.shade300],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Edit Workspace',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Workspace Name Field
              TextFormField(
                controller: _nameController,
                enabled: !_loading,
                decoration: InputDecoration(
                  labelText: 'Workspace Name',
                  hintText: 'Enter workspace name',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Workspace name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (value.trim().length > 50) {
                    return 'Name must be less than 50 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                enabled: !_loading,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe what this workspace is for...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.trim().length > 200) {
                    return 'Description must be less than 200 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Info about changes
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Changes will be saved immediately and visible to all workspace members.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade400,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: _loading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Icon(Icons.save, size: 18),
          label: Text(_loading ? 'Saving...' : 'Save Changes'),
        ),
      ],
    );
  }
}