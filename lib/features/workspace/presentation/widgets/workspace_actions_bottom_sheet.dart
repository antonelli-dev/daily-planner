import 'package:flutter/material.dart';
import '../../domain/entities/workspace.entity.dart';

class WorkspaceActionsBottomSheet extends StatelessWidget {
  final Workspace workspace;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onSettings;
  final VoidCallback onDelete;

  const WorkspaceActionsBottomSheet({
    super.key,
    required this.workspace,
    required this.onOpen,
    required this.onEdit,
    required this.onSettings,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: workspace.isPersonal
                        ? [Colors.green.shade400, Colors.blue.shade400]
                        : [Colors.purple.shade400, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  workspace.isPersonal ? Icons.person : Icons.group,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workspace.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (workspace.description != null)
                      Text(
                        workspace.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          _buildActionTile(
            icon: Icons.launch,
            title: 'Open Workspace',
            subtitle: 'Go to workspace dashboard',
            color: Colors.green.shade400,
            onTap: () {
              Navigator.pop(context);
              onOpen();
            },
          ),
          const SizedBox(height: 8),
          _buildActionTile(
            icon: Icons.edit,
            title: 'Quick Edit',
            subtitle: 'Modify name and description',
            color: Colors.purple.shade400,
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          const SizedBox(height: 8),
          _buildActionTile(
            icon: Icons.settings,
            title: 'Workspace Settings',
            subtitle: 'Manage members and permissions',
            color: Colors.blue.shade400,
            onTap: () {
              Navigator.pop(context);
              onSettings();
            },
          ),
          const SizedBox(height: 8),
          _buildActionTile(
            icon: Icons.delete_outline,
            title: 'Delete Workspace',
            subtitle: 'Permanently remove workspace',
            color: Colors.red.shade400,
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),

          const SizedBox(height: 20),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}