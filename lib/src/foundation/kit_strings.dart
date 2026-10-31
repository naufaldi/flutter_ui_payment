import '../payment/payment_models.dart';
import '../verification/capture_models.dart';
import 'payment_localizations.dart';

/// English/Indonesian strings for the interaction, navigation, sheet, media,
/// promotion and transaction components. Kept apart from the payment strings
/// so each file stays readable; hosts use them through
/// [PaymentLocalizations.of] like every other kit string.
extension KitStrings on PaymentLocalizations {
  String _k(String en, String id) => languageCode == 'id' ? id : en;

  /// Spoken percentage.
  String chartPercent(String value) => _k('$value percent', '$value persen');

  // Charts
  String get chartLine => _k('Line chart', 'Grafik garis');
  String get chartBar => _k('Bar chart', 'Grafik batang');
  String get chartMeter => _k('Breakdown', 'Rincian');
  String get chartSparkline => _k('Trend', 'Tren');
  String get chartNoData => _k('No data', 'Tidak ada data');
  String get chartPendingKey => _k('Pending', 'Menunggu');
  String get chartUnknownKey => _k('Not confirmed', 'Belum terkonfirmasi');
  String get chartLoadFailed => _k('Chart didn’t load', 'Grafik gagal dimuat');
  String get chartEmptyTitle =>
      _k('No data for this period', 'Belum ada data untuk periode ini');
  String chartRange(String from, String to, int count) => _k(
    'From $from to $to, $count period(s).',
    'Dari $from sampai $to, $count periode.',
  );
  String chartLowest(String amount, String label) =>
      _k('Lowest $amount on $label.', 'Terendah $amount pada $label.');
  String chartHighest(String amount, String label) =>
      _k('Highest $amount on $label.', 'Tertinggi $amount pada $label.');
  String chartLatest(String amount, String label) =>
      _k('Latest $amount on $label.', 'Terakhir $amount pada $label.');
  String chartPendingCount(int n) => _k(
    n == 1
        ? '1 period is pending and not counted.'
        : '$n periods are pending and not counted.',
    '$n periode masih menunggu dan tidak dihitung.',
  );
  String chartUnknownCount(int n) => _k(
    n == 1
        ? '1 period is not confirmed yet and not counted.'
        : '$n periods are not confirmed yet and not counted.',
    '$n periode belum terkonfirmasi dan tidak dihitung.',
  );
  String chartMissingCount(int n) => _k(
    n == 1 ? '1 period has no data.' : '$n periods have no data.',
    '$n periode tanpa data.',
  );
  String meterItem(String label, String amount) => '$label $amount';

  // Capture
  String get captureSourceTitle => _k('Add a photo', 'Tambah foto');
  String get captureSourceCamera => _k('Take a photo', 'Ambil foto');
  String get captureSourceGallery =>
      _k('Choose from gallery', 'Pilih dari galeri');
  String get captureSourceFile => _k('Choose a file', 'Pilih file');
  String get captureTipLight =>
      _k('Use even light', 'Gunakan cahaya yang merata');
  String get captureTipGlare =>
      _k('Avoid glare on the card', 'Hindari pantulan cahaya di kartu');
  String get captureTipCorners =>
      _k('Show all four corners', 'Tampilkan keempat sudut kartu');
  String get captureTipFaceAndCard => _k(
    'Make sure your face and the card are both visible',
    'Pastikan wajah dan KTP sama-sama terlihat',
  );
  String get captureTipNoCover => _k(
    'Don’t cover any text with your fingers',
    'Jangan menutupi tulisan dengan jari',
  );
  String get captureTake => _k('Take photo', 'Ambil foto');
  String get captureRetake => _k('Retake', 'Ulangi');
  String get captureUse => _k('Use photo', 'Pakai foto');
  String captureTitle(CaptureKind kind) => switch (kind) {
    CaptureKind.idCard => _k('Photo of your ID card', 'Foto KTP'),
    CaptureKind.selfieWithIdCard => _k(
      'Selfie with your ID card',
      'Selfie dengan KTP',
    ),
  };
  String captureFramingHint(CaptureKind kind) => switch (kind) {
    CaptureKind.idCard => _k(
      'Fit the card inside the frame.',
      'Posisikan KTP di dalam bingkai.',
    ),
    CaptureKind.selfieWithIdCard => _k(
      'Keep your face in the oval and hold the card below your chin.',
      'Posisikan wajah di dalam oval dan pegang KTP di bawah dagu.',
    ),
  };
  String capturePhotoLabel(CaptureKind kind) => switch (kind) {
    CaptureKind.idCard => _k('Your photo: ID card', 'Foto Anda: KTP'),
    CaptureKind.selfieWithIdCard => _k(
      'Your photo: selfie with ID card',
      'Foto Anda: selfie dengan KTP',
    ),
  };
  String captureFrameLabel(CaptureKind kind) => switch (kind) {
    CaptureKind.idCard => _k('Frame for your ID card', 'Bingkai untuk KTP'),
    CaptureKind.selfieWithIdCard => _k(
      'Frame for your face and ID card',
      'Bingkai untuk wajah dan KTP',
    ),
  };

  // Interaction
  String get close => _k('Close', 'Tutup');
  String get cancel => _k('Cancel', 'Batal');
  String get confirm => _k('Confirm', 'Konfirmasi');
  String get moreActions => _k('More actions', 'Aksi lainnya');
  String get loading => _k('Loading', 'Memuat');
  String get retry => _k('Retry', 'Coba lagi');
  String get expand => _k('Show details', 'Tampilkan detail');
  String get collapse => _k('Hide details', 'Sembunyikan detail');
  String get dismiss => _k('Dismiss', 'Tutup');

  // Navigation
  String get openNavigation => _k('Open navigation', 'Buka navigasi');
  String get navigation => _k('Navigation', 'Navigasi');
  String get selected => _k('Selected', 'Dipilih');

  // Sheets
  String get closeSheet => _k('Close panel', 'Tutup panel');

  // Media
  String get play => _k('Play', 'Putar');
  String get pause => _k('Pause', 'Jeda');
  String get replay => _k('Replay', 'Putar ulang');
  String get mute => _k('Mute', 'Bisukan');
  String get unmute => _k('Unmute', 'Bunyikan');
  String get seek => _k('Playback position', 'Posisi pemutaran');
  String get videoLoading => _k('Loading video', 'Memuat video');
  String get videoBuffering => _k('Buffering', 'Menyangga');
  String get videoEnded => _k('Finished', 'Selesai');
  String get videoErrorTitle =>
      _k('Video can’t play', 'Video tidak dapat diputar');
  String get videoErrorMessage => _k(
    'Check your connection and try again.',
    'Periksa koneksi lalu coba lagi.',
  );
  String get videoUnsupported => _k(
    'Video isn’t available on this device.',
    'Video tidak tersedia di perangkat ini.',
  );
  String videoPosition(String position, String duration) =>
      _k('$position of $duration', '$position dari $duration');

  // Promotions
  String get sponsored => _k('Sponsored', 'Bersponsor');
  String get promotion => _k('Promo', 'Promo');
  String get whyThisAd => _k('Why this?', 'Kenapa ini?');
  String get promoUnavailable =>
      _k('No offers right now', 'Belum ada penawaran');
  String get promoLoadFailed =>
      _k('Offers didn’t load', 'Penawaran gagal dimuat');

