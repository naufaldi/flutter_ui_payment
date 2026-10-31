import 'package:flutter_ui_payment/flutter_ui_payment.dart';

import '../coordinator/demo_coordinator.dart';
import 'scenario_config.dart';

class ScenarioVariant {
  const ScenarioVariant({
    required this.label,
    required this.config,
    this.start = FlowStep.overview,
    this.textScale,
    this.dark,
    this.reduceMotion,
  });

  final Bi label;
  final ScenarioConfig config;

  /// Where the demo opens; seeded attempts always open on their status.
  final FlowStep start;
  final double? textScale;
  final bool? dark;
  final bool? reduceMotion;
}

class Scenario {
  const Scenario({
    required this.id,
    required this.title,
    required this.expect,
    required this.variants,
  });

  final String id;
  final Bi title;

  /// What to try and what must happen; mirrors the PRD acceptance.
  final Bi expect;
  final List<ScenarioVariant> variants;
}

const _noKyc = ScenarioConfig(kycRequired: false);

const _processingThenSuccess = [
  ServerStep(PaymentStatus.processing),
  ServerStep(PaymentStatus.processing),
  ServerStep(PaymentStatus.succeeded),
];

/// Every scenario the PRD's matrix requires, plus the main journeys.
const scenarios = <Scenario>[
  Scenario(
    id: 'H01',
    title: Bi(
      'Complete flow: KYC → pay → receipt',
      'Alur lengkap: KYC → bayar → struk',
    ),
    expect: Bi(
      'Consent, identity, document fixtures, review, in-review then verified (Check status), checkout Rp102.500, host challenge, one submit, host polling to success, receipt.',
      'Consent, identitas, fixture dokumen, tinjauan, ditinjau lalu terverifikasi (Cek status), checkout Rp102.500, challenge host, satu submit, polling host sampai berhasil, struk.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Balance', 'Saldo'),
        config: ScenarioConfig(hostPolls: true),
      ),
    ],
  ),
  Scenario(
    id: 'H02',
    title: Bi('Checkout without KYC', 'Checkout tanpa KYC'),
    expect: Bi(
      'Host policy does not require KYC; checkout opens directly. Choose the virtual account to see instructions, countdown and status refresh without a new payment.',
      'Kebijakan host tidak mewajibkan KYC; checkout langsung terbuka. Pilih virtual account untuk melihat instruksi, countdown, dan refresh status tanpa pembayaran baru.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Balance or VA', 'Saldo atau VA'),
        config: ScenarioConfig(kycRequired: false, hostPolls: true),
        start: FlowStep.checkout,
      ),
    ],
  ),
  Scenario(
    id: 'H03',
    title: Bi('Resume KYC under review', 'Lanjutkan KYC yang sedang ditinjau'),
    expect: Bi(
      'Opens on the in-review status submitted 3 days ago; only Check status is offered.',
      'Membuka status sedang ditinjau sejak 3 hari lalu; hanya Cek status yang tersedia.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('In review', 'Ditinjau'),
        config: ScenarioConfig(initialKyc: VerificationStatus.inReview),
        start: FlowStep.kycStatus,
      ),
    ],
  ),
  // ---------------------------------------------------------------- KYC
  Scenario(
    id: 'K01',
    title: Bi('Consent not given', 'Consent belum diberikan'),
    expect: Bi(
      'Checkbox starts unchecked, Continue is disabled, the policy link opens the host page.',
      'Checkbox tidak tercentang, Lanjutkan nonaktif, tautan kebijakan dibuka oleh host.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Intro', 'Intro'),
        config: ScenarioConfig(),
        start: FlowStep.kycIntro,
      ),
    ],
  ),
  Scenario(
    id: 'K02',
    title: Bi(
      'Empty, invalid and non-ASCII fields',
      'Field kosong, invalid, nama non-ASCII',
    ),
    expect: Bi(
      'Submit empty: errors on each field, focus moves to the first. Name accepts “Đặng Thị Ngọc Ánh”; NIK must be 16 digits (host rule).',
      'Kirim kosong: error di tiap field, fokus ke field pertama. Nama menerima “Đặng Thị Ngọc Ánh”; NIK wajib 16 digit (aturan host).',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Identity form', 'Formulir identitas'),
        config: ScenarioConfig(),
        start: FlowStep.kycIdentity,
      ),
    ],
  ),
  Scenario(
    id: 'K03',
    title: Bi('Capture permission denied', 'Izin kamera ditolak'),
    expect: Bi(
      'Choose “Take a photo”. Host reports the denial; the slot shows Try again or Open settings. Other slots stay usable.',
      'Pilih “Ambil foto”. Host melaporkan penolakan; slot menampilkan Coba lagi atau Buka pengaturan. Slot lain tetap bisa dipakai.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Denied once', 'Ditolak sekali'),
        config: ScenarioConfig(
          captureAccess: [CaptureAccess.denied, CaptureAccess.granted],
        ),
        start: FlowStep.kycDocuments,
      ),
      ScenarioVariant(
        label: Bi('Permanently denied', 'Ditolak permanen'),
        config: ScenarioConfig(
          captureAccess: [CaptureAccess.permanentlyDenied],
        ),
        start: FlowStep.kycDocuments,
      ),
    ],
  ),
  Scenario(
    id: 'K04',
    title: Bi(
      'Too large, wrong type, interrupted',
      'Terlalu besar, tipe salah, terputus',
    ),
    expect: Bi(
      'Pick “ktp_scan_besar.jpg” (12 MB) or “ktp_dokumen.pdf” to see host limits; the first valid upload drops and offers Try again. The camera variant shows a host rejection, then lets you retake.',
      'Pilih “ktp_scan_besar.jpg” (12 MB) atau “ktp_dokumen.pdf” untuk melihat batas host; unggahan valid pertama terputus dan menawarkan Coba lagi.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Documents', 'Dokumen'),
        config: ScenarioConfig(interruptFirstUpload: true),
        start: FlowStep.kycDocuments,
      ),
      ScenarioVariant(
        label: Bi('Camera photo rejected', 'Foto kamera ditolak'),
        config: ScenarioConfig(rejectFirstCapture: true),
        start: FlowStep.kycDocuments,
      ),
    ],
  ),
  Scenario(
    id: 'K05',
    title: Bi('Replace file during upload', 'Ganti file saat unggah'),
    expect: Bi(
      'Uploads take 4 s. Tap Replace while uploading; the older upload finishes but is ignored (see host log) and review shows the newest file.',
      'Unggahan 4 detik. Tekan Ganti saat mengunggah; unggahan lama selesai tetapi diabaikan (lihat log host) dan tinjauan menampilkan file terbaru.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Slow upload', 'Unggah lambat'),
        config: ScenarioConfig(uploadDuration: Duration(seconds: 4)),
        start: FlowStep.kycDocuments,
      ),
    ],
  ),
  Scenario(
    id: 'K06',
    title: Bi('Submit timeout or double tap', 'Submit timeout atau double tap'),
    expect: Bi(
      'Double-tapping Submit sends one request. The answer times out after the host stored it: status shows “not confirmed”, only Check status is offered, never rejected.',
      'Double tap Kirim hanya mengirim satu request. Jawaban timeout setelah host menyimpannya: status “belum terkonfirmasi”, hanya Cek status, tidak pernah ditolak.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Timeout', 'Timeout'),
        config: ScenarioConfig(kycSubmit: KycSubmitOutcome.timeoutThenInReview),
        start: FlowStep.kycReview,
      ),
    ],
  ),
  Scenario(
    id: 'K07',
    title: Bi(
      'Long review, update needed, rejected',
      'Review lama, perlu perbaikan, ditolak',
    ),
    expect: Bi(
      'Each state shows a safe reason and only host-allowed steps. Update needed keeps valid data and asks only for the flagged document. Rejected cannot be retried.',
      'Tiap state menampilkan alasan aman dan langkah yang diizinkan host. Perlu perbaikan mempertahankan data valid dan hanya meminta dokumen yang ditandai. Ditolak tidak bisa diulang.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Long review', 'Review lama'),
        config: ScenarioConfig(initialKyc: VerificationStatus.inReview),
        start: FlowStep.kycStatus,
      ),
      ScenarioVariant(
        label: Bi('Update needed', 'Perlu perbaikan'),
        config: ScenarioConfig(
          initialKyc: VerificationStatus.actionRequired,
          kycReason: Bi(
            'The ID photo is blurry. Upload a clearer photo; your other details are kept.',
            'Foto KTP buram. Unggah foto yang lebih jelas; data lain tetap tersimpan.',
          ),
          kycFieldsToFix: {idCardSlot},
          prefillIdentity: true,
        ),
        start: FlowStep.kycStatus,
      ),
      ScenarioVariant(
        label: Bi('Submit → update needed', 'Kirim → perlu perbaikan'),
        config: ScenarioConfig(kycReview: KycReviewOutcome.actionRequired),
        start: FlowStep.kycReview,
      ),
      ScenarioVariant(
        label: Bi('Rejected', 'Ditolak'),
        config: ScenarioConfig(
          initialKyc: VerificationStatus.rejected,
          kycReason: Bi(
            'Verification could not be approved.',
            'Verifikasi tidak dapat disetujui.',
          ),
        ),
        start: FlowStep.kycStatus,
      ),
    ],
  ),
  Scenario(
    id: 'K08',
    title: Bi(
      'KYC expired, session expired, restart',
      'KYC kedaluwarsa, sesi habis, restart',
    ),
    expect: Bi(
      'Expired KYC asks to verify again. Session expiry at submit returns to review with nothing charged. Restart (host tools) drops the identity draft; the host re-checks eligibility.',
      'KYC kedaluwarsa meminta verifikasi ulang. Sesi habis saat submit kembali ke tinjauan tanpa penarikan dana. Restart (alat host) menghapus draf identitas; host mengecek ulang eligibility.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('KYC expired', 'KYC kedaluwarsa'),
        config: ScenarioConfig(initialKyc: VerificationStatus.expired),
        start: FlowStep.kycStatus,
      ),
      ScenarioVariant(
        label: Bi('Session expired', 'Sesi habis'),
        config: ScenarioConfig(kycRequired: false, sessionExpiredOnce: true),
        start: FlowStep.checkout,
      ),
      ScenarioVariant(
        label: Bi('Restart mid-KYC', 'Restart di tengah KYC'),
        config: ScenarioConfig(prefillIdentity: true),
        start: FlowStep.kycDocuments,
      ),
    ],
  ),
  // ------------------------------------------------------------ Payment
  Scenario(
    id: 'P01',
    title: Bi(
      'Amount: empty, zero, limits, pasted',
      'Nominal: kosong, nol, limit, tempel',
    ),
    expect: Bi(
      'Top-up between Rp10.000 and Rp2.000.000. Try 0, -5, 5000000, “Rp 150.000” and “150,000” (ambiguous in id). Invalid input never gets a quote.',
      'Isi saldo Rp10.000–Rp2.000.000. Coba 0, -5, 5000000, “Rp 150.000”, dan “150,000” (ambigu di id). Input invalid tidak pernah mendapat quote.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Top-up', 'Isi saldo'),
        config: ScenarioConfig(kycRequired: false, flexibleAmount: true),
        start: FlowStep.checkout,
      ),
    ],
  ),
  Scenario(
    id: 'P02',
    title: Bi(
      'Quote failed, expired or changed',
      'Quote gagal, kedaluwarsa, atau berubah',
    ),
    expect: Bi(
      'Failure shows Retry. An expired quote is silently refreshed when terms are equal. A changed total shows old vs new and requires explicit acceptance before paying.',
      'Kegagalan menampilkan Coba lagi. Quote kedaluwarsa diperbarui diam-diam bila syarat sama. Total berubah menampilkan lama vs baru dan wajib disetujui ulang sebelum bayar.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Fails once', 'Gagal sekali'),
        config: ScenarioConfig(
          kycRequired: false,
          quote: QuoteBehavior.failOnce,
        ),
        start: FlowStep.checkout,
      ),
      ScenarioVariant(
        label: Bi('Expires', 'Kedaluwarsa'),
        config: ScenarioConfig(
          kycRequired: false,
          quote: QuoteBehavior.expiredAtConfirm,
        ),
        start: FlowStep.checkout,
      ),
      ScenarioVariant(
        label: Bi('Total changes', 'Total berubah'),
        config: ScenarioConfig(
          kycRequired: false,
          quote: QuoteBehavior.totalChangesAtConfirm,
        ),
        start: FlowStep.checkout,
      ),
    ],
  ),
  Scenario(
    id: 'P03',
    title: Bi(
      'No methods, unavailable, low balance',
      'Metode kosong, tidak tersedia, saldo kurang',
    ),
    expect: Bi(
      'Reasons are visible on disabled methods; only host-supplied methods appear; an empty list blocks checkout with an explanation.',
      'Alasan terlihat pada metode nonaktif; hanya metode dari host yang muncul; daftar kosong menahan checkout dengan penjelasan.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Empty', 'Kosong'),
        config: ScenarioConfig(kycRequired: false, methods: MethodSet.empty),
        start: FlowStep.checkout,
      ),
      ScenarioVariant(
        label: Bi('Unavailable', 'Tidak tersedia'),
        config: ScenarioConfig(
          kycRequired: false,
          methods: MethodSet.someUnavailable,
        ),
        start: FlowStep.checkout,
      ),
      ScenarioVariant(
        label: Bi('Low balance', 'Saldo kurang'),
        config: ScenarioConfig(
          kycRequired: false,
          methods: MethodSet.insufficientBalance,
        ),
        start: FlowStep.checkout,
      ),
    ],
  ),
  Scenario(
    id: 'P04',
    title: Bi(
      'Challenge canceled, failed, expired',
      'Challenge dibatalkan, gagal, kedaluwarsa',
    ),
    expect: Bi(
      'No payment is sent (submit count stays 0). Cancel and failure use different copy; Back to review keeps the valid quote.',
      'Pembayaran tidak dikirim (jumlah submit tetap 0). Batal dan gagal memakai copy berbeda; Kembali ke tinjauan mempertahankan quote valid.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Canceled', 'Dibatalkan'),
        config: ScenarioConfig(kycRequired: false, auth: AuthOutcome.cancel),
        start: FlowStep.checkout,
      ),
      ScenarioVariant(
        label: Bi('Failed', 'Gagal'),
        config: ScenarioConfig(kycRequired: false, auth: AuthOutcome.fail),
        start: FlowStep.checkout,
      ),
      ScenarioVariant(
        label: Bi('Expired', 'Kedaluwarsa'),
        config: ScenarioConfig(kycRequired: false, auth: AuthOutcome.expire),
        start: FlowStep.checkout,
      ),
    ],
  ),
  Scenario(
    id: 'P05',
    title: Bi('Double tap / slow submit', 'Double tap / submit lambat'),
    expect: Bi(
      'Submit takes 2.5 s. Repeated taps on Pay and Confirm show a busy state; the host log shows one submit and one idempotency key.',
      'Submit 2,5 detik. Tap berulang pada Bayar dan Konfirmasi menampilkan status sibuk; log host menunjukkan satu submit dan satu idempotency key.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Slow', 'Lambat'),
        config: ScenarioConfig(kycRequired: false, submit: SubmitBehavior.slow),
        start: FlowStep.checkout,
      ),
    ],
  ),
  Scenario(
    id: 'P06',
    title: Bi('Accepted but response lost', 'Diterima server, respons hilang'),
    expect: Bi(
      'The server records the payment but the answer times out. The screen shows “Result not confirmed yet”, offers only Check status (same reference) and never Pay again.',
      'Server mencatat pembayaran tetapi jawaban timeout. Layar menampilkan “Hasil belum terkonfirmasi”, hanya Cek status (referensi sama), tanpa Bayar lagi.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Timeout', 'Timeout'),
        config: ScenarioConfig(
          kycRequired: false,
          submit: SubmitBehavior.responseLost,
          script: [
            ServerStep(PaymentStatus.processing),
            ServerStep(PaymentStatus.succeeded),
          ],
        ),
        start: FlowStep.checkout,
      ),
    ],
  ),
  Scenario(
    id: 'P07',
    title: Bi('Long pending, offline refresh', 'Pending lama, refresh offline'),
    expect: Bi(
      'Pending shows the host reason. The second check fails offline: last-known status and its time stay visible, nothing turns into failed. Later checks succeed.',
      'Pending menampilkan alasan host. Cek kedua gagal offline: status terakhir dan waktunya tetap terlihat, tidak berubah jadi gagal. Cek berikutnya berhasil.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Pending', 'Pending'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(PaymentStatus.processing),
            ServerStep(
              PaymentStatus.pending,
              reason: Bi(
                'Waiting for bank confirmation (simulated).',
                'Menunggu konfirmasi bank (simulasi).',
              ),
            ),
            ServerStep.fault(ServerFault.offline),
            ServerStep(
              PaymentStatus.pending,
              reason: Bi(
                'Waiting for bank confirmation (simulated).',
                'Menunggu konfirmasi bank (simulasi).',
              ),
            ),
            ServerStep(PaymentStatus.succeeded),
          ],
        ),
      ),
    ],
  ),
  Scenario(
    id: 'P08',
    title: Bi(
      'Background or restart while processing',
      'Background/restart saat diproses',
    ),
    expect: Bi(
      'Pay, then use Simulate restart in host tools (or background the app). The host restores the attempt reference and refreshes; nothing is submitted again.',
      'Bayar, lalu pakai Simulasi restart di alat host (atau background-kan app). Host memulihkan referensi attempt dan refresh; tidak ada submit ulang.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Processing', 'Diproses'),
        config: ScenarioConfig(
          kycRequired: false,
          script: _processingThenSuccess,
        ),
        start: FlowStep.checkout,
      ),
    ],
  ),
  Scenario(
    id: 'P09',
    title: Bi(
      'Manual instructions reach expiry',
      'Instruksi manual mencapai batas waktu',
    ),
    expect: Bi(
      'A 20-second virtual account. The countdown stops at 00:00, then the host checks status; only the host declares it expired.',
      'Virtual account 20 detik. Countdown berhenti di 00:00, lalu host mengecek status; hanya host yang menyatakan kedaluwarsa.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('20 s VA', 'VA 20 dtk'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          seedMethodId: 'va',
          vaScript: [ServerStep(PaymentStatus.pending)],
          vaExpiry: Duration(seconds: 20),
        ),
      ),
    ],
  ),
  Scenario(
    id: 'P10',
    title: Bi(
      'Duplicate or late stale status',
      'Status duplikat atau terlambat',
    ),
    expect: Bi(
      'Check status: success arrives, then a duplicate and an older “processing” snapshot arrive late. Both are ignored (host log); success stays success.',
      'Cek status: sukses datang, lalu duplikat dan snapshot “diproses” yang lebih lama datang terlambat. Keduanya diabaikan (log host); sukses tetap sukses.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Late webhook', 'Webhook terlambat'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(PaymentStatus.processing),
            ServerStep(PaymentStatus.processing),
            ServerStep(PaymentStatus.succeeded, replayStale: true),
          ],
        ),
      ),
    ],
  ),
  Scenario(
    id: 'P11',
    title: Bi(
      'Host confirms failed, canceled, expired',
      'Host mengonfirmasi gagal, batal, kedaluwarsa',
    ),
    expect: Bi(
      'Safe reason and next action. “Start a new payment” appears only when the host allows it and the old result is final.',
      'Alasan aman dan langkah lanjut. “Buat pembayaran baru” hanya muncul bila host mengizinkan dan hasil lama sudah pasti.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Failed', 'Gagal'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(PaymentStatus.processing),
            ServerStep(PaymentStatus.processing),
            ServerStep(
              PaymentStatus.failed,
              reason: Bi(
                'The bank declined (simulated). You weren’t charged.',
                'Bank menolak transaksi (simulasi). Dana tidak ditarik.',
              ),
            ),
          ],
        ),
      ),
      ScenarioVariant(
        label: Bi('Failed, no retry', 'Gagal, tanpa ulang'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(PaymentStatus.processing),
            ServerStep(
              PaymentStatus.failed,
              reason: Bi(
                'Account restricted by the provider (simulated).',
                'Akun dibatasi oleh penyedia (simulasi).',
              ),
              actions: {PaymentAction.contactSupport},
            ),
          ],
        ),
      ),
      ScenarioVariant(
        label: Bi('Canceled', 'Dibatalkan'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(PaymentStatus.processing),
            ServerStep(PaymentStatus.canceled),
          ],
        ),
      ),
      ScenarioVariant(
        label: Bi('Expired', 'Kedaluwarsa'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(PaymentStatus.pending),
            ServerStep(PaymentStatus.expired),
          ],
        ),
      ),
    ],
  ),
  Scenario(
    id: 'P12',
    title: Bi('Back or Cancel while pending', 'Back atau Batal saat pending'),
    expect: Bi(
      'Back explains that leaving doesn’t cancel the payment. Request cancellation waits for the host before showing Canceled.',
      'Back menjelaskan bahwa keluar tidak membatalkan pembayaran. Minta pembatalan menunggu host sebelum menampilkan Dibatalkan.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('VA pending', 'VA pending'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          seedMethodId: 'va',
          vaScript: [ServerStep(PaymentStatus.pending)],
        ),
      ),
    ],
  ),
  Scenario(
    id: 'P13',
    title: Bi(
      'Succeeded but receipt fails',
      'Berhasil tetapi struk gagal dimuat',
    ),
    expect: Bi(
      'Success stays visible while receipt details fail; Retry loads them without paying again.',
      'Status sukses tetap terlihat saat detail struk gagal; Coba lagi memuatnya tanpa membayar ulang.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Receipt error', 'Struk error'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          receiptFailsOnce: true,
          script: [
            ServerStep(PaymentStatus.processing),
            ServerStep(PaymentStatus.succeeded),
          ],
        ),
      ),
    ],
  ),
  Scenario(
    id: 'P14',
    title: Bi(
      'Refund pending, partial, full, failed',
      'Refund pending, sebagian, penuh, gagal',
    ),
    expect: Bi(
      'The original payment stays “successful”; the refund has its own section. An amount above the paid total is shown as unavailable.',
      'Pembayaran awal tetap “berhasil”; refund punya bagian sendiri. Nominal di atas total dibayar ditampilkan tidak tersedia.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Pending', 'Pending'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(
              PaymentStatus.succeeded,
              refund: RefundInfo(
                status: RefundStatus.pending,
                amount: Money.idr(102500),
              ),
            ),
          ],
        ),
      ),
      ScenarioVariant(
        label: Bi('Partial', 'Sebagian'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(
              PaymentStatus.succeeded,
              refund: RefundInfo(
                status: RefundStatus.partial,
                amount: Money.idr(50000),
              ),
            ),
          ],
        ),
      ),
      ScenarioVariant(
        label: Bi('Full', 'Penuh'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(
              PaymentStatus.succeeded,
              refund: RefundInfo(
                status: RefundStatus.refunded,
                amount: Money.idr(102500),
              ),
            ),
          ],
        ),
      ),
      ScenarioVariant(
        label: Bi('Failed', 'Gagal'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(
              PaymentStatus.succeeded,
              refund: RefundInfo(
                status: RefundStatus.failed,
                amount: Money.idr(102500),
              ),
            ),
          ],
        ),
      ),
      ScenarioVariant(
        label: Bi('Over-refund (invalid)', 'Refund berlebih (invalid)'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(
              PaymentStatus.succeeded,
              refund: RefundInfo(
                status: RefundStatus.partial,
                amount: Money.idr(250000),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
  Scenario(
    id: 'P15',
    title: Bi(
      'Share canceled/failed, copy failed',
      'Share batal/gagal, salin gagal',
    ),
    expect: Bi(
      'Feedback appears below the receipt; the receipt and status do not change. Only allowlisted fields are shared (host log).',
      'Umpan balik muncul di bawah struk; struk dan status tidak berubah. Hanya field allowlist yang dibagikan (log host).',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Share dismissed', 'Share dibatalkan'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          share: ShareBehavior.dismissed,
          script: [ServerStep(PaymentStatus.succeeded)],
        ),
      ),
      ScenarioVariant(
        label: Bi('Share failed', 'Share gagal'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          share: ShareBehavior.failed,
          script: [ServerStep(PaymentStatus.succeeded)],
        ),
      ),
      ScenarioVariant(
        label: Bi('Copy failed', 'Salin gagal'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          clipboardFails: true,
          script: [ServerStep(PaymentStatus.succeeded)],
        ),
      ),
    ],
  ),
  // -------------------------------------------------------- Cross-cutting
  Scenario(
    id: 'X01',
    title: Bi('Invalid server data', 'Data server invalid'),
    expect: Bi(
      'The provider sends an unknown status. The adapter rejects it: “Couldn’t refresh status” with the last-known Processing, no success and no raw provider text.',
      'Penyedia mengirim status tak dikenal. Adapter menolaknya: “Status belum bisa diperbarui” dengan status terakhir Diproses, tanpa sukses dan tanpa teks mentah penyedia.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Unknown enum', 'Enum tak dikenal'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          script: [
            ServerStep(PaymentStatus.processing),
            ServerStep(PaymentStatus.processing),
            ServerStep.fault(ServerFault.invalidData),
            ServerStep(PaymentStatus.succeeded),
          ],
        ),
      ),
    ],
  ),
  Scenario(
    id: 'X02',
    title: Bi(
      '200% text, keyboard, long labels',
      'Teks 200%, keyboard, label panjang',
    ),
    expect: Bi(
      'Rows stack, everything scrolls, the total and Pay stay reachable with the keyboard open; no overflow.',
      'Baris menumpuk, semua bisa discroll, total dan Bayar tetap terjangkau saat keyboard terbuka; tanpa overflow.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Checkout', 'Checkout'),
        config: ScenarioConfig(kycRequired: false, longLabels: true),
        start: FlowStep.checkout,
        textScale: 2,
      ),
      ScenarioVariant(
        label: Bi('Identity form', 'Formulir identitas'),
        config: ScenarioConfig(longLabels: true),
        start: FlowStep.kycIdentity,
        textScale: 2,
      ),
    ],
  ),
  Scenario(
    id: 'X03',
    title: Bi(
      'Dark, reduced motion, screen reader',
      'Gelap, gerak dikurangi, pembaca layar',
    ),
    expect: Bi(
      'Statuses use icon + text + color; spinners become static icons; amounts are announced as plain numbers.',
      'Status memakai ikon + teks + warna; spinner menjadi ikon statis; nominal dibacakan sebagai angka biasa.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Full flow', 'Alur lengkap'),
        config: ScenarioConfig(hostPolls: true),
        dark: true,
        reduceMotion: true,
      ),
    ],
  ),
  Scenario(
    id: 'X04',
    title: Bi(
      'Switch account while a response is pending',
      'Ganti akun saat respons tertunda',
    ),
    expect: Bi(
      'Status checks take 3 s. Tap Check status, then switch to account B: the late response is discarded and account A’s status/receipt never appear.',
      'Cek status 3 detik. Tekan Cek status, lalu ganti ke akun B: respons terlambat dibuang dan status/struk akun A tidak tampil.',
    ),
    variants: [
      ScenarioVariant(
        label: Bi('Slow check', 'Cek lambat'),
        config: ScenarioConfig(
          kycRequired: false,
          seedAttempt: true,
          slowStatusCheck: true,
          script: [
            ServerStep(PaymentStatus.processing),
            ServerStep(PaymentStatus.processing),
            ServerStep(PaymentStatus.succeeded),
          ],
        ),
      ),
    ],
  ),
];

/// Same as [_noKyc]; exposed for the component gallery's standalone host.
const galleryConfig = _noKyc;
