import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../payment/payment_models.dart';
import '../verification/verification_models.dart';
import 'money.dart';

/// Strings and formatters for the kit in English (`en`) and Indonesian (`id`).
///
/// Add [PaymentLocalizations.delegate] to `localizationsDelegates`. Without
/// it, widgets still pick a language from the ambient locale.
class PaymentLocalizations {
  PaymentLocalizations(
    this.languageCode, {
    this.dateInputPattern = 'DD/MM/YYYY',
  }) : assert(_validDatePattern(dateInputPattern)),
       moneyFormat = MoneyFormat(languageCode);

  /// Typed date hint, DD/MM/YYYY in both locales (Q12).
  /// DD, MM and YYYY each occur once with one repeated /, . or - separator.
  /// Override app-wide with a host `LocalizationsDelegate<PaymentLocalizations>`
  /// returning `PaymentLocalizations(code, dateInputPattern: 'MM/DD/YYYY')`.
  /// Applies app-wide; there is no per-field override.
  final String dateInputPattern;

  /// Persistent localized pattern; parsing uses dateInputPattern.
  String get dateInputHint => languageCode == 'id'
      ? dateInputPattern
            .replaceAll('DD', 'HH')
            .replaceAll('MM', 'BB')
            .replaceAll('YYYY', 'TTTT')
      : dateInputPattern;

  static bool _validDatePattern(String pattern) {
    final match = RegExp(
      r'^(DD|MM|YYYY)([/.\-])(DD|MM|YYYY)\2(DD|MM|YYYY)$',
    ).firstMatch(pattern);
    return match != null && {match[1], match[3], match[4]}.length == 3;
  }

  /// Compact calendar range using the same localized month names as formatDate.
  ///
  /// Each date keeps its no-break spaces. The short same-month form
  /// ("1–31 Oct 2026") never breaks at its dash (U+2060 joins it); the
  /// spaced form keeps one break after "– " so a long range can wrap at
  /// large text without splitting a date (#65).
  String formatDateRange(DateTime start, DateTime end) {
    if ((start.year == end.year &&
        start.month == end.month &&
        start.day == end.day)) {
      return formatDate(start);
    }
    final e = formatDate(end);
    if (start.year != end.year) return '${formatDate(start)}$_nbsp– $e';
    if (start.month == end.month) return '${start.day}$_wj–$_wj$e';
    return '${start.day}$_nbsp${_month(start)}$_nbsp– $e';
  }

  /// Calendar date in the host zone; unlike [formatDateTime], no conversion
  /// to the device zone occurs and the time is ignored. Day, month and year
  /// are joined by no-break spaces (U+00A0), so "1 Oct 2026" never wraps
  /// inside the date.
  String formatDate(DateTime value) =>
      '${value.day}$_nbsp${_month(value)}$_nbsp${value.year}';

  static const _nbsp = '\u00A0';
  static const _wj = '\u2060';
  String _month(DateTime value) =>
      (_id ? _monthsId : _monthsEn)[value.month - 1];

  final String languageCode;
  final MoneyFormat moneyFormat;

  static const supportedLanguages = ['en', 'id'];

  static const LocalizationsDelegate<PaymentLocalizations> delegate =
      _PaymentLocalizationsDelegate();

  static PaymentLocalizations of(BuildContext context) {
    final fromDelegate = Localizations.of<PaymentLocalizations>(
      context,
      PaymentLocalizations,
    );
    if (fromDelegate != null) return fromDelegate;
    final code = Localizations.maybeLocaleOf(context)?.languageCode;
    return PaymentLocalizations(code == 'id' ? 'id' : 'en');
  }

  bool get _id => languageCode == 'id';
  String _t(String en, String id) => _id ? id : en;

