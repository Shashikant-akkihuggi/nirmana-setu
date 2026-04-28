/// Language Keys
/// 
/// This file contains ONLY string keys - NO actual text.
/// All visible text is stored in app_localizations.dart.
/// 
/// Why separate keys?
/// - Type-safe string references
/// - Autocomplete support
/// - Compile-time error checking
/// - Easy refactoring
/// - No typos in string keys
class LangKeys {
  // App Name & Branding
  static const appName = "app_name";
  static const manageProjects = "manage_projects";
  static const manageProjectsEase = "manage_projects_ease";

  // Welcome Screen
  static const getStarted = "get_started";

  // Role Selection
  static const chooseYourRole = "choose_your_role";
  static const selectHowYouUse = "select_how_you_use";
  static const fieldManager = "field_manager";
  static const fieldManagerDesc = "field_manager_desc";
  static const projectEngineer = "project_engineer";
  static const projectEngineerDesc = "project_engineer_desc";
  static const ownerClient = "owner_client";
  static const ownerClientDesc = "owner_client_desc";

  // Authentication
  static const login = "login";
  static const logIn = "log_in";
  static const logout = "logout";
  static const createAccount = "create_account";
  static const email = "email";
  static const password = "password";
  static const confirmPassword = "confirm_password";
  static const fullName = "full_name";
  static const phone = "phone";
  static const phoneOptional = "phone_optional";
  static const mobileNumber = "mobile_number";
  static const forgotPassword = "forgot_password";
  static const resetYourPassword = "reset_your_password";
  static const enterEmailOrPhone = "enter_email_or_phone";
  static const sendResetLink = "send_reset_link";
  static const newHere = "new_here";
  static const alreadyHaveAccount = "already_have_account";
  static const orContinueWith = "or_continue_with";
  static const google = "google";
  static const facebook = "facebook";
  static const agreeToTerms = "agree_to_terms";

  // Validation Messages
  static const enterYourEmail = "enter_your_email";
  static const enterYourPassword = "enter_your_password";
  static const enterYourFullName = "enter_your_full_name";
  static const enterYourName = "enter_your_name";
  static const passwordMinLength = "password_min_length";
  static const passwordsDoNotMatch = "passwords_do_not_match";
  static const invalidEmail = "invalid_email";
  static const nameRequired = "name_required";
  static const emailRequired = "email_required";

  // Auth Errors
  static const loginFailed = "login_failed";
  static const noAccountFound = "no_account_found";
  static const incorrectPassword = "incorrect_password";
  static const invalidEmailAddress = "invalid_email_address";
  static const accountDisabled = "account_disabled";
  static const invalidCredentials = "invalid_credentials";
  static const accountCreationFailed = "account_creation_failed";
  static const emailAlreadyInUse = "email_already_in_use";
  static const weakPassword = "weak_password";
  static const googleSignInFailed = "google_sign_in_failed";
  static const logoutFailed = "logout_failed";
  static const pleaseAcceptTerms = "please_accept_terms";

  // Loading States
  static const pleaseWait = "please_wait";
  static const loading = "loading";

  // Dashboard Common
  static const dashboard = "dashboard";
  static const home = "home";
  static const profile = "profile";
  static const notifications = "notifications";
  static const settings = "settings";

  // Owner Dashboard
  static const ownerDashboard = "owner_dashboard";
  static const investmentTransparency = "investment_transparency";
  static const totalInvestment = "total_investment";
  static const amountSpent = "amount_spent";
  static const remainingBudget = "remaining_budget";
  static const overallProgress = "overall_progress";
  static const progressGallery = "progress_gallery";
  static const billingGSTInvoices = "billing_gst_invoices";
  static const plotPlanning = "plot_planning";
  static const projectStatusDashboard = "project_status_dashboard";
  static const directCommunication = "direct_communication";
  static const milestones = "milestones";
  static const gallery = "gallery";
  static const invoices = "invoices";

  // Engineer Dashboard
  static const engineerDashboard = "engineer_dashboard";
  static const verificationQualityOverview = "verification_quality_overview";
  static const offlineWillSyncLater = "offline_will_sync_later";
  static const offlineItemsPendingSync = "offline_items_pending_sync";
  static const pendingApprovals = "pending_approvals";
  static const photosToReview = "photos_to_review";
  static const delayedMilestones = "delayed_milestones";
  static const materialRequests = "material_requests";
  static const reviewDPRs = "review_dprs";
  static const materialApprovals = "material_approvals";
  static const projectDetails = "project_details";
  static const plotReviews = "plot_reviews";
  static const materials = "materials";
  static const approvals = "approvals";

  // Manager Dashboard
  static const fieldManagerDashboard = "field_manager_dashboard";
  static const reports = "reports";
  static const attendance = "attendance";

  // Profile Screen
  static const myProfile = "my_profile";
  static const editProfile = "edit_profile";
  static const saveProfile = "save_profile";
  static const save = "save";
  static const cancel = "cancel";
  static const role = "role";
  static const offline = "offline";
  static const online = "online";
  static const syncedWithCloud = "synced_with_cloud";
  static const savedLocally = "saved_locally";
  static const savedLocallyWillSync = "saved_locally_will_sync";
  static const syncing = "syncing";
  static const offlineMode = "offline_mode";
  static const noProfileFound = "no_profile_found";
  static const noProfileLoaded = "no_profile_loaded";
  static const profileSaved = "profile_saved";
  static const profileSavedSyncing = "profile_saved_syncing";
  static const failedToSaveProfile = "failed_to_save_profile";

  // Language Selection
  static const selectLanguage = "select_language";
  static const chooseYourLanguage = "choose_your_language";
  static const selectPreferredLanguage = "select_preferred_language";
  static const continueBtn = "continue_btn";
  static const english = "english";
  static const hindi = "hindi";
  static const kannada = "kannada";
  static const marathi = "marathi";
  static const tamil = "tamil";

  // Common Actions
  static const submit = "submit";
  static const confirm = "confirm";
  static const delete = "delete";
  static const edit = "edit";
  static const update = "update";
  static const close = "close";
  static const back = "back";
  static const next = "next";
  static const done = "done";
  static const retry = "retry";
  static const refresh = "refresh";

  // Common Messages
  static const success = "success";
  static const error = "error";
  static const warning = "warning";
  static const info = "info";
  static const comingSoon = "coming_soon";
  static const noDataAvailable = "no_data_available";
  static const tryAgain = "try_again";

  // Sync Messages
  static const syncComplete = "sync_complete";
  static const syncFailed = "sync_failed";
  static const syncInProgress = "sync_in_progress";

  // Connectivity
  static const noInternetConnection = "no_internet_connection";
  static const internetRestored = "internet_restored";
  static const workingOffline = "working_offline";

  // Placeholder Screens
  static const screenComingSoon = "screen_coming_soon";
}
