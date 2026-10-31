import 'package:flutter/widgets.dart';

/// Copy owned by the demo host app (not the package).
class DemoStrings {
  const DemoStrings(this.languageCode);

  final String languageCode;

  static DemoStrings of(BuildContext context) =>
      DemoStrings(Localizations.localeOf(context).languageCode);

  bool get _id => languageCode == 'id';
  String _t(String en, String id) => _id ? id : en;

  String get groupAccount => _t("Account", "Akun");
  String get yourAccount => _t("Your account", "Akun Anda");
  String get transactions => _t("Transactions", "Transaksi");
  String get statement => _t("Statement", "Laporan");
  String get fees => _t("Fees", "Biaya");
  String get accountSettings => _t("Settings", "Pengaturan");
  String get signInContinue =>
      _t("Continue with Ruang Bayar", "Lanjut dengan Ruang Bayar");
  String get signInDescription => _t(
    "Sign in to pay, verify your identity and see your payments.",
    "Masuk untuk membayar, memverifikasi identitas, dan melihat pembayaran Anda.",
  );
  String get signInLearnMore =>
      _t("What this app can see", "Yang bisa dilihat aplikasi ini");
  String get signInCanceled =>
      _t("Sign-in was canceled. Try again.", "Masuk dibatalkan. Coba lagi.");
  String get signInFootnote => _t(
    "Ruang Bayar never asks for your PIN in this app.",
    "Ruang Bayar tidak pernah meminta PIN Anda di aplikasi ini.",
  );
  String get terms => _t("Terms", "Ketentuan");
  String get privacy => _t("Privacy", "Privasi");
  String get verifyTitle =>
      _t("Verify your identity", "Verifikasi identitas Anda");
  String get verifyDescription =>
      _t("Three steps, about 3 minutes.", "Tiga langkah, sekitar 3 menit.");
  String get taskDetails => _t("Your details", "Data diri");
  String get taskDocuments => _t("Documents", "Dokumen");
  String get taskReview => _t("Review and submit", "Tinjau dan kirim");
  String get groupPersonal => _t("Personal details", "Data pribadi");
  String get groupWorkAddress => _t("Work and address", "Pekerjaan dan alamat");
  String get province => _t("Province", "Provinsi");
  String get provinceRequired =>
      _t("Choose your province", "Pilih provinsi Anda");
  String get fixHighlighted =>
      _t("Fix the highlighted details", "Perbaiki data yang ditandai");
  String get spendingTitle => _t(
    "Spending, this month vs last",
    "Pengeluaran, bulan ini vs bulan lalu",
  );
  String get thisMonth => _t("This month", "Bulan ini");
  String get lastMonth => _t("Last month", "Bulan lalu");
  String get dateRange => _t("Date range", "Rentang tanggal");
  String get activeFilters => _t("Active filters", "Filter aktif");
  String get clearAll => _t("Clear all", "Hapus semua");
  String get filterDate => _t("Date", "Tanggal");
  String get filterStatus => _t("Status", "Status");
  String get filterSearch => _t("Search", "Cari");
  String get noTransactionsTitle =>
      _t("No transactions in this range", "Tidak ada transaksi di rentang ini");
  String get noTransactionsMessage => _t(
    "Try a wider date range or clear the filters.",
    "Coba rentang tanggal lebih luas atau hapus filter.",
  );
  String get historyFailed =>
      _t("Transactions didn't load", "Transaksi gagal dimuat");
  String get orderContext => _t("Your order", "Pesanan Anda");
  String get merchantHelp => _t("Merchant help", "Bantuan merchant");
  String get last7Days => _t("Last 7 days", "7 hari terakhir");
  String get presetThisMonth => _t("This month", "Bulan ini");
  String get presetLastMonth => _t("Last month", "Bulan lalu");

  String get viewDetails =>
      _t("View transaction details", "Lihat detail transaksi");
  String get paymentModule => _t("Payment", "Pembayaran");
  String get attempts => _t("Attempts", "Percobaan");
  String get merchant => _t("Merchant", "Merchant");
  String get viewReceipt => _t("View receipt", "Lihat struk");
  String get reportProblem => _t("Report a problem", "Laporkan masalah");
  String get whatWentWrong => _t("What went wrong?", "Apa masalahnya?");
  String get chargedTwice => _t("Charged twice", "Terdebit dua kali");
  String get wrongAmount => _t("Wrong amount", "Nominal salah");
  String get notReceived =>
      _t("Didn't get what I paid for", "Pesanan tidak diterima");
  String get otherProblem => _t("Something else", "Lainnya");
  String get describeProblem =>
      _t("Describe the problem", "Jelaskan masalahnya");
  String get noSecrets => _t(
    "Don't include your PIN, OTP or card number.",
    "Jangan tulis PIN, OTP, atau nomor kartu.",
  );
  String get sendReport => _t("Send report", "Kirim laporan");
  String get discardTitle => _t("Discard this report?", "Buang laporan ini?");
  String get discardMessage =>
      _t("What you typed will be lost.", "Teks yang Anda tulis akan hilang.");
  String get discard => _t("Discard", "Buang");
  String get statementTitle => _t(
    "Settlement statement, October 2026",
    "Laporan penyelesaian, Oktober 2026",
  );
  String get searchSettlements => _t("Search settlements", "Cari penyelesaian");
  String get download => _t("Download", "Unduh");
  String get feesTitle => _t("Fee schedule", "Daftar biaya");
  String get feesNote => _t("Fees include VAT.", "Biaya sudah termasuk PPN.");
  String get feesTooltip => _t(
    "Set by Ruang Bayar for each payment method.",
    "Ditetapkan Ruang Bayar per metode pembayaran.",
  );
  String get notifications => _t("Notifications", "Notifikasi");
  String get refundUpdates => _t("Refund updates", "Kabar pengembalian dana");
  String get promotions => _t("Promotions", "Promosi");
  String get payments => _t("Payments", "Pembayaran");
  String get defaultMethod => _t("Default method", "Metode bawaan");
  String get statementLanguage => _t("Statement language", "Bahasa laporan");
  String get saved => _t("Saved", "Tersimpan");
  String get saveFailed =>
      _t("Couldn't save. Try again.", "Gagal menyimpan. Coba lagi.");
  String get noSettlementsTitle =>
      _t("No matching settlements", "Tidak ada penyelesaian yang cocok");
  String get noSettlementsMessage => _t(
    "Clear your search to see the statement.",
    "Hapus pencarian untuk melihat laporan.",
  );
  String get clearSearch => _t("Clear search", "Hapus pencarian");
  String get reportFailed => _t(
    "Report wasn't sent. Try again.",
    'Laporan belum terkirim. Coba lagi.',
  );
  String reportSent(String caseId) =>
      _t('Report sent. Case $caseId', 'Laporan terkirim. Kasus $caseId');
  String downloadSelected(int n) =>
      _t('Download selected ($n)', 'Unduh yang dipilih ($n)');
  String prepared(int n) =>
      _t('Prepared $n settlements', '$n penyelesaian disiapkan');

  String get appName => 'Ruang Bayar';
  String get simulated => _t(
    'Simulation — synthetic data, no real money or identity',
    'Simulasi — data sintetis, tanpa uang atau identitas asli',
  );
  String get tabDemo => _t('Demo', 'Demo');
  String get tabScenarios => _t('Scenarios', 'Skenario');
  String get tabGallery => _t('Gallery', 'Galeri');
  String get settings => _t('Display settings', 'Pengaturan tampilan');
  String get brand => _t('Brand theme', 'Tema brand');
  String get appearance => _t('Appearance', 'Tampilan');
  String get light => _t('Light', 'Terang');
  String get darkLabel => _t('Dark', 'Gelap');
  String get system => _t('System', 'Sistem');
  String get language => _t('Language', 'Bahasa');
  String get textSize => _t('Text size', 'Ukuran teks');
  String get reduceMotion => _t('Reduce motion', 'Kurangi gerakan');

  String get productTitle => 'Paket Belajar';
  String get productSubtitle => _t(
    'One month of guided lessons from Ruang Bayar Akademi',
    'Satu bulan kelas terbimbing dari Ruang Bayar Akademi',
  );
  String get topUpTitle => _t('Learning credit top-up', 'Isi Saldo Belajar');
  String get buyNow => _t('Buy now', 'Beli sekarang');
  String get topUpNow => _t('Top up', 'Isi saldo');
  String get identityStatus => _t('Identity', 'Identitas');
  String get kycNotRequired =>
      _t('Not required by this host', 'Tidak diwajibkan host ini');
  String get unresolvedTitle =>
      _t('A payment needs your attention', 'Ada pembayaran yang perlu dicek');
  String get unresolvedMessage => _t(
    'Its result isn’t final yet. Open it to check the status — don’t pay again.',
    'Hasilnya belum final. Buka untuk cek status — jangan bayar lagi.',
  );
  String get openPayment => _t('Open payment', 'Buka pembayaran');
  String account(String id) => _t('Account $id', 'Akun $id');
  String get switchAccount => _t('Switch account', 'Ganti akun');
  String get loading => _t('Loading…', 'Memuat…');

  String get stepConsent => _t('Verification', 'Verifikasi');
  String get stepIdentity => _t('Your identity', 'Identitas Anda');
  String get stepDocuments => _t('Documents', 'Dokumen');
  String get stepReview => _t('Review', 'Tinjau');
  String get stepStatus => _t('Verification status', 'Status verifikasi');
  String get stepCheckout => _t('Checkout', 'Checkout');
  String get stepConfirm => _t('Review payment', 'Tinjau pembayaran');
  String get stepAuthorize => _t('Confirm payment', 'Konfirmasi pembayaran');
  String get stepPayment => _t('Payment', 'Pembayaran');
  String get stepReceipt => _t('Receipt', 'Struk');

  String get fullName =>
      _t('Full name (as on ID)', 'Nama lengkap (sesuai KTP)');
  String get idNumber => _t('ID number (NIK)', 'Nomor KTP (NIK)');
  String get birthDate => _t('Date of birth', 'Tanggal lahir');

