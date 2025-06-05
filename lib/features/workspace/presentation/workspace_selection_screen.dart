// Replace your existing workspace_selection_screen.dart with this updated version
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../domain/entities/workspace.entity.dart';
import '../domain/usecases/get_workspaces.usecase.dart';
import '../domain/usecases/get_pending_invitations.usecase.dart';
import '../domain/usecases/accept_invitation.usecase.dart';
import '../domain/usecases/reject_invitation.usecase.dart';
import '../domain/usecases/delete_workspace.usecase.dart';
import '../domain/usecases/update_workspace.usecase.dart';
import '../domain/entities/workspace_member.dart';
import 'widgets/workspace_actions_bottom_sheet.dart';
import 'widgets/quick_edit_workspace_dialog.dart';
import 'widgets/delete_workspace_dialog.dart';

class WorkspaceSelectionScreen extends StatefulWidget {
  const WorkspaceSelectionScreen({super.key});

  @override
  State<WorkspaceSelectionScreen> createState() => _WorkspaceSelectionScreenState();
}

class _WorkspaceSelectionScreenState extends State<WorkspaceSelectionScreen> {
  List<Workspace> _workspaces = [];
  List<WorkspaceMember> _pendingInvitations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final getWorkspacesUseCase = GetIt.I<GetWorkspacesUseCase>();
      final getPendingInvitationsUseCase = GetIt.I<GetPendingInvitationsUseCase>();

      final results = await Future.wait([
        getWorkspacesUseCase(),
        getPendingInvitationsUseCase(),
      ]);

      setState(() {
        _workspaces = results[0] as List<Workspace>;
        _pendingInvitations = results[1] as List<WorkspaceMember>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _acceptInvitation(String workspaceId) async {
    try {
      _showLoadingSnackBar('Accepting invitation...');

      final acceptInvitationUseCase = GetIt.I<AcceptInvitationUseCase>();
      await acceptInvitationUseCase(workspaceId);

      if (mounted) {
        _hideCurrentSnackBar();
        _showSuccessSnackBar('Invitation accepted successfully!');
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _hideCurrentSnackBar();
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        if (errorMessage.contains('Plan básico') ||
            errorMessage.contains('Premium') ||
            errorMessage.contains('Actualiza')) {
          _showPremiumUpgradeDialog(errorMessage);
        } else {
          _showErrorSnackBar('Error accepting invitation: $errorMessage');
        }
      }
    }
  }

  Future<void> _rejectInvitation(String workspaceId) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Reject Invitation',
      content: 'Are you sure you want to reject this workspace invitation?',
      confirmText: 'Reject',
      confirmColor: Colors.red,
    );

    if (!confirmed) return;

    try {
      _showLoadingSnackBar('Rejecting invitation...');

      final rejectInvitationUseCase = GetIt.I<RejectInvitationUseCase>();
      await rejectInvitationUseCase(workspaceId);

      if (mounted) {
        _hideCurrentSnackBar();
        _showInfoSnackBar('Invitation rejected');
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _hideCurrentSnackBar();
        _showErrorSnackBar('Error rejecting invitation: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  Future<void> _quickEditWorkspace(Workspace workspace) async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => QuickEditWorkspaceDialog(workspace: workspace),
    );

    if (result == null) return;

    try {
      _showLoadingSnackBar('Updating workspace...');

      final updateWorkspaceUseCase = GetIt.I<UpdateWorkspaceUseCase>();
      await updateWorkspaceUseCase(
        workspace.id,
        result['name']!,
        description: result['description'],
      );

      if (mounted) {
        _hideCurrentSnackBar();
        _showSuccessSnackBar('Workspace updated successfully!');
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _hideCurrentSnackBar();
        _showErrorSnackBar('Error updating workspace: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  Future<void> _deleteWorkspace(Workspace workspace) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteWorkspaceDialog(workspace: workspace),
    );

    if (confirmed != true) return;

    try {
      _showLoadingSnackBar('Deleting "${workspace.name}"...');

      final deleteWorkspaceUseCase = GetIt.I<DeleteWorkspaceUseCase>();
      await deleteWorkspaceUseCase(workspace.id);

      if (mounted) {
        _hideCurrentSnackBar();
        _showSuccessSnackBar('Workspace "${workspace.name}" deleted successfully');
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _hideCurrentSnackBar();
        _showErrorSnackBar('Error deleting workspace: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  void _showWorkspaceActions(Workspace workspace) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WorkspaceActionsBottomSheet(
        workspace: workspace,
        onOpen: () => context.go('/workspace/${workspace.id}'),
        onEdit: () => _quickEditWorkspace(workspace),
        onSettings: () => context.push('/workspace/${workspace.id}/settings'),
        onDelete: () => _deleteWorkspace(workspace),
      ),
    );
  }

  void _showPremiumUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.amber.shade400],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Upgrade to Premium',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.replaceAll('Error: Failed to accept invitation: ', ''),
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Premium features include team collaboration, unlimited workspaces, and advanced reporting.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Maybe Later', style: TextStyle(color: Colors.grey.shade600)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.amber.shade500],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showInfoSnackBar('Premium upgrade feature coming soon!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.star, size: 18),
              label: const Text('Upgrade Now'),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    Color? confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  // SnackBar helper methods
  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _hideCurrentSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Select Workspace',
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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh, color: Colors.grey.shade700),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-workspace'),
        backgroundColor: Colors.purple.shade400,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Workspace',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading workspaces',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_workspaces.isEmpty && _pendingInvitations.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending Invitations Section
          if (_pendingInvitations.isNotEmpty) ...[
            _buildSectionTitle('Pending Invitations', _pendingInvitations.length),
            const SizedBox(height: 16),
            ..._pendingInvitations.map(_buildInvitationCard),
            const SizedBox(height: 32),
          ],

          // Workspaces Section
          if (_workspaces.isNotEmpty) ...[
            _buildSectionTitle('Your Workspaces', _workspaces.length),
            const SizedBox(height: 16),
            ..._workspaces.map(_buildWorkspaceCard),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade400,
                    Colors.blue.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.workspaces_outlined,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Workspaces Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first workspace to start\norganizing your tasks and collaborating with your team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceCard(Workspace workspace) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: workspace.isPersonal
                  ? [Colors.green.shade300, Colors.blue.shade300]
                  : [Colors.purple.shade300, Colors.pink.shade300],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            workspace.isPersonal ? Icons.person : Icons.group,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          workspace.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: workspace.description != null
            ? Text(
          workspace.description!,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
            : Text(
          workspace.isPersonal ? 'Personal workspace' : 'Team workspace',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick actions button
            IconButton(
              onPressed: () => _showWorkspaceActions(workspace),
              icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
              tooltip: 'Workspace Actions',
            ),
            // Quick access arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
        onTap: () => context.go('/workspace/${workspace.id}'),
        onLongPress: () => _showWorkspaceActions(workspace),
      ),
    );
  }

  Widget _buildInvitationCard(WorkspaceMember invitation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.email,
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
                  invitation.workspaceName ?? 'Workspace Invitation',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Role: ${invitation.role}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _acceptInvitation(invitation.workspaceId),
                icon: const Icon(Icons.check, color: Colors.green),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _rejectInvitation(invitation.workspaceId),
                icon: const Icon(Icons.close, color: Colors.red),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}