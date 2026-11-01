import '../content/data_table.dart';
import '../content/task_list.dart';
import '../forms/date_range_picker.dart';
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

  /// Current local sort summary.
  String sortBy(String summary) => _k('Sort: $summary', 'Urutkan: $summary');

  String get sortDefault => _k('Default order', 'Urutan bawaan');

  /// Direction words matching the column's value kind.
  String sortDirection(PaymentCellType cell, bool ascending) => switch (cell) {
    PaymentCellType.date =>
      ascending
          ? _k('oldest first', 'terlama dulu')
          : _k('newest first', 'terbaru dulu'),
    PaymentCellType.currency =>
      ascending
          ? _k('lowest first', 'terendah dulu')
          : _k('highest first', 'tertinggi dulu'),
    _ => ascending ? _k('A to Z', 'A ke Z') : _k('Z to A', 'Z ke A'),
  };

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

  /// Hint for external destinations.
  String get opensExternally =>
      _k('Opens outside the app', 'Membuka di luar aplikasi');

  /// Banner dismiss action.
  String get hideBanner => _k('Hide banner', 'Sembunyikan banner');

  /// Invalid calendar date.
  String get enterValidDate =>
      _k('Enter a valid date', 'Masukkan tanggal yang valid');

  /// Calendar action.
  String get chooseDate => _k('Choose date', 'Pilih tanggal');

  /// Optional field marker.
  String get optional => _k('optional', 'opsional');

  /// Remaining character count.
  String charactersLeft(int n) => _k(
    n == 1 ? '1 character left' : '$n characters left',
    'Sisa $n karakter',
  );

  /// Currency switch label.
  String get currencyLabel => _k('Currency', 'Mata uang');

  /// Calendar range action.
  String get chooseDates => _k('Choose dates', 'Pilih tanggal');

  /// Custom range action.
  String get customRange => _k('Custom range', 'Rentang lain');

  /// Clear range action.
  String get clearDates => _k('Clear dates', 'Hapus tanggal');

  // Kit date sheets (D51, D52, D52a).

  /// Switches the range sheet to typed entry.
  String get typeDates => _k('Type dates', 'Ketik tanggal');

  /// Switches the range sheet back to the calendar.
  String get useCalendar => _k('Use calendar', 'Pakai kalender');

  /// First typed date of a range.
  String get startDate => _k('Start date', 'Tanggal mulai');

  /// Last typed date of a range.
  String get endDate => _k('End date', 'Tanggal akhir');

  /// Range summary while only the start is chosen.
  String get chooseEndDate => _k('Choose an end date', 'Pilih tanggal akhir');

  /// Applies the chosen range.
  String get applyDates => _k('Apply', 'Terapkan');

  /// Clears the chosen dates.
  String get clear => _k('Clear', 'Hapus');

  /// Wheel column names.
  String get day => _k('Day', 'Hari');
  String get month => _k('Month', 'Bulan');
  String get year => _k('Year', 'Tahun');

  /// Spoken marker on today's date.
  String get today => _k('today', 'hari ini');

  /// Spoken markers on the ends of a range.
  String get rangeStart => _k('range start', 'awal rentang');
  String get rangeEnd => _k('range end', 'akhir rentang');

  /// Typed range whose start is after its end.
  String get startAfterEnd => _k(
    'The start date must be on or before the end date.',
    'Tanggal mulai harus sebelum atau sama dengan tanggal akhir.',
  );

  /// Typed date outside the allowed range.
  String dateOutOfRange(String first, String last) => _k(
    'Choose a date from $first to $last.',
    'Pilih tanggal dari $first sampai $last.',
  );

  /// Chip remove action.
  String removeItem(String label) => _k('Remove $label', 'Hapus $label');

  /// Finishes a multiple-choice search sheet.
  String get done => _k('Done', 'Selesai');

  /// Search result count.
  String resultsCount(int n) =>
      _k(n == 1 ? '1 result' : '$n results', '$n hasil');

  /// Calendar grouping label.
  String dateGranularity(PaymentDateGranularity g) => switch (g) {
    PaymentDateGranularity.day => _k('Day', 'Hari'),
    PaymentDateGranularity.week => _k('Week', 'Minggu'),
    PaymentDateGranularity.month => _k('Month', 'Bulan'),
    PaymentDateGranularity.year => _k('Year', 'Tahun'),
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

  /// Image decode failure.
  String get imageUnavailable =>
      _k('Image unavailable', 'Gambar tidak tersedia');

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

  /// Spoken task status.
  String taskStatus(PaymentTaskStatus status) => _k(
    switch (status) {
      PaymentTaskStatus.notStarted => 'Not started',
      PaymentTaskStatus.inProgress => 'In progress',
      PaymentTaskStatus.blocked => 'Blocked',
      PaymentTaskStatus.complete => 'Complete',
    },
    switch (status) {
      PaymentTaskStatus.notStarted => 'Belum dimulai',
      PaymentTaskStatus.inProgress => 'Sedang berjalan',
      PaymentTaskStatus.blocked => 'Tertahan',
      PaymentTaskStatus.complete => 'Selesai',
    },
  );

  /// Spoken child task completion count.
  String subTasksComplete(int done, int total) => _k(
    '$done of $total sub-tasks complete',
    '$done dari $total subtugas selesai',
  );

  /// Select all on this page.
  String get selectAllOnPage =>
      _k('Select all on this page', 'Pilih semua di halaman ini');

  /// Previous page.
  String get previousPage => _k('Previous page', 'Halaman sebelumnya');

  /// Next page.
  String get nextPage => _k('Next page', 'Halaman berikutnya');

  /// Nothing here yet.
  String get emptyTitle => _k('Nothing here yet', 'Belum ada data');

  /// Sort.
  String get sort => _k('Sort', 'Urutkan');

  /// Move left.
  @Deprecated('Not supported (D28). Removed in 0.2.0.')
  String get moveLeft => _k('Move left', 'Geser ke kiri');

  /// Move right.
  @Deprecated('Not supported (D28). Removed in 0.2.0.')
  String get moveRight => _k('Move right', 'Geser ke kanan');

  /// Wider.
  @Deprecated('Not supported (D28). Removed in 0.2.0.')
  String get wider => _k('Wider', 'Lebarkan');

  /// Narrower.
  @Deprecated('Not supported (D28). Removed in 0.2.0.')
  String get narrower => _k('Narrower', 'Sempitkan');

  /// Localized selectRow label.
  String selectRow(String title) => _k('Select $title', 'Pilih $title');

  /// Localized rowsSelected label.
  String rowsSelected(int n) => _k('$n selected', '$n dipilih');

  /// Localized pageRange label.
  String pageRange(int from, int to, int total) =>
      _k('$from–$to of $total', '$from–$to dari $total');

  /// Localized pageNumber label.
  String pageNumber(int n) => _k('Page $n', 'Halaman $n');

  /// Localized rowActions label.
  String rowActions(String title) =>
      _k('Actions for $title', 'Aksi untuk $title');

  /// Localized sortedAscending label.
  String sortedAscending(String label) =>
      _k('$label, ascending', '$label, naik');

  /// Localized sortedDescending label.
  String sortedDescending(String label) =>
      _k('$label, descending', '$label, turun');

  /// Localized columnOptions label.
  @Deprecated('Not supported (D28). Removed in 0.2.0.')
  String columnOptions(String label) =>
      _k('Column options for $label', 'Opsi kolom $label');

  /// Save.
  String get save => _k('Save', 'Simpan');

  /// Sign in to continue.
  String get signInTitle =>
      _k('Sign in to continue', 'Masuk untuk melanjutkan');

  /// All steps.
  String get allSteps => _k('All steps', 'Semua langkah');

  /// All steps complete.
  String get onboardingDone =>
      _k('All steps complete', 'Semua langkah selesai');

  /// Ancestor navigation label.
  String backTo(String label) => _k('Back to $label', 'Kembali ke $label');

  /// Create an item.
  String get create => _k('Create', 'Tambah');

  /// Sign-in heading over what the connecting app can do (D61).
  String get signInCan => _k('This app can', 'Aplikasi ini bisa');

  /// Sign-in heading over what the connecting app can never do (D61).
  String get signInCannot => _k('It can never', 'Aplikasi ini tidak bisa');
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
