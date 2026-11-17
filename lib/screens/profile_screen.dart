
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/session_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({
    super.key,
    required this.username,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  File? profileImage;
  bool isLoading = true;

  final Color primaryColor = const Color(0xFF414936);
  final Color backgroundColor = const Color(0xFFF5F0E6);

  String get imageKey => 'profile_image_${widget.username}';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // Memuat foto profil berdasarkan username
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(imageKey);

    if (savedPath != null && File(savedPath).existsSync()) {
      profileImage = File(savedPath);
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // Menampilkan pilihan kamera atau galeri
  Future<void> _showImageSource() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFCF5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt_outlined,
                    color: primaryColor,
                  ),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: primaryColor,
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // Memilih foto dan menyimpannya ke penyimpanan internal aplikasi
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile == null) return;

      final directory = await getApplicationDocumentsDirectory();

      final safeUsername = widget.username.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );

      final savedFile = File(
        '${directory.path}/profile_$safeUsername.jpg',
      );

      await File(pickedFile.path).copy(savedFile.path);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(imageKey, savedFile.path);

      if (!mounted) return;

      setState(() {
        profileImage = savedFile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil diperbarui!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await SessionService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // FOTO PROFIL
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 58,
                      backgroundColor: const Color(0xFFE9E1D2),
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!)
                          : null,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : profileImage == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 65,
                                  color: primaryColor,
                                )
                              : null,
                    ),
                  ),

                  // TOMBOL EDIT FOTO
                  Positioned(
                    bottom: 3,
                    right: 3,
                    child: GestureDetector(
                      onTap: _showImageSource,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: backgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 22),

              // INFORMASI USER
              Text(
                widget.username,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'MOYA SHOP MEMBER',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: primaryColor.withOpacity(0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 30),

              // KARTU DESKRIPSI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.spa_outlined,
                      size: 30,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome to MOYA Shop',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Semoga responsi besok lancar, aminn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Colors.brown.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // TOMBOL LOGOUT
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
