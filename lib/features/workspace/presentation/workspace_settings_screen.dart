import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../domain/entities/workspace.entity.dart';
import '../domain/entities/workspace_member.dart';
import '../domain/usecases/get_workspace_by_id.usecase.dart';
import '../domain/usecases/update_workspace.usecase.dart';
import '../domain/usecases/delete_workspace.usecase.dart';
import '../domain/usecases/get_workspace_members.usecase.dart';
import '../domain/usecases/invite_member.usecase.dart';
import '../domain/usecases/remove_member.usecase.dart';
import '../../../core/shared/widgets/loading_widget.dart';
import '../../../core/shared/widgets/error_widget.dart';

class WorkspaceSettingsScreen extends StatefulWidget {
  final String workspaceId;

  const WorkspaceSettingsScreen({
    super.key,
    required this.workspaceId,
  });

  @override
  State<WorkspaceSettingsScreen> createState() => _WorkspaceSettingsScreenState();
}

class _WorkspaceSettingsScreenState extends State<WorkspaceSettingsScreen> {
  Workspace? _workspace;
  List<WorkspaceMember> _members = [];
  bool _loading = true;
  bool _isOwner = false;
  String? _error;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final getWorkspaceUseCase = GetIt.I<GetWorkspaceUseCase>();
      final getMembersUseCase = GetIt.I<GetWorkspaceMembersUseCase>();

      // Load workspace and members in parallel
      final workspace = await getWorkspaceUseCase(widget.workspaceId);
      final members = await getMembersUseCase(widget.workspaceId);

      setState(() {
        _workspace = workspace;
        _members = members;
        _nameController.text = workspace.name;
        _descriptionController.text = workspace.description ?? '';

        // Check if current user is owner - you'll need to implement this check
        // For now, assuming user is owner
        _isOwner = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Replace the _updateWorkspace method in your workspace_settings_screen.dart
  Future<void> _updateWorkspace() async {
    if (_workspace == null) return;

    // Validate input
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Workspace name cannot be empty', isError: true);
      return;
    }

    try {
      // Show loading state
      _showSnackBar('Updating workspace...', isLoading: true);

      final updateWorkspaceUseCase = GetIt.I<UpdateWorkspaceUseCase>();
      final updatedWorkspace = await updateWorkspaceUseCase(
        widget.workspaceId,
        _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
        _showSnackBar('Workspace updated successfully!');

        // Wait a moment for user to see the success message
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Navigate back to workspace selection to refresh the list
          context.go('/workspaces');
        }
      }
    } catch (e) {
      if (mounted) {
        // Hide loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSnackBar('Error updating workspace: ${e.toString()}', isError: true);
      }
    }
  }


