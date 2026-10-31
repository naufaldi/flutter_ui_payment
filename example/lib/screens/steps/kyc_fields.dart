import 'package:flutter/material.dart';
import 'package:flutter_ui_payment/flutter_ui_payment.dart';
import '../../coordinator/demo_coordinator.dart';
import '../../demo_strings.dart';
import 'package:flutter/services.dart';

/// Host identity rules: any script for names, 16-digit NIK, 17+ years.
List<IdentityFieldSpec> identityFields(DemoStrings s) => [
  IdentityFieldSpec(
    key: 'name',
    group: s.groupPersonal,
    label: s.fullName,
    textCapitalization: TextCapitalization.words,
    autofillHints: const [AutofillHints.name],
    validator: (v) {
      if (v.isEmpty) return s.nameRequired;
      if (v.runes.length < 2) return s.nameTooShort;
      return null;
    },
  ),
  IdentityFieldSpec(
    key: 'nik',
    group: s.groupPersonal,
    label: s.idNumber,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
    maskInReview: true,
    validator: (v) {
      final digits = v.replaceAll(' ', '');
      if (digits.isEmpty) return s.idRequired;
      if (!RegExp(r'^\d{16}$').hasMatch(digits)) return s.idFormat;
      return null;
    },
  ),
  IdentityFieldSpec(
    key: 'dob',
    group: s.groupPersonal,
    label: s.birthDate,
    kind: IdentityFieldKind.date,
    firstDate: DateTime(1900),
    lastDate: DateUtils.dateOnly(DateTime.now()),
    validator: (v) {
      if (v.isEmpty) return s.dobRequired;
      final date = DateTime.parse(v);
      final now = DateTime.now();
      if (date.isAfter(DateTime(now.year - 17, now.month, now.day))) {
        return s.dobAge;
      }
      return null;
    },
  ),
  IdentityFieldSpec(
    key: 'occupation',
    group: s.groupWorkAddress,
    label: s.occupation,
    kind: IdentityFieldKind.choice,
    options: [
      PaymentSelectOption(value: 'employee', label: s.employee),
      PaymentSelectOption(value: 'entrepreneur', label: s.entrepreneur),
      PaymentSelectOption(value: 'student', label: s.student),
      PaymentSelectOption(value: 'civilServant', label: s.civilServant),
      PaymentSelectOption(value: 'homemaker', label: s.homemaker),
      PaymentSelectOption(value: 'freelancer', label: s.freelancer),
      PaymentSelectOption(value: 'retired', label: s.retired),
      PaymentSelectOption(value: 'other', label: s.other),
    ],
    validator: (v) => v.isEmpty ? s.occupationRequired : null,
  ),
  IdentityFieldSpec(
    key: 'province',
    label: s.province,
    group: s.groupWorkAddress,
    kind: IdentityFieldKind.search,
    options: _provinces,
    validator: (v) => v.isEmpty ? s.provinceRequired : null,
  ),
];

List<DocumentRequirement> documentRequirements(DemoStrings s) => [
  DocumentRequirement(
    key: idCardSlot,
    label: s.idCardLabel,
    acceptedTypes: const {'image/jpeg', 'image/png'},
    acceptedTypesLabel: s.imageTypes,
    maxBytes: 5 * 1024 * 1024,
  ),
  DocumentRequirement(
    key: selfieSlot,
    label: s.selfieLabel,
    acceptedTypes: const {'image/jpeg', 'image/png'},
    acceptedTypesLabel: s.imageTypes,
    maxBytes: 5 * 1024 * 1024,
  ),
];

const _provinces = [
  PaymentSelectOption(value: 'aceh', label: 'Aceh'),
  PaymentSelectOption(value: 'sumatera-utara', label: 'Sumatera Utara'),
  PaymentSelectOption(value: 'sumatera-barat', label: 'Sumatera Barat'),
  PaymentSelectOption(value: 'riau', label: 'Riau'),
  PaymentSelectOption(value: 'kepulauan-riau', label: 'Kepulauan Riau'),
  PaymentSelectOption(value: 'jambi', label: 'Jambi'),
  PaymentSelectOption(value: 'sumatera-selatan', label: 'Sumatera Selatan'),
  PaymentSelectOption(
    value: 'kepulauan-bangka-belitung',
    label: 'Kepulauan Bangka Belitung',
  ),
  PaymentSelectOption(value: 'bengkulu', label: 'Bengkulu'),
  PaymentSelectOption(value: 'lampung', label: 'Lampung'),
  PaymentSelectOption(value: 'dki-jakarta', label: 'DKI Jakarta'),
  PaymentSelectOption(value: 'jawa-barat', label: 'Jawa Barat'),
  PaymentSelectOption(value: 'banten', label: 'Banten'),
  PaymentSelectOption(value: 'jawa-tengah', label: 'Jawa Tengah'),
  PaymentSelectOption(value: 'di-yogyakarta', label: 'DI Yogyakarta'),
  PaymentSelectOption(value: 'jawa-timur', label: 'Jawa Timur'),
  PaymentSelectOption(value: 'bali', label: 'Bali'),
  PaymentSelectOption(
    value: 'nusa-tenggara-barat',
    label: 'Nusa Tenggara Barat',
  ),
  PaymentSelectOption(
    value: 'nusa-tenggara-timur',
    label: 'Nusa Tenggara Timur',
  ),
  PaymentSelectOption(value: 'kalimantan-barat', label: 'Kalimantan Barat'),
  PaymentSelectOption(value: 'kalimantan-tengah', label: 'Kalimantan Tengah'),
  PaymentSelectOption(value: 'kalimantan-selatan', label: 'Kalimantan Selatan'),
  PaymentSelectOption(value: 'kalimantan-timur', label: 'Kalimantan Timur'),
  PaymentSelectOption(value: 'kalimantan-utara', label: 'Kalimantan Utara'),
  PaymentSelectOption(value: 'sulawesi-utara', label: 'Sulawesi Utara'),
  PaymentSelectOption(value: 'gorontalo', label: 'Gorontalo'),
  PaymentSelectOption(value: 'sulawesi-tengah', label: 'Sulawesi Tengah'),
  PaymentSelectOption(value: 'sulawesi-barat', label: 'Sulawesi Barat'),
  PaymentSelectOption(value: 'sulawesi-selatan', label: 'Sulawesi Selatan'),
  PaymentSelectOption(value: 'sulawesi-tenggara', label: 'Sulawesi Tenggara'),
  PaymentSelectOption(value: 'maluku', label: 'Maluku'),
  PaymentSelectOption(value: 'maluku-utara', label: 'Maluku Utara'),
  PaymentSelectOption(value: 'papua', label: 'Papua'),
  PaymentSelectOption(value: 'papua-barat', label: 'Papua Barat'),
  PaymentSelectOption(value: 'papua-barat-daya', label: 'Papua Barat Daya'),
  PaymentSelectOption(value: 'papua-tengah', label: 'Papua Tengah'),
  PaymentSelectOption(value: 'papua-pegunungan', label: 'Papua Pegunungan'),
  PaymentSelectOption(value: 'papua-selatan', label: 'Papua Selatan'),
];
