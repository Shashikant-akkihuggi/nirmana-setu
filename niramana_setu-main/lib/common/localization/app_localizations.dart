/// App Localizations
/// 
/// This file contains ALL visible text in the application.
/// Supports multiple languages: English, Hindi, Kannada.
/// 
/// Why centralized translations?
/// - Single source of truth for all text
/// - Easy to add new languages
/// - Consistent terminology
/// - Professional translation workflow
/// - No hardcoded strings anywhere
class AppLocalizations {
  static final Map<String, Map<String, String>> _translations = {
    'en': _english,
    'hi': _hindi,
    'kn': _kannada,
    'mr': _marathi,
    'ta': _tamil,
  };

  /// Get translation for a key in specified language
  static String translate(String key, String languageCode) {
    return _translations[languageCode]?[key] ?? key;
  }

  /// Get all supported language codes
  static List<String> get supportedLanguages => ['en', 'hi', 'kn', 'mr', 'ta'];

  /// English translations
  static const Map<String, String> _english = {
    // App Name & Branding
    "app_name": "Niramana Setu",
    "manage_projects": "Manage projects",
    "manage_projects_ease": "Manage projects with ease",

    // Welcome Screen
    "get_started": "Get Started",

    // Role Selection
    "choose_your_role": "Choose Your Role",
    "select_how_you_use": "Select how you use Niramana Setu",
    "field_manager": "Field Manager",
    "field_manager_desc": "Manage on-site tasks and oversee daily operations",
    "project_engineer": "Project Engineer",
    "project_engineer_desc": "Design project plans and ensure technical accuracy",
    "owner_client": "Owner / Client",
    "owner_client_desc": "Track project progress and manage contracts",

    // Authentication
    "login": "Login",
    "log_in": "Log In",
    "logout": "Logout",
    "create_account": "Create account",
    "email": "Email",
    "password": "Password",
    "confirm_password": "Confirm password",
    "full_name": "Full name",
    "phone": "Phone",
    "phone_optional": "Phone (Optional)",
    "mobile_number": "Mobile number",
    "forgot_password": "Forgot password?",
    "reset_your_password": "Reset your password",
    "enter_email_or_phone": "Enter your email or phone to receive a reset link.",
    "send_reset_link": "Send Reset Link",
    "new_here": "New here? ",
    "already_have_account": "Already have an account? ",
    "or_continue_with": "or continue with",
    "google": "Google",
    "facebook": "Facebook",
    "agree_to_terms": "I agree to Terms & Privacy Policy",

    // Validation Messages
    "enter_your_email": "Enter your email",
    "enter_your_password": "Enter your password",
    "enter_your_full_name": "Enter your full name",
    "enter_your_name": "Enter your name",
    "password_min_length": "Password must be at least 6 characters",
    "passwords_do_not_match": "Passwords do not match",
    "invalid_email": "Invalid email",
    "name_required": "Name is required",
    "email_required": "Email is required",

    // Auth Errors
    "login_failed": "Login failed. Please check your credentials.",
    "no_account_found": "No account found with this email.",
    "incorrect_password": "Incorrect password.",
    "invalid_email_address": "Invalid email address.",
    "account_disabled": "This account has been disabled.",
    "invalid_credentials": "Invalid email or password.",
    "account_creation_failed": "Account creation failed. Please try again.",
    "email_already_in_use": "An account with this email already exists.",
    "weak_password": "Password is too weak. Use at least 6 characters.",
    "google_sign_in_failed": "Google sign-in failed. Please try again.",
    "logout_failed": "Logout failed. Please try again.",
    "please_accept_terms": "Please accept the Terms & Privacy Policy",

    // Loading States
    "please_wait": "Please wait...",
    "loading": "Loading...",

    // Dashboard Common
    "dashboard": "Dashboard",
    "home": "Home",
    "profile": "Profile",
    "notifications": "Notifications",
    "settings": "Settings",

    // Owner Dashboard
    "owner_dashboard": "Owner Dashboard",
    "investment_transparency": "Investment transparency & project overview",
    "total_investment": "Total Investment",
    "amount_spent": "Amount Spent",
    "remaining_budget": "Remaining Budget",
    "overall_progress": "Overall Progress",
    "progress_gallery": "Progress Gallery",
    "billing_gst_invoices": "Billing & GST Invoices",
    "plot_planning": "Plot Planning",
    "project_status_dashboard": "Project Status Dashboard",
    "direct_communication": "Direct Communication",
    "milestones": "Milestones",
    "gallery": "Gallery",
    "invoices": "Invoices",

    // Engineer Dashboard
    "engineer_dashboard": "Engineer Dashboard",
    "verification_quality_overview": "Verification & Quality Overview",
    "offline_will_sync_later": "Offline – will sync later",
    "offline_items_pending_sync": "Offline items pending sync",
    "pending_approvals": "Pending Approvals",
    "photos_to_review": "Photos to Review",
    "delayed_milestones": "Delayed Milestones",
    "material_requests": "Material Requests",
    "review_dprs": "Review DPRs",
    "material_approvals": "Material Approvals",
    "project_details": "Project Details",
    "plot_reviews": "Plot Reviews",
    "materials": "Materials",
    "approvals": "Approvals",

    // Manager Dashboard
    "field_manager_dashboard": "Field Manager Dashboard",
    "reports": "Reports",
    "attendance": "Attendance",

    // Profile Screen
    "my_profile": "My Profile",
    "edit_profile": "Edit Profile",
    "save_profile": "Save Profile",
    "save": "Save",
    "cancel": "Cancel",
    "role": "Role",
    "offline": "Offline",
    "online": "Online",
    "synced_with_cloud": "Synced with cloud",
    "saved_locally": "Saved locally",
    "saved_locally_will_sync": "Saved locally • Will sync when online",
    "syncing": "Syncing...",
    "offline_mode": "Offline mode",
    "no_profile_found": "No profile found",
    "no_profile_loaded": "No profile loaded",
    "profile_saved": "Profile saved locally",
    "profile_saved_syncing": "Profile saved and syncing...",
    "failed_to_save_profile": "Failed to save profile",

    // Language Selection
    "select_language": "Select Language",
    "choose_your_language": "Choose Your Language",
    "select_preferred_language": "Select your preferred language to continue",
    "continue_btn": "Continue",
    "english": "English",
    "hindi": "हिंदी",
    "kannada": "ಕನ್ನಡ",
    "marathi": "मराठी",
    "tamil": "தமிழ்",

    // Common Actions
    "submit": "Submit",
    "confirm": "Confirm",
    "delete": "Delete",
    "edit": "Edit",
    "update": "Update",
    "close": "Close",
    "back": "Back",
    "next": "Next",
    "done": "Done",
    "retry": "Retry",
    "refresh": "Refresh",

    // Common Messages
    "success": "Success",
    "error": "Error",
    "warning": "Warning",
    "info": "Info",
    "coming_soon": "Coming soon...",
    "no_data_available": "No data available",
    "try_again": "Try again",

    // Sync Messages
    "sync_complete": "Sync complete",
    "sync_failed": "Sync failed",
    "sync_in_progress": "Sync in progress",

    // Connectivity
    "no_internet_connection": "No internet connection",
    "internet_restored": "Internet restored",
    "working_offline": "Working offline",

    // Placeholder Screens
    "screen_coming_soon": "screen coming soon...",
  };