  Future<void> _deleteWorkspace() async {
    if (_workspace == null) return;

    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    try {
      final deleteWorkspaceUseCase = GetIt.I<DeleteWorkspaceUseCase>();
      await deleteWorkspaceUseCase(widget.workspaceId);

      if (mounted) {
        _showSnackBar('Workspace deleted successfully!');
        // Navigate back to workspace selection
        context.go('/workspaces');
      }
    } catch (e) {
      _showSnackBar('Error deleting workspace: ${e.toString()}', isError: true);
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Workspace'),
        content: Text(
          'Are you sure you want to delete "${_workspace!.name}"? This action cannot be undone and will delete all associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _inviteMember() async {
    final result = await _showInviteMemberDialog();
    if (result == null) return;

    try {
      final inviteMemberUseCase = GetIt.I<InviteMemberUseCase>();
      await inviteMemberUseCase(
        widget.workspaceId,
        result['email']!,
        result['role']!,
      );

      _showSnackBar('Invitation sent successfully!');
      _loadData(); // Refresh data
    } catch (e) {
      _showSnackBar('Error sending invitation: ${e.toString()}', isError: true);
    }
  }

  Future<Map<String, String>?> _showInviteMemberDialog() async {
    final emailController = TextEditingController();
    String selectedRole = 'member';

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Invite Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter member email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'member', child: Text('Member')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedRole = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                if (emailController.text.trim().isEmpty) return;
                Navigator.of(context).pop({
                  'email': emailController.text.trim(),
                  'role': selectedRole,
                });
              },
              child: const Text('Send Invitation'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(WorkspaceMember member) async {
    final confirmed = await _showRemoveMemberDialog(member);
    if (!confirmed) return;

    try {
      final removeMemberUseCase = GetIt.I<RemoveMemberUseCase>();
      await removeMemberUseCase(widget.workspaceId, member.userId);

      _showSnackBar('Member removed successfully');
      _loadData(); // Refresh data
    } catch (e) {
      _showSnackBar('Error removing member: ${e.toString()}', isError: true);
    }
  }

  Future<bool> _showRemoveMemberDialog(WorkspaceMember member) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.userEmail ?? 'this member'} from the workspace?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    ) ?? false;
  }

// Updated _showSnackBar method with loading support
  void _showSnackBar(String message, {bool isError = false, bool isLoading = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                isError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white, // Fixed: Make snackbar text visible
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isLoading
            ? Colors.blue
            : (isError ? Colors.red : Colors.green),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isLoading ? 3 : (isError ? 4 : 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Workspace Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.shade300,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.grey.shade700),
        actions: [
          if (_isOwner)
            IconButton(
              onPressed: _deleteWorkspace,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Workspace',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingWidget(message: 'Loading workspace settings...');
    }

    if (_error != null) {
      return CustomErrorWidget.generic(
        message: _error!,
        onRetry: _loadData,
      );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workspace Details Section
          _buildSection(
            'Workspace Details',
            _buildWorkspaceDetailsCard(),
          ),
          const SizedBox(height: 32),

          // Members Section
          _buildSection(
            'Members (${_members.length})',
            _buildMembersCard(),
          ),

          if (_isOwner) ...[
            const SizedBox(height: 32),
            _buildDangerZone(),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  // Replace the _buildWorkspaceDetailsCard method in your workspace_settings_screen.dart
  Widget _buildWorkspaceDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            enabled: _isOwner,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87, // Fixed: Make text visible
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Workspace Name',
              labelStyle: TextStyle(
                color: Colors.grey.shade700, // Fixed: Make label visible
                fontWeight: FontWeight.w500,
              ),
              hintText: 'Enter workspace name',
              hintStyle: TextStyle(
                color: Colors.grey.shade500, // Fixed: Make hint visible
              ),
              prefixIcon: Icon(
                Icons.business,
                color: Colors.grey.shade600, // Fixed: Make icon visible
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: _isOwner ? Colors.white : Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            enabled: _isOwner,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87, // Fixed: Make text visible
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              labelStyle: TextStyle(
                color: Colors.grey.shade700, // Fixed: Make label visible
                fontWeight: FontWeight.w500,
              ),
              hintText: 'Describe what this workspace is for...',
              hintStyle: TextStyle(
                color: Colors.grey.shade500, // Fixed: Make hint visible
              ),
              prefixIcon: Icon(
                Icons.description,
                color: Colors.grey.shade600, // Fixed: Make icon visible
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: _isOwner ? Colors.white : Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
              ),
            ),
          ),
          if (_isOwner) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _updateWorkspace,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white, // Fixed: Make button text visible
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isOwner)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _inviteMember,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Invite Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          if (_members.isEmpty)
            _buildEmptyMembersState()
          else
            ..._buildMembersList(),
        ],
      ),
    );
  }

  Widget _buildEmptyMembersState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No members yet',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite team members to collaborate',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMembersList() {
    return _members.asMap().entries.map((entry) {
      final index = entry.key;
      final member = entry.value;
      return Column(
        children: [
          if (index > 0 || _isOwner) const Divider(height: 1),
          _buildMemberTile(member),
        ],
      );
    }).toList();
  }

  Widget _buildMemberTile(WorkspaceMember member) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: _getMemberAvatarColor(member),
        child: Icon(
          _getMemberIcon(member),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        member.userEmail ?? 'Unknown User',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: _buildMemberSubtitle(member),
      trailing: _buildMemberActions(member),
    );
  }

  Color _getMemberAvatarColor(WorkspaceMember member) {
    if (member.isOwner) return Colors.purple.shade400;
    if (member.isAdmin) return Colors.blue.shade400;
    return Colors.green.shade400;
  }

  IconData _getMemberIcon(WorkspaceMember member) {
    if (member.isOwner) return Icons.star;
    if (member.isAdmin) return Icons.admin_panel_settings;
    return Icons.person;
  }

  Widget _buildMemberSubtitle(WorkspaceMember member) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _getMemberRoleColor(member),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            member.role.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _getMemberRoleTextColor(member),
            ),
          ),
        ),
        if (member.isPending) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'PENDING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getMemberRoleColor(WorkspaceMember member) {
    if (member.isOwner) return Colors.purple.shade100;
    if (member.isAdmin) return Colors.blue.shade100;
    return Colors.green.shade100;
  }

  Color _getMemberRoleTextColor(WorkspaceMember member) {
    if (member.isOwner) return Colors.purple.shade700;
    if (member.isAdmin) return Colors.blue.shade700;
    return Colors.green.shade700;
  }

  Widget? _buildMemberActions(WorkspaceMember member) {
    if (!_isOwner || member.isOwner) return null;

    return IconButton(
      onPressed: () => _removeMember(member),
      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
      tooltip: 'Remove Member',
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Once you delete a workspace, there is no going back. This will permanently delete the workspace and all associated data.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _deleteWorkspace,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Workspace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}