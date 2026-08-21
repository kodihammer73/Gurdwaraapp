// lib/services/localization_service.dart
//
// Lightweight localization for the app. Supports English, Malay and Punjabi.
// The selected language is persisted in SharedPreferences and applied
// immediately via a ValueNotifier so the UI rebuilds on change.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported app languages.
enum AppLanguage {
  english('en', 'English'),
  malay('ms', 'Bahasa Melayu'),
  punjabi('pa', 'ਪੰਜਾਬੀ');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Holds the current language and notifies listeners when it changes.
class LocalizationService {
  LocalizationService._();

  static final LocalizationService instance = LocalizationService._();

  static const String _prefsKey = 'app_language';

  /// Notifies the UI to rebuild when the language changes.
  final ValueNotifier<AppLanguage> language =
      ValueNotifier<AppLanguage>(AppLanguage.english);

  /// Loads the saved language (or defaults to English).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      language.value = AppLanguage.fromCode(code);
    } catch (_) {
      language.value = AppLanguage.english;
    }
  }

  /// Sets the language and persists it.
  Future<void> setLanguage(AppLanguage lang) async {
    language.value = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, lang.code);
    } catch (_) {
      // Best-effort persistence.
    }
  }

  /// Returns the localized string for [key].
  String t(String key) {
    final table = _strings[language.value] ?? _strings[AppLanguage.english]!;
    return table[key] ?? _strings[AppLanguage.english]![key] ?? key;
  }
}

