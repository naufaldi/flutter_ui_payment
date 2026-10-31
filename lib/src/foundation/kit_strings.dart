import '../payment/payment_models.dart';
import 'payment_localizations.dart';

/// English/Indonesian strings for the interaction, navigation, sheet, media,
/// promotion and transaction components. Kept apart from the payment strings
/// so each file stays readable; hosts use them through
/// [PaymentLocalizations.of] like every other kit string.
extension KitStrings on PaymentLocalizations {
  String _k(String en, String id) => languageCode == 'id' ? id : en;

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