  String get nameRequired =>
      _t('Enter your full name.', 'Masukkan nama lengkap.');
  String get nameTooShort =>
      _t('Name looks too short.', 'Nama terlalu pendek.');
  String get idRequired => _t('Enter your ID number.', 'Masukkan nomor KTP.');
  String get idFormat =>
      _t('NIK must be exactly 16 digits.', 'NIK harus tepat 16 digit.');
  String get occupation => _t('Occupation', 'Pekerjaan');
  String get occupationRequired =>
      _t('Choose your occupation.', 'Pilih pekerjaan Anda.');
  String get employee => _t('Employee', 'Karyawan');
  String get entrepreneur => _t('Entrepreneur', 'Wiraswasta');
  String get student => _t('Student', 'Pelajar atau mahasiswa');
  String get civilServant => _t('Civil servant', 'PNS');
  String get homemaker => _t('Homemaker', 'Ibu rumah tangga');
  String get freelancer => _t('Freelancer', 'Pekerja lepas');
  String get retired => _t('Retired', 'Pensiunan');
  String get other => _t('Other', 'Lainnya');
  String get dobRequired =>
      _t('Enter your date of birth.', 'Masukkan tanggal lahir.');
  String get dobAge => _t('You must be 17 or older.', 'Usia minimal 17 tahun.');
  String get reqIdentityTitle =>
      _t('Name, NIK and date of birth', 'Nama, NIK, dan tanggal lahir');
  String get reqIdentityPurpose => _t(
    'To match you with your ID as required for paid learning services.',
    'Untuk mencocokkan Anda dengan KTP sesuai ketentuan layanan berbayar.',
  );
  String get reqIdTitle => _t('Photo of your ID card', 'Foto KTP');
  String get reqIdPurpose => _t(
    'Checked once by our reviewer, then kept per the retention policy.',
    'Diperiksa sekali oleh peninjau, lalu disimpan sesuai kebijakan retensi.',
  );
  String get reqSelfieTitle =>
      _t('Selfie holding your ID', 'Swafoto dengan KTP');
  String get reqSelfiePurpose => _t(
    'Confirms the ID belongs to you. Never used for marketing.',
    'Memastikan KTP milik Anda. Tidak dipakai untuk pemasaran.',
  );
  String get idCardLabel => _t('ID card (KTP)', 'KTP');
  String get selfieLabel => _t('Selfie with ID', 'Swafoto dengan KTP');
  String get imageTypes => 'JPG, PNG';
  String get pickFixture => _t('Choose a demo document', 'Pilih dokumen demo');
  String get fixtureNote => _t(
    'Synthetic fixtures stand in for the host’s camera or file picker.',
    'Fixture sintetis menggantikan kamera atau pemilih file host.',
  );
  String fixtureTag(String tag) => switch (tag) {
    'tooLarge' => _t('Too large', 'Terlalu besar'),
    'wrongType' => _t('Wrong type', 'Tipe salah'),
    _ => _t('Valid sample', 'Contoh valid'),
  };
  String get continueToReview => _t('Continue to review', 'Lanjut ke tinjauan');
  String get policyOpened => _t(
    'Host opened its privacy policy (simulated).',
    'Host membuka kebijakan privasinya (simulasi).',
  );
  String get supportOpened => _t(
    'Support handoff opened by the host (simulated).',
    'Host membuka kanal bantuan (simulasi).',
  );
  String get backToHome => _t('Back to home', 'Kembali ke beranda');
  String get done => _t('Done', 'Selesai');
  String get reviewAndPay => _t('Review payment', 'Tinjau pembayaran');
  String get getQuote => _t('Get price', 'Lihat harga');
  String get quoteLoading =>
      _t('Getting the latest price…', 'Mengambil harga terbaru…');
  String get quoteFailedTitle =>
      _t('Price unavailable', 'Harga belum tersedia');
  String get retry => _t('Try again', 'Coba lagi');
  String get confirmFootnote => _t(
    'The final price is confirmed by Ruang Bayar when you tap Pay.',
    'Harga final dikonfirmasi Ruang Bayar saat Anda menekan Bayar.',
  );
  String get sessionExpiredTitle => _t('Signed out', 'Sesi berakhir');
  String get cancelRequestedTitle =>
      _t('Cancellation requested', 'Pembatalan diminta');
  String get cancelRequestedMessage => _t(
    'Waiting for the provider to confirm. Until then the payment may still complete.',
    'Menunggu konfirmasi penyedia. Sampai saat itu pembayaran masih bisa selesai.',
  );
  String get leaveTitle => _t('Leave this screen?', 'Tinggalkan layar ini?');
  String get leaveMessage => _t(
    'Leaving doesn’t cancel the payment. It keeps going and you can check its status from Home.',
    'Keluar tidak membatalkan pembayaran. Pembayaran tetap berjalan dan statusnya bisa dicek dari Beranda.',
  );
  String get stay => _t('Stay', 'Tetap di sini');
  String get leave => _t('Leave', 'Keluar');
  String get receiptLoadFailedTitle =>
      _t('Receipt details didn’t load', 'Detail struk gagal dimuat');
  String get receiptLoadFailedMessage => _t(
    'Your payment is successful. Retrying only reloads the details.',
    'Pembayaran Anda berhasil. Coba lagi hanya memuat ulang detail.',
  );

  // Host tools
  String get hostTools => _t('Host tools (simulation)', 'Alat host (simulasi)');
  String get simulateRestart => _t('Simulate restart', 'Simulasi restart');
  String get simulateBackground =>
      _t('Background & resume', 'Background & kembali');
  String hostStats(int submits, int attempts, int charges) => _t(
    'Submits $submits · server attempts $attempts · charges $charges',
    'Submit $submits · attempt server $attempts · penarikan $charges',
  );
  String get hostLogEmpty => _t('No host events yet.', 'Belum ada event host.');

  // Scenario picker
  String get scenarioIntro => _t(
    'Each scenario resets the simulated host with deterministic fixtures and opens the demo where the behavior can be tried.',
    'Setiap skenario mereset host simulasi dengan fixture deterministik dan membuka demo di titik perilaku yang dapat dicoba.',
  );
  String get run => _t('Run', 'Jalankan');
  String get groupJourneys => _t('Main journeys', 'Alur utama');
  String get groupKyc => _t('Identity verification', 'Verifikasi identitas');
  String get groupPayment => _t('Payment', 'Pembayaran');
  String get groupCross => _t('Cross-cutting', 'Lintas fitur');
  String activeScenario(String id) =>
      _t('Scenario $id active', 'Skenario $id aktif');
}
