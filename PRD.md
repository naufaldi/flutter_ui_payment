# PRD: Flutter UI Payment

Tanggal: 30 Oktober 2026  
Status: keputusan produk untuk implementasi; belum menjadi aplikasi atau package yang berjalan.  
Pusat proyek: `~/WebApps/flutter-ui-payment`  
Nama package sementara: `flutter_ui_payment`; ketersediaan nama belum diperiksa.

## 1. Ringkasan dan janji produk

**Developer dapat merakit alur verifikasi identitas dan pembayaran yang rapi, mudah dikustomisasi, dan jelas saat transaksi belum selesai maupun gagal.**

Produk berupa library komponen UI Flutter dengan contoh integrasi lengkap. KYC adalah modul opsional yang dapat dikomposisikan dengan checkout. Library tidak memproses pembayaran, memutuskan kelayakan identitas, atau mengharuskan setiap pembayaran melewati KYC.

Tujuan pemilik proyek adalah menunjukkan kemampuan design engineering dan software engineering untuk portofolio kerja. Relevansi ke fintech seperti Fazz datang dari pemahaman alur transaksi dan kualitas implementasi. Nama, visual, dan API produk tetap independen dari perusahaan tertentu.

## 2. Dasar keputusan: bukti, asumsi, dan validasi

### Bukti yang tersedia

- Pemilik proyek menginginkan open source Flutter payment UI kit untuk portofolio, dengan cakupan KYC sampai pembayaran dan edge case.
- Payfazz mendeskripsikan layanan keagenan untuk top-up, tagihan, transfer, serta QRIS; alur publiknya mencakup input tujuan, pemilihan produk, konfirmasi, dan struk. Ini memberi konteks domain, bukan bukti masalah UX aplikasi mereka. [S1]
- Produk prabayar dan pascabayar mereka menunjukkan konteks pembelian nominal dan pembayaran tagihan yang berbeda. [S2][S3]
- Flutter mendukung pengembangan package dan distribusi melalui pub.dev. [S5][S6]
- Kebutuhan Flutter untuk lowongan Fazz yang dituju belum terverifikasi. Job board Talenta yang ditautkan halaman karier gagal diakses dengan HTTP 403 saat riset. [S4]

### Asumsi produk yang dipilih

- Developer Flutter aplikasi commerce, top-up, dan pembayaran tagihan adalah pengguna awal.
- Kesulitan yang ditargetkan adalah menyusun detail pembayaran, state asinkron, dan edge case secara konsisten sambil mempertahankan identitas visual aplikasi.
- Lima sampai sepuluh komponen yang digunakan dalam alur lengkap lebih kuat untuk portofolio awal dibanding katalog besar tanpa perilaku nyata.
- Package yang tidak mengikat router, state manager, atau payment provider akan lebih mudah dicoba.

Belum ada wawancara developer, observasi workaround, perbandingan kompetitor yang sistematis, atau bukti adopsi. Asumsi tersebut tidak boleh ditulis sebagai hasil riset pengguna.

### Kesimpulan product thinking

1. **Satu ide utama:** komponen payment yang dapat dikomposisikan dan tetap jelas pada status transaksi yang sulit.
2. **Rantai asumsi:** komponen menyelesaikan pekerjaan berulang developer → mudah diintegrasikan ke aplikasi lain → kualitas dapat dinilai melalui demo → proyek menjadi bukti kompetensi portofolio. Yang diuji pertama adalah kegunaan dan kemudahan integrasi.
3. **Risiko terbesar:** library hanya menjadi screenshot gallery. Tes termurah: developer lain memasang package lokal dan merakit checkout dengan data serta theme miliknya.
4. **Fokus bulan pertama:** satu alur lengkap dengan state nyata di simulator; provider pembayaran dan KYC tetap adapter simulasi. Ini target scope, bukan janji kalender.
5. **Prinsip yang belum terpenuhi:** workaround pengguna belum diamati (#1), pengguna eksternal konkret belum direkrut (#4), dan alasan memilih dibanding alternatif belum terbukti (#2).
6. **Yang belum terjawab:** permintaan pasar, kecocokan dengan lowongan tertentu, dan beban maintenance setelah dipakai orang lain.

## 3. Pengguna dan ukuran keberhasilan

**Pengguna langsung:** developer Flutter yang sudah punya aplikasi dan backend, lalu membutuhkan UI payment yang bisa mengikuti brand mereka.

**Pengguna akhir demo:** pembeli fiktif yang memverifikasi identitas sesuai kebijakan aplikasi, meninjau pembelian, membayar, dan melihat bukti transaksi.

**Pembaca portofolio:** engineer atau hiring manager yang ingin menilai API design, state ownership, visual craft, testing, dan penanganan kegagalan.

Target awal yang akan diukur, bukan hasil yang sudah tercapai:

- Satu developer eksternal dapat merakit checkout dengan theme sendiri dalam ≤30 menit dari README, tanpa mengubah source package.
- Demo dapat menyelesaikan happy flow dan seluruh skenario prioritas pada matriks di bagian 9.
- Package dapat digunakan tanpa memasang router, state manager, kamera, atau SDK payment provider tertentu.
- Kandidat pengguna dapat menjelaskan perbedaan `processing`, `pending`, dan status belum diketahui setelah mencoba demo.
- Bukti portofolio mencakup API yang dapat dipakai, demo native, pengujian perilaku, dan penjelasan tradeoff. Jumlah stars bukan gate peluncuran.

## 4. Scope MVP dan batas produk

### Masuk MVP

- Primitives: theme extension, warna status, tipografi, spacing, amount display, info row, dan aksi loading.
- KYC UI: penjelasan kebutuhan data/consent, formulir identitas, slot unggah dokumen, tinjauan, status verifikasi, dan permintaan perbaikan.
- Checkout: amount input opsional, ringkasan item/biaya, pemilih metode pembayaran, dan konfirmasi.
- Handoff otorisasi ke host: komponen menampilkan challenge state, bukan mengimplementasikan autentikasi finansial.
- Instruksi pembayaran manual untuk contoh virtual account simulasi: referensi, nominal, kedaluwarsa, dan cek status.
- Status pembayaran dan struk yang aman dibagikan.
- Gallery per komponen dan demo alur lengkap dengan skenario deterministik.
- Light/dark, token brand, semantic labels, text scaling, Bahasa Indonesia/English.

### Di luar MVP

- OCR, liveness, face matching, penilaian dokumen, atau keputusan KYC sungguhan.
- Backend produksi, ledger, settlement, saldo uang nyata, refund processing, chargeback, dan fraud engine.
- SDK bank/payment gateway, kartu kredit, penyimpanan PAN/CVV, autentikasi OTP/PIN sungguhan.
- Login/account management lengkap, transfer multi-currency, dan dashboard operasional.
- Implementasi capture kamera native. Host dapat menyediakannya kemudian lewat callback; MVP memakai fixture sintetis.
- Klaim compliance atau siap produksi untuk layanan keuangan.

Refund tetap memiliki state tampilan dalam demo agar status setelah pembayaran tidak menyesatkan. Tombol refund sungguhan bukan bagian library.

## 5. Pengalaman utama

Demo memakai brand fiktif **Ruang Bayar** dan pembelian fiktif **Paket Belajar**, bukan nama atau logo perusahaan rujukan. Nilai contoh: harga Rp100.000 + biaya layanan Rp2.500 = total Rp102.500. Semua data dan dokumen sintetis diberi label demo.

1. Pengguna membuka overview demo dan melihat bahwa pembayaran disimulasikan.
2. Kebijakan demo meminta KYC. Layar menjelaskan data yang diminta dan alasannya, lalu meminta consent yang belum tercentang.
3. Pengguna mengisi identitas demo, memilih fixture dokumen, lalu meninjau input.
4. Pengiriman KYC menghasilkan status menunggu pemeriksaan, kemudian `verified` pada skenario utama.
5. Pengguna masuk checkout, meninjau item, biaya, total, dan metode pembayaran.
6. Saat konfirmasi, host memastikan quote masih berlaku dan mengirim snapshot terbaru. Perubahan total mengharuskan konfirmasi ulang.
7. Jalur utama memakai metode saldo simulasi dan challenge host simulasi, lalu mengirim pembayaran sekali untuk satu attempt.
8. UI mengikuti status host sampai berhasil, lalu menampilkan struk dan aksi berbagi/salin yang relevan.
9. Jalur kedua memakai virtual account simulasi: tampilkan instruksi dan waktu kedaluwarsa, lalu status dapat diperbarui tanpa membuat pembayaran baru.

KYC tidak selalu menjadi gerbang: gallery juga menyediakan contoh checkout tanpa KYC dan contoh melanjutkan KYC yang sedang ditinjau. Kebijakan akses disuplai host.

## 6. Katalog komponen dan kontrak penerimaan

Nama berikut adalah rancangan API, bukan kelas yang sudah tersedia. Komponen dasar dapat dipakai terpisah; halaman gabungan hanya contoh komposisi.

| Modul / calon komponen | Outcome pengguna | Edge utama | Definition of Done |
|---|---|---|---|
| `PaymentTheme`, amount display, info row | Brand dan nilai uang konsisten | Dark mode, label panjang, angka besar, text scale | Dua theme berbeda diterapkan dari luar package tanpa fork; semua nominal memakai formatter yang sama |
| `VerificationIntro`, `IdentityForm` | Memahami kebutuhan data dan memperbaiki input | Consent belum diberikan, input kosong, error server, identitas non-ASCII | Submit ditahan saat invalid; field memiliki label dan error yang dapat dibaca screen reader; aturan identitas dapat dikonfigurasi host |
| `DocumentUploadTile`, `VerificationReview` | Memilih dokumen dan memeriksa data | Permission ditolak oleh host, file invalid, unggah gagal, ganti dokumen | Batas tipe/ukuran berasal dari host; error dapat dicoba ulang; mengganti file membatalkan/mengabaikan hasil upload sebelumnya |
| `VerificationStatus` | Mengetahui hasil dan langkah berikutnya | Review lama, perbaikan diminta, ditolak, kedaluwarsa | Setiap state memiliki penjelasan dan aksi yang diizinkan; tidak ada tombol bypass verifikasi |
| `AmountInput`, `PaymentSummary` | Memahami nilai dan total | Nol, negatif, melebihi limit, quote berubah, biaya tidak tersedia | Input invalid tidak bisa dikonfirmasi; semua fee ditampilkan sebelum bayar; total dari quote host, bukan hitungan UI yang dipercaya backend |
| `PaymentMethodPicker` | Memilih metode yang dapat dipakai | Kosong, disabled, biaya berubah, metode hilang | Alasan unavailable terlihat; pilihan yang tidak valid dibersihkan; perubahan quote memicu tinjauan ulang |
| `PaymentConfirmation`, `AuthorizationPrompt` | Menyetujui detail akhir dengan sadar | Double tap, challenge dibatalkan/gagal/expired, app background | Satu callback submit aktif; cancel challenge tidak ditampilkan sebagai pembayaran sukses; secret tidak masuk state publik library |
| `PaymentInstructions`, `PaymentStatusView` | Menyelesaikan pembayaran dan memahami statusnya | Timeout, pending, offline, expired, status terlambat | Countdown memakai waktu host; cek status tidak membuat transaksi baru; keberhasilan hanya dari data otoritatif host |
| `PaymentReceipt` | Memeriksa dan membagikan bukti | Data panjang, pending, share ditolak, refund | Struk sukses hanya untuk pembayaran settled/succeeded; pending diberi ringkasan status; share hanya memuat field allowlist |

## 7. Arsitektur: pemilik data dan batas tanggung jawab

Pemisahan dirancang karena status UI dan status bisnis tidak sama. Contoh: request timeout adalah fakta jaringan; pembayaran gagal adalah keputusan backend/provider.

| Area | Pemilik | Tanggung jawab library |
|---|---|---|
| Nilai input sementara, fokus, ekspansi detail | Widget/controller lokal | Menyediakan interaksi dan validasi presentasi |
| Persyaratan identitas, consent policy, izin pembayaran | Host/backend | Menampilkan kebijakan yang diberikan, tidak menentukan aturan universal |
| Upload dokumen dan keputusan KYC | Host adapter/backend | Menampilkan progress, error terstruktur, dan hasil |
| Harga, fee, limit, quote expiry | Host/backend | Merender snapshot lengkap dan meminta konfirmasi ulang saat berubah |
| Challenge dan kredensial otorisasi | Host/auth SDK/backend | Menampilkan status dan mendelegasikan tindakan; tidak menerima PIN/OTP mentah lewat model publik |
| Status pembayaran, idempotency, refund | Host/backend/provider | Merender state otoritatif; tidak mengklaim bisa mencegah debit ganda dari UI saja |
| Status polling, recovery, lifecycle | Host application coordinator | Menawarkan event/callback dan menampilkan hasil; widget tidak memulai polling tersembunyi |

Aliran integrasi: respons provider → parser adapter host → model domain library → widget. Data JSON tidak dipercaya langsung oleh widget. Nilai tak dikenal dipetakan ke error/status unavailable yang aman, tanpa mengarang hasil transaksi.

Kontrak minimal yang direncanakan:

- `Money`: kode mata uang + integer minor units; demo memakai IDR. Jangan memakai floating point untuk penjumlahan uang. Format lokal terpisah dari nilai domain.
- `PaymentQuote`: ID/revisi, item, fee, total, mata uang, metode, dan expiry. Host bertanggung jawab atas konsistensi total dan validitas quote.
- `PaymentAttempt`: attempt ID lokal, quote ID/revisi, referensi transaksi server bila tersedia, status bisnis, waktu pembaruan/revisi server, dan action yang diizinkan.
- `VerificationSnapshot`: request ID, status, alasan aman ditampilkan, field yang perlu diperbaiki, dan action yang diizinkan. Tidak berisi bytes dokumen atau identitas lengkap dalam model status.
- `PaymentReceiptData`: transaction ID, merchant, waktu, breakdown, metode yang dimasking, dan hasil. Tidak memuat dokumen KYC atau secret.
- Callback/event untuk request quote, submit verification, authorize, submit payment, refresh status, dan share. Error menggunakan kategori terstruktur serta pesan aman, bukan exception mentah provider.

Tidak memilih Bloc/Riverpod/provider sebagai dependency publik. Example boleh memakai coordinator Dart sederhana untuk menunjukkan satu pemilik state. Tidak perlu framework state machine baru sampai kompleksitas implementasi membuktikan kebutuhannya.

## 8. State dan invariant

### KYC

State bisnis: `notStarted`, `inReview`, `actionRequired`, `verified`, `rejected`, `expired`.

Status lokal terpisah: editing, validating, uploading, submitting, atau gagal mengirim. Kegagalan jaringan tidak mengubah KYC menjadi rejected.

Transisi: notStarted/actionRequired/expired → edit → submit → inReview. Hasil host dapat mengubah inReview menjadi actionRequired, verified, atau rejected. Verified dapat menjadi expired atau dicabut berdasarkan kebijakan host; akses pembayaran harus diperiksa kembali oleh backend ketika transaksi dikirim.

### Pembayaran

Persiapan: editing → quoting → review → authorizing bila diperlukan → submitting. Aksi gagal sebelum pengiriman kembali ke review dengan konteks yang masih valid.

State bisnis setelah transaksi diketahui server: `requiresAction`, `processing`, `pending`, `succeeded`, `failed`, `canceled`, `expired`. Refund ditampilkan sebagai lifecycle terpisah: `none`, `pending`, `partial`, `refunded`, atau `failed`, bukan mengganti sukses awal menjadi gagal.

`requiresAction` meminta tindakan pengguna sesuai instruksi host. `processing` berarti permintaan sedang dieksekusi. `pending` berarti transaksi sudah diketahui tetapi masih menunggu pembayaran, pemeriksaan, atau penyelesaian; host menyuplai alasan dan aksi spesifik. Tidak satu pun dari ketiganya mengizinkan UI menyimpulkan sukses atau mengirim pembayaran baru secara otomatis.

Status pengamatan lokal: `fresh`, `refreshing`, `unavailable`. Saat submit timeout sebelum referensi server diterima, attempt tetap disimpan sebagai pengiriman dengan hasil belum diketahui. UI mengunci pembayaran ulang dan meminta rekonsiliasi melalui host berdasarkan attempt/idempotency reference. Status belum diketahui bukan status bisnis baru dari provider.

Aturan yang wajib dipertahankan:

1. `verified` hanya berasal dari host otoritatif, bukan dari file berhasil diunggah.
2. Satu operasi pengiriman aktif untuk satu payment attempt. Host mempertahankan idempotency key yang sama selama merekonsiliasi pengiriman yang belum jelas; key baru hanya untuk attempt baru yang sah.
3. Timeout, offline, atau countdown habis tidak boleh menyimpulkan debit gagal atau pembayaran berhasil.
4. Data status terlambat tidak boleh menurunkan hasil lebih baru. Adapter host harus merekonsiliasi urutan/revisi dan peristiwa koreksi resmi provider.
5. Membatalkan layar tidak membatalkan transaksi. UI hanya menyebut canceled setelah host mengonfirmasinya.
6. Quote atau metode berubah setelah otorisasi mengharuskan review dan otorisasi ulang untuk detail yang baru.
7. Menonaktifkan tombol adalah perlindungan interaksi, bukan pengganti deduplikasi backend.
8. Setelah restart, host memulihkan referensi attempt dan mengecek status; library tidak menyimpan dokumen KYC, PIN, atau kredensial untuk resume.

## 9. Matriks edge case dan perilaku wajib

Semua skenario di bawah harus dapat dipilih dari scenario picker demo. Fixture bersifat deterministik agar kegagalan bisa diulang.

| ID | Kondisi | Perilaku yang diharapkan / acceptance |
|---|---|---|
| K01 | Consent belum diberikan | Submit dinonaktifkan; tautan kebijakan dapat dibuka host; tidak ada preselection |
| K02 | Field kosong, format tidak valid, nama non-ASCII | Error pada field yang relevan; nama tidak dibatasi ke huruf ASCII; format identitas ditentukan konfigurasi host |
| K03 | Capture permission ditolak atau permanen ditolak | Host memberi reason; tampilkan retry/settings action sesuai capability host; input lain tetap tersedia |
| K04 | File terlalu besar, tipe salah, upload terputus | Tampilkan batas yang diberikan host dan aksi perbaikan; UI tidak menyebut dokumen sah hanya karena ekstensi cocok |
| K05 | Pengguna mengganti file saat upload berjalan | Hasil upload lama diabaikan melalui request identity; review hanya menampilkan file terbaru |
| K06 | Submit verification timeout atau double tap | Tahan submit baru sampai host mengecek request sebelumnya; tampilkan hasil belum diketahui, bukan rejected |
| K07 | KYC lama ditinjau, actionRequired, atau rejected | Tampilkan alasan aman dan langkah yang diizinkan; data yang masih valid tidak harus diisi ulang; rejected tidak otomatis dapat diulang |
| K08 | KYC expired/dicabut, sesi auth expired, app restart | Host mengecek ulang eligibility; input sensitif tidak dipulihkan dari storage biasa; pengguna melihat langkah lanjut yang jelas |
| P01 | Nominal kosong/nol/negatif/melebihi limit atau input paste berformat | Parse sesuai konfigurasi locale; jelaskan error; tidak ada submit dengan nilai ambigu |
| P02 | Quote gagal, expired, atau total berubah | Tampilkan retry quote; sesudah perubahan tampilkan total baru dan minta persetujuan ulang |
| P03 | Metode kosong/unavailable atau saldo kurang | Jelaskan kondisi; tawarkan metode lain yang memang disuplai host; tidak mengarang opsi |
| P04 | Challenge gagal/dibatalkan/expired | Kembali ke review bila quote valid; tidak kirim payment; cancel dan failure memiliki copy berbeda |
| P05 | Double tap/submit lambat | Hanya satu event submit aktif; coordinator memakai attempt yang sama; UI tetap memberi feedback |
| P06 | Submit diterima server, respons hilang | Tampilkan status belum diketahui; cek status memakai referensi attempt yang sama; tidak tampilkan tombol Bayar Lagi |
| P07 | Pending lama/offline/refresh gagal | Tampilkan last-known status dan waktu pembaruan; sediakan cek status saat tersedia; tidak mengubahnya jadi failed |
| P08 | Tutup layar/background/restart saat proses | Kembali ke detail attempt yang dipulihkan host; refresh saat resume; tidak submit otomatis |
| P09 | Instruksi manual mencapai expiry | Countdown menjadi nol tanpa angka negatif; host memeriksa status sebelum keputusan akhir; expiry lokal bukan bukti tidak terbayar |
| P10 | Respons duplikat atau status lama datang belakangan | Snapshot lama diabaikan host; transaksi sukses tetap sukses; koreksi resmi direkonsiliasi, bukan dibuang sembarang |
| P11 | Host mengonfirmasi failed/canceled/expired | Tampilkan alasan aman dan next action; attempt baru hanya bila host mengizinkan dan hasil lama sudah pasti |
| P12 | Pengguna menekan Back atau Cancel | Jelaskan apakah hanya meninggalkan layar; jangan menjanjikan pembatalan dana; jika cancel tersedia, tunggu konfirmasi host |
| P13 | Succeeded tetapi detail struk gagal dimuat | Status sukses tetap terlihat; retry detail tidak membayar ulang |
| P14 | Refund pending/partial/full/failed | Tampilkan original payment dan refund terpisah; nilai refund tidak melebihi jumlah yang sah dari host |
| P15 | Share dibatalkan/gagal, clipboard gagal | Struk dan status tetap tersedia; kegagalan share tidak mengubah transaksi; berikan feedback yang sesuai |
| X01 | Data server invalid/enum baru/referensi tidak cocok | Adapter menolak snapshot; tampilkan unavailable dengan last-known state bila ada; jangan menampilkan sukses atau error provider mentah |
| X02 | Text scale 200%, keyboard terbuka, label panjang | Konten tetap terbaca dan dapat discroll; total dan aksi penting bisa dijangkau; tidak ada overflow |
| X03 | Dark theme, reduced motion, screen reader | Kontras dan label semantik terjaga; status tidak hanya berdasarkan warna; animasi dekoratif dapat dikurangi |
| X04 | Ganti akun ketika respons lama datang | Host membuang hasil akun sebelumnya dan membersihkan konteks sensitif; struk/status akun lama tidak ditampilkan |

## 10. Visual, interaksi, dan aksesibilitas

- Karakter visual: tenang, jelas, mengutamakan nominal dan konsekuensi aksi. Brand bisa diubah melalui theme.
- Hierarki: total akhir dan metode pembayaran menonjol; biaya tidak disembunyikan hanya dalam expandable section.
- Status berbeda memakai label, ikon, dan copy; warna menjadi pendukung.
- Tombol punya idle/loading/disabled/error feedback yang konsisten. Loading tidak menggeser layout.
- Target sentuh minimum proyek 48 logical pixels; urutan fokus mengikuti alur baca.
- Error field ditampilkan setelah interaksi yang relevan atau submit, dengan fokus ke error pertama.
- Widget menghormati text scaling, safe area, keyboard inset, dan preferensi reduced motion.
- Motion mikro yang dipakai memiliki tujuan feedback. Tidak ada confetti berulang atau animasi yang menghambat pembacaan status.
- Tanggal dan nominal diformat melalui locale. MVP mendukung `id` dan `en`; teks panjang keduanya diperiksa.

## 11. Privasi dan security boundary

Ini kontrak desain UI dan contoh integrasi, bukan aturan kepatuhan KYC atau nasihat regulasi. Persyaratan verifikasi ditentukan host dan pihak yang bertanggung jawab atas layanannya.

- Demo hanya menggunakan identitas, gambar dokumen, referensi pembayaran, dan uang sintetis.
- Jangan menambahkan API key, PIN, OTP, token sesi, atau data identitas asli ke repository, fixture, analytics, dan crash log.
- Model status dan error tidak menyertakan raw provider payload. Data identitas ditampilkan seminimal kebutuhan review.
- Tidak ada analytics atau network call otomatis dalam core package.
- Host memiliki auth/session, otorisasi setiap transaksi, upload validation di server, idempotency, rate limits, serta persyaratan retensi dan penghapusan dokumen.
- Host bertanggung jawab atas perlindungan layar sensitif pada app switcher/screenshot sesuai platform dan threat model. Package menyediakan struktur yang bisa disembunyikan/masking, bukan menjanjikan perlindungan OS lintas platform. Risiko kebocoran screenshot dijelaskan OWASP. [S7]
- Callback share menerima data struk yang di-allowlist, bukan screenshot seluruh halaman KYC atau state aplikasi.
- Recovery hanya memerlukan referensi opaque yang disimpan host dengan perlindungan sesuai sensitivitasnya. Referensi tersebut tidak menggantikan auth atau izin akses transaksi.

## 12. Struktur implementasi yang direncanakan

```text
flutter-ui-payment/
  README.md
  PRD.md
  pubspec.yaml                 # root menjadi package, setelah scaffold
  lib/
    flutter_ui_payment.dart    # public exports yang disengaja
    src/
      foundation/
      verification/
      payment/
      receipt/
  example/                     # satu app: gallery dan demo flow
    lib/
      scenarios/
      adapters/                # fake KYC, quote, auth, payment
  test/                        # kontrak model dan widget behavior
  example/integration_test/    # alur end-to-end dan recovery
```

Tidak perlu monorepo multi-package untuk MVP. KYC tetap modul terpisah dalam satu package; baru dipisah package bila kebutuhan dependency atau konsumen membuktikannya. Core package menghindari dependency native yang tidak dibutuhkan pengguna checkout saja.

Demo platform awal: Android dan iOS. Gallery Flutter Web untuk mencoba komponen di browser; ini tidak membuktikan dukungan capture kamera, native share, atau proteksi layar di platform tersebut. Matriks dukungan harus membedakan rendering UI dan kemampuan integrasi host.

## 13. Tahapan implementasi dan gate

| Tahap | Hasil yang dapat dinilai | Bukti selesai |
|---|---|---|
| 1. Foundation dan payment slice | Satu checkout ber-theme dengan quote, status, dan struk | Package lokal dipakai example; satu flow sukses di simulator; model timeout/pending diuji sebelum menambah komponen lain |
| 2. KYC module | Consent, identitas, dokumen fixture, review, dan status | Jalur verified serta actionRequired/rejected berfungsi; tidak ada dokumen asli; gallery checkout tetap bisa berjalan tanpa KYC |
| 3. Lifecycle dan edges | Flow utama KYC → pembayaran serta seluruh scenario matrix | Skenario deterministik; submit timeout dan resume tidak membuat attempt baru; snapshot lama tidak merusak hasil |
| 4. Craft dan penggunaan eksternal | Dua theme, dua locale, accessibility, panduan integrasi | Developer lain mencoba checkout; feedback konkret ditindaklanjuti; native visual proof diperiksa |
| 5. Distribusi | Repo publik, package, gallery yang bisa dicoba | Release checklist dipenuhi; nama tersedia; target remote dan hosting dikonfirmasi saat publikasi dilakukan |

Alur pengguna utama tetap dimulai dari KYC. Urutan engineering dimulai dari payment slice untuk menguji janji inti produk sebelum membangun modul pendukung.

## 14. Verifikasi dan definisi selesai v0.1

### Hasil produk

- Format/analyzer bersih: `dart format --output=none --set-exit-if-changed .` dan `flutter analyze`.
- Tes package: `flutter test`; fokus pada nominal, snapshot valid/invalid, rendered state, akses aksi, dan callback submit, bukan menduplikasi implementasi.
- Integration test example: `flutter test integration_test` dari folder example dengan target emulator/simulator yang dipilih saat implementasi. Harus mencakup happy flow, timeout setelah server menerima, double tap, pending → success, quote berubah, KYC actionRequired, dan recovery attempt setelah restart.
- Finalisasi backend idempotency diuji terhadap fake host contract, bukan diklaim terbukti pada provider nyata. Integration test menegaskan satu attempt dan event submit yang diharapkan.
- Jalankan demo pada Android emulator dan iOS simulator secara berurutan. Agent mengoperasikan dan memeriksa sendiri hasilnya.
- Ambil dan inspeksi screenshot lokal untuk KYC review, checkout, pending/status belum diketahui, serta struk pada light/dark dan text scale 200%. Catat path konkret ketika artefak tersebut benar-benar dibuat; belum ada screenshot saat PRD ditulis.
- Gallery web diuji di browser nyata setelah tersedia, termasuk navigasi keyboard dan theme. Tutup tab milik tugas setelah pemeriksaan. Browser viewport tidak menggantikan bukti native.
- Pemeriksaan security terarah: tidak ada PII/secret di fixture/log/share, hasil akun lama diabaikan, dan tidak ada aksi pay ulang pada status belum diketahui.

### Performa

Budget awal berikut adalah target proyek yang belum diukur:

- Profilkan scroll checkout dan pembaruan status dalam profile mode, pada satu target 60 Hz yang dicatat. Target p95 build dan raster frame masing-masing <16,7 ms, dihitung terpisah, sesudah warm-up selama interaksi terulang 30 detik.
- Status polling dimiliki host, berhenti saat tidak dibutuhkan, dan tidak berjalan dari setiap rebuild widget. Callback refresh tidak saling menumpuk.
- Pemilihan/replacement fixture dokumen tidak menyisakan bytes atau resource lama di coordinator. Periksa penggunaan memori setelah 10 siklus pemilihan dan keluar layar; tidak ada pertumbuhan retained resources yang terus bertambah.
- Catat perangkat/OS, renderer, build mode, workload, dan angka terukur. Hasil simulator/emulator hanya mewakili lingkungan itu; physical device bukan gate rutin MVP.

### Gate akhir

v0.1 selesai ketika package benar-benar bisa dikonsumsi dari example, semua skenario prioritas bagian 9 dapat diperagakan, required checks lulus, dan bukti native serta hasil profil diinspeksi. Test unit/golden saja tidak cukup untuk mengklaim flow native bekerja. Klaim platform yang belum diperiksa tetap pending.

Ulangi hanya check yang terpengaruh perubahan, kegagalan, atau temuan konkret. Ketika CI menjalankan gate penuh, jangan mengulang suite lokal tanpa alasan baru.

**Tahap dokumen sekarang selesai saat** README dan PRD tersimpan di pusat proyek, keputusan/asumsi dibedakan, setiap modul punya acceptance, edge case/state owner jelas, serta rencana verifikasi dan distribusi dapat dieksekusi. Ini tidak berarti v0.1 sudah diimplementasikan.

## 15. Open source, distribusi, dan maintenance

Keputusan lisensi proyek: MIT untuk kode milik proyek saat implementasi/release. Sertakan file LICENSE dan atribusi dependency/aset sebelum publikasi; jangan memakai logo, screenshot, atau materi perusahaan rujukan sebagai aset library.

Tiga permukaan distribusi:

1. **GitHub:** source, README, contoh, issue, contribution guide, kebijakan keamanan, dan changelog. Repository publik khusus proyek, terpisah dari personal workspace.
2. **pub.dev:** package untuk dependency Flutter, API docs, contoh pemakaian, versi SDK yang benar-benar diuji, dan daftar platform yang sesuai bukti. Persyaratan publikasi mengikuti dokumentasi Dart/Flutter. [S5][S6]
3. **Gallery Flutter Web:** live preview komponen dan scenario picker dengan label simulasi. Hosting dipilih ketika ada target deployment yang diotorisasi.

Release awal direncanakan `0.1.0`. Nama package dan repo perlu diperiksa ketersediaannya sebelum membuat identitas publik. Sebelum release: README install/import/example, LICENSE, CHANGELOG, analisis/tes, review paket berkas untuk menghindari PII/secret, lalu `flutter pub publish --dry-run` dan inspeksi hasilnya.

Gunakan versi SDK yang dipilih dari stable yang tersedia saat scaffold, lalu dokumentasikan minimum yang benar-benar diuji; PRD ini tidak menebak nomor versi. Hindari menjanjikan dukungan semua Flutter lama atau semua provider pembayaran.

Distribusi konten awal: demo singkat yang menjelaskan satu masalah nyata seperti timeout setelah pembayaran terkirim, tautan package/gallery, dan contoh integrasi. Fazz dapat menjadi konteks diskusi saat melamar, tetapi proyek tetap relevan untuk tim lain. Belum ada bukti saluran ini menghasilkan pengguna.

Maintenance awal: perbaiki defect yang dapat direproduksi, dokumentasikan breaking change, dan terima integrasi host lewat adapter. Permintaan provider baru tidak otomatis masuk core library.

## 16. Risiko dan keputusan yang sengaja ditunda

| Risiko | Keputusan penanganan |
|---|---|
| Scope KYC sampai payment berubah menjadi aplikasi fintech penuh | Batasi ke UI, adapter contract, dan simulasi; tidak membangun layanan finansial |
| API terlalu generik sehingga susah dipakai | Rancang lewat satu example lengkap dan satu checkout tanpa KYC; ekstraksi berdasarkan penggunaan nyata |
| Tampilan tampak cantik tetapi error state tidak bisa dijalankan | Scenario picker dan fixture deterministik menjadi bagian MVP |
| Terikat ke Payfazz/PPOB | Brand sendiri, payment model generik, use case lintas kategori |
| Memerlukan banyak plugin native pada semua konsumen | Core UI menerima callback/capability host; kamera/provider SDK tidak menjadi dependency wajib |
| Portofolio tidak cocok dengan pekerjaan yang dituju | Verifikasi lowongan dan stack sebelum mengklaim kecocokan; domain relevance bukan bukti hiring fit |
| Tidak ada pengguna eksternal | Jalankan tes integrasi developer sebelum menambah banyak komponen |

Ditunda sampai implementasi: nama publik final, minimum SDK aktual, perangkat profil yang tersedia, detail API Dart final, target hosting, serta provider produksi. Hal tersebut tidak menghalangi PRD dan simulasi awal.

## 16a. Perluasan cakupan komponen (diotorisasi pemilik, 30 Oktober 2026)

Bagian ini menambah cakupan; requirement MVP pada bagian 1–16 tetap berlaku dan tidak dilonggarkan. Pemilik proyek meminta fondasi komponen yang lebih lengkap dan mengizinkan keputusan produk/engineering diambil atas namanya. Keputusan dan tradeoff dicatat di `docs/decisions.md`.

| Kelompok | Komponen | Batas |
|---|---|---|
| Interaksi | `ActionTile`, `ActionMenu`, `showPaymentConfirmDialog`, `showPaymentSnackBar`, `ExpandableSection`, `LoadingSkeleton`, `StateMessage` | Fee tidak boleh disembunyikan di bagian yang bisa dilipat |
| Navigasi | `AdaptiveNavShell`, `NavSidebar` | Sidebar di layar lebar, drawer modal di layar sempit; Escape/Back menutup; fokus kembali ke pemicu |
| Sheet/drawer | `PaymentSheet`, `showPaymentSheet`, `showPaymentSideSheet` | "Tutup" hanya menutup UI; membatalkan pembayaran adalah permintaan ke host dengan konfirmasi |
| Video | `PaymentVideoPlayer` + kontrak `PaymentVideoController` | Tanpa dependency media di package; tanpa autoplay; pause saat background/tersembunyi; contoh memakai `video_player` dan klip sintetis lokal |
| Promosi/iklan | `PromoCard`, `PromoSlot` | Selalu berlabel (bersponsor + pengiklan atau promo); tanpa SDK iklan, tracking, kampanye nyata, atau perubahan quote |
| Pembayaran | `PaymentActionBar`, `MerchantHeader`, `PaymentStepIndicator`, `BalanceCard`, `PromoCodeInput`, `TransactionHistory`, `TransactionDetail` | Saldo, kode promo, dan riwayat adalah verdict host; status tidak diketahui tetap "dalam proses", bukan gagal |
| Design system (Fondasi + Tier 1), ditambahkan 31 Oktober 2026 | Token publik `PaymentTheme`, `PaymentType`, `PaymentMotion`; komponen baru `PaymentTextField` (termasuk `.search`), `PaymentIconButton`, `PaymentCopyButton`, `PaymentLink`; pola pembayaran wajib memakai komponen Tier 1. Spesifikasi lengkap di `docs/prd-foundation-components.md` | Varian baru hanya dengan dua pemakaian nyata yang berbeda makna; komponen baru hanya hasil ekstraksi atau kebutuhan pola Tier 2; tidak ada field PIN/OTP/rahasia; clipboard, tautan, kamera dijalankan host lewat callback |

Kompatibilitas Android lama: minimum yang dideklarasikan API 24 (Android 7.0), mengikuti Flutter 3.44.6 yang terpasang; dependency contoh tidak menaikkannya. Runtime yang benar-benar diuji hanya Android 11 (API 30) arm64 emulator. Detail di `docs/compatibility.md`.

Status perluasan ini adalah implementasi lokal, bukan klaim v0.1 selesai. Gate bagian 14 yang belum terpenuhi tetap terbuka: uji developer eksternal, pemeriksaan gallery web di browser, iOS untuk komponen baru, raster budget pada perangkat fisik, dan distribusi.

## 17. Sumber

Sumber diperiksa pada 30 Oktober 2026. Sumber perusahaan mendukung deskripsi produk publik, bukan detail arsitektur internal, stack Flutter, atau temuan usability. Keputusan scope, komponen, dan acceptance di atas merupakan keputusan proyek.

- [S1: Payfazz, deskripsi produk dan alur agen](https://fazz.com/id/payfazz/)
- [S2: Payfazz, top-up prabayar](https://fazz.com/id/payfazz/produk/topup-prabayar/)
- [S3: Payfazz, tagihan pascabayar](https://fazz.com/id/payfazz/produk/tagihan-pascabayar/)
- [S4: Fazz Careers](https://fazz.com/careers/)
- [S5: Flutter, developing packages and plugins](https://docs.flutter.dev/packages-and-plugins/developing-packages)
- [S6: Dart, publishing packages](https://dart.dev/tools/pub/publishing)
- [S7: OWASP MASWE-0038, sensitive data in screenshots/recordings](https://mas.owasp.org/MASWE/MASVS-PLATFORM/MASWE-0038/)
