import 'package:flutter/material.dart';
import 'package:rakit_ui/rakit_ui.dart';

import 'block_demo_shell.dart';
import 'compositions/login_block.dart';
import 'compositions/register_block.dart';

void main() => runBlockDemo(const AuthBlocksDemo());

enum AuthDemoScenario {
  signInFailsOnce,
  registrationFailsOnce,
  verificationRequired,
  directAccount,
}

enum _Route { login, register, recovery, policy, home }

const _fixtureEmail = 'mina@example.com';
const _fixturePassword = 'notes123';
const _fixtureCode = '248913';

/// Synthetic Annota-themed host connecting the generic Login and Register
/// blocks. It is deliberately not Annota's production authentication flow:
/// there is no backend, account store, email delivery or secret persistence.
class AuthBlocksDemo extends StatefulWidget {
  const AuthBlocksDemo({
    super.key,
    this.initialScenario = AuthDemoScenario.signInFailsOnce,
    this.initialDark = false,
    this.delay = const Duration(milliseconds: 600),
    this.textScale,
    this.initiallyRegister = false,
  });

  final AuthDemoScenario initialScenario;
  final bool initialDark;
  final Duration delay;
  final bool initiallyRegister;

  /// Optional fixed text scale for accessibility proof.
  final double? textScale;

  @override
  State<AuthBlocksDemo> createState() => _AuthBlocksDemoState();
}

class _AuthBlocksDemoState extends State<AuthBlocksDemo> {
  late bool dark = widget.initialDark;
  late AuthDemoScenario scenario = widget.initialScenario;
  late _Route route = widget.initiallyRegister ? _Route.register : _Route.login;
  RegisterBlockStep registerStep = RegisterBlockStep.details;
  String? loginError;
  String? registerError;
  String? recoveryMessage;
  bool busy = false;
  int generation = 0;
  int signInAttempts = 0;
  int registerAttempts = 0;
  String registeredEmail = _fixtureEmail;

  void reset(AuthDemoScenario next) => setState(() {
    generation++;
    scenario = next;
    route = _Route.login;
    registerStep = RegisterBlockStep.details;
    loginError = null;
    registerError = null;
    recoveryMessage = null;
    busy = false;
    signInAttempts = 0;
    registerAttempts = 0;
    registeredEmail = _fixtureEmail;
  });

  void open(_Route next) => setState(() {
    route = next;
    loginError = null;
    registerError = null;
  });

  Future<void> signIn(LoginCredentials credentials) async {
    if (busy) return;
    final current = generation;
    signInAttempts++;
    setState(() {
      busy = true;
      loginError = null;
    });
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    setState(() {
      busy = false;
      final failFirst =
          scenario == AuthDemoScenario.signInFailsOnce && signInAttempts == 1;
      final wrongFixture =
          credentials.email != _fixtureEmail ||
          credentials.password != _fixturePassword;
      if (failFirst || wrongFixture) {
        loginError =
            'Check the email and password for this synthetic account, then try again.';
        return;
      }
      route = _Route.home;
    });
  }

  Future<void> register(RegisterSubmission submission) async {
    if (busy) return;
    final current = generation;
    registerAttempts++;
    setState(() {
      busy = true;
      registerError = null;
      registeredEmail = submission.email;
    });
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    setState(() {
      busy = false;
      if (scenario == AuthDemoScenario.registrationFailsOnce &&
          registerAttempts == 1) {
        registerError =
            'The illustrative host could not create the account. Nothing was saved; try again.';
        return;
      }
      if (scenario == AuthDemoScenario.verificationRequired) {
        registerStep = RegisterBlockStep.verification;
      } else {
        route = _Route.home;
      }
    });
  }

  Future<void> verify(String code) async {
    if (busy) return;
    final current = generation;
    setState(() {
      busy = true;
      registerError = null;
    });
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    setState(() {
      busy = false;
      if (code != _fixtureCode) {
        registerError =
            'That code does not match the synthetic message. Use $_fixtureCode or resend it.';
        return;
      }
      route = _Route.home;
    });
  }

  Future<void> resendCode() async {
    if (busy) return;
    final current = generation;
    setState(() => busy = true);
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    setState(() {
      busy = false;
      registerError = null;
    });
  }

  Future<void> sendRecovery(String email) async {
    if (busy) return;
    final current = generation;
    setState(() {
      busy = true;
      recoveryMessage = null;
    });
    await Future<void>.delayed(widget.delay);
    if (!mounted || current != generation) return;
    setState(() {
      busy = false;
      recoveryMessage =
          'If $email belongs to this synthetic host, a reset message is waiting in the fixture inbox.';
    });
  }

  @override
  Widget build(BuildContext context) => BlockDemoShell(
    title: 'Annota auth · illustrative demo',
    dark: dark,
    onToggleDark: () => setState(() => dark = !dark),
    lightTheme: annotaTheme(Brightness.light),
    darkTheme: annotaTheme(Brightness.dark),
    locale: const Locale('en'),
    textScale: widget.textScale,
    scenarios: [
      (
        label: 'Sign-in fails once',
        onSelected: () => reset(AuthDemoScenario.signInFailsOnce),
      ),
      (
        label: 'Registration fails once',
        onSelected: () => reset(AuthDemoScenario.registrationFailsOnce),
      ),
      (
        label: 'Email verification required',
        onSelected: () => reset(AuthDemoScenario.verificationRequired),
      ),
      (
        label: 'Registration continues directly',
        onSelected: () => reset(AuthDemoScenario.directAccount),
      ),
    ],
    body: (context) => switch (route) {
      _Route.login => LoginBlock(
        key: ValueKey('login-$generation'),
        initialEmail: _fixtureEmail,
        busy: busy,
        errorText: loginError,
        onSubmit: signIn,
        onForgotPassword: () => open(_Route.recovery),
        onRegister: () => open(_Route.register),
      ),
      _Route.register => RegisterBlock(
        key: ValueKey('register-$generation-$registerStep'),
        step: registerStep,
        initialEmail: _fixtureEmail,
        verificationEmail: registeredEmail,
        busy: busy,
        errorText: registerError,
        onSubmit: register,
        onVerify: verify,
        onResendVerification: resendCode,
        onLogin: () => open(_Route.login),
        onPolicy: () => open(_Route.policy),
      ),
      _Route.recovery => _RecoveryPage(
        key: ValueKey('recovery-$generation'),
        busy: busy,
        message: recoveryMessage,
        initialEmail: _fixtureEmail,
        onSubmit: sendRecovery,
        onBack: () => open(_Route.login),
      ),
      _Route.policy => _PolicyPage(onBack: () => open(_Route.register)),
      _Route.home => _HomePage(onSignOut: () => reset(scenario)),
    },
  );
}

class _RecoveryPage extends StatefulWidget {
  const _RecoveryPage({
    super.key,
    required this.busy,
    required this.message,
    required this.initialEmail,
    required this.onSubmit,
    required this.onBack,
  });

  final bool busy;
  final String? message;
  final String initialEmail;
  final Future<void> Function(String email) onSubmit;
  final VoidCallback onBack;

  @override
  State<_RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<_RecoveryPage> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    return PaymentFullPageView(
      title: 'Reset password',
      pageLink: PaymentLink(label: 'Log in', onPressed: widget.onBack),
      primaryAction: PaymentButton(
        label: 'Send reset message',
        busy: widget.busy,
        busyLabel: 'Sending reset message',
        onPressed: widget.busy ? null : submit,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: theme.space(PaymentSpace.group),
          children: [
            if (widget.message != null)
              PaymentBanner(
                tone: StatusTone.success,
                title: 'Reset message recorded',
                message: widget.message,
                announce: true,
              ),
            PaymentTextField(
              label: 'Email address',
              controller: _email,
              type: PaymentTextFieldType.email,
              required: true,
              enabled: !widget.busy,
              validator: (value) =>
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value ?? '')
                  ? null
                  : 'Enter a valid email address.',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => submit(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyPage extends StatelessWidget {
  const _PolicyPage({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    return PaymentFullPageView(
      title: 'Terms and privacy',
      pageLink: PaymentLink(label: 'Create account', onPressed: onBack),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(PaymentSpace.group),
        children: [
          const PaymentBanner(
            tone: StatusTone.neutral,
            title: 'Illustrative host policy',
            message:
                'This page belongs to the demo host. It is not Annota production policy or authentication copy.',
          ),
          Text(
            'In a real app, this destination explains what account data the host collects, why it collects it, retention, deletion and contact choices. The block only opens the host destination; it never writes a consent record.',
            style: type.body.copyWith(color: theme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = PaymentTheme.of(context);
    final type = PaymentType.of(context);
    return PaymentFullPageView(
      title: 'Home',
      primaryAction: PaymentButton(
        label: 'Sign out',
        variant: PaymentButtonVariant.secondary,
        onPressed: onSignOut,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.space(PaymentSpace.group),
        children: [
          const PaymentBanner(
            tone: StatusTone.success,
            title: 'Signed in',
            message:
                'The host navigated here after its synthetic authentication callback.',
          ),
          const PaymentBanner(
            tone: StatusTone.neutral,
            title: 'Illustrative Annota host',
            message:
                'This is a synthetic auth demo, not Annota’s production sign-in or account system.',
          ),
          PaymentSection(
            title: 'Next in Annota',
            child: Text(
              'Scan a document, review highlights and save notes. Those product surfaces are outside this authentication block demo.',
              style: type.body.copyWith(color: theme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Annota-derived illustrative host theme. Light colors follow the pinned web
/// handoff; the dark adaptation exists only so the demo can inspect kit states
/// in both appearances and is not an Annota production dark palette.
ThemeData annotaTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172B);
  final surface = dark ? const Color(0xFF0F172B) : Colors.white;
  final muted = dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
  final secondary = dark ? const Color(0xFFCBD5E1) : const Color(0xFF62748E);
  final border = dark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);
  final onAccent = dark ? const Color(0xFF0F172B) : Colors.white;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F172B),
    brightness: brightness,
    primary: ink,
    onPrimary: onAccent,
    surface: surface,
    onSurface: ink,
  );
  final payment = PaymentTheme.fromColorScheme(scheme).copyWith(
    accent: ink,
    onAccent: onAccent,
    surface: surface,
    surfaceMuted: muted,
    outline: dark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
    textPrimary: ink,
    textSecondary: secondary,
    border: border,
    disabled: dark ? const Color(0xFF64748B) : const Color(0xFFA3AAB8),
    radius: 12,
    controlRadius: 6,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: surface,
    extensions: [payment],
    dividerTheme: DividerThemeData(color: payment.outline, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        height: 24 / 17,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      shape: Border(bottom: BorderSide(color: payment.outline)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: payment.controlBorderRadius,
        side: BorderSide(color: payment.outline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: payment.controlBorderRadius,
        borderSide: BorderSide(color: border),
      ),
    ),
  );
}