  /// Hindi translations
  static const Map<String, String> _hindi = {
    // App Name & Branding
    "app_name": "निर्माण सेतु",
    "manage_projects": "परियोजनाओं का प्रबंधन करें",
    "manage_projects_ease": "आसानी से परियोजनाओं का प्रबंधन करें",

    // Welcome Screen
    "get_started": "शुरू करें",

    // Role Selection
    "choose_your_role": "अपनी भूमिका चुनें",
    "select_how_you_use": "चुनें कि आप निर्माण सेतु का उपयोग कैसे करते हैं",
    "field_manager": "फील्ड मैनेजर",
    "field_manager_desc": "साइट पर कार्यों का प्रबंधन करें और दैनिक संचालन की देखरेख करें",
    "project_engineer": "परियोजना इंजीनियर",
    "project_engineer_desc": "परियोजना योजनाएं डिजाइन करें और तकनीकी सटीकता सुनिश्चित करें",
    "owner_client": "मालिक / ग्राहक",
    "owner_client_desc": "परियोजना की प्रगति को ट्रैक करें और अनुबंधों का प्रबंधन करें",

    // Authentication
    "login": "लॉगिन",
    "log_in": "लॉग इन करें",
    "logout": "लॉगआउट",
    "create_account": "खाता बनाएं",
    "email": "ईमेल",
    "password": "पासवर्ड",
    "confirm_password": "पासवर्ड की पुष्टि करें",
    "full_name": "पूरा नाम",
    "phone": "फोन",
    "phone_optional": "फोन (वैकल्पिक)",
    "mobile_number": "मोबाइल नंबर",
    "forgot_password": "पासवर्ड भूल गए?",
    "reset_your_password": "अपना पासवर्ड रीसेट करें",
    "enter_email_or_phone": "रीसेट लिंक प्राप्त करने के लिए अपना ईमेल या फोन दर्ज करें।",
    "send_reset_link": "रीसेट लिंक भेजें",
    "new_here": "यहाँ नए हैं? ",
    "already_have_account": "पहले से खाता है? ",
    "or_continue_with": "या जारी रखें",
    "google": "गूगल",
    "facebook": "फेसबुक",
    "agree_to_terms": "मैं नियम और गोपनीयता नीति से सहमत हूं",

    // Validation Messages
    "enter_your_email": "अपना ईमेल दर्ज करें",
    "enter_your_password": "अपना पासवर्ड दर्ज करें",
    "enter_your_full_name": "अपना पूरा नाम दर्ज करें",
    "enter_your_name": "अपना नाम दर्ज करें",
    "password_min_length": "पासवर्ड कम से कम 6 अक्षर का होना चाहिए",
    "passwords_do_not_match": "पासवर्ड मेल नहीं खाते",
    "invalid_email": "अमान्य ईमेल",
    "name_required": "नाम आवश्यक है",
    "email_required": "ईमेल आवश्यक है",

    // Auth Errors
    "login_failed": "लॉगिन विफल। कृपया अपनी साख जांचें।",
    "no_account_found": "इस ईमेल के साथ कोई खाता नहीं मिला।",
    "incorrect_password": "गलत पासवर्ड।",
    "invalid_email_address": "अमान्य ईमेल पता।",
    "account_disabled": "यह खाता अक्षम कर दिया गया है।",
    "invalid_credentials": "अमान्य ईमेल या पासवर्ड।",
    "account_creation_failed": "खाता निर्माण विफल। कृपया पुन: प्रयास करें।",
    "email_already_in_use": "इस ईमेल के साथ पहले से एक खाता मौजूद है।",
    "weak_password": "पासवर्ड बहुत कमजोर है। कम से कम 6 अक्षर का उपयोग करें।",
    "google_sign_in_failed": "गूगल साइन-इन विफल। कृपया पुन: प्रयास करें।",
    "logout_failed": "लॉगआउट विफल। कृपया पुन: प्रयास करें।",
    "please_accept_terms": "कृपया नियम और गोपनीयता नीति स्वीकार करें",

    // Loading States
    "please_wait": "कृपया प्रतीक्षा करें...",
    "loading": "लोड हो रहा है...",

    // Dashboard Common
    "dashboard": "डैशबोर्ड",
    "home": "होम",
    "profile": "प्रोफ़ाइल",
    "notifications": "सूचनाएं",
    "settings": "सेटिंग्स",

    // Owner Dashboard
    "owner_dashboard": "मालिक डैशबोर्ड",
    "investment_transparency": "निवेश पारदर्शिता और परियोजना अवलोकन",
    "total_investment": "कुल निवेश",
    "amount_spent": "खर्च की गई राशि",
    "remaining_budget": "शेष बजट",
    "overall_progress": "समग्र प्रगति",
    "progress_gallery": "प्रगति गैलरी",
    "billing_gst_invoices": "बिलिंग और जीएसटी चालान",
    "plot_planning": "प्लॉट योजना",
    "project_status_dashboard": "परियोजना स्थिति डैशबोर्ड",
    "direct_communication": "सीधा संचार",
    "milestones": "मील के पत्थर",
    "gallery": "गैलरी",
    "invoices": "चालान",

    // Engineer Dashboard
    "engineer_dashboard": "इंजीनियर डैशबोर्ड",
    "verification_quality_overview": "सत्यापन और गुणवत्ता अवलोकन",
    "offline_will_sync_later": "ऑफ़लाइन – बाद में सिंक होगा",
    "offline_items_pending_sync": "ऑफ़लाइन आइटम सिंक लंबित",
    "pending_approvals": "लंबित अनुमोदन",
    "photos_to_review": "समीक्षा के लिए फोटो",
    "delayed_milestones": "विलंबित मील के पत्थर",
    "material_requests": "सामग्री अनुरोध",
    "review_dprs": "डीपीआर की समीक्षा करें",
    "material_approvals": "सामग्री अनुमोदन",
    "project_details": "परियोजना विवरण",
    "plot_reviews": "प्लॉट समीक्षा",
    "materials": "सामग्री",
    "approvals": "अनुमोदन",

    // Manager Dashboard
    "field_manager_dashboard": "फील्ड मैनेजर डैशबोर्ड",
    "reports": "रिपोर्ट",
    "attendance": "उपस्थिति",

    // Profile Screen
    "my_profile": "मेरी प्रोफ़ाइल",
    "edit_profile": "प्रोफ़ाइल संपादित करें",
    "save_profile": "प्रोफ़ाइल सहेजें",
    "save": "सहेजें",
    "cancel": "रद्द करें",
    "role": "भूमिका",
    "offline": "ऑफ़लाइन",
    "online": "ऑनलाइन",
    "synced_with_cloud": "क्लाउड के साथ सिंक किया गया",
    "saved_locally": "स्थानीय रूप से सहेजा गया",
    "saved_locally_will_sync": "स्थानीय रूप से सहेजा गया • ऑनलाइन होने पर सिंक होगा",
    "syncing": "सिंक हो रहा है...",
    "offline_mode": "ऑफ़लाइन मोड",
    "no_profile_found": "कोई प्रोफ़ाइल नहीं मिली",
    "no_profile_loaded": "कोई प्रोफ़ाइल लोड नहीं हुई",
    "profile_saved": "प्रोफ़ाइल स्थानीय रूप से सहेजी गई",
    "profile_saved_syncing": "प्रोफ़ाइल सहेजी गई और सिंक हो रही है...",
    "failed_to_save_profile": "प्रोफ़ाइल सहेजने में विफल",

    // Language Selection
    "select_language": "भाषा चुनें",
    "choose_your_language": "अपनी भाषा चुनें",
    "select_preferred_language": "जारी रखने के लिए अपनी पसंदीदा भाषा चुनें",
    "continue_btn": "जारी रखें",
    "english": "English",
    "hindi": "हिंदी",
    "kannada": "ಕನ್ನಡ",
    "marathi": "मराठी",
    "tamil": "தமிழ்",

    // Common Actions
    "submit": "जमा करें",
    "confirm": "पुष्टि करें",
    "delete": "हटाएं",
    "edit": "संपादित करें",
    "update": "अपडेट करें",
    "close": "बंद करें",
    "back": "वापस",
    "next": "अगला",
    "done": "हो गया",
    "retry": "पुन: प्रयास करें",
    "refresh": "रीफ्रेश करें",

    // Common Messages
    "success": "सफलता",
    "error": "त्रुटि",
    "warning": "चेतावनी",
    "info": "जानकारी",
    "coming_soon": "जल्द आ रहा है...",
    "no_data_available": "कोई डेटा उपलब्ध नहीं",
    "try_again": "पुन: प्रयास करें",

    // Sync Messages
    "sync_complete": "सिंक पूर्ण",
    "sync_failed": "सिंक विफल",
    "sync_in_progress": "सिंक प्रगति में",

    // Connectivity
    "no_internet_connection": "कोई इंटरनेट कनेक्शन नहीं",
    "internet_restored": "इंटरनेट बहाल",
    "working_offline": "ऑफ़लाइन काम कर रहा है",

    // Placeholder Screens
    "screen_coming_soon": "स्क्रीन जल्द आ रही है...",
  };


