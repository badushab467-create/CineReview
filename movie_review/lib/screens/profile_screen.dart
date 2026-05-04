import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController(text: 'MovieBuff99');
  int _selectedAvatarIndex = 0;
  bool _isEditing = false;

  final List<IconData> _avatars = [
    Icons.person_rounded,
    Icons.face_rounded,
    Icons.sentiment_satisfied_alt_rounded,
    Icons.pets_rounded,
    Icons.cruelty_free_rounded,
    Icons.catching_pokemon_rounded,
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _signOut() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showAvatarPicker(ThemeProvider theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Profile Photo',
                style: TextStyle(
                  color: theme.backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AnimationLimiter(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _avatars.length,
                    itemBuilder: (context, index) {
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        columnCount: 4,
                        duration: const Duration(milliseconds: 400),
                        child: ScaleAnimation(
                          child: FadeInAnimation(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedAvatarIndex = index);
                                Navigator.pop(context);
                              },
                              child: CircleAvatar(
                                backgroundColor: _selectedAvatarIndex == index
                                    ? theme.themeColor
                                    : theme.themeColor.withOpacity(0.2),
                                child: Icon(
                                  _avatars[index],
                                  color: _selectedAvatarIndex == index
                                      ? Colors.black
                                      : theme.themeColor,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isLight = themeProvider.backgroundColor.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black87 : Colors.white;

    final children = [
      // Profile Photo
      Center(
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: CircleAvatar(
                key: ValueKey<int>(_selectedAvatarIndex),
                radius: 60,
                backgroundColor: themeProvider.themeColor.withOpacity(0.15),
                child: Icon(
                  _avatars[_selectedAvatarIndex],
                  size: 60,
                  color: themeProvider.themeColor,
                ),
              ),
            ),
            if (_isEditing)
              GestureDetector(
                onTap: () => _showAvatarPicker(themeProvider),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeProvider.themeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: themeProvider.backgroundColor, width: 3),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 20),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 32),

      // Edit Toggle
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile Details',
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded, color: themeProvider.themeColor),
            label: Text(
              _isEditing ? 'Save' : 'Edit',
              style: TextStyle(color: themeProvider.themeColor),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Nickname TextBox
      TextField(
        controller: _nicknameController,
        enabled: _isEditing,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: 'Nickname',
          prefixIcon: const Icon(Icons.person_rounded),
          filled: true,
          fillColor: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: (val) => setState(() {}), // Refresh QR code
      ),
      const SizedBox(height: 32),

      // QR Code Section
      Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: QrImageView(
            data: 'CineReviewUser:${_nicknameController.text}',
            version: QrVersions.auto,
            size: 150.0,
            backgroundColor: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: Text(
          'Your CineReview QR',
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
        ),
      ),
      const SizedBox(height: 40),

      // Theme Customization Toggle
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(isLight ? Icons.light_mode : Icons.dark_mode, color: themeProvider.themeColor),
                const SizedBox(width: 12),
                Text(
                  isLight ? 'Light Theme' : 'Dark Theme',
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Switch(
              value: !isLight,
              activeColor: themeProvider.themeColor,
              onChanged: (val) {
                themeProvider.toggleThemeMode();
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 40),

      // Sign Out Button
      ElevatedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: children.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: children[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