  static const _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _monthsId = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// "30 Oct 2026, 14:05" / "30 Okt 2026, 14.05" in the device time zone.
  /// The date part uses [formatDate]'s no-break spaces.
  String formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${formatDate(local)}, $hh${_id ? '.' : ':'}$mm';
  }

  String formatBytes(int bytes) {
    final decimal = moneyFormat.decimalSeparator;
    if (bytes >= 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      final text = mb == mb.roundToDouble()
          ? mb.toStringAsFixed(0)
          : mb.toStringAsFixed(1).replaceAll('.', decimal);
      return '$text MB';
    }
    return '${(bytes / 1024).ceil()} KB';
  }

  // General
  String get working => _t('Working…', 'Sedang diproses…');
  String get contentHidden => _t('Content hidden', 'Konten disembunyikan');
  String timeRemaining(String time) =>
      _t('Time remaining $time', 'Sisa waktu $time');
  String get continueLabel => _t('Continue', 'Lanjutkan');
  String get tryAgain => _t('Try again', 'Coba lagi');
  String get edit => _t('Edit', 'Ubah');
  String get copy => _t('Copy', 'Salin');
  String get copied => _t('Copied', 'Disalin');
  String get copyFailed => _t('Copy failed', 'Gagal menyalin');
  String get unavailable => _t('Unavailable', 'Tidak tersedia');
  String get detailsTitle => _t('Details', 'Detail');
  String get lastUpdated => _t('Last updated', 'Terakhir diperbarui');
  String updatedAt(String time) => _t('Updated $time', 'Diperbarui $time');
  String get checkingStatus => _t('Checking status…', 'Mengecek status…');
  String get submitting => _t('Submitting…', 'Mengirim…');

  // Amount
  String get amountLabel => _t('Amount', 'Nominal');
  String minimumAmount(String v) => _t('Min. $v', 'Min. $v');
  String maximumAmount(String v) => _t('Max. $v', 'Maks. $v');
  String amountIssue(AmountIssue issue, {Money? minimum, Money? maximum}) {
    return switch (issue) {
      AmountIssue.empty => _t('Enter an amount.', 'Masukkan nominal.'),
      AmountIssue.invalidFormat => _t(
        'Use digits only, for example 150000.',
        'Gunakan angka saja, misalnya 150000.',
      ),
      AmountIssue.ambiguous => _t(
        'This format can be read two ways. Remove separators and try again.',
        'Format ini bisa dibaca dua arti. Hapus pemisah lalu coba lagi.',
      ),
      AmountIssue.negative => _t(
        'Amount can’t be negative.',
        'Nominal tidak boleh negatif.',
      ),
      AmountIssue.zero => _t(
        'Amount must be more than 0.',
        'Nominal harus lebih dari 0.',
      ),
      AmountIssue.belowMinimum => _t(
        'Minimum amount is ${minimum == null ? '' : moneyFormat.format(minimum)}.',
        'Nominal minimum ${minimum == null ? '' : moneyFormat.format(minimum)}.',
      ),
      AmountIssue.aboveMaximum => _t(
        'Maximum amount is ${maximum == null ? '' : moneyFormat.format(maximum)}.',
        'Nominal maksimum ${maximum == null ? '' : moneyFormat.format(maximum)}.',
      ),
    };
  }

  // Summary & methods
  String get summaryTitle => _t('Order summary', 'Ringkasan pesanan');
  String get totalLabel => _t('Total', 'Total');
  String get totalChangedTitle =>
      _t('The total has changed', 'Total pembayaran berubah');
  String totalChangedMessage(String before, String after) => _t(
    'Was $before, now $after. Review the details before paying.',
    'Sebelumnya $before, sekarang $after. Tinjau detail sebelum membayar.',
  );
  String acceptNewTotal(String total) => _t(
    'I’ve reviewed the new total of $total',
    'Saya sudah meninjau total baru $total',
  );
  String get methodTitle => _t('Payment method', 'Metode pembayaran');
  String get paymentMethod => methodTitle;
  String get payWithTitle => _t('Pay with', 'Bayar dengan');
  String get noMethodsTitle =>
      _t('No payment methods available', 'Belum ada metode pembayaran');
  String get noMethodsMessage => _t(
    'Payment can’t continue right now. Try again later.',
    'Pembayaran belum bisa dilanjutkan. Coba lagi nanti.',
  );
  String payAmount(String total) => _t('Pay $total', 'Bayar $total');
  String get sendingPayment => _t('Sending payment…', 'Mengirim pembayaran…');

  // Authorization
  String get authReadyTitle =>
      _t('Confirm it’s you', 'Konfirmasi bahwa ini Anda');
  String get authReadyMessage => _t(
    'Your app will ask for your PIN or biometrics. Nothing is charged until you approve.',
    'Aplikasi akan meminta PIN atau biometrik. Belum ada dana yang ditarik sebelum Anda menyetujui.',
  );
  String get authInProgressTitle =>
      _t('Waiting for approval…', 'Menunggu persetujuan…');
  String get authInProgressMessage => _t(
    'Complete the confirmation shown by your app.',
    'Selesaikan konfirmasi yang ditampilkan aplikasi.',
  );
  String get authApprovedTitle => _t('Approved', 'Disetujui');
  String get authApprovedMessage =>
      _t('Sending your payment.', 'Mengirim pembayaran Anda.');
  String get authCanceledTitle =>
      _t('Confirmation canceled', 'Konfirmasi dibatalkan');
  String get authCanceledMessage => _t(
    'You stopped the confirmation. No payment was sent.',
    'Anda menghentikan konfirmasi. Pembayaran tidak dikirim.',
  );
  String get authFailedTitle =>
      _t('Confirmation didn’t succeed', 'Konfirmasi tidak berhasil');
  String get authFailedMessage => _t(
    'We couldn’t confirm it’s you. No payment was sent.',
    'Identitas Anda belum bisa dikonfirmasi. Pembayaran tidak dikirim.',
  );
  String get authExpiredTitle =>
      _t('Confirmation timed out', 'Waktu konfirmasi habis');
  String get authExpiredMessage => _t(
    'The confirmation request expired. No payment was sent.',
    'Permintaan konfirmasi kedaluwarsa. Pembayaran tidak dikirim.',
  );
  String get authorize => _t('Confirm payment', 'Konfirmasi pembayaran');
  String get authorizeAgain => _t('Confirm again', 'Konfirmasi ulang');
  String get backToReview => _t('Back to review', 'Kembali ke tinjauan');

  // Instructions
  String get instructionsTitle =>
      _t('Transfer instructions', 'Instruksi transfer');
  String get accountNumber =>
      _t('Virtual account number', 'Nomor virtual account');
  String get amountToPay => _t('Amount to pay', 'Jumlah dibayar');
  String get payBefore => _t('Pay before', 'Bayar sebelum');
  String get howToPay => _t('How to pay', 'Cara bayar');
  String get instructionsElapsedTitle =>
      _t('Payment time has ended', 'Waktu pembayaran berakhir');
  String get instructionsElapsedMessage => _t(
    'If you already transferred, your payment may still be recorded. Check the status before paying again.',
    'Jika Anda sudah transfer, pembayaran mungkin tetap tercatat. Cek status sebelum membayar lagi.',
  );

  // Payment status
  String get statusSendingTitle => _t('Sending', 'Mengirim');
  String get statusSendingMessage => _t(
    'Sending your payment. Keep this screen open.',
    'Pembayaran sedang dikirim. Biarkan layar ini terbuka.',
  );
  String get statusUnknownTitle =>
      _t('Result not confirmed yet', 'Hasil belum terkonfirmasi');
  String get statusUnknownMessage => _t(
    'Your payment was sent but we didn’t get an answer. Don’t pay again — check the status to see what happened.',
    'Pembayaran sudah dikirim tetapi belum ada jawaban. Jangan bayar lagi — cek status untuk melihat hasilnya.',
  );

  /// First line of the unknown-outcome screen, set on its own so the one
  /// instruction that prevents a double charge is read first.
  String get statusUnknownLead => _t('Don’t pay again.', 'Jangan bayar lagi.');
  String get statusUnknownDetail => _t(
    'Your payment was sent, but no result has arrived.',
    'Pembayaran sudah dikirim, tetapi hasilnya belum diterima.',
  );
  String get statusRequiresActionTitle => _t('Action needed', 'Perlu tindakan');
  String get statusRequiresActionMessage => _t(
    'Follow the steps to finish this payment.',
    'Ikuti langkah untuk menyelesaikan pembayaran ini.',
  );
  String get statusProcessingTitle => _t('Processing', 'Diproses');
  String get statusProcessingMessage => _t(
    'Your payment is being processed. This usually takes a moment.',
    'Pembayaran sedang diproses. Biasanya hanya sebentar.',
  );
  String get statusPendingTitle => _t('Pending', 'Menunggu');
  String get statusPendingMessage => _t(
    'Waiting for payment or confirmation from the provider.',
    'Menunggu pembayaran atau konfirmasi dari penyedia.',
  );
  String get statusSucceededTitle =>
      _t('Payment successful', 'Pembayaran berhasil');
  String get statusSucceededMessage =>
      _t('Your payment is complete.', 'Pembayaran Anda selesai.');
  String get statusFailedTitle => _t('Payment failed', 'Pembayaran gagal');
  String get statusFailedMessage => _t(
    'The provider declined this payment. You weren’t charged.',
    'Penyedia menolak pembayaran ini. Dana tidak ditarik.',
  );
  String get statusCanceledTitle =>
      _t('Payment canceled', 'Pembayaran dibatalkan');
  String get statusCanceledMessage =>
      _t('This payment was canceled.', 'Pembayaran ini telah dibatalkan.');
  String get statusExpiredTitle =>
      _t('Payment expired', 'Pembayaran kedaluwarsa');
  String get statusExpiredMessage => _t(
    'The time to pay has ended and no payment was received.',
    'Waktu pembayaran berakhir dan tidak ada pembayaran yang diterima.',
  );
  String get statusUnavailableTitle =>
      _t('Couldn’t refresh status', 'Status belum bisa diperbarui');
  String get statusUnavailableMessage => _t(
    'Showing the last known status. Try checking again shortly.',
    'Menampilkan status terakhir yang diketahui. Coba cek lagi sebentar lagi.',
  );
  String statusLastKnown(String time) => _t(
    'Showing the last known status from $time. This doesn’t mean the payment failed.',
    'Menampilkan status terakhir dari $time. Ini tidak berarti pembayaran gagal.',
  );
  String get attemptReference =>
      _t('Payment reference', 'Referensi pembayaran');
  String get transactionReference => _t('Transaction ID', 'ID transaksi');
  String get notYetConfirmed => _t('Not confirmed yet', 'Belum terkonfirmasi');

  String paymentActionLabel(PaymentAction action) => switch (action) {
    PaymentAction.checkStatus => _t('Check status', 'Cek status'),
    PaymentAction.viewInstructions => _t(
      'View instructions',
      'Lihat instruksi',
    ),
    PaymentAction.requestCancel => _t(
      'Request cancellation',
      'Minta pembatalan',
    ),
    PaymentAction.startNewAttempt => _t(
      'Start a new payment',
      'Buat pembayaran baru',
    ),
    PaymentAction.viewReceipt => _t('View receipt', 'Lihat struk'),
    PaymentAction.contactSupport => _t('Contact support', 'Hubungi bantuan'),
  };

  // Refund
  String get refundTitle => _t('Refund', 'Pengembalian dana');
  String refundStatusLabel(RefundStatus status) => switch (status) {
    RefundStatus.none => _t('No refund', 'Tidak ada pengembalian'),
    RefundStatus.pending => _t('Refund pending', 'Pengembalian diproses'),
    RefundStatus.partial => _t('Partially refunded', 'Dikembalikan sebagian'),
    RefundStatus.refunded => _t('Refunded', 'Dana dikembalikan'),
    RefundStatus.failed => _t('Refund failed', 'Pengembalian gagal'),
  };
  String get refundAmount => _t('Refund amount', 'Nominal pengembalian');
  String get refundAmountUnavailable =>
      _t('Amount unavailable', 'Nominal tidak tersedia');
  String get refundSeparateNote => _t(
    'The original payment stays successful; refunds are tracked separately.',
    'Pembayaran awal tetap berhasil; pengembalian dana dicatat terpisah.',
  );

  // Receipt
  String get merchant => _t('Merchant', 'Merchant');
  String get paidAt => _t('Paid at', 'Dibayar pada');
  String receiptShareTitle(String merchant) =>
      _t('Payment receipt — $merchant', 'Bukti pembayaran — $merchant');
  String get shareReceipt => _t('Share receipt', 'Bagikan struk');
  String get shareDone => _t('Receipt shared', 'Struk dibagikan');
  String get shareDismissed => _t(
    'Sharing canceled. Your receipt is still here.',
    'Berbagi dibatalkan. Struk tetap tersedia.',
  );
  String get shareFailed => _t(
    'Couldn’t share. Your payment and receipt are unchanged.',
    'Gagal membagikan. Pembayaran dan struk tidak berubah.',
  );
  String get copyFailedReceipt => _t(
    'Couldn’t copy. Select the ID to copy it manually.',
    'Gagal menyalin. Pilih ID untuk menyalin manual.',
  );
  String get shareAllowlistNote => _t(
    'Shares merchant, transaction ID, time, total and masked method only.',
    'Hanya membagikan merchant, ID transaksi, waktu, total, dan metode yang disamarkan.',
  );

  // Verification
  String get kycIntroTitle =>
      _t('Verify your identity', 'Verifikasi identitas Anda');
  String get kycIntroMessage => _t(
    'We’ll ask for the following. Here’s why each item is needed.',
    'Kami akan meminta data berikut. Ini alasan setiap data dibutuhkan.',
  );
  String get readPrivacyPolicy =>
      _t('Read the privacy policy', 'Baca kebijakan privasi');
  String get consentLabel => _t(
    'I agree to share this data for identity verification.',
    'Saya setuju membagikan data ini untuk verifikasi identitas.',
  );
  String get consentRequiredHint =>
      _t('Give consent to continue.', 'Berikan persetujuan untuk melanjutkan.');
  String get fieldNeedsUpdate =>
      _t('Please update this item.', 'Mohon perbarui data ini.');
  String documentLimits(String types, String size) =>
      _t('$types · max $size', '$types · maks. $size');
  String get documentEmpty => _t('Not added', 'Belum ditambahkan');
  String get documentUploading => _t('Uploading', 'Mengunggah');
  String get documentUploaded => _t('Uploaded', 'Terunggah');
  String get documentFailed => _t('Needs attention', 'Perlu perhatian');
  String get documentMissing => _t('Missing', 'Belum ada');
  String get chooseDocument => _t('Choose document', 'Pilih dokumen');
  String get replaceDocument => _t('Replace', 'Ganti');
  String get openSettings => _t('Open settings', 'Buka pengaturan');
  String documentIssueTitle(DocumentIssueKind kind) => switch (kind) {
    DocumentIssueKind.permissionDenied => _t(
      'Access not allowed',
      'Akses tidak diizinkan',
    ),
    DocumentIssueKind.permissionPermanentlyDenied => _t(
      'Access is turned off',
      'Akses dinonaktifkan',
    ),
    DocumentIssueKind.tooLarge => _t(
      'File too large',
      'Ukuran file terlalu besar',
    ),
    DocumentIssueKind.unsupportedType => _t(
      'File type not accepted',
      'Jenis file tidak diterima',
    ),
    DocumentIssueKind.uploadInterrupted => _t(
      'Upload interrupted',
      'Unggahan terputus',
    ),
    DocumentIssueKind.rejectedByHost => _t(
      'Document not accepted',
      'Dokumen tidak diterima',
    ),
  };
  String documentIssueMessage(
    DocumentIssueKind kind,
    String limits,
  ) => switch (kind) {
    DocumentIssueKind.permissionDenied => _t(
      'Allow access to add a document. You can keep filling in other details.',
      'Izinkan akses untuk menambahkan dokumen. Data lain tetap bisa diisi.',
    ),
    DocumentIssueKind.permissionPermanentlyDenied => _t(
      'Turn on access in Settings to add a document.',
      'Aktifkan akses di Pengaturan untuk menambahkan dokumen.',
    ),
    DocumentIssueKind.tooLarge => _t(
      'Choose a smaller file ($limits).',
      'Pilih file yang lebih kecil ($limits).',
    ),
    DocumentIssueKind.unsupportedType => _t(
      'Choose an accepted file ($limits).',
      'Pilih file yang diterima ($limits).',
    ),
    DocumentIssueKind.uploadInterrupted => _t(
      'The connection dropped. Your file wasn’t saved; try again.',
      'Koneksi terputus. File belum tersimpan; coba lagi.',
    ),
    DocumentIssueKind.rejectedByHost => _t(
      'Choose a different document.',
      'Pilih dokumen lain.',
    ),
  };
  String get reviewDetailsTitle => _t('Your details', 'Data Anda');
  String get reviewDocumentsTitle => _t('Documents', 'Dokumen');
  String get documentsIncomplete => _t(
    'Add every document before submitting.',
    'Lengkapi semua dokumen sebelum mengirim.',
  );
  String get submitVerification =>
      _t('Submit for verification', 'Kirim untuk verifikasi');
  String get kycUnknownTitle =>
      _t('Submission not confirmed', 'Pengiriman belum terkonfirmasi');
  String get kycUnknownMessage => _t(
    'We didn’t hear back after sending. Your details may already be under review — check the status before sending again.',
    'Belum ada jawaban setelah pengiriman. Data Anda mungkin sudah ditinjau — cek status sebelum mengirim ulang.',
  );
  String kycStatusTitle(VerificationStatus status) => switch (status) {
    VerificationStatus.notStarted => _t('Not verified', 'Belum diverifikasi'),
    VerificationStatus.inReview => _t('In review', 'Sedang ditinjau'),
    VerificationStatus.actionRequired => _t('Update needed', 'Perlu perbaikan'),
    VerificationStatus.verified => _t('Verified', 'Terverifikasi'),
    VerificationStatus.rejected => _t('Not approved', 'Tidak disetujui'),
    VerificationStatus.expired => _t(
      'Verification expired',
      'Verifikasi kedaluwarsa',
    ),
  };
  String kycStatusMessage(VerificationStatus status) => switch (status) {
    VerificationStatus.notStarted => _t(
      'Verify your identity to use features that require it.',
      'Verifikasi identitas untuk memakai fitur yang membutuhkannya.',
    ),
    VerificationStatus.inReview => _t(
      'We’re checking your details. You’ll see the result here.',
      'Data Anda sedang diperiksa. Hasilnya akan muncul di sini.',
    ),
    VerificationStatus.actionRequired => _t(
      'Some items need an update. Your other details are kept.',
      'Beberapa data perlu diperbaiki. Data lain tetap tersimpan.',
    ),
    VerificationStatus.verified => _t(
      'Your identity is verified.',
      'Identitas Anda sudah terverifikasi.',
    ),
    VerificationStatus.rejected => _t(
      'Your verification wasn’t approved. Contact support for next steps.',
      'Verifikasi Anda tidak disetujui. Hubungi bantuan untuk langkah berikutnya.',
    ),
    VerificationStatus.expired => _t(
      'Your verification is no longer valid. Verify again to continue.',
      'Verifikasi Anda sudah tidak berlaku. Verifikasi ulang untuk melanjutkan.',
    ),
  };
  String verificationActionLabel(VerificationAction action) => switch (action) {
    VerificationAction.start => _t('Start verification', 'Mulai verifikasi'),
    VerificationAction.fixDetails => _t('Update details', 'Perbarui data'),
    VerificationAction.checkStatus => _t('Check status', 'Cek status'),
    VerificationAction.contactSupport => _t(
      'Contact support',
      'Hubungi bantuan',
    ),
    VerificationAction.continueToPayment => _t(
      'Continue to payment',
      'Lanjut ke pembayaran',
    ),
  };

  // Calendar (D51, D52, D52a). Day, month and year are joined with no-break
  // spaces so a date never wraps inside itself.

  /// Full month name for [month] 1–12: "October" / "Oktober".
  String monthName(int month) =>
      (_id ? _monthsLongId : _monthsLongEn)[month - 1];

  /// Calendar month heading: "October 2026" / "Oktober 2026".
  String formatMonthYear(DateTime value) =>
      '${monthName(value.month)}\u00A0${value.year}';

  /// Spoken calendar day: "Tuesday, 14 October 2026" /
  /// "Selasa, 14 Oktober 2026".
  String formatDateLong(DateTime value) =>
      '${_weekdaysLong[_id ? 1 : 0][value.weekday - 1]}, '
      '${value.day}\u00A0${monthName(value.month)}\u00A0${value.year}';

  /// Weekday column heading for [weekday] as in [DateTime.weekday]
  /// (1 = Monday … 7 = Sunday): "Mon" / "Sen".
  String weekdayShort(int weekday) =>
      _weekdaysLong[_id ? 1 : 0][weekday - 1].substring(0, 3);

  /// First column of the calendar, as a [DateTime.weekday] value: Monday
  /// in Indonesian, Sunday in English.
  int get firstDayOfWeek => _id ? DateTime.monday : DateTime.sunday;

  static const _monthsLongEn = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _monthsLongId = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', //
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const _weekdaysLong = [
    [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', //
      'Friday', 'Saturday', 'Sunday',
    ],
    ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'],
  ];
}

class _PaymentLocalizationsDelegate
    extends LocalizationsDelegate<PaymentLocalizations> {
  const _PaymentLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      PaymentLocalizations.supportedLanguages.contains(locale.languageCode);

  @override
  Future<PaymentLocalizations> load(Locale locale) =>
      SynchronousFuture(PaymentLocalizations(locale.languageCode));

  @override
  bool shouldReload(_PaymentLocalizationsDelegate old) => false;
}
