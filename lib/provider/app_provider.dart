import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('tr', 'TR'),
    Locale('en', 'US'),
  ];

  bool get isEnglish => locale.languageCode == 'en';

  // Common
  String get appName => isEnglish ? 'Trello' : 'Trello';
  String get cancel => isEnglish ? 'Cancel' : 'İptal';
  String get save => isEnglish ? 'Save' : 'Kaydet';
  String get delete => isEnglish ? 'Delete' : 'Sil';
  String get edit => isEnglish ? 'Edit' : 'Düzenle';
  String get create => isEnglish ? 'Create' : 'Oluştur';
  String get update => isEnglish ? 'Update' : 'Güncelle';
  String get loading => isEnglish ? 'Loading...' : 'Yükleniyor...';
  String get error => isEnglish ? 'Error' : 'Hata';
  String get success => isEnglish ? 'Success' : 'Başarılı';
  String get confirm => isEnglish ? 'Confirm' : 'Onayla';
  String get close => isEnglish ? 'Close' : 'Kapat';
  String get ok => isEnglish ? 'OK' : 'Tamam';
  String get yes => isEnglish ? 'Yes' : 'Evet';
  String get no => isEnglish ? 'No' : 'Hayır';

  // Navigation
  String get boards => isEnglish ? 'Boards' : 'Panolar';
  String get createBoard => isEnglish ? 'Create' : 'Oluştur';
  String get myBoards => isEnglish ? 'My Boards' : 'Panolarım';
  String get account => isEnglish ? 'Account' : 'Hesabım';
  String get profile => isEnglish ? 'Profile' : 'Profil';

  // Board
  String get boardTitle => isEnglish ? 'Board Title' : 'Pano Başlığı';
  String get boardDescription => isEnglish ? 'Description' : 'Açıklama';
  String get boardColor => isEnglish ? 'Board Color' : 'Pano Rengi';
  String get boardCreated => isEnglish ? 'Board created successfully' : 'Pano başarıyla oluşturuldu';
  String get boardUpdated => isEnglish ? 'Board updated successfully' : 'Pano başarıyla güncellendi';
  String get boardDeleted => isEnglish ? 'Board deleted successfully' : 'Pano başarıyla silindi';
  String get deleteBoardTitle => isEnglish ? 'Delete Board' : 'Panoyu Sil';
  String get deleteBoardConfirm => isEnglish ? 'Are you sure you want to delete this board and all tasks?' : 'Bu panoyu ve tüm görevleri silmek istediğinizden emin misiniz?';
  String get editBoard => isEnglish ? 'Edit Board' : 'Panoyu Düzenle';
  String get noBoards => isEnglish ? 'No boards yet.' : 'Henüz bir pano yok.';

  // Task
  String get tasks => isEnglish ? 'tasks' : 'görev';
  String get task => isEnglish ? 'task' : 'görev';
  String get myTasks => isEnglish ? 'mine' : 'benim';
  String get createTask => isEnglish ? 'Create Task' : 'Görev Oluştur';
  String get taskTitle => isEnglish ? 'Task Title' : 'Görev Başlığı';
  String get taskDescription => isEnglish ? 'Task Description' : 'Görev Açıklaması';
  String get taskPriority => isEnglish ? 'Priority' : 'Öncelik';
  String get taskDeadline => isEnglish ? 'Deadline (Optional)' : 'Bitiş Tarihi (İsteğe bağlı)';
  String get taskAssignees => isEnglish ? 'Assignees' : 'Atanan Kişiler';
  String get taskDetails => isEnglish ? 'Task Details' : 'Görev Detayları';
  String get taskCreated => isEnglish ? 'Task created successfully!' : 'Görev başarıyla oluşturuldu!';
  String get taskUpdated => isEnglish ? 'Task updated successfully!' : 'Görev başarıyla güncellendi!';
  String get taskDeleted => isEnglish ? 'Task deleted successfully!' : 'Görev başarıyla silindi!';
  String get deleteTask => isEnglish ? 'Delete Task' : 'Görevi Sil';
  String get deleteTaskConfirm => isEnglish ? 'Are you sure you want to delete this task?' : 'Bu görevi silmek istediğinizden emin misiniz?';
  String get taskStatusUpdated => isEnglish ? 'Task status updated!' : 'Görev durumu güncellendi!';
  String get noDescription => isEnglish ? 'No description added' : 'Açıklama eklenmemiş';
  String get unassigned => isEnglish ? 'Unassigned' : 'Atanmamış';
  String get notSet => isEnglish ? 'Not set' : 'Belirlenmemiş';

  // Task Status
  String get todo => isEnglish ? 'To Do' : 'Yapılacaklar';
  String get inProgress => isEnglish ? 'In Progress' : 'Devam Edenler';
  String get done => isEnglish ? 'Completed' : 'Tamamlandı';

  // Task Priority
  String get high => isEnglish ? 'High' : 'Yüksek';
  String get medium => isEnglish ? 'Medium' : 'Orta';
  String get low => isEnglish ? 'Low' : 'Düşük';

  // Profile
  String get profilePicture => isEnglish ? 'Profile Picture' : 'Profil Resmi';
  String get editProfile => isEnglish ? 'Edit Profile' : 'Profili Düzenle';
  String get fullName => isEnglish ? 'Full Name' : 'Ad Soyad';
  String get email => isEnglish ? 'Email' : 'E-posta';
  String get profileUpdated => isEnglish ? 'Profile updated successfully!' : 'Profil başarıyla güncellendi!';
  String get nameRequired => isEnglish ? 'Name cannot be empty!' : 'Ad soyad boş olamaz!';
  String get emailRequired => isEnglish ? 'Email cannot be empty!' : 'E-posta boş olamaz!';
  String get totalBoards => isEnglish ? 'Total Boards' : 'Toplam Pano';
  String get completedTasks => isEnglish ? 'Completed' : 'Tamamlanan';
  String get activeTasks => isEnglish ? 'Active Tasks' : 'Aktif Görev';

  // Settings
  String get settings => isEnglish ? 'Settings' : 'Ayarlar';
  String get notifications => isEnglish ? 'Notifications' : 'Bildirimler';
  String get notificationsDesc => isEnglish ? 'Task updates and reminders' : 'Görev güncellemeleri ve hatırlatmalar';
  String get darkTheme => isEnglish ? 'Dark Theme' : 'Koyu Tema';
  String get darkThemeDesc => isEnglish ? 'Switch between dark and light theme' : 'Karanlık ve aydınlık tema arasında geçiş';
  String get language => isEnglish ? 'Language' : 'Dil';
  String get languageChanged => isEnglish ? 'Language changed to' : 'Dil değiştirildi:';
  String get turkish => isEnglish ? 'Turkish' : 'Türkçe';
  String get english => isEnglish ? 'English' : 'İngilizce';
  String get chooseLanguage => isEnglish ? 'Choose Language' : 'Dil Seçin';

  // Security
  String get security => isEnglish ? 'Security' : 'Güvenlik';
  String get securityDesc => isEnglish ? 'Password and security settings' : 'Şifre ve güvenlik ayarları';
  String get changePassword => isEnglish ? 'Change Password' : 'Şifre Değiştir';
  String get currentPassword => isEnglish ? 'Current Password' : 'Mevcut Şifre';
  String get newPassword => isEnglish ? 'New Password' : 'Yeni Şifre';
  String get confirmPassword => isEnglish ? 'Confirm Password' : 'Yeni Şifre Tekrar';
  String get passwordChanged => isEnglish ? 'Password changed successfully!' : 'Şifre başarıyla değiştirildi!';
  String get fillAllFields => isEnglish ? 'Fill in all fields!' : 'Tüm alanları doldurun!';
  String get passwordsNotMatch => isEnglish ? 'Passwords do not match!' : 'Yeni şifreler eşleşmiyor!';
  String get passwordTooShort => isEnglish ? 'Password must be at least 6 characters!' : 'Şifre en az 6 karakter olmalıdır!';

  // Help & Support
  String get helpAndSupport => isEnglish ? 'Help & Support' : 'Yardım ve Destek';
  String get helpAndSupportDesc => isEnglish ? 'FAQ and feedback form' : 'SSS ve geri bildirim formu';
  String get feedbackForm => isEnglish ? 'Feedback Form' : 'Geri Bildirim Formu';
  String get feedbackDesc => isEnglish ? 'Write to us about your questions, suggestions or issues you encounter.' : 'Sorularınız, önerileriniz veya karşılaştığınız sorunlar hakkında bize yazın.';
  String get feedbackPlaceholder => isEnglish ? 'Write your message here...' : 'Mesajınızı buraya yazın...';
  String get feedbackSent => isEnglish ? 'Your feedback has been sent successfully!' : 'Geri bildiriminiz başarıyla gönderildi!';
  String get writeMessage => isEnglish ? 'Please write a message!' : 'Lütfen bir mesaj yazın!';
  String get send => isEnglish ? 'Send' : 'Gönder';

  // About
  String get about => isEnglish ? 'About' : 'Hakkımızda';
  String get aboutDesc => isEnglish ? 'Application information' : 'Uygulama bilgileri';
  String get aboutText => isEnglish 
    ? 'This application has been developed for task and project management.\n\nVersion: 1.0.0\nDeveloper: SnY Team\n© 2023 All rights reserved.'
    : 'Bu uygulama, görev ve proje yönetimi için geliştirilmiştir.\n\nVersiyon: 1.0.0\nGeliştirici: SnY Ekibi\n© 2023 Tüm hakları saklıdır.';

  // Logout
  String get logout => isEnglish ? 'Logout' : 'Çıkış Yap';
  String get logoutDesc => isEnglish ? 'Secure logout from your account' : 'Hesabınızdan güvenli çıkış';
  String get logoutConfirm => isEnglish ? 'Are you sure you want to logout?' : 'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?';

  // Assignees
  String get searchEmail => isEnglish ? 'Search by email...' : 'E-posta adresi yazın...';
  String get addPersonEmail => isEnglish ? 'Type email to add new person...' : 'Yeni kişi eklemek için e-posta yazın...';
  String get unknown => isEnglish ? 'Unknown' : 'Bilinmeyen';
  String get others => isEnglish ? 'others' : 'diğer';

  // Date
  String get today => isEnglish ? 'Today' : 'Bugün';
  String get tomorrow => isEnglish ? 'Tomorrow' : 'Yarın';
  String get yesterday => isEnglish ? 'Yesterday' : 'Dün';
  String get daysLater => isEnglish ? 'days later' : 'gün sonra';
  String get daysAgo => isEnglish ? 'days ago' : 'gün geçti';

  // Activity
  String get activity => isEnglish ? 'Activity' : 'Aktivite';
  String get taskCreatedOn => isEnglish ? 'Task created on' : 'Görev';
  String get lastUpdated => isEnglish ? 'Last updated:' : 'Son güncelleme:';
  String get createdOn => isEnglish ? 'created on' : 'tarihinde oluşturuldu';

  // Status messages
  String get boardTitleRequired => isEnglish ? 'Board title cannot be empty!' : 'Pano başlığı boş olamaz!';
  String get taskTitleRequired => isEnglish ? 'Task title cannot be empty!' : 'Görev başlığı boş olamaz!';
  String get invalidDateFormat => isEnglish ? 'Invalid date format. Please enter in dd.mm.yyyy format.' : 'Geçersiz tarih formatı. Lütfen gg.aa.yyyy formatında girin.';

  // Board ownership
  String get owner => isEnglish ? 'Owner' : 'Sahibi';
  String get member => isEnglish ? 'Member' : 'Üye';

  // Errors
  String get errorLoadingBoards => isEnglish ? 'Error loading boards' : 'Panolar yüklenirken hata oluştu';
  String get errorLoadingTasks => isEnglish ? 'Error loading tasks' : 'Görevler yüklenirken hata oluştu';
  String get errorOccurred => isEnglish ? 'An error occurred:' : 'Bir hata oluştu:';
  String get errorCreatingBoard => isEnglish ? 'Error creating board:' : 'Pano oluşturulurken hata oluştu:';
  String get errorUpdatingBoard => isEnglish ? 'Error updating board:' : 'Pano güncellenirken hata oluştu:';
  String get errorDeletingBoard => isEnglish ? 'Error deleting board:' : 'Pano silinirken hata oluştu:';
  String get errorCreatingTask => isEnglish ? 'Error:' : 'Hata:';
  String get errorUpdatingTask => isEnglish ? 'Error:' : 'Hata:';
  String get errorDeletingTask => isEnglish ? 'Error deleting task:' : 'Görev silinirken hata oluştu:';
  String get errorUpdatingStatus => isEnglish ? 'Error updating status:' : 'Durum güncellenirken hata oluştu:';
  String get errorUpdatingProfile => isEnglish ? 'Error updating profile:' : 'Profil güncellenirken hata oluştu:';
  String get errorChangingPassword => isEnglish ? 'Password could not be changed:' : 'Şifre değiştirilemedi:';
  String get errorSendingFeedback => isEnglish ? 'Feedback could not be sent:' : 'Geri bildirim gönderilemedi:';
  String get errorLoggingOut => isEnglish ? 'Could not logout:' : 'Çıkış yapılamadı:';

  // Loading states
  String get loadingUserData => isEnglish ? 'Loading user data...' : 'Kullanıcı verisi yükleniyor...';
  String get couldNotLoadUserData => isEnglish ? 'Could not load user data' : 'Kullanıcı verisi yüklenemedi';
  String get tryAgain => isEnglish ? 'Try Again' : 'Tekrar Dene';
  String get noNameSpecified => isEnglish ? 'No Name Specified' : 'İsim Belirtilmemiş';

  // Placeholders
  String get enterBoardTitle => isEnglish ? 'Enter board title' : 'Pano başlığını girin';
  String get enterBoardDescription => isEnglish ? 'Enter board description' : 'Pano açıklamasını girin';
  String get enterTaskTitle => isEnglish ? 'Enter task title' : 'Görev başlığını girin';
  String get enterTaskDescription => isEnglish ? 'Enter task description' : 'Görev açıklamasını girin';
  String get dateFormat => isEnglish ? 'dd.mm.yyyy' : 'gg.aa.yyyy';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['tr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}