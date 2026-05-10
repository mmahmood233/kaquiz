import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../auth/login_screen.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final user = context.read<AuthViewModel>().currentUser;
    final original = user?.name ?? '';
    final changed = _nameController.text.trim() != original;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final vm = context.read<AuthViewModel>();
    final success = await vm.updateProfile(_nameController.text.trim());
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (success) _hasChanges = false;
    });

    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          success ? Icons.check_circle_rounded : Icons.error_rounded,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(success ? 'Profile updated!' : vm.errorMessage ?? 'Update failed'),
      ]),
      backgroundColor: success ? AppTheme.success : AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<MapViewModel>().stopTracking();
      await context.read<AuthViewModel>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const LoginScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Profile'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _isSaving ? AppTheme.textHint : AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, vm, _) {
          final user = vm.currentUser;
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildAvatar(user.email),
                const SizedBox(height: 8),
                _buildEmail(user.email),
                const SizedBox(height: 32),
                _buildForm(),
                const SizedBox(height: 32),
                _buildLogoutSection(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String email) {
    return Container(
      padding: const EdgeInsets.only(top: 32, bottom: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          UserAvatar(email: email, radius: 48),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmail(String email) {
    return Text(
      email,
      style: const TextStyle(
        fontSize: 14,
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Display Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saveProfile(),
                  decoration: InputDecoration(
                    hintText: 'Enter your display name',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    suffixIcon: _isSaving
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    AppTheme.primary),
                              ),
                            ),
                          )
                        : null,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Name cannot be empty';
                    }
                    if (v.trim().length > 50) {
                      return 'Name is too long';
                    }
                    return null;
                  },
                ),
                if (_hasChanges) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ListTile(
          onTap: _handleLogout,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.logout_rounded,
                color: AppTheme.error, size: 20),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.error,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded,
              color: AppTheme.error.withOpacity(0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
