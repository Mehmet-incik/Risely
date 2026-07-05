import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';
import '../services/services.dart';
import '../widgets/samsung_time_picker.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onTaskToggled;
  const ProfileScreen({super.key, required this.onTaskToggled});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _pickNotificationTime() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SamsungStyleTimePicker(initialTime: TaskStore.notificationTime ?? '07:00'),
      ),
    );
    if (result != null && context.mounted) {
      final parts = result.split(':');
      await TaskStore.saveNotificationTime(result);
      await NotificationService.scheduleMorningMotivation(int.parse(parts[0]), int.parse(parts[1]));
      setState(() {});
      widget.onTaskToggled();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🔔 Her sabah $result\'da motivasyon gelecek!'), backgroundColor: AppColors.xp));
    }
  }

  Future<void> _cancelNotifications() async {
    await TaskStore.saveNotificationTime(null);
    await NotificationService.cancelAllNotifications();
    setState(() {});
    widget.onTaskToggled();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm bildirimler kapatıldı.'), backgroundColor: Colors.red));
    }
  }

  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: TaskStore.userName);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profil Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 16),
            Text('Adın', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: AppColors.text),
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.xp,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    await TaskStore.saveUserName(nameCtrl.text);
                    setState(() {});
                    widget.onTaskToggled();
                  }
                  Navigator.pop(context);
                },
                child: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Verileri Sıfırla'),
        content: const Text('Tüm görevler ve istatistikler silinecek. Emin misiniz?'),
        actions: [
          CupertinoDialogAction(child: const Text('İptal', style: TextStyle(color: Colors.blue)), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Evet, Sil'),
            onPressed: () async {
              TaskStore.allTasks.clear();
              await TaskStore.saveTasks();
              widget.onTaskToggled();
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veriler sıfırlandı.'), backgroundColor: AppColors.xp));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelInfo = TaskStore.getUserLevelInfo();
    final doneTasks = TaskStore.allTasks.where((t) => t.isDone).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => AvatarPickerSheet(
                  currentAvatar: TaskStore.userAvatar,
                  onSelected: (a) {
                    setState(() {});
                    widget.onTaskToggled();
                  },
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.xp, AppColors.academic])),
                    child: Center(child: Text(TaskStore.userAvatar, style: const TextStyle(fontSize: 48))),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: AppColors.xp, shape: BoxShape.circle, border: Border.all(color: AppColors.bg, width: 2)),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(TaskStore.userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text)),
            const SizedBox(height: 4),
            Text('Seviye ${levelInfo['level']} • ${levelInfo['title']}', style: const TextStyle(fontSize: 14, color: AppColors.xp, fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatCard('Puan', '${TaskStore.totalXp} XP', AppColors.xp),
                  const SizedBox(width: 12),
                  _buildStatCard('Görev', '$doneTasks Adet', AppColors.work),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BİLDİRİMLER', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildMenuTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: TaskStore.notificationTime != null ? AppColors.xp : AppColors.textMuted,
                    title: TaskStore.notificationTime != null ? 'Sabah Bildirimi (${TaskStore.notificationTime})' : 'Sabah Motivasyonu Kur',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (TaskStore.notificationTime != null)
                          GestureDetector(
                            onTap: _cancelNotifications,
                            child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.cancel, color: Colors.redAccent, size: 20)),
                          ),
                        Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ],
                    ),
                    onTap: _pickNotificationTime,
                  ),
                  // Test butonu KALDIRILDI!
                  const SizedBox(height: 24),
                  Text('AYARLAR', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildMenuTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Adımı Değiştir',
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: _showEditProfileSheet,
                  ),
                  _buildMenuTile(
                    icon: isDarkModeNotifier.value ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    title: isDarkModeNotifier.value ? 'Karanlık Mod' : 'Aydınlık Mod',
                    trailing: CupertinoSwitch(
                      value: isDarkModeNotifier.value,
                      activeColor: AppColors.xp,
                      onChanged: (val) async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('is_dark_mode', val);
                        isDarkModeNotifier.value = val;
                      },
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  Text('VERİ YÖNETİMİ', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildMenuTile(
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.red,
                    title: 'Tüm Verileri Sıfırla',
                    titleColor: Colors.red,
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: _showResetDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required Widget trailing, required VoidCallback onTap, Color? iconColor, Color? titleColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.textMuted, size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: titleColor ?? AppColors.text))),
            trailing,
          ],
        ),
      ),
    );
  }
}

class AvatarPickerSheet extends StatefulWidget {
  final String currentAvatar;
  final Function(String) onSelected;
  const AvatarPickerSheet({super.key, required this.currentAvatar, required this.onSelected});

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  late String selected;
  final List<Map<String, String>> avatars = [
    {'emoji': '🦅', 'name': 'Kartal'}, {'emoji': '🦁', 'name': 'Aslan'}, {'emoji': '🤖', 'name': 'Robot'},
    {'emoji': '🚀', 'name': 'Roket'}, {'emoji': '🌟', 'name': 'Yıldız'}, {'emoji': '⚡', 'name': 'Şimşek'},
    {'emoji': '🔥', 'name': 'Ateş'}, {'emoji': '🎯', 'name': 'Hedef'}, {'emoji': '🧠', 'name': 'Beyin'},
    {'emoji': '🦸', 'name': 'Kahraman'}
  ];

  @override
  void initState() {
    super.initState();
    selected = widget.currentAvatar;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Avatar Seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
              GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close_rounded, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Seni en iyi hangisi temsil ediyor?', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.85),
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              final avatar = avatars[index];
              final isSelected = selected == avatar['emoji'];
              return GestureDetector(
                onTap: () => setState(() => selected = avatar['emoji']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.xp.withOpacity(0.15) : AppColors.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.xp : AppColors.border, width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(avatar['emoji']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(avatar['name']!, style: TextStyle(fontSize: 9, color: isSelected ? AppColors.xp : AppColors.textMuted, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.xp,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await TaskStore.saveAvatar(selected);
                widget.onSelected(selected);
                Navigator.pop(context);
              },
              child: const Text('Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