  /// Kannada translations
  static const Map<String, String> _kannada = {
    // App Name & Branding
    "app_name": "ನಿರ್ಮಾಣ ಸೇತು",
    "manage_projects": "ಯೋಜನೆಗಳನ್ನು ನಿರ್ವಹಿಸಿ",
    "manage_projects_ease": "ಸುಲಭವಾಗಿ ಯೋಜನೆಗಳನ್ನು ನಿರ್ವಹಿಸಿ",

    // Welcome Screen
    "get_started": "ಪ್ರಾರಂಭಿಸಿ",

    // Role Selection
    "choose_your_role": "ನಿಮ್ಮ ಪಾತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ",
    "select_how_you_use": "ನೀವು ನಿರ್ಮಾಣ ಸೇತುವನ್ನು ಹೇಗೆ ಬಳಸುತ್ತೀರಿ ಎಂಬುದನ್ನು ಆಯ್ಕೆಮಾಡಿ",
    "field_manager": "ಕ್ಷೇತ್ರ ವ್ಯವಸ್ಥಾಪಕ",
    "field_manager_desc": "ಸೈಟ್‌ನಲ್ಲಿ ಕಾರ್ಯಗಳನ್ನು ನಿರ್ವಹಿಸಿ ಮತ್ತು ದೈನಂದಿನ ಕಾರ್ಯಾಚರಣೆಗಳನ್ನು ಮೇಲ್ವಿಚಾರಣೆ ಮಾಡಿ",
    "project_engineer": "ಯೋಜನಾ ಇಂಜಿನಿಯರ್",
    "project_engineer_desc": "ಯೋಜನಾ ಯೋಜನೆಗಳನ್ನು ವಿನ್ಯಾಸಗೊಳಿಸಿ ಮತ್ತು ತಾಂತ್ರಿಕ ನಿಖರತೆಯನ್ನು ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ",
    "owner_client": "ಮಾಲೀಕ / ಗ್ರಾಹಕ",
    "owner_client_desc": "ಯೋಜನಾ ಪ್ರಗತಿಯನ್ನು ಟ್ರ್ಯಾಕ್ ಮಾಡಿ ಮತ್ತು ಒಪ್ಪಂದಗಳನ್ನು ನಿರ್ವಹಿಸಿ",

    // Authentication
    "login": "ಲಾಗಿನ್",
    "log_in": "ಲಾಗ್ ಇನ್ ಮಾಡಿ",
    "logout": "ಲಾಗ್ಔಟ್",
    "create_account": "ಖಾತೆ ರಚಿಸಿ",
    "email": "ಇಮೇಲ್",
    "password": "ಪಾಸ್‌ವರ್ಡ್",
    "confirm_password": "ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ",
    "full_name": "ಪೂರ್ಣ ಹೆಸರು",
    "phone": "ಫೋನ್",
    "phone_optional": "ಫೋನ್ (ಐಚ್ಛಿಕ)",
    "mobile_number": "ಮೊಬೈಲ್ ಸಂಖ್ಯೆ",
    "forgot_password": "ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿರುವಿರಾ?",
    "reset_your_password": "ನಿಮ್ಮ ಪಾಸ್‌ವರ್ಡ್ ಮರುಹೊಂದಿಸಿ",
    "enter_email_or_phone": "ಮರುಹೊಂದಿಸುವ ಲಿಂಕ್ ಸ್ವೀಕರಿಸಲು ನಿಮ್ಮ ಇಮೇಲ್ ಅಥವಾ ಫೋನ್ ನಮೂದಿಸಿ.",
    "send_reset_link": "ಮರುಹೊಂದಿಸುವ ಲಿಂಕ್ ಕಳುಹಿಸಿ",
    "new_here": "ಇಲ್ಲಿ ಹೊಸದೇ? ",
    "already_have_account": "ಈಗಾಗಲೇ ಖಾತೆ ಹೊಂದಿದ್ದೀರಾ? ",
    "or_continue_with": "ಅಥವಾ ಮುಂದುವರಿಸಿ",
    "google": "ಗೂಗಲ್",
    "facebook": "ಫೇಸ್‌ಬುಕ್",
    "agree_to_terms": "ನಾನು ನಿಯಮಗಳು ಮತ್ತು ಗೌಪ್ಯತಾ ನೀತಿಗೆ ಒಪ್ಪುತ್ತೇನೆ",

    // Validation Messages
    "enter_your_email": "ನಿಮ್ಮ ಇಮೇಲ್ ನಮೂದಿಸಿ",
    "enter_your_password": "ನಿಮ್ಮ ಪಾಸ್‌ವರ್ಡ್ ನಮೂದಿಸಿ",
    "enter_your_full_name": "ನಿಮ್ಮ ಪೂರ್ಣ ಹೆಸರು ನಮೂದಿಸಿ",
    "enter_your_name": "ನಿಮ್ಮ ಹೆಸರು ನಮೂದಿಸಿ",
    "password_min_length": "ಪಾಸ್‌ವರ್ಡ್ ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳಾಗಿರಬೇಕು",
    "passwords_do_not_match": "ಪಾಸ್‌ವರ್ಡ್‌ಗಳು ಹೊಂದಿಕೆಯಾಗುತ್ತಿಲ್ಲ",
    "invalid_email": "ಅಮಾನ್ಯ ಇಮೇಲ್",
    "name_required": "ಹೆಸರು ಅಗತ್ಯವಿದೆ",
    "email_required": "ಇಮೇಲ್ ಅಗತ್ಯವಿದೆ",

    // Auth Errors
    "login_failed": "ಲಾಗಿನ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ರುಜುವಾತುಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.",
    "no_account_found": "ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಯಾವುದೇ ಖಾತೆ ಕಂಡುಬಂದಿಲ್ಲ.",
    "incorrect_password": "ತಪ್ಪು ಪಾಸ್‌ವರ್ಡ್.",
    "invalid_email_address": "ಅಮಾನ್ಯ ಇಮೇಲ್ ವಿಳಾಸ.",
    "account_disabled": "ಈ ಖಾತೆಯನ್ನು ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ.",
    "invalid_credentials": "ಅಮಾನ್ಯ ಇಮೇಲ್ ಅಥವಾ ಪಾಸ್‌ವರ್ಡ್.",
    "account_creation_failed": "ಖಾತೆ ರಚನೆ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
    "email_already_in_use": "ಈ ಇಮೇಲ್‌ನೊಂದಿಗೆ ಈಗಾಗಲೇ ಖಾತೆ ಅಸ್ತಿತ್ವದಲ್ಲಿದೆ.",
    "weak_password": "ಪಾಸ್‌ವರ್ಡ್ ತುಂಬಾ ದುರ್ಬಲವಾಗಿದೆ. ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳನ್ನು ಬಳಸಿ.",
    "google_sign_in_failed": "ಗೂಗಲ್ ಸೈನ್-ಇನ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
    "logout_failed": "ಲಾಗ್ಔಟ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.",
    "please_accept_terms": "ದಯವಿಟ್ಟು ನಿಯಮಗಳು ಮತ್ತು ಗೌಪ್ಯತಾ ನೀತಿಯನ್ನು ಸ್ವೀಕರಿಸಿ",

    // Loading States
    "please_wait": "ದಯವಿಟ್ಟು ನಿರೀಕ್ಷಿಸಿ...",
    "loading": "ಲೋಡ್ ಆಗುತ್ತಿದೆ...",

    // Dashboard Common
    "dashboard": "ಡ್ಯಾಶ್‌ಬೋರ್ಡ್",
    "home": "ಮುಖಪುಟ",
    "profile": "ಪ್ರೊಫೈಲ್",
    "notifications": "ಅಧಿಸೂಚನೆಗಳು",
    "settings": "ಸೆಟ್ಟಿಂಗ್‌ಗಳು",

    // Owner Dashboard
    "owner_dashboard": "ಮಾಲೀಕ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್",
    "investment_transparency": "ಹೂಡಿಕೆ ಪಾರದರ್ಶಕತೆ ಮತ್ತು ಯೋಜನಾ ಅವಲೋಕನ",
    "total_investment": "ಒಟ್ಟು ಹೂಡಿಕೆ",
    "amount_spent": "ಖರ್ಚು ಮಾಡಿದ ಮೊತ್ತ",
    "remaining_budget": "ಉಳಿದ ಬಜೆಟ್",
    "overall_progress": "ಒಟ್ಟಾರೆ ಪ್ರಗತಿ",
    "progress_gallery": "ಪ್ರಗತಿ ಗ್ಯಾಲರಿ",
    "billing_gst_invoices": "ಬಿಲ್ಲಿಂಗ್ ಮತ್ತು ಜಿಎಸ್‌ಟಿ ಇನ್‌ವಾಯ್ಸ್‌ಗಳು",
    "plot_planning": "ಪ್ಲಾಟ್ ಯೋಜನೆ",
    "project_status_dashboard": "ಯೋಜನಾ ಸ್ಥಿತಿ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್",
    "direct_communication": "ನೇರ ಸಂವಹನ",
    "milestones": "ಮೈಲಿಗಲ್ಲುಗಳು",
    "gallery": "ಗ್ಯಾಲರಿ",
    "invoices": "ಇನ್‌ವಾಯ್ಸ್‌ಗಳು",

    // Engineer Dashboard
    "engineer_dashboard": "ಇಂಜಿನಿಯರ್ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್",
    "verification_quality_overview": "ಪರಿಶೀಲನೆ ಮತ್ತು ಗುಣಮಟ್ಟ ಅವಲೋಕನ",
    "offline_will_sync_later": "ಆಫ್‌ಲೈನ್ – ನಂತರ ಸಿಂಕ್ ಆಗುತ್ತದೆ",
    "offline_items_pending_sync": "ಆಫ್‌ಲೈನ್ ಐಟಂಗಳು ಸಿಂಕ್ ಬಾಕಿ",
    "pending_approvals": "ಬಾಕಿ ಅನುಮೋದನೆಗಳು",
    "photos_to_review": "ಪರಿಶೀಲಿಸಲು ಫೋಟೋಗಳು",
    "delayed_milestones": "ವಿಳಂಬವಾದ ಮೈಲಿಗಲ್ಲುಗಳು",
    "material_requests": "ವಸ್ತು ವಿನಂತಿಗಳು",
    "review_dprs": "ಡಿಪಿಆರ್‌ಗಳನ್ನು ಪರಿಶೀಲಿಸಿ",
    "material_approvals": "ವಸ್ತು ಅನುಮೋದನೆಗಳು",
    "project_details": "ಯೋಜನಾ ವಿವರಗಳು",
    "plot_reviews": "ಪ್ಲಾಟ್ ಪರಿಶೀಲನೆಗಳು",
    "materials": "ವಸ್ತುಗಳು",
    "approvals": "ಅನುಮೋದನೆಗಳು",

    // Manager Dashboard
    "field_manager_dashboard": "ಕ್ಷೇತ್ರ ವ್ಯವಸ್ಥಾಪಕ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್",
    "reports": "ವರದಿಗಳು",
    "attendance": "ಹಾಜರಾತಿ",

    // Profile Screen
    "my_profile": "ನನ್ನ ಪ್ರೊಫೈಲ್",
    "edit_profile": "ಪ್ರೊಫೈಲ್ ಸಂಪಾದಿಸಿ",
    "save_profile": "ಪ್ರೊಫೈಲ್ ಉಳಿಸಿ",
    "save": "ಉಳಿಸಿ",
    "cancel": "ರದ್ದುಮಾಡಿ",
    "role": "ಪಾತ್ರ",
    "offline": "ಆಫ್‌ಲೈನ್",
    "online": "ಆನ್‌ಲೈನ್",
    "synced_with_cloud": "ಕ್ಲೌಡ್‌ನೊಂದಿಗೆ ಸಿಂಕ್ ಮಾಡಲಾಗಿದೆ",
    "saved_locally": "ಸ್ಥಳೀಯವಾಗಿ ಉಳಿಸಲಾಗಿದೆ",
    "saved_locally_will_sync": "ಸ್ಥಳೀಯವಾಗಿ ಉಳಿಸಲಾಗಿದೆ • ಆನ್‌ಲೈನ್ ಆದಾಗ ಸಿಂಕ್ ಆಗುತ್ತದೆ",
    "syncing": "ಸಿಂಕ್ ಆಗುತ್ತಿದೆ...",
    "offline_mode": "ಆಫ್‌ಲೈನ್ ಮೋಡ್",
    "no_profile_found": "ಯಾವುದೇ ಪ್ರೊಫೈಲ್ ಕಂಡುಬಂದಿಲ್ಲ",
    "no_profile_loaded": "ಯಾವುದೇ ಪ್ರೊಫೈಲ್ ಲೋಡ್ ಆಗಿಲ್ಲ",
    "profile_saved": "ಪ್ರೊಫೈಲ್ ಸ್ಥಳೀಯವಾಗಿ ಉಳಿಸಲಾಗಿದೆ",
    "profile_saved_syncing": "ಪ್ರೊಫೈಲ್ ಉಳಿಸಲಾಗಿದೆ ಮತ್ತು ಸಿಂಕ್ ಆಗುತ್ತಿದೆ...",
    "failed_to_save_profile": "ಪ್ರೊಫೈಲ್ ಉಳಿಸಲು ವಿಫಲವಾಗಿದೆ",

    // Language Selection
    "select_language": "ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ",
    "choose_your_language": "ನಿಮ್ಮ ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ",
    "select_preferred_language": "ಮುಂದುವರಿಸಲು ನಿಮ್ಮ ಆದ್ಯತೆಯ ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ",
    "continue_btn": "ಮುಂದುವರಿಸಿ",
    "english": "English",
    "hindi": "हिंदी",
    "kannada": "ಕನ್ನಡ",
    "marathi": "मराठी",
    "tamil": "தமிழ்",

    // Common Actions
    "submit": "ಸಲ್ಲಿಸಿ",
    "confirm": "ದೃಢೀಕರಿಸಿ",
    "delete": "ಅಳಿಸಿ",
    "edit": "ಸಂಪಾದಿಸಿ",
    "update": "ನವೀಕರಿಸಿ",
    "close": "ಮುಚ್ಚಿ",
    "back": "ಹಿಂದೆ",
    "next": "ಮುಂದೆ",
    "done": "ಮುಗಿದಿದೆ",
    "retry": "ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ",
    "refresh": "ರಿಫ್ರೆಶ್ ಮಾಡಿ",

    // Common Messages
    "success": "ಯಶಸ್ಸು",
    "error": "ದೋಷ",
    "warning": "ಎಚ್ಚರಿಕೆ",
    "info": "ಮಾಹಿತಿ",
    "coming_soon": "ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿದೆ...",
    "no_data_available": "ಯಾವುದೇ ಡೇಟಾ ಲಭ್ಯವಿಲ್ಲ",
    "try_again": "ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ",

    // Sync Messages
    "sync_complete": "ಸಿಂಕ್ ಪೂರ್ಣಗೊಂಡಿದೆ",
    "sync_failed": "ಸಿಂಕ್ ವಿಫಲವಾಗಿದೆ",
    "sync_in_progress": "ಸಿಂಕ್ ಪ್ರಗತಿಯಲ್ಲಿದೆ",

    // Connectivity
    "no_internet_connection": "ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವಿಲ್ಲ",
    "internet_restored": "ಇಂಟರ್ನೆಟ್ ಮರುಸ್ಥಾಪಿಸಲಾಗಿದೆ",
    "working_offline": "ಆಫ್‌ಲೈನ್‌ನಲ್ಲಿ ಕೆಲಸ ಮಾಡುತ್ತಿದೆ",

    // Placeholder Screens
    "screen_coming_soon": "ಪರದೆ ಶೀಘ್ರದಲ್ಲೇ ಬರಲಿದೆ...",
  };


