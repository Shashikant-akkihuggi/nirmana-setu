/// Global Project Context - Single Source of Truth for Project Selection
/// 
/// Rules:
/// - activeProjectId == null → NO FEATURES
/// - activeProjectId != null → FEATURES UNLOCKED
class ProjectContext {
  static String? activeProjectId;
  static String? activeProjectName;
  
  /// Set the active project (when user clicks a project card)
  static void setActiveProject(String projectId, String projectName) {
    activeProjectId = projectId;
    activeProjectName = projectName;
  }
  
  /// Clear active project (when user goes back to dashboard)
  static void clearActiveProject() {
    activeProjectId = null;
    activeProjectName = null;
  }
  
  /// Check if a project is currently selected
  static bool get hasActiveProject => activeProjectId != null;
  
  /// Get current project info for display
  static Map<String, String?> get currentProject => {
    'id': activeProjectId,
    'name': activeProjectName,
  };
}