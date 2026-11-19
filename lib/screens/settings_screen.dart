import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_strings.dart';
import '../providers/timer_provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/storage_service.dart';

/// Professional Settings Screen allowing full customization of timer durations,
/// audio/haptic notification preferences, productivity stats, and app information.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _focusDuration;
  late int _breakDuration;
  late int _longBreakDuration;
  late int _dailyGoal;
  late bool _soundEnabled;
  late bool _vibrationEnabled;

  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageService>();
    _focusDuration = storage.getPomodoroDuration();
    _breakDuration = storage.getShortBreakDuration();
    _longBreakDuration = storage.getLongBreakDuration();
    _dailyGoal = storage.getDailyGoal();
    _soundEnabled = storage.isSoundEnabled();
    _vibrationEnabled = storage.isVibrationEnabled();
  }

  Future<void> _saveSettings() async {
    final storage = context.read<StorageService>();
    final timerProvider = context.read<TimerProvider>();

    await Future.wait([
      storage.setPomodoroDuration(_focusDuration),
      storage.setShortBreakDuration(_breakDuration),
      storage.setLongBreakDuration(_longBreakDuration),
      storage.setSoundEnabled(_soundEnabled),
      storage.setVibrationEnabled(_vibrationEnabled),
    ]);

    timerProvider.soundService.setSoundEnabled(_soundEnabled);
    timerProvider.soundService.setVibrationEnabled(_vibrationEnabled);
    timerProvider.updateDurations();
  }

  void _updateFocusDuration(int minutes) {
    final validated = minutes.clamp(AppConstants.minMinutes, AppConstants.maxPomodoroMinutes);
    setState(() => _focusDuration = validated);
    _saveSettings();
  }

  void _updateBreakDuration(int minutes) {
    final validated = minutes.clamp(AppConstants.minMinutes, AppConstants.maxBreakMinutes);
    setState(() => _breakDuration = validated);
    _saveSettings();
  }

  Future<void> _showCustomDurationDialog({
    required String title,
    required int currentValue,
    required int min,
    required int max,
    required ValueChanged<int> onSaved,
  }) async {
    final controller = TextEditingController(text: currentValue.toString());
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(ctx).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter minutes ($min - $max)',
                      suffixText: 'min',
                      errorText: errorMessage,
                      filled: true,
                      fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(ctx).colorScheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    AppStrings.cancelAction,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final parsed = int.tryParse(controller.text.trim());
                    if (parsed == null) {
                      setDialogState(() => errorMessage = 'Please enter a valid number');
                    } else if (parsed < min || parsed > max) {
                      setDialogState(() => errorMessage = 'Must be between $min and $max minutes');
                    } else {
                      onSaved(parsed);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showResetProductivityConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppStrings.resetProductivityTitle,
          style: TextStyle(
            color: Theme.of(ctx).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          AppStrings.resetProductivityMessage,
          style: TextStyle(
            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              AppStrings.cancelAction,
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              AppStrings.resetAction,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<TimerProvider>().resetProductivity();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Today's focus sessions reset to 0"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<TimerProvider>();
    final appSettings = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          AppStrings.settings,
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            // ==========================================
            // 1. TIMER SETTINGS
            // ==========================================
            _buildSectionHeader(
              title: AppStrings.timerSettings,
              icon: Icons.timer_outlined,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // Focus Duration Slider & Steppers
                    _buildDurationTile(
                      title: AppStrings.pomodoroDuration,
                      subtitle: 'Duration: 1 to 120 minutes',
                      value: _focusDuration,
                      min: AppConstants.minMinutes,
                      max: AppConstants.maxPomodoroMinutes,
                      presetPills: const [15, 25, 45, 60],
                      onChanged: _updateFocusDuration,
                      onTapValueBadge: () => _showCustomDurationDialog(
                        title: 'Focus Duration',
                        currentValue: _focusDuration,
                        min: AppConstants.minMinutes,
                        max: AppConstants.maxPomodoroMinutes,
                        onSaved: _updateFocusDuration,
                      ),
                    ),
                    const Divider(height: 1),
                    _buildDurationTile(
                      title: 'Long Break Duration', subtitle: 'Duration: 1 to 60 minutes',
                      value: _longBreakDuration, min: 1, max: AppConstants.maxBreakMinutes,
                      presetPills: const [10, 15, 20],
                      onChanged: (value) { setState(() => _longBreakDuration = value); _saveSettings(); },
                      onTapValueBadge: () => _showCustomDurationDialog(title: 'Long Break Duration', currentValue: _longBreakDuration, min: 1, max: AppConstants.maxBreakMinutes, onSaved: (value) { setState(() => _longBreakDuration = value); _saveSettings(); }),
                    ),
                    const Divider(height: 1),
                    // Break Duration Slider & Steppers
                    _buildDurationTile(
                      title: AppStrings.shortBreakDuration,
                      subtitle: 'Duration: 1 to 60 minutes',
                      value: _breakDuration,
                      min: AppConstants.minMinutes,
                      max: AppConstants.maxBreakMinutes,
                      presetPills: const [3, 5, 10, 15],
                      onChanged: _updateBreakDuration,
                      onTapValueBadge: () => _showCustomDurationDialog(
                        title: 'Break Duration',
                        currentValue: _breakDuration,
                        min: AppConstants.minMinutes,
                        max: AppConstants.maxBreakMinutes,
                        onSaved: _updateBreakDuration,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(title: 'Daily Goal & Appearance', icon: Icons.flag_outlined),
            const SizedBox(height: 8),
            Card(child: Column(children: [
              ListTile(
                title: const Text('Daily focus goal'),
                subtitle: Text('$_dailyGoal completed sessions'),
                leading: const Icon(Icons.track_changes),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(tooltip: 'Decrease daily goal', onPressed: _dailyGoal > 1 ? () => _updateDailyGoal(_dailyGoal - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
                  Text('$_dailyGoal', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(tooltip: 'Increase daily goal', onPressed: _dailyGoal < 12 ? () => _updateDailyGoal(_dailyGoal + 1) : null, icon: const Icon(Icons.add_circle_outline)),
                ]),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Slider(min: 1,max: 12,divisions: 11,value: _dailyGoal.toDouble(),label:'$_dailyGoal sessions',onChanged:(value)=>_updateDailyGoal(value.round()))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: DropdownButtonFormField<ThemeMode>(value: appSettings.themeMode, decoration: const InputDecoration(labelText: 'Theme'), items: const [DropdownMenuItem(value:ThemeMode.system,child:Text('System default')),DropdownMenuItem(value:ThemeMode.light,child:Text('Light')),DropdownMenuItem(value:ThemeMode.dark,child:Text('Dark'))], onChanged:(mode){if(mode!=null)appSettings.setThemeMode(mode);})),
              const SizedBox(height: 12),
            ])),
            const SizedBox(height: 24),

            // ==========================================
            // 2. NOTIFICATION SETTINGS
            // ==========================================
            _buildSectionHeader(
              title: AppStrings.notificationSettings,
              icon: Icons.notifications_active_outlined,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_outlined, color: AppColors.primary),
                    title: Text(
                      AppStrings.soundEffects,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    subtitle: const Text(AppStrings.soundEffectsSubtitle),
                    value: _soundEnabled,
                    onChanged: (val) {
                      setState(() => _soundEnabled = val);
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration_outlined, color: AppColors.primary),
                    title: Text(
                      AppStrings.vibration,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    subtitle: const Text(AppStrings.vibrationSubtitle),
                    value: _vibrationEnabled,
                    onChanged: (val) {
                      setState(() => _vibrationEnabled = val);
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // 3. PRODUCTIVITY SETTINGS
            // ==========================================
            _buildSectionHeader(
              title: AppStrings.productivitySettings,
              icon: Icons.insights_rounded,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  // View Today's Completed Sessions Tile
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                    ),
                    title: Text(
                      AppStrings.todayCompleted,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    subtitle: Text('${timerProvider.completedSessions} sessions completed today'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${timerProvider.completedSessions}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Reset Today's Session Counter Action
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restart_alt_rounded, color: AppColors.accent, size: 22),
                    ),
                    title: Text(
                      "Reset Today's Session Counter",
                      style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    subtitle: const Text("Reset completed count to 0 while keeping history"),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: () => _showResetProductivityConfirmation(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // 4. APP INFORMATION
            // ==========================================
            _buildSectionHeader(
              title: AppStrings.appInfoTitle,
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Logo & Version
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.16),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.appName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Version ${AppStrings.appVersion}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    // About Description
                    Text(
                      AppStrings.aboutTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.aboutDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.spa_outlined, size: 14, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            AppStrings.appTagline,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _updateDailyGoal(int value) async {
    final goal = value.clamp(1, 12);
    setState(() => _dailyGoal = goal);
    await context.read<StorageService>().setDailyGoal(goal);
    if (mounted) context.read<TimerProvider>().notifySettingsChanged();
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationTile({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required List<int> presetPills,
    required ValueChanged<int> onChanged,
    required VoidCallback onTapValueBadge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Stepper Buttons and Value Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decrement Button
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove_rounded, size: 16),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: value > min ? () => onChanged(value - 1) : null,
                  ),
                  const SizedBox(width: 8),
                  // Tappable Value Badge for direct input dialog
                  GestureDetector(
                    onTap: onTapValueBadge,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$value min',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Increment Button
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    onPressed: value < max ? () => onChanged(value + 1) : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Slider Control
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
          activeTrackColor: Theme.of(context).colorScheme.primary,
          inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
          thumbColor: Theme.of(context).colorScheme.primary,
          overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (val) => onChanged(val.round()),
            ),
          ),

          // Quick Preset Pills Row
          Wrap(
            spacing: 8,
            children: presetPills.map((preset) {
              final isSelected = value == preset;
              return ChoiceChip(
                label: Text('$preset min'),
                selected: isSelected,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (_) => onChanged(preset),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