  /// Marathi translations
  static const Map<String, String> _marathi = {
    // App Name & Branding
    "app_name": "निर्माण सेतू",
    "manage_projects": "प्रकल्प व्यवस्थापित करा",
    "manage_projects_ease": "सहजपणे प्रकल्प व्यवस्थापित करा",

    // Welcome Screen
    "get_started": "सुरू करा",

    // Role Selection
    "choose_your_role": "तुमची भूमिका निवडा",
    "select_how_you_use": "तुम्ही निर्माण सेतू कसा वापरता ते निवडा",
    "field_manager": "फील्ड मॅनेजर",
    "field_manager_desc": "साइटवरील कामे व्यवस्थापित करा आणि दैनंदिन कामकाजावर देखरेख ठेवा",
    "project_engineer": "प्रकल्प अभियंता",
    "project_engineer_desc": "प्रकल्प योजना तयार करा आणि तांत्रिक अचूकता सुनिश्चित करा",
    "owner_client": "मालक / ग्राहक",
    "owner_client_desc": "प्रकल्पाची प्रगती ट्रॅक करा आणि करार व्यवस्थापित करा",

    // Authentication
    "login": "लॉगिन",
    "log_in": "लॉग इन करा",
    "logout": "लॉगआउट",
    "create_account": "खाते तयार करा",
    "email": "ईमेल",
    "password": "पासवर्ड",
    "confirm_password": "पासवर्डची पुष्टी करा",
    "full_name": "पूर्ण नाव",
    "phone": "फोन",
    "phone_optional": "फोन (ऐच्छिक)",
    "mobile_number": "मोबाइल नंबर",
    "forgot_password": "पासवर्ड विसरलात?",
    "reset_your_password": "तुमचा पासवर्ड रीसेट करा",
    "enter_email_or_phone": "रीसेट लिंक मिळवण्यासाठी तुमचा ईमेल किंवा फोन प्रविष्ट करा.",
    "send_reset_link": "रीसेट लिंक पाठवा",
    "new_here": "येथे नवीन आहात? ",
    "already_have_account": "आधीच खाते आहे? ",
    "or_continue_with": "किंवा सुरू ठेवा",
    "google": "गूगल",
    "facebook": "फेसबुक",
    "agree_to_terms": "मी अटी आणि गोपनीयता धोरणाशी सहमत आहे",

    // Validation Messages
    "enter_your_email": "तुमचा ईमेल प्रविष्ट करा",
    "enter_your_password": "तुमचा पासवर्ड प्रविष्ट करा",
    "enter_your_full_name": "तुमचे पूर्ण नाव प्रविष्ट करा",
    "enter_your_name": "तुमचे नाव प्रविष्ट करा",
    "password_min_length": "पासवर्ड किमान 6 वर्णांचा असावा",
    "passwords_do_not_match": "पासवर्ड जुळत नाहीत",
    "invalid_email": "अवैध ईमेल",
    "name_required": "नाव आवश्यक आहे",
    "email_required": "ईमेल आवश्यक आहे",

    // Auth Errors
    "login_failed": "लॉगिन अयशस्वी. कृपया तुमची माहिती तपासा.",
    "no_account_found": "या ईमेलसह कोणतेही खाते आढळले नाही.",
    "incorrect_password": "चुकीचा पासवर्ड.",
    "invalid_email_address": "अवैध ईमेल पत्ता.",
    "account_disabled": "हे खाते अक्षम केले आहे.",
    "invalid_credentials": "अवैध ईमेल किंवा पासवर्ड.",
    "account_creation_failed": "खाते तयार करणे अयशस्वी. कृपया पुन्हा प्रयत्न करा.",
    "email_already_in_use": "या ईमेलसह आधीच खाते अस्तित्वात आहे.",
    "weak_password": "पासवर्ड खूप कमकुवत आहे. किमान 6 वर्ण वापरा.",
    "google_sign_in_failed": "गूगल साइन-इन अयशस्वी. कृपया पुन्हा प्रयत्न करा.",
    "logout_failed": "लॉगआउट अयशस्वी. कृपया पुन्हा प्रयत्न करा.",
    "please_accept_terms": "कृपया अटी आणि गोपनीयता धोरण स्वीकारा",

    // Loading States
    "please_wait": "कृपया प्रतीक्षा करा...",
    "loading": "लोड होत आहे...",

    // Dashboard Common
    "dashboard": "डॅशबोर्ड",
    "home": "होम",
    "profile": "प्रोफाइल",
    "notifications": "सूचना",
    "settings": "सेटिंग्ज",

    // Owner Dashboard
    "owner_dashboard": "मालक डॅशबोर्ड",
    "investment_transparency": "गुंतवणूक पारदर्शकता आणि प्रकल्प विहंगावलोकन",
    "total_investment": "एकूण गुंतवणूक",
    "amount_spent": "खर्च केलेली रक्कम",
    "remaining_budget": "उर्वरित बजेट",
    "overall_progress": "एकूण प्रगती",
    "progress_gallery": "प्रगती गॅलरी",
    "billing_gst_invoices": "बिलिंग आणि जीएसटी बीजक",
    "plot_planning": "प्लॉट नियोजन",
    "project_status_dashboard": "प्रकल्प स्थिती डॅशबोर्ड",
    "direct_communication": "थेट संवाद",
    "milestones": "टप्पे",
    "gallery": "गॅलरी",
    "invoices": "बीजक",

    // Engineer Dashboard
    "engineer_dashboard": "अभियंता डॅशबोर्ड",
    "verification_quality_overview": "पडताळणी आणि गुणवत्ता विहंगावलोकन",
    "offline_will_sync_later": "ऑफलाइन – नंतर समक्रमित होईल",
    "offline_items_pending_sync": "ऑफलाइन आयटम समक्रमण प्रलंबित",
    "pending_approvals": "प्रलंबित मंजुरी",
    "photos_to_review": "पुनरावलोकनासाठी फोटो",
    "delayed_milestones": "विलंबित टप्पे",
    "material_requests": "साहित्य विनंत्या",
    "review_dprs": "डीपीआर पुनरावलोकन करा",
    "material_approvals": "साहित्य मंजुरी",
    "project_details": "प्रकल्प तपशील",
    "plot_reviews": "प्लॉट पुनरावलोकन",
    "materials": "साहित्य",
    "approvals": "मंजुरी",

    // Manager Dashboard
    "field_manager_dashboard": "फील्ड मॅनेजर डॅशबोर्ड",
    "reports": "अहवाल",
    "attendance": "उपस्थिती",

    // Profile Screen
    "my_profile": "माझे प्रोफाइल",
    "edit_profile": "प्रोफाइल संपादित करा",
    "save_profile": "प्रोफाइल जतन करा",
    "save": "जतन करा",
    "cancel": "रद्द करा",
    "role": "भूमिका",
    "offline": "ऑफलाइन",
    "online": "ऑनलाइन",
    "synced_with_cloud": "क्लाउडसह समक्रमित",
    "saved_locally": "स्थानिक पातळीवर जतन केले",
    "saved_locally_will_sync": "स्थानिक पातळीवर जतन केले • ऑनलाइन असताना समक्रमित होईल",
    "syncing": "समक्रमित होत आहे...",
    "offline_mode": "ऑफलाइन मोड",
    "no_profile_found": "कोणतेही प्रोफाइल आढळले नाही",
    "no_profile_loaded": "कोणतेही प्रोफाइल लोड झाले नाही",
    "profile_saved": "प्रोफाइल स्थानिक पातळीवर जतन केले",
    "profile_saved_syncing": "प्रोफाइल जतन केले आणि समक्रमित होत आहे...",
    "failed_to_save_profile": "प्रोफाइल जतन करण्यात अयशस्वी",

    // Language Selection
    "select_language": "भाषा निवडा",
    "choose_your_language": "तुमची भाषा निवडा",
    "select_preferred_language": "सुरू ठेवण्यासाठी तुमची पसंतीची भाषा निवडा",
    "continue_btn": "सुरू ठेवा",
    "english": "English",
    "hindi": "हिंदी",
    "kannada": "ಕನ್ನಡ",
    "marathi": "मराठी",
    "tamil": "தமிழ்",

    // Common Actions
    "submit": "सबमिट करा",
    "confirm": "पुष्टी करा",
    "delete": "हटवा",
    "edit": "संपादित करा",
    "update": "अपडेट करा",
    "close": "बंद करा",
    "back": "मागे",
    "next": "पुढे",
    "done": "पूर्ण झाले",
    "retry": "पुन्हा प्रयत्न करा",
    "refresh": "रीफ्रेश करा",

    // Common Messages
    "success": "यश",
    "error": "त्रुटी",
    "warning": "चेतावणी",
    "info": "माहिती",
    "coming_soon": "लवकरच येत आहे...",
    "no_data_available": "कोणताही डेटा उपलब्ध नाही",
    "try_again": "पुन्हा प्रयत्न करा",

    // Sync Messages
    "sync_complete": "समक्रमण पूर्ण",
    "sync_failed": "समक्रमण अयशस्वी",
    "sync_in_progress": "समक्रमण प्रगतीपथावर",

    // Connectivity
    "no_internet_connection": "इंटरनेट कनेक्शन नाही",
    "internet_restored": "इंटरनेट पुनर्संचयित",
    "working_offline": "ऑफलाइन कार्य करत आहे",

    // Placeholder Screens
    "screen_coming_soon": "स्क्रीन लवकरच येत आहे...",
  };


  /// Tamil translations
  static const Map<String, String> _tamil = {
    // App Name & Branding
    "app_name": "நிர்மாண சேது",
    "manage_projects": "திட்டங்களை நிர்வகிக்கவும்",
    "manage_projects_ease": "எளிதாக திட்டங்களை நிர்வகிக்கவும்",

    // Welcome Screen
    "get_started": "தொடங்குங்கள்",

    // Role Selection
    "choose_your_role": "உங்கள் பங்கை தேர்வு செய்யவும்",
    "select_how_you_use": "நீங்கள் நிர்மாண சேதுவை எவ்வாறு பயன்படுத்துகிறீர்கள் என்பதைத் தேர்ந்தெடுக்கவும்",
    "field_manager": "கள மேலாளர்",
    "field_manager_desc": "தளத்தில் பணிகளை நிர்வகித்து தினசரி செயல்பாடுகளை மேற்பார்வையிடவும்",
    "project_engineer": "திட்ட பொறியாளர்",
    "project_engineer_desc": "திட்ட திட்டங்களை வடிவமைத்து தொழில்நுட்ப துல்லியத்தை உறுதிப்படுத்தவும்",
    "owner_client": "உரிமையாளர் / வாடிக்கையாளர்",
    "owner_client_desc": "திட்ட முன்னேற்றத்தை கண்காணித்து ஒப்பந்தங்களை நிர்வகிக்கவும்",

    // Authentication
    "login": "உள்நுழைவு",
    "log_in": "உள்நுழைக",
    "logout": "வெளியேறு",
    "create_account": "கணக்கை உருவாக்கவும்",
    "email": "மின்னஞ்சல்",
    "password": "கடவுச்சொல்",
    "confirm_password": "கடவுச்சொல்லை உறுதிப்படுத்தவும்",
    "full_name": "முழு பெயர்",
    "phone": "தொலைபேசி",
    "phone_optional": "தொலைபேசி (விருப்பமானது)",
    "mobile_number": "மொபைல் எண்",
    "forgot_password": "கடவுச்சொல்லை மறந்துவிட்டீர்களா?",
    "reset_your_password": "உங்கள் கடவுச்சொல்லை மீட்டமைக்கவும்",
    "enter_email_or_phone": "மீட்டமைப்பு இணைப்பைப் பெற உங்கள் மின்னஞ்சல் அல்லது தொலைபேசியை உள்ளிடவும்.",
    "send_reset_link": "மீட்டமைப்பு இணைப்பை அனுப்பவும்",
    "new_here": "இங்கே புதியவரா? ",
    "already_have_account": "ஏற்கனவே கணக்கு உள்ளதா? ",
    "or_continue_with": "அல்லது தொடரவும்",
    "google": "கூகுள்",
    "facebook": "பேஸ்புக்",
    "agree_to_terms": "நான் விதிமுறைகள் மற்றும் தனியுரிமை கொள்கையை ஏற்கிறேன்",

    // Validation Messages
    "enter_your_email": "உங்கள் மின்னஞ்சலை உள்ளிடவும்",
    "enter_your_password": "உங்கள் கடவுச்சொல்லை உள்ளிடவும்",
    "enter_your_full_name": "உங்கள் முழு பெயரை உள்ளிடவும்",
    "enter_your_name": "உங்கள் பெயரை உள்ளிடவும்",
    "password_min_length": "கடவுச்சொல் குறைந்தது 6 எழுத்துகளாக இருக்க வேண்டும்",
    "passwords_do_not_match": "கடவுச்சொற்கள் பொருந்தவில்லை",
    "invalid_email": "தவறான மின்னஞ்சல்",
    "name_required": "பெயர் தேவை",
    "email_required": "மின்னஞ்சல் தேவை",

    // Auth Errors
    "login_failed": "உள்நுழைவு தோல்வியடைந்தது. உங்கள் விவரங்களைச் சரிபார்க்கவும்.",
    "no_account_found": "இந்த மின்னஞ்சலுடன் கணக்கு எதுவும் இல்லை.",
    "incorrect_password": "தவறான கடவுச்சொல்.",
    "invalid_email_address": "தவறான மின்னஞ்சல் முகவரி.",
    "account_disabled": "இந்த கணக்கு முடக்கப்பட்டுள்ளது.",
    "invalid_credentials": "தவறான மின்னஞ்சல் அல்லது கடவுச்சொல்.",
    "account_creation_failed": "கணக்கு உருவாக்கம் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.",
    "email_already_in_use": "இந்த மின்னஞ்சலுடன் ஏற்கனவே கணக்கு உள்ளது.",
    "weak_password": "கடவுச்சொல் மிகவும் பலவீனமானது. குறைந்தது 6 எழுத்துகளைப் பயன்படுத்தவும்.",
    "google_sign_in_failed": "கூகுள் உள்நுழைவு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.",
    "logout_failed": "வெளியேறுதல் தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.",
    "please_accept_terms": "விதிமுறைகள் மற்றும் தனியுரிமை கொள்கையை ஏற்கவும்",

    // Loading States
    "please_wait": "தயவுசெய்து காத்திருக்கவும்...",
    "loading": "ஏற்றுகிறது...",

    // Dashboard Common
    "dashboard": "டாஷ்போர்டு",
    "home": "முகப்பு",
    "profile": "சுயவிவரம்",
    "notifications": "அறிவிப்புகள்",
    "settings": "அமைப்புகள்",

    // Owner Dashboard
    "owner_dashboard": "உரிமையாளர் டாஷ்போர்டு",
    "investment_transparency": "முதலீட்டு வெளிப்படைத்தன்மை மற்றும் திட்ட மேலோட்டம்",
    "total_investment": "மொத்த முதலீடு",
    "amount_spent": "செலவழித்த தொகை",
    "remaining_budget": "மீதமுள்ள பட்ஜெட்",
    "overall_progress": "ஒட்டுமொத்த முன்னேற்றம்",
    "progress_gallery": "முன்னேற்ற காட்சியகம்",
    "billing_gst_invoices": "பில்லிங் மற்றும் ஜிஎஸ்டி விலைப்பட்டியல்கள்",
    "plot_planning": "நில திட்டமிடல்",
    "project_status_dashboard": "திட்ட நிலை டாஷ்போர்டு",
    "direct_communication": "நேரடி தொடர்பு",
    "milestones": "மைல்கற்கள்",
    "gallery": "காட்சியகம்",
    "invoices": "விலைப்பட்டியல்கள்",

    // Engineer Dashboard
    "engineer_dashboard": "பொறியாளர் டாஷ்போர்டு",
    "verification_quality_overview": "சரிபார்ப்பு மற்றும் தர மேலோட்டம்",
    "offline_will_sync_later": "ஆஃப்லைன் – பின்னர் ஒத்திசைக்கப்படும்",
    "offline_items_pending_sync": "ஆஃப்லைன் உருப்படிகள் ஒத்திசைவு நிலுவையில்",
    "pending_approvals": "நிலுவையில் உள்ள ஒப்புதல்கள்",
    "photos_to_review": "மதிப்பாய்வு செய்ய புகைப்படங்கள்",
    "delayed_milestones": "தாமதமான மைல்கற்கள்",
    "material_requests": "பொருள் கோரிக்கைகள்",
    "review_dprs": "டிபிஆர்களை மதிப்பாய்வு செய்யவும்",
    "material_approvals": "பொருள் ஒப்புதல்கள்",
    "project_details": "திட்ட விவரங்கள்",
    "plot_reviews": "நில மதிப்பாய்வுகள்",
    "materials": "பொருட்கள்",
    "approvals": "ஒப்புதல்கள்",

    // Manager Dashboard
    "field_manager_dashboard": "கள மேலாளர் டாஷ்போர்டு",
    "reports": "அறிக்கைகள்",
    "attendance": "வருகைப்பதிவு",

    // Profile Screen
    "my_profile": "எனது சுயவிவரம்",
    "edit_profile": "சுயவிவரத்தைத் திருத்து",
    "save_profile": "சுயவிவரத்தைச் சேமி",
    "save": "சேமி",
    "cancel": "ரத்துசெய்",
    "role": "பங்கு",
    "offline": "ஆஃப்லைன்",
    "online": "ஆன்லைன்",
    "synced_with_cloud": "கிளவுடுடன் ஒத்திசைக்கப்பட்டது",
    "saved_locally": "உள்ளூரில் சேமிக்கப்பட்டது",
    "saved_locally_will_sync": "உள்ளூரில் சேமிக்கப்பட்டது • ஆன்லைனில் இருக்கும்போது ஒத்திசைக்கப்படும்",
    "syncing": "ஒத்திசைக்கிறது...",
    "offline_mode": "ஆஃப்லைன் பயன்முறை",
    "no_profile_found": "சுயவிவரம் எதுவும் இல்லை",
    "no_profile_loaded": "சுயவிவரம் ஏற்றப்படவில்லை",
    "profile_saved": "சுயவிவரம் உள்ளூரில் சேமிக்கப்பட்டது",
    "profile_saved_syncing": "சுயவிவரம் சேமிக்கப்பட்டு ஒத்திசைக்கிறது...",
    "failed_to_save_profile": "சுயவிவரத்தைச் சேமிக்க முடியவில்லை",

    // Language Selection
    "select_language": "மொழியைத் தேர்ந்தெடுக்கவும்",
    "choose_your_language": "உங்கள் மொழியைத் தேர்வு செய்யவும்",
    "select_preferred_language": "தொடர உங்கள் விருப்ப மொழியைத் தேர்ந்தெடுக்கவும்",
    "continue_btn": "தொடரவும்",
    "english": "English",
    "hindi": "हिंदी",
    "kannada": "ಕನ್ನಡ",
    "marathi": "मराठी",
    "tamil": "தமிழ்",

    // Common Actions
    "submit": "சமர்ப்பிக்கவும்",
    "confirm": "உறுதிப்படுத்து",
    "delete": "நீக்கு",
    "edit": "திருத்து",
    "update": "புதுப்பிக்கவும்",
    "close": "மூடு",
    "back": "பின்",
    "next": "அடுத்து",
    "done": "முடிந்தது",
    "retry": "மீண்டும் முயற்சிக்கவும்",
    "refresh": "புதுப்பிக்கவும்",

    // Common Messages
    "success": "வெற்றி",
    "error": "பிழை",
    "warning": "எச்சரிக்கை",
    "info": "தகவல்",
    "coming_soon": "விரைவில் வருகிறது...",
    "no_data_available": "தரவு எதுவும் இல்லை",
    "try_again": "மீண்டும் முயற்சிக்கவும்",

    // Sync Messages
    "sync_complete": "ஒத்திசைவு முடிந்தது",
    "sync_failed": "ஒத்திசைவு தோல்வியடைந்தது",
    "sync_in_progress": "ஒத்திசைவு நடைபெறுகிறது",

    // Connectivity
    "no_internet_connection": "இணைய இணைப்பு இல்லை",
    "internet_restored": "இணையம் மீட்டமைக்கப்பட்டது",
    "working_offline": "ஆஃப்லைனில் வேலை செய்கிறது",

    // Placeholder Screens
    "screen_coming_soon": "திரை விரைவில் வருகிறது...",
  };
}
