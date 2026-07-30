class AppConstants {
  const AppConstants._();

  static const String appName = 'Sakshi Vani';
  static const String appHindiName = 'साक्षी वाणी';

  static const String firebaseProjectHint = 'sakshi-vani';

  static const String songsDbAssetPath = 'assets/Sakshivani_Unicode_Clean.db';
  static const String durangAssetPath = 'assets/durang_puthi.json';

  // Song book identifiers.
  static const String bookSakshivani = 'sakshivani';
  static const String bookDurang = 'durang';
  static const String bookSakshivaniLabel = 'साक्षी वाणी';
  static const String bookDurangLabel = 'दुरंग पुथी';
  static const String catechismAssetPath = 'catechism.json';
  static const String quizAssetPath = 'quiz_data.json';
  static const String bibleZipAssetPath = 'bible_db.zip';
  static const String hindiBibleEntryPath = 'Bible-Database_godlytalias-master/Hindi/bible.json';
  static const String englishBibleEntryPath = 'Bible-Database_godlytalias-master/English/bible.json';

  /// Hosted on the main branch — not bundled in the app binary (~42 MB saved).
  static const String bibleZipDownloadUrl =
      'https://github.com/arpanguria68-ui/Sakshivani-Lutherans/raw/main/bible_db.zip';

  static const int songMinTextSize = 14;
  static const int songMaxTextSize = 34;
  static const int songDefaultTextSize = 20;

  // AdMob — Sakshi Vani production account. Must match the
  // <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID">
  // entry in AndroidManifest.xml.
  static const String admobAppId = 'ca-app-pub-6899681300834088~6904562491';
  static const String admobBannerUnitId = 'ca-app-pub-6899681300834088/4487382791';
  static const String admobInterstitialUnitId = 'ca-app-pub-6899681300834088/4278399158';

  static const String iapRemoveAdsProductId = 'remove_ads_tier1';

  /// `cloudflare/email-otp-worker` deployment (no trailing slash).
  static const String emailOtpWorkerUrl = 'https://sakshivani-email-otp.neelimaguria42.workers.dev';

  /// Public privacy / terms (GitHub Pages — free hosting for Play Console).
  static const String siteBaseUrl =
      'https://arpanguria68-ui.github.io/Sakshivani-Lutherans';
  static const String privacyPolicyUrl = '$siteBaseUrl/privacy/';
  static const String privacyPolicyHiUrl = '$siteBaseUrl/privacy/?lang=hi';
  static const String termsOfServiceUrl = '$siteBaseUrl/terms/';
  static const String termsOfServiceHiUrl = '$siteBaseUrl/terms/?lang=hi';

  /// Bundled copies for in-app reading (EN + HI).
  static const String privacyPolicyAssetEn = 'PRIVACY.md';
  static const String privacyPolicyAssetHi = 'PRIVACY_HI.md';
  static const String termsOfServiceAssetEn = 'TERMS.md';
  static const String termsOfServiceAssetHi = 'TERMS_HI.md';
}
