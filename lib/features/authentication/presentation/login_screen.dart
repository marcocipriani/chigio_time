import 'dart:async' show unawaited;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../app/theme/color_schemes.dart';
import '../../../core/constants/app_strings.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _googleLoading = false;
  bool _emailLoading = false;
  bool _showEmailForm = false;
  bool _isRegister = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passCtrl2 = TextEditingController();

  void _openEmailForm({required bool register}) {
    setState(() {
      _showEmailForm = true;
      _isRegister = register;
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passCtrl2.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final cred = await ref.read(authRepositoryProvider).signInWithGoogle();
      final photoUrl = cred?.user?.photoURL;
      if (photoUrl != null) {
        unawaited(ref.read(profileRepositoryProvider).syncPhotoUrl(photoUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorGoogleSignIn(e)),
            backgroundColor: AppColors.red700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;
    setState(() => _emailLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email, pass);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authErrorMessage(e.code)),
            backgroundColor: AppColors.red700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorGeneric(e)),
            backgroundColor: AppColors.red700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final pass2 = _passCtrl2.text;
    if (email.isEmpty || pass.isEmpty) return;
    if (pass != pass2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.passwordMismatch)),
      );
      return;
    }
    setState(() => _emailLoading = true);
    try {
      await ref.read(authRepositoryProvider).registerWithEmail(email, pass);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_authErrorMessage(e.code)),
            backgroundColor: AppColors.red700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorGeneric(e)),
            backgroundColor: AppColors.red700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.resetPasswordHint)),
      );
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.resetPasswordSent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorGeneric(e)),
            backgroundColor: AppColors.red700,
          ),
        );
      }
    }
  }

  String _authErrorMessage(String code) => switch (code) {
    'user-not-found' => AppStrings.authErrUserNotFound,
    'wrong-password' => AppStrings.authErrWrongPassword,
    'invalid-email' => AppStrings.authErrInvalidEmail,
    'email-already-in-use' => AppStrings.authErrEmailInUse,
    'weak-password' => AppStrings.authErrWeakPassword,
    'invalid-credential' => AppStrings.authErrInvalidCredential,
    _ => AppStrings.authErrCode(code),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.neutral900;
    final textSub = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : AppColors.neutral600;
    final divColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 56),

                    // ── Hero ──────────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF0055A5,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 36,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppColors.blue600,
                                  child: const Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            AppStrings.appName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: textMain,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.chigioMotto,
                            style: TextStyle(fontSize: 12, color: textSub),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── 1. Sign in with Google (primary) ──────────────────────
                    _GoogleSignInButton(
                      loading: _googleLoading,
                      onPressed: _googleLoading ? null : _handleGoogleSignIn,
                    ),

                    const SizedBox(height: 20),

                    // ── Divider ───────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(child: Divider(color: divColor, height: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            AppStrings.orDivider,
                            style: TextStyle(fontSize: 11, color: textSub),
                          ),
                        ),
                        Expanded(child: Divider(color: divColor, height: 1)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── 2. Email sign-in (secondary) ──────────────────────────
                    AnimatedCrossFade(
                      firstChild: _EmailCollapseBtn(
                        isDark: isDark,
                        textSub: textSub,
                        onTap: () => _openEmailForm(register: false),
                      ),
                      secondChild: _EmailForm(
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        passCtrl2: _passCtrl2,
                        isRegister: _isRegister,
                        isDark: isDark,
                        textSub: textSub,
                        loading: _emailLoading,
                        onSignIn: _isRegister
                            ? _handleRegister
                            : _handleEmailSignIn,
                        onForgotPassword: _handleForgotPassword,
                        onToggleMode: () =>
                            setState(() => _isRegister = !_isRegister),
                        onCollapse: () =>
                            setState(() => _showEmailForm = false),
                      ),
                      crossFadeState: _showEmailForm
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 220),
                    ),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        alignment: Alignment.topCenter,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: _showEmailForm
                          ? const SizedBox.shrink(
                              key: ValueKey('register-hidden'),
                            )
                          : Padding(
                              key: const ValueKey('register-visible'),
                              padding: const EdgeInsets.only(top: 28),
                              child: Center(
                                child: _AuthModeToggle(
                                  isRegister: false,
                                  textSub: textSub,
                                  onTap: () => _openEmailForm(register: true),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Google Sign-In button (official branding) ─────────────────────────────────
//
// White background, coloured Google logo, dark text — follows Google Identity
// guidelines: https://developers.google.com/identity/gsi/web/guides/display-button

class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const _GoogleSignInButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          splashColor: const Color(0xFF4285F4).withValues(alpha: 0.08),
          highlightColor: const Color(0xFFf8f8f8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF747775), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3C4043).withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: const Color(0xFF3C4043).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4285F4),
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        label: AppStrings.googleChipLabel,
                        image: true,
                        child: Image.asset(
                          'assets/images/google_g_logo.png',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.signInGoogle,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1F1F1F),
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Email collapsed pill ──────────────────────────────────────────────────────

class _EmailCollapseBtn extends StatelessWidget {
  final bool isDark;
  final Color textSub;
  final VoidCallback onTap;

  const _EmailCollapseBtn({
    required this.isDark,
    required this.textSub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 18, color: textSub),
            const SizedBox(width: 10),
            Text(
              AppStrings.signInEmail,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Email expanded form ───────────────────────────────────────────────────────

class _EmailForm extends StatefulWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController passCtrl2;
  final bool isRegister;
  final bool isDark;
  final Color textSub;
  final bool loading;
  final VoidCallback onSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onToggleMode;
  final VoidCallback onCollapse;

  const _EmailForm({
    required this.emailCtrl,
    required this.passCtrl,
    required this.passCtrl2,
    required this.isRegister,
    required this.isDark,
    required this.textSub,
    required this.loading,
    required this.onSignIn,
    required this.onForgotPassword,
    required this.onToggleMode,
    required this.onCollapse,
  });

  @override
  State<_EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<_EmailForm> {
  bool _obscurePass = true;
  bool _obscurePass2 = true;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.03);
    final border = widget.isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: border),
    );
    final textStyle = TextStyle(
      fontSize: 14,
      color: widget.isDark
          ? Colors.white.withValues(alpha: 0.9)
          : AppColors.neutral900,
    );
    final hintStyle = TextStyle(
      fontSize: 14,
      color: widget.isDark
          ? Colors.white.withValues(alpha: 0.28)
          : AppColors.neutral400,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row ────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: widget.textSub),
              const SizedBox(width: 8),
              Text(
                widget.isRegister
                    ? AppStrings.registerEmail
                    : AppStrings.signInEmail,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.textSub,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onCollapse,
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 20,
                  color: widget.textSub,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Email field ───────────────────────────────────────────
          TextField(
            controller: widget.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: textStyle,
            decoration: InputDecoration(
              hintText: AppStrings.emailPlaceholder,
              hintStyle: hintStyle,
              labelText: AppStrings.emailLabel,
              labelStyle: TextStyle(fontSize: 13, color: widget.textSub),
              border: fieldBorder,
              enabledBorder: fieldBorder,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.blue400,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),

          const SizedBox(height: 10),

          // ── Password field ────────────────────────────────────────
          TextField(
            controller: widget.passCtrl,
            obscureText: _obscurePass,
            style: textStyle,
            decoration: InputDecoration(
              hintText: AppStrings.passwordPlaceholder,
              hintStyle: hintStyle,
              labelText: AppStrings.passwordLabel,
              labelStyle: TextStyle(fontSize: 13, color: widget.textSub),
              border: fieldBorder,
              enabledBorder: fieldBorder,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.blue400,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
              filled: true,
              fillColor: Colors.transparent,
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscurePass = !_obscurePass),
                child: Icon(
                  _obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: widget.textSub,
                ),
              ),
            ),
          ),

          // ── Confirm password (register only) ──────────────────────
          if (widget.isRegister) ...[
            const SizedBox(height: 10),
            TextField(
              controller: widget.passCtrl2,
              obscureText: _obscurePass2,
              style: textStyle,
              decoration: InputDecoration(
                hintText: AppStrings.repeatPassword,
                hintStyle: hintStyle,
                labelText: AppStrings.confirmPassword,
                labelStyle: TextStyle(fontSize: 13, color: widget.textSub),
                border: fieldBorder,
                enabledBorder: fieldBorder,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppColors.blue400,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscurePass2 = !_obscurePass2),
                  child: Icon(
                    _obscurePass2
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: widget.textSub,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 6),

          // ── Forgot password (login only) ──────────────────────────
          if (!widget.isRegister)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: widget.onForgotPassword,
                child: Text(
                  AppStrings.forgotPassword,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue400,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ── Sign-in / Register button ─────────────────────────────
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: widget.loading ? null : widget.onSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: widget.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.isRegister
                          ? AppStrings.registerLink
                          : AppStrings.signInBtn,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Toggle login/register ─────────────────────────────────
          Center(
            child: _AuthModeToggle(
              isRegister: widget.isRegister,
              textSub: widget.textSub,
              onTap: widget.onToggleMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  final bool isRegister;
  final Color textSub;
  final VoidCallback onTap;

  const _AuthModeToggle({
    required this.isRegister,
    required this.textSub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = isRegister
        ? AppStrings.alreadyHaveAccount
        : AppStrings.registerPrompt;
    final action = isRegister ? AppStrings.signInBtn : AppStrings.registerLink;

    return Semantics(
      button: true,
      label: '$prompt$action',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textSub,
              ),
              children: [
                TextSpan(text: prompt),
                TextSpan(
                  text: action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue400,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.blue400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
