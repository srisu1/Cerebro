import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cerebro_app/config/constants.dart';
import 'package:cerebro_app/config/theme.dart';
import 'package:cerebro_app/providers/auth_provider.dart';

const _termsText =
    'CEREBRO Terms of Service\n\nLast updated: February 2026\n\n'
    '1. Acceptance of Terms\nBy accessing or using CEREBRO, you agree to these Terms.\n\n'
    '2. Description of Service\nCEREBRO is an AI-powered student companion for study tracking, '
    'health monitoring, and daily life management.\n\n'
    '3. User Accounts\nYou are responsible for your account security.\n\n'
    '4. Acceptable Use\nYou agree not to misuse the service.\n\n'
    '5. Modifications\nWe may modify these terms at any time.';

const _privacyText =
    'CEREBRO Privacy Policy\n\nLast updated: February 2026\n\n'
    '1. Information We Collect\nName, email, study habits, health data, avatar preferences.\n\n'
    '2. How We Use It\nPersonalized recommendations and cross-domain insights.\n\n'
    '3. Data Storage\nSecurely stored with industry-standard encryption.\n\n'
    '4. Your Rights\nExport or delete your data anytime.\n\n'
    '5. Contact\nsupport@cerebro-app.com';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _hidePass = true;

  late AnimationController _ac;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authProvider.notifier)
        .login(email: _emailC.text.trim(), password: _passC.text);
    if (ok && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final setupDone =
          prefs.getBool(AppConstants.setupCompleteKey) ?? false;
      final avatarDone =
          prefs.getBool(AppConstants.avatarCreatedKey) ?? false;
      if (!setupDone) {
        context.go('/setup');
      } else if (!avatarDone) {
        context.go('/avatar-setup');
      } else {
        context.go('/home');
      }
    }
  }

  void _showForgotPassword() {
    final rc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => _CuteDialog(
        accent: CerebroTheme.gold,
        title: 'Reset Password',
        body: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("Enter your email and we'll send a reset link!",
              style: GoogleFonts.nunito(
                  color: CerebroTheme.brown, fontSize: 14, height: 1.5)),
          const SizedBox(height: 14),
          TextField(
              controller: rc,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: _softInput(
                  hint: 'Email address', icon: Icons.email_outlined)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child: _CuteBtn(
                    label: 'Cancel',
                    color: CerebroTheme.creamMid,
                    textColor: CerebroTheme.brown,
                    onTap: () => Navigator.pop(ctx),
                    small: true)),
            const SizedBox(width: 10),
            Expanded(
                child: _CuteBtn(
                    label: 'Send Link',
                    color: CerebroTheme.gold,
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'If an account exists, a reset link will be sent!',
                            style: GoogleFonts.nunito(
                                fontSize: 13, color: Colors.white)),
                        backgroundColor: CerebroTheme.sage,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ));
                    },
                    small: true)),
          ]),
        ]),
      ),
    );
  }

  void _showTermsPopup(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => _CuteDialog(
        accent: CerebroTheme.sage,
        title: title,
        body: Column(mainAxisSize: MainAxisSize.min, children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: SingleChildScrollView(
                child: Text(content,
                    style: GoogleFonts.nunito(
                        color: CerebroTheme.brown,
                        fontSize: 13,
                        height: 1.7))),
          ),
          const SizedBox(height: 16),
          _CuteBtn(
              label: 'Got it!',
              color: CerebroTheme.sage,
              onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    );
  }

  InputDecoration _softInput(
      {required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.nunito(
          color: CerebroTheme.creamDark,
          fontSize: 14,
          fontWeight: FontWeight.w500),
      filled: true,
      fillColor: const Color(0xFFFAF6F1),
      prefixIcon:
          Icon(icon, color: CerebroTheme.brown.withOpacity(0.55), size: 20),
      suffixIcon: suffix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: CerebroTheme.creamDark, width: 2)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: CerebroTheme.creamDark, width: 2)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: CerebroTheme.sage, width: 2.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: CerebroTheme.coral, width: 2)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: CerebroTheme.coral, width: 2.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final loading = auth.status == AuthStatus.loading;
    final wide = MediaQuery.of(context).size.width > 920;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F2),
      body: wide
          ? Row(children: [
              _brandPanel(),
              Expanded(child: _formPanel(auth, loading)),
            ])
          : _formPanel(auth, loading),
    );
  }

  Widget _brandPanel() {
    return SizedBox(
      width: 380,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5EDE4), // warm cream top
              Color(0xFFE4F0E8), // sage tint bottom
            ],
          ),
        ),
        child: Stack(
          children: [
            // background shapes
            Positioned(
              top: 60,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CerebroTheme.sage.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: CerebroTheme.gold.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 200,
              right: 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: CerebroTheme.lavender.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 1,
                color: CerebroTheme.outline.withOpacity(0.06),
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _logoBadge(),
                    const SizedBox(height: 22),

                    Text('CEREBRO',
                        style: GoogleFonts.gaegu(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: CerebroTheme.outline,
                          letterSpacing: 3,
                        )),
                    const SizedBox(height: 6),
                    Text('Your AI Student Companion',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CerebroTheme.brown,
                        )),

                    const SizedBox(height: 28),

                    Container(
                      width: 60,
                      height: 3,
                      decoration: BoxDecoration(
                        color: CerebroTheme.sage.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(height: 28),

                    _featureChip(
                        Icons.auto_stories_rounded, 'Smart Study Tools',
                        CerebroTheme.sage),
                    const SizedBox(height: 10),
                    _featureChip(
                        Icons.favorite_rounded, 'Wellbeing Tracking',
                        CerebroTheme.pinkPop),
                    const SizedBox(height: 10),
                    _featureChip(
                        Icons.emoji_events_rounded, 'Level Up & Earn XP',
                        CerebroTheme.gold),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoBadge() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FD4AD), Color(0xFF5FB085)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CerebroTheme.outline, width: 4),
        boxShadow: [CerebroTheme.shadow3D],
      ),
      child: Center(
        child: Text('C',
            style: GoogleFonts.gaegu(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            )),
      ),
    );
  }

  Widget _featureChip(IconData icon, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: CerebroTheme.outline.withOpacity(0.08), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Text(text,
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CerebroTheme.outline)),
        ],
      ),
    );
  }

  // --- form panel ---
  Widget _formPanel(AuthState auth, bool loading) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: FadeTransition(
          opacity: _fade,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back',
                      style: GoogleFonts.gaegu(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: CerebroTheme.outline,
                      )),
                  const SizedBox(height: 4),
                  Text('Sign in to continue your quest',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CerebroTheme.brown,
                      )),
                  const SizedBox(height: 28),

                  _GoogleBtn(onTap: loading ? null : () async {
                    final ok = await ref
                        .read(authProvider.notifier)
                        .loginWithGoogle();
                    if (ok && mounted) {
                      final prefs =
                          await SharedPreferences.getInstance();
                      final setupDone = prefs.getBool(
                              AppConstants.setupCompleteKey) ??
                          false;
                      final avatarDone = prefs.getBool(
                              AppConstants.avatarCreatedKey) ??
                          false;
                      if (!setupDone) {
                        context.go('/setup');
                      } else if (!avatarDone) {
                        context.go('/avatar-setup');
                      } else {
                        context.go('/home');
                      }
                    }
                  }),
                  const SizedBox(height: 22),

                  Row(children: [
                    const Expanded(
                        child: Divider(
                            color: CerebroTheme.creamDark, thickness: 1.5)),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or',
                          style: GoogleFonts.nunito(
                              color: CerebroTheme.brown,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Expanded(
                        child: Divider(
                            color: CerebroTheme.creamDark, thickness: 1.5)),
                  ]),
                  const SizedBox(height: 22),

                  _label('Email'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailC,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: _softInput(
                        hint: 'you@university.ac.uk',
                        icon: Icons.email_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  _label('Password'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passC,
                    obscureText: _hidePass,
                    style: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: _softInput(
                      hint: 'Enter your password',
                      icon: Icons.lock_outlined,
                      suffix: IconButton(
                        icon: Icon(
                          _hidePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: CerebroTheme.brown.withOpacity(0.5),
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _hidePass = !_hidePass),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Password is required';
                      }
                      if (v.length < 8) return 'At least 8 characters';
                      return null;
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPassword,
                      style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4)),
                      child: Text('Forgot password?',
                          style: GoogleFonts.nunito(
                            color: CerebroTheme.brown,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                CerebroTheme.brown.withOpacity(0.4),
                          )),
                    ),
                  ),

                  if (auth.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: CerebroTheme.coral.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: CerebroTheme.coral.withOpacity(0.4),
                            width: 1.5),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline,
                            color: CerebroTheme.coral, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(auth.errorMessage!,
                                style: GoogleFonts.nunito(
                                    color: CerebroTheme.coralDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600))),
                      ]),
                    ),

                  const SizedBox(height: 6),

                  SizedBox(
                    width: double.infinity,
                    child: _CuteBtn(
                      label: 'Sign In',
                      color: CerebroTheme.sage,
                      onTap: loading ? null : _handleLogin,
                      loading: loading,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: GoogleFonts.nunito(
                                  color: CerebroTheme.brown,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Text('Sign Up',
                                style: GoogleFonts.nunito(
                                    color: CerebroTheme.sageDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14)),
                          ),
                        ]),
                  ),

                  const SizedBox(height: 14),

                  Center(
                    child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text('By continuing, you agree to our ',
                              style: GoogleFonts.nunito(
                                  color: CerebroTheme.brown
                                      .withOpacity(0.6),
                                  fontSize: 11)),
                          GestureDetector(
                            onTap: () => _showTermsPopup(
                                'Terms of Service', _termsText),
                            child: Text('Terms',
                                style: GoogleFonts.nunito(
                                    color: CerebroTheme.brown,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    decoration:
                                        TextDecoration.underline)),
                          ),
                          Text(' and ',
                              style: GoogleFonts.nunito(
                                  color: CerebroTheme.brown
                                      .withOpacity(0.6),
                                  fontSize: 11)),
                          GestureDetector(
                            onTap: () => _showTermsPopup(
                                'Privacy Policy', _privacyText),
                            child: Text('Privacy Policy',
                                style: GoogleFonts.nunito(
                                    color: CerebroTheme.brown,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    decoration:
                                        TextDecoration.underline)),
                          ),
                        ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: CerebroTheme.outline));
}

// --- shared widgets ---

class _CuteDialog extends StatelessWidget {
  final Color accent;
  final String title;
  final Widget body;
  const _CuteDialog(
      {required this.accent, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: CerebroTheme.outline, width: 3),
          boxShadow: [
            BoxShadow(
                color: CerebroTheme.outline.withOpacity(0.14),
                offset: const Offset(0, 6),
                blurRadius: 0),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            decoration: BoxDecoration(
              color: accent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(children: [
              Expanded(
                  child: Text(title,
                      style: GoogleFonts.gaegu(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: Colors.white),
                ),
              ),
            ]),
          ),
          Flexible(
              child:
                  Padding(padding: const EdgeInsets.all(20), child: body)),
        ]),
      ),
    );
  }
}

class _GoogleBtn extends StatefulWidget {
  final VoidCallback? onTap;
  final String label;
  const _GoogleBtn(
      {required this.onTap, this.label = 'Continue with Google'});
  @override
  State<_GoogleBtn> createState() => _GoogleBtnState();
}

class _GoogleBtnState extends State<_GoogleBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _p = true) : null,
      onTapUp: widget.onTap != null ? (_) {
        setState(() => _p = false);
        widget.onTap!();
      } : null,
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 50,
        transform: Matrix4.translationValues(0, _p ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CerebroTheme.creamDark, width: 2),
          boxShadow: [
            if (!_p)
              BoxShadow(
                  color: CerebroTheme.outline.withOpacity(0.08),
                  offset: const Offset(0, 3),
                  blurRadius: 0),
          ],
        ),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: CerebroTheme.outline.withOpacity(0.3),
                    width: 1.5)),
            child: Center(
                child: Text('G',
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4285F4)))),
          ),
          const SizedBox(width: 10),
          Text(widget.label,
              style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CerebroTheme.outline)),
        ]),
      ),
    );
  }
}

class _CuteBtn extends StatefulWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final bool loading;
  final bool small;
  const _CuteBtn({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    this.onTap,
    this.loading = false,
    this.small = false,
  });
  @override
  State<_CuteBtn> createState() => _CuteBtnState();
}

class _CuteBtnState extends State<_CuteBtn> {
  bool _p = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) {
        setState(() => _p = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: widget.small ? 44 : 52,
        transform: Matrix4.translationValues(0, _p ? 3 : 0, 0),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: CerebroTheme.outline,
              width: widget.small ? 2.5 : 3),
          boxShadow: [
            if (!_p)
              BoxShadow(
                  color: CerebroTheme.outline.withOpacity(0.25),
                  offset: const Offset(0, 4),
                  blurRadius: 0),
          ],
        ),
        child: Center(
          child: widget.loading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: widget.textColor))
              : Text(widget.label,
                  style: GoogleFonts.nunito(
                      fontSize: widget.small ? 14 : 16,
                      fontWeight: FontWeight.w800,
                      color: widget.textColor)),
        ),
      ),
    );
  }
}