/// Translation tables keyed by language.
const Map<AppLanguage, Map<String, String>> _strings = {
  AppLanguage.english: {
    'home': 'Home',
    'calendar': 'Calendar',
    'gallery': 'Gallery',
    'about': 'About',
    'settings': 'Settings',
    'explore': 'Explore',
    'upcoming_events': 'Upcoming Events',
    'no_events_this_week': 'No events this week',
    'check_calendar': 'Check the calendar for upcoming events.',
    'call': 'Call',
    'directions': 'Directions',
    'whatsapp': 'WhatsApp',
    'quick_actions': 'Quick Actions',
    'last_updated': 'Updated',
    'whats_new': "What's New",
    'language': 'Language',
    'appearance': 'Appearance',
    'preferences': 'Preferences',
    'push_notifications': 'Push Notifications',
    'push_notifications_sub': 'Receive event reminders and announcements',
    'system_default': 'System Default',
    'light': 'Light',
    'dark': 'Dark',
    'about_app': 'About',
    'developed_for': 'Developed for Gurdwara Sahib Melaka',
    'retry': 'Retry',
    'unable_to_load': 'Unable to load',
    'pull_to_refresh': 'Pull down to refresh the latest data from the website.',
    'waheguru': 'Waheguru Ji Ka Khalsa Waheguru Ji Ki Fateh',
    'barsi': 'Barsi',
    'barsi_sub': 'Annual remembrance',
    'calendar_sub': 'View events & schedules',
    'gallery_sub': 'Photos & memories',
    'about_sub': 'Our community',
    'settings_sub': 'Preferences & theme',
    'office_bearers': 'Office Bearers',
    'contact_information': 'Contact Information',
    'address': 'Address',
    'contact_person': 'Contact Person',
    'contact_number': 'Contact Number',
    'map_to_location': 'Map to Location',
    'open_daily': 'Gurdwara Sahib Melaka is open daily.',
    'all_rights_reserved': 'All rights reserved.',
    'version': 'Version',
    'no_events': 'No events on this date.',
    'no_upcoming_events': 'No upcoming events.',
    'today': 'Today',
    'filter_by_year': 'Filter by year',
    'all_years': 'All years',
    'no_images_category': 'No images in this category.',
    'no_gallery_images': 'No gallery images available from the website.',
    'sample_images': 'Here are some sample gallery images:',
    'refresh_gallery': 'Refresh Gallery',
    'unable_to_load_homepage': 'Unable to load homepage',
    'unable_to_load_calendar': 'Unable to load calendar',
    'unable_to_load_gallery': 'Unable to load gallery',
    'unable_to_load_about': 'Unable to load about information',
    'skip': 'Skip',
    'next': 'Next',
    'get_started': 'Get Started',
    'welcome_title': 'Welcome to Gurdwara Sahib Melaka',
    'welcome_sub':
        'Your spiritual home in Melaka. Stay connected with the sangat and never miss a program.',
    'events_calendar_title': 'Events & Calendar',
    'events_calendar_sub':
        'Browse upcoming events, programs and the annual Barsi remembrance — all in one place.',
    'stay_connected_title': 'Stay Connected',
    'stay_connected_sub':
        'Get push notifications for events and browse the photo gallery to relive special moments.',
  },
  AppLanguage.malay: {
    'home': 'Utama',
    'calendar': 'Kalendar',
    'gallery': 'Galeri',
    'about': 'Tentang',
    'settings': 'Tetapan',
    'explore': 'Teroka',
    'upcoming_events': 'Acara Akan Datang',
    'no_events_this_week': 'Tiada acara minggu ini',
    'check_calendar': 'Semak kalendar untuk acara akan datang.',
    'call': 'Panggil',
    'directions': 'Arah',
    'whatsapp': 'WhatsApp',
    'quick_actions': 'Tindakan Pantas',
    'last_updated': 'Dikemas kini',
    'whats_new': 'Apa yang Baru',
    'language': 'Bahasa',
    'appearance': 'Penampilan',
    'preferences': 'Keutamaan',
    'push_notifications': 'Pemberitahuan Push',
    'push_notifications_sub': 'Terima peringatan acara dan pengumuman',
    'system_default': 'Lalai Sistem',
    'light': 'Cerah',
    'dark': 'Gelap',
    'about_app': 'Tentang',
    'developed_for': 'Dibangunkan untuk Gurdwara Sahib Melaka',
    'retry': 'Cuba Lagi',
    'unable_to_load': 'Tidak dapat memuatkan',
    'pull_to_refresh': 'Tarik ke bawah untuk menyegarkan data terkini dari laman web.',
    'waheguru': 'Waheguru Ji Ka Khalsa Waheguru Ji Ki Fateh',
    'barsi': 'Barsi',
    'barsi_sub': 'Peringatan tahunan',
    'calendar_sub': 'Lihat acara & jadual',
    'gallery_sub': 'Foto & kenangan',
    'about_sub': 'Komuniti kami',
    'settings_sub': 'Keutamaan & tema',
    'office_bearers': 'Pegawai',
    'contact_information': 'Maklumat Hubungan',
    'address': 'Alamat',
    'contact_person': 'Orang Hubungan',
    'contact_number': 'Nombor Hubungan',
    'map_to_location': 'Peta ke Lokasi',
    'open_daily': 'Gurdwara Sahib Melaka dibuka setiap hari.',
    'all_rights_reserved': 'Hak cipta terpelihara.',
    'version': 'Versi',
    'no_events': 'Tiada acara pada tarikh ini.',
    'no_upcoming_events': 'Tiada acara akan datang.',
    'today': 'Hari Ini',
    'filter_by_year': 'Tapis mengikut tahun',
    'all_years': 'Semua tahun',
    'no_images_category': 'Tiada imej dalam kategori ini.',
    'no_gallery_images': 'Tiada imej galeri tersedia dari laman web.',
    'sample_images': 'Berikut adalah beberapa imej contoh galeri:',
    'refresh_gallery': 'Segarkan Galeri',
    'unable_to_load_homepage': 'Tidak dapat memuatkan laman utama',
    'unable_to_load_calendar': 'Tidak dapat memuatkan kalendar',
    'unable_to_load_gallery': 'Tidak dapat memuatkan galeri',
    'unable_to_load_about': 'Tidak dapat memuatkan maklumat tentang',
    'skip': 'Langkau',
    'next': 'Seterusnya',
    'get_started': 'Mula',
    'welcome_title': 'Selamat Datang ke Gurdwara Sahib Melaka',
    'welcome_sub':
        'Rumah rohani anda di Melaka. Kekal berhubung dengan sangat dan jangan terlepas sebarang program.',
    'events_calendar_title': 'Acara & Kalendar',
    'events_calendar_sub':
        'Lihat acara akan datang, program dan peringatan Barsi tahunan — semua di satu tempat.',
    'stay_connected_title': 'Kekal Berhubung',
    'stay_connected_sub':
        'Terima pemberitahuan push untuk acara dan lihat galeri foto untuk mengingati detik istimewa.',
  },
  AppLanguage.punjabi: {
    'home': 'ਹੋਮ',
    'calendar': 'ਕੈਲੰਡਰ',
    'gallery': 'ਗੈਲਰੀ',
    'about': 'ਬਾਰੇ',
    'settings': 'ਸੈਟਿੰਗਾਂ',
    'explore': 'ਖੋਜੋ',
    'upcoming_events': 'ਆਉਣ ਵਾਲੇ ਸਮਾਗਮ',
    'no_events_this_week': 'ਇਸ ਹਫ਼ਤੇ ਕੋਈ ਸਮਾਗਮ ਨਹੀਂ',
    'check_calendar': 'ਆਉਣ ਵਾਲੇ ਸਮਾਗਮਾਂ ਲਈ ਕੈਲੰਡਰ ਵੇਖੋ।',
    'call': 'ਕਾਲ',
    'directions': 'ਰਸਤਾ',
    'whatsapp': 'ਵਟਸਐਪ',
    'quick_actions': 'ਤੁਰੰਤ ਕਾਰਵਾਈਆਂ',
    'last_updated': 'ਅੱਪਡੇਟ ਕੀਤਾ',
    'whats_new': 'ਨਵਾਂ ਕੀ ਹੈ',
    'language': 'ਭਾਸ਼ਾ',
    'appearance': 'ਦਿੱਖ',
    'preferences': 'ਤਰਜੀਹਾਂ',
    'push_notifications': 'ਪੁਸ਼ ਸੂਚਨਾਵਾਂ',
    'push_notifications_sub': 'ਸਮਾਗਮ ਰੀਮਾਈਂਡਰ ਅਤੇ ਘੋਸ਼ਣਾਵਾਂ ਪ੍ਰਾਪਤ ਕਰੋ',
    'system_default': 'ਸਿਸਟਮ ਡਿਫਾਲਟ',
    'light': 'ਚਮਕਦਾਰ',
    'dark': 'ਹਨੇਰਾ',
    'about_app': 'ਬਾਰੇ',
    'developed_for': 'ਗੁਰਦੁਆਰਾ ਸਾਹਿਬ ਮਲਕਾ ਲਈ ਵਿਕਸਤ',
    'retry': 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ',
    'unable_to_load': 'ਲੋਡ ਕਰਨ ਵਿੱਚ ਅਸਮਰੱਥ',
    'pull_to_refresh': 'ਵੈੱਬਸਾਈਟ ਤੋਂ ਨਵਾਂ ਡਾਟਾ ਪ੍ਰਾਪਤ ਕਰਨ ਲਈ ਹੇਠਾਂ ਖਿੱਚੋ।',
    'waheguru': 'ਵਾਹਿਗੁਰੂ ਜੀ ਕਾ ਖਾਲਸਾ ਵਾਹਿਗੁਰੂ ਜੀ ਕੀ ਫਤਹਿ',
    'barsi': 'ਬਰਸੀ',
    'barsi_sub': 'ਸਾਲਾਨਾ ਯਾਦਗਿਰੀ',
    'calendar_sub': 'ਸਮਾਗਮ ਅਤੇ ਸਮਾਂ-ਸਾਰਣੀ ਵੇਖੋ',
    'gallery_sub': 'ਫੋਟੋਆਂ ਅਤੇ ਯਾਦਾਂ',
    'about_sub': 'ਸਾਡੀ ਸੰਗਤ',
    'settings_sub': 'ਤਰਜੀਹਾਂ ਅਤੇ ਥੀਮ',
    'office_bearers': 'ਅਧਿਕਾਰੀ',
    'contact_information': 'ਸੰਪਰਕ ਜਾਣਕਾਰੀ',
    'address': 'ਪਤਾ',
    'contact_person': 'ਸੰਪਰਕ ਵਿਅਕਤੀ',
    'contact_number': 'ਸੰਪਰਕ ਨੰਬਰ',
    'map_to_location': 'ਸਥਾਨ ਦਾ ਨਕਸ਼ਾ',
    'open_daily': 'ਗੁਰਦੁਆਰਾ ਸਾਹਿਬ ਮਲਕਾ ਰੋਜ਼ਾਨਾ ਖੁੱਲ੍ਹਾ ਹੈ।',
    'all_rights_reserved': 'ਸਾਰੇ ਹੱਕ ਰਾਖਵੇਂ ਹਨ।',
    'version': 'ਵਰਜਨ',
    'no_events': 'ਇਸ ਤਾਰੀਖ਼ ਨੂੰ ਕੋਈ ਸਮਾਗਮ ਨਹੀਂ।',
    'no_upcoming_events': 'ਕੋਈ ਆਉਣ ਵਾਲਾ ਸਮਾਗਮ ਨਹੀਂ।',
    'today': 'ਅੱਜ',
    'filter_by_year': 'ਸਾਲ ਅਨੁਸਾਰ ਫਿਲਟਰ ਕਰੋ',
    'all_years': 'ਸਾਰੇ ਸਾਲ',
    'no_images_category': 'ਇਸ ਸ਼੍ਰੇਣੀ ਵਿੱਚ ਕੋਈ ਚਿੱਤਰ ਨਹੀਂ।',
    'no_gallery_images': 'ਵੈੱਬਸਾਈਟ ਤੋਂ ਕੋਈ ਗੈਲਰੀ ਚਿੱਤਰ ਉਪਲਬਧ ਨਹੀਂ।',
    'sample_images': 'ਇੱਥੇ ਕੁਝ ਨਮੂਨਾ ਗੈਲਰੀ ਚਿੱਤਰ ਹਨ:',
    'refresh_gallery': 'ਗੈਲਰੀ ਤਾਜ਼ਾ ਕਰੋ',
    'unable_to_load_homepage': 'ਹੋਮਪੇਜ ਲੋਡ ਕਰਨ ਵਿੱਚ ਅਸਮਰੱਥ',
    'unable_to_load_calendar': 'ਕੈਲੰਡਰ ਲੋਡ ਕਰਨ ਵਿੱਚ ਅਸਮਰੱਥ',
    'unable_to_load_gallery': 'ਗੈਲਰੀ ਲੋਡ ਕਰਨ ਵਿੱਚ ਅਸਮਰੱਥ',
    'unable_to_load_about': 'ਬਾਰੇ ਜਾਣਕਾਰੀ ਲੋਡ ਕਰਨ ਵਿੱਚ ਅਸਮਰੱਥ',
    'skip': 'ਛੱਡੋ',
    'next': 'ਅਗਲਾ',
    'get_started': 'ਸ਼ੁਰੂ ਕਰੋ',
    'welcome_title': 'ਗੁਰਦੁਆਰਾ ਸਾਹਿਬ ਮਲਕਾ ਵਿੱਚ ਤੁਹਾਡਾ ਸਵਾਗਤ ਹੈ',
    'welcome_sub':
        'ਮਲਕਾ ਵਿੱਚ ਤੁਹਾਡਾ ਰੂਹਾਨੀ ਘਰ। ਸੰਗਤ ਨਾਲ ਜੁੜੇ ਰਹੋ ਅਤੇ ਕੋਈ ਪ੍ਰੋਗਰਾਮ ਨਾ ਖੁੰਝਾਓ।',
    'events_calendar_title': 'ਸਮਾਗਮ ਅਤੇ ਕੈਲੰਡਰ',
    'events_calendar_sub':
        'ਆਉਣ ਵਾਲੇ ਸਮਾਗਮ, ਪ੍ਰੋਗਰਾਮ ਅਤੇ ਸਾਲਾਨਾ ਬਰਸੀ ਯਾਦਗਿਰੀ — ਸਭ ਇੱਕ ਥਾਂ।',
    'stay_connected_title': 'ਜੁੜੇ ਰਹੋ',
    'stay_connected_sub':
        'ਸਮਾਗਮਾਂ ਲਈ ਪੁਸ਼ ਸੂਚਨਾਵਾਂ ਪ੍ਰਾਪਤ ਕਰੋ ਅਤੇ ਖਾਸ ਪਲਾਂ ਨੂੰ ਯਾਦ ਕਰਨ ਲਈ ਫੋਟੋ ਗੈਲਰੀ ਵੇਖੋ।',
  },
};