  // Payment extras
  String get updatingTotal => _k('Updating total…', 'Memperbarui total…');
  String stepOf(int current, int total, String label) => _k(
    'Step $current of $total: $label',
    'Langkah $current dari $total: $label',
  );
  String get completedStep => _k('completed', 'selesai');
  String get balanceTitle => _k('Balance', 'Saldo');
  String get balanceUnavailable =>
      _k('Balance unavailable', 'Saldo tidak tersedia');
  String get balanceInsufficient =>
      _k('Not enough balance', 'Saldo tidak cukup');
  String balanceShortfall(String amount) => _k(
    'Add $amount to pay with balance.',
    'Tambah $amount untuk membayar dengan saldo.',
  );
  String limitUsed(String used, String total) => _k(
    '$used of $total monthly limit used',
    '$used dari limit bulanan $total terpakai',
  );
  String get promoCodeLabel => _k('Promo code', 'Kode promo');
  String get apply => _k('Apply', 'Pakai');
  String get remove => _k('Remove', 'Hapus');
  String get checkingCode => _k('Checking code…', 'Memeriksa kode…');
  String get promoCodeEmpty =>
      _k('Enter a code first.', 'Masukkan kode terlebih dulu.');
  String promoApplied(String code) => _k('$code applied', '$code dipakai');
  String get merchantVerified =>
      _k('Verified merchant', 'Merchant terverifikasi');
  String orderRef(String ref) => _k('Order $ref', 'Pesanan $ref');

  /// Default search field label.
  String get search => _k('Search', 'Cari');

  // Transactions
  String get transactionsTitle => _k('Transactions', 'Transaksi');
  String get searchTransactions => _k('Search transactions', 'Cari transaksi');
  String get clearSearch => _k('Clear search', 'Hapus pencarian');
  String get noTransactionsTitle =>
      _k('No transactions yet', 'Belum ada transaksi');
  String get noTransactionsMessage => _k(
    'Payments you make will appear here.',
    'Pembayaran yang Anda lakukan akan muncul di sini.',
  );
  String get noMatchesTitle => _k('No matches', 'Tidak ada hasil');
  String get noMatchesMessage =>
      _k('Try another keyword or filter.', 'Coba kata kunci atau filter lain.');
  String get transactionsFailedTitle =>
      _k('Transactions didn’t load', 'Transaksi gagal dimuat');
  String get resetFilters => _k('Reset filters', 'Atur ulang filter');
  String transactionFilterLabel(TransactionFilter filter) => switch (filter) {
    TransactionFilter.all => _k('All', 'Semua'),
    TransactionFilter.inProgress => _k('In progress', 'Dalam proses'),
    TransactionFilter.succeeded => _k('Succeeded', 'Berhasil'),
    TransactionFilter.unsuccessful => _k('Unsuccessful', 'Tidak berhasil'),
    TransactionFilter.refunds => _k('Refunds', 'Refund'),
  };
  String get paymentLabel => _k('Payment', 'Pembayaran');
  String get dateLabel => _k('Date', 'Tanggal');
  String get methodLabel => _k('Method', 'Metode');
  String get merchantLabel => _k('Merchant', 'Merchant');
}

/// Groups used by transaction filters. Defined here so the strings and the
/// filter stay in one vocabulary; the matching rules live with the records.
enum TransactionFilter { all, inProgress, succeeded, unsuccessful, refunds }

/// Short status label shared by transaction rows and details.
extension PaymentStatusLabel on PaymentLocalizations {
  String paymentStatusShort(PaymentStatus? status) => switch (status) {
    null => statusUnknownTitle,
    PaymentStatus.requiresAction => statusRequiresActionTitle,
    PaymentStatus.processing => statusProcessingTitle,
    PaymentStatus.pending => statusPendingTitle,
    PaymentStatus.succeeded => languageCode == 'id' ? 'Berhasil' : 'Succeeded',
    PaymentStatus.failed => languageCode == 'id' ? 'Gagal' : 'Failed',
    PaymentStatus.canceled => languageCode == 'id' ? 'Dibatalkan' : 'Canceled',
    PaymentStatus.expired => languageCode == 'id' ? 'Kedaluwarsa' : 'Expired',
  };
}
