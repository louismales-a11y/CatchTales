import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';
import '../widgets/water_background.dart';

/// Screen shown after sign-up / login requiring email verification.
/// Blocks access to the main app until the email is verified.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    final verified = await AuthService.instance.checkEmailVerification();
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(tr('verifyNotYet')),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    final sent = await AuthService.instance.sendEmailVerification();
    if (!mounted) return;
    setState(() => _isResending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(sent ? tr('verifyEmailResent') : tr('verifyResendFailed')),
        backgroundColor: sent ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    return Scaffold(
      body: WaterBackground(
        showFish: true,
        
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 20)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Icon(Icons.mark_email_unread, size: 48, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    tr('verifyTitle'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF76FF03), letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${tr("verifyEmailDesc")}\n${auth.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('verifyHint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.white38, height: 1.4),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : _checkVerification,
                      icon: _isChecking
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF003544)))
                          : const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(_isChecking ? tr('verifyChecking') : tr('verifyIveVerified')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF76FF03),
                        foregroundColor: const Color(0xFF003544),
                        elevation: 8,
                        shadowColor: const Color(0xFF76FF03).withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _isResending ? null : _resendEmail,
                      icon: _isResending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                          : const Icon(Icons.refresh, size: 18),
                      label: Text(_isResending ? tr('verifySending') : tr('verifyResend')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () async => await AuthService.instance.logout(),
                    child: Text(tr('verifyUseDifferent'), style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
