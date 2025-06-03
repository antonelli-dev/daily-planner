class WorkspaceMember {
  final String id;
  final String workspaceId;
  final String userId;
  final String role; // 'owner', 'admin', 'member'
  final String status; // 'active', 'pending', 'inactive'
  final String? invitedBy;
  final DateTime invitedAt;
  final DateTime? joinedAt;
  final DateTime? leftAt;

  // Additional fields for UI
  final String? workspaceName;
  final String? workspaceDescription;
  final String? userEmail;
  final String? userName;

  const WorkspaceMember({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.role,
    required this.status,
    this.invitedBy,
    required this.invitedAt,
    this.joinedAt,
    this.leftAt,
    this.workspaceName,
    this.workspaceDescription,
    this.userEmail,
    this.userName,
  });

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) {
    return WorkspaceMember(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      invitedBy: json['invitedBy'] as String?,
      invitedAt: DateTime.parse(json['invitedAt'] as String),
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : null,
      leftAt: json['leftAt'] != null
          ? DateTime.parse(json['leftAt'] as String)
          : null,
      workspaceName: json['workspaceName'] as String?,
      workspaceDescription: json['workspaceDescription'] as String?,
      userEmail: json['userEmail'] as String?,
      userName: json['userName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspaceId': workspaceId,
      'userId': userId,
      'role': role,
      'status': status,
      'invitedBy': invitedBy,
      'invitedAt': invitedAt.toIso8601String(),
      'joinedAt': joinedAt?.toIso8601String(),
      'leftAt': leftAt?.toIso8601String(),
      'workspaceName': workspaceName,
      'workspaceDescription': workspaceDescription,
      'userEmail': userEmail,
      'userName': userName,
    };
  }

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get canManageMembers => isOwner || isAdmin;

  WorkspaceMember copyWith({
    String? id,
    String? workspaceId,
    String? userId,
    String? role,
    String? status,
    String? invitedBy,
    DateTime? invitedAt,
    DateTime? joinedAt,
    DateTime? leftAt,
    String? workspaceName,
    String? workspaceDescription,
    String? userEmail,
    String? userName,
  }) {
    return WorkspaceMember(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedAt: invitedAt ?? this.invitedAt,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      workspaceName: workspaceName ?? this.workspaceName,
      workspaceDescription: workspaceDescription ?? this.workspaceDescription,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WorkspaceMember &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'WorkspaceMember{id: $id, userId: $userId, role: $role, status: $status}';
  }
}