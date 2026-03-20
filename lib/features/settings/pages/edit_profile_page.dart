import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../../services/session_store.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../app/routes.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionStore>();
    _nameController = TextEditingController(
      text: session.userName.isNotEmpty ? session.userName : 'User',
    );
    _emailController = TextEditingController(
      text: session.userEmail.isNotEmpty ? session.userEmail : '',
    );
    _locationController = TextEditingController(text: 'Colombo, Sri Lanka');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _isSaving = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Not logged in');

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');

        final file = File(pickedFile.path);
        await storageRef.putFile(file);

        final url = await storageRef.getDownloadURL();
        await user.updatePhotoURL(url);

        // This will force the UI to reflect new photo URL
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  void _handleSave() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (_nameController.text.isNotEmpty &&
            user.displayName != _nameController.text) {
          await user.updateDisplayName(_nameController.text);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update Firebase profile: $e')),
      );
    }

    if (!mounted) return;

    final session = context.read<SessionStore>();
    session.setUserName(_nameController.text);
    session.setUserEmail(_emailController.text);

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark
        ? const Color(0xFF00D4AA)
        : const Color(0xFF1976D2);
    final subtextColor = isDark
        ? const Color(0xFF8892B0)
        : const Color(0xFF64748B);
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: Text(
              'Save',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.6),
                        ],
                      ),
                      image: photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(photoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: photoUrl == null
                        ? Center(
                            child: Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : 'D',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isSaving ? null : _pickImage,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF0A1628)
                                : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF0A1628)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the camera to change photo',
              style: TextStyle(fontSize: 12, color: subtextColor),
            ),
            const SizedBox(height: 32),

            // Form fields
            AppTextField(
              label: 'Full Name',
              hint: 'Enter your full name',
              controller: _nameController,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Email Address',
              hint: 'Enter your email',
              controller: _emailController,
              readOnly: true,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Location',
              hint: 'Enter your location',
              controller: _locationController,
            ),
            const SizedBox(height: 32),

            // Save button
            PrimaryButton(
              label: 'Save Changes',
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: 32),

            // Danger zone
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3E2723).withValues(alpha: 0.5)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEF5350).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFFEF5350),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Permanently delete your account and all associated data.',
                    style: TextStyle(fontSize: 13, color: subtextColor),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _showDeleteAccountDialog(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF5350),
                        side: const BorderSide(color: Color(0xFFEF5350)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone. All your data, drying sessions, and devices will be permanently deleted.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter your password to confirm:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final password = passwordController.text.trim();
              Navigator.of(ctx).pop(password);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
            ),
            child: const Text(
              'Delete Permanently',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ).then((result) {
      // Do NOT dispose passwordController here — the dialog's exit
      // animation may still reference it. Let GC handle cleanup.
      if (result != null && result is String && result.isNotEmpty) {
        _performAccountDeletion(context, result);
      } else if (result != null && result is String && result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password is required to delete your account.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _performAccountDeletion(
    BuildContext context,
    String password,
  ) async {
    // Capture references before any async gap so we don't use a disposed context
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not found');
      }

      // 1. Re-authenticate with Firebase (required for sensitive operations)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Call backend to delete all user data (sessions, devices)
      //    Use a timeout so we don't hang forever if the backend is down.
      //    If the backend is unreachable, we still proceed with Firebase deletion.
      final token = await user.getIdToken(true);
      const baseUrl = 'http://192.168.1.4:5000';

      try {
        final response = await http
            .delete(
              Uri.parse('$baseUrl/user/delete-account'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          debugPrint(
            'Backend deletion returned ${response.statusCode}: ${response.body}',
          );
        }
      } catch (backendError) {
        // Backend might be down — continue with Firebase account deletion anyway
        debugPrint('Backend deletion failed (continuing): $backendError');
      }

      // 3. Delete the Firebase Auth account
      await user.delete();

      // 4. Clear local data (SharedPreferences stores the session info)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 5. Navigate to login page
      // Do NOT call session.logout() — it triggers notifyListeners() which
      // tries to rebuild widgets that are being torn down by navigation.
      // SharedPreferences is already cleared, so the next login gets fresh data.
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Failed to delete account.';
      if (e.code == 'wrong-password') {
        message = 'Incorrect password. Please try again.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
