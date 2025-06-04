class ApiEndpoints {
  // Workspace endpoints
  static const String workspaces = '/workspaces';
  static String workspace(String id) => '/workspaces/$id';
  static String workspaceMembers(String id) => '/workspaces/$id/members';
  static String inviteMember(String id) => '/workspaces/$id/invite';
  static String removeMember(String workspaceId, String userId) =>
      '/workspaces/$workspaceId/members/$userId';
  static String acceptInvitation(String id) => '/workspaces/$id/accept-invitation';
  static String rejectInvitation(String id) => '/workspaces/$id/reject-invitation';
  static const String pendingInvitations = '/workspaces/invitations/pending';

  // Schedule endpoints
  static String schedules(String workspaceId) => '/workspaces/$workspaceId/schedules';
  static String schedule(String workspaceId, String scheduleId) =>
      '/workspaces/$workspaceId/schedules/$scheduleId';
  static String completeSchedule(String workspaceId, String scheduleId) =>
      '/workspaces/$workspaceId/schedules/$scheduleId/complete';
  static String assignSchedule(String workspaceId, String scheduleId) =>
      '/workspaces/$workspaceId/schedules/$scheduleId/assign';

  // Routine endpoints
  static String routines(String workspaceId) => '/workspaces/$workspaceId/routines';
  static String routine(String workspaceId, String routineId) =>
      '/workspaces/$workspaceId/routines/$routineId';

  // Finance endpoints
  static String incomes(String workspaceId) => '/workspaces/$workspaceId/finances/incomes';
  static String income(String workspaceId, String incomeId) =>
      '/workspaces/$workspaceId/finances/incomes/$incomeId';
  static String expenses(String workspaceId) => '/workspaces/$workspaceId/finances/expenses';
  static String expense(String workspaceId, String expenseId) =>
      '/workspaces/$workspaceId/finances/expenses/$expenseId';
  static String incomeCategories(String workspaceId) =>
      '/workspaces/$workspaceId/finances/income-categories';
  static String expenseCategories(String workspaceId) =>
      '/workspaces/$workspaceId/finances/expense-categories';
  static String projections(String workspaceId) =>
      '/workspaces/$workspaceId/finances/projections';

  // Report endpoints
  static String completedTasksReport(String workspaceId) =>
      '/workspaces/$workspaceId/reports/completed-tasks';
  static String productivityReport(String workspaceId) =>
      '/workspaces/$workspaceId/reports/productivity';
  static String dashboardStats(String workspaceId) =>
      '/workspaces/$workspaceId/reports/dashboard-stats';
}