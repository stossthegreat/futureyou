import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../design/tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import '../widgets/date_strip.dart';
import '../widgets/scrollable_header.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedType = 'habit';
  String _frequency = 'daily';
  int _everyNDays = 2;

  final _titleController = TextEditingController();
  final _timeController = TextEditingController(text: '07:00');
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  Color _selectedColor = AppColors.emerald;
  String? _selectedEmoji;
  bool _reminderOn = false; // Alarm toggle - defaults OFF
  final List<bool> _repeatDays = List.generate(7, (index) => false);
  final List<String> _dayNames = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  @override
  void initState() {
    super.initState();
    // Start on Manage tab by default
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _onTypeChanged(_selectedType);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onDateSelected(DateTime d) => setState(() => _selectedDate = d);

  void _onTypeChanged(String type) {
    setState(() {
      _selectedType = type;
      for (int i = 0; i < 7; i++) {
        if (type == 'habit') {
          _repeatDays[i] = i >= 1 && i <= 5;
        } else {
          _repeatDays[i] = i == DateTime.now().weekday % 7;
        }
      }
    });
  }

  void _toggleRepeatDay(int i) => setState(() => _repeatDays[i] = !_repeatDays[i]);

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.emerald,
            onSurface: AppColors.textPrimary,
          ),
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: AppColors.baseDark2,
            dialBackgroundColor: AppColors.baseDark3,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickEmoji() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: AppColors.baseDark2,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppBorderRadius.xl)),
        ),
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            setState(() {
              _selectedEmoji = emoji.emoji;
            });
            Navigator.pop(context);
          },
          config: Config(
            height: 256,
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              emojiSizeMax: 28,
              backgroundColor: AppColors.baseDark2,
              columns: 7,
              buttonMode: ButtonMode.MATERIAL,
            ),
            skinToneConfig: const SkinToneConfig(),
            categoryViewConfig: const CategoryViewConfig(
              backgroundColor: AppColors.baseDark2,
              iconColorSelected: AppColors.emerald,
              indicatorColor: AppColors.emerald,
            ),
            bottomActionBarConfig: const BottomActionBarConfig(
              backgroundColor: AppColors.baseDark2,
              buttonColor: AppColors.baseDark3,
              buttonIconColor: AppColors.emerald,
            ),
          ),
        ),
      ),
    );
  }

  List<int> _getRepeatDays() {
    switch (_frequency) {
      case 'daily': return [0,1,2,3,4,5,6];
      case 'weekdays': return [1,2,3,4,5];
      case 'weekends': return [0,6];
      case 'custom': return [
        for (int i=0;i<_repeatDays.length;i++) if(_repeatDays[i]) i
      ];
      default: return [1,2,3,4,5];
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(habitEngineProvider).createHabit(
        title: _titleController.text.trim(),
        type: _selectedType,
        time: _timeController.text,
        startDate: DateTime.now(),
        endDate: _endDate,
        repeatDays: _getRepeatDays(),
        color: _selectedColor,
        emoji: _selectedEmoji,
        reminderOn: _reminderOn, // Pass the alarm toggle state
      );

      _titleController.clear();
      _timeController.text = '07:00';
      setState(() {
        _frequency = 'daily';
        _selectedColor = AppColors.emerald;
        _selectedEmoji = null;
        _reminderOn = false; // Reset alarm toggle
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children:[
          const Icon(LucideIcons.check,color:Colors.white,size:16),
          const SizedBox(width:8),
          Text('${_selectedType.capitalize()} created successfully!')
        ]),
        backgroundColor: AppColors.success,
      ));

      setState(() => _selectedDate = DateTime.now());
      _tabController.animateTo(1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _updateFrequency(String newFrequency) {
    setState(() {
      _frequency = newFrequency;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Scrollable header at the very top
              const SliverToBoxAdapter(
                child: ScrollableHeader(),
              ),
              // Date strip
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    DateStrip(selectedDate: _selectedDate, onDateSelected: _onDateSelected),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [Tab(text:'Add New'),Tab(text:'Manage')],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
              // Tab content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildAddNewTab(), _buildManageTab()],
                ),
              ),
            ],
          ),

          // Floating "Create" button only visible on Manage tab
          if (_tabController.index == 1)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: () => _tabController.animateTo(0),
                backgroundColor: AppColors.emerald,
                icon: const Icon(LucideIcons.plus, color: Colors.black),
                label: const Text('Create', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildAddNewTab() {
    return SingleChildScrollView(
      child: GlassCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _typeSelector(),
              const SizedBox(height: AppSpacing.lg),
              _textField('Title', _titleController,
                  icon: _selectedType == 'habit'
                      ? LucideIcons.flame
                      : LucideIcons.alarmCheck),
              const SizedBox(height: AppSpacing.lg),
              _emojiField(),
              const SizedBox(height: AppSpacing.lg),
              _alarmToggle(),
              const SizedBox(height: AppSpacing.lg),
              _timeField(),
              const SizedBox(height: AppSpacing.lg),
              _dateField('Start Date', _startDate, _selectStartDate),
              const SizedBox(height: AppSpacing.lg),
              _dateField('End Date', _endDate, _selectEndDate),
              const SizedBox(height: AppSpacing.lg),
              _frequencySelector(),
              const SizedBox(height: AppSpacing.lg),
              _colorPicker(),
              const SizedBox(height: AppSpacing.xl),
              _commitButton(),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeSelector() => Row(
        children: [
          Expanded(
              child: GlassButton(
            onPressed: () => _onTypeChanged('habit'),
            backgroundColor: _selectedType == 'habit'
                ? AppColors.emerald
                : AppColors.glassBackground,
            borderColor: _selectedType == 'habit'
                ? AppColors.emerald
                : AppColors.glassBorder,
            child: Text('Habit',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _selectedType == 'habit'
                      ? Colors.black
                      : AppColors.textSecondary,
                )),
          )),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: GlassButton(
            onPressed: () => _onTypeChanged('task'),
            backgroundColor: _selectedType == 'task'
                ? AppColors.cyan
                : AppColors.glassBackground,
            borderColor: _selectedType == 'task'
                ? AppColors.cyan
                : AppColors.glassBorder,
            child: Text('Task',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _selectedType == 'task'
                      ? Colors.black
                      : AppColors.textSecondary,
                )),
          )),
        ],
      );

  Widget _textField(String label, TextEditingController c,
          {required IconData icon}) =>
      TextFormField(
        controller: c,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: 'Add a $_selectedType title...',
          prefixIcon: Icon(icon, color: AppColors.textTertiary),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null,
      );

  Widget _emojiField() => GestureDetector(
        onTap: _pickEmoji,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border.all(color: AppColors.glassBorder),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.smile,
                color: AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _selectedEmoji ?? 'Pick an emoji (optional)',
                style: AppTextStyles.body.copyWith(
                  color: _selectedEmoji != null
                      ? AppColors.textPrimary
                      : AppColors.textQuaternary,
                  fontSize: _selectedEmoji != null ? 24 : 16,
                ),
              ),
              const Spacer(),
              Icon(
                LucideIcons.chevronDown,
                color: AppColors.textTertiary,
                size: 16,
              ),
            ],
          ),
        ),
      );

  Widget _alarmToggle() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          border: Border.all(color: AppColors.glassBorder),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              _reminderOn ? LucideIcons.bell : LucideIcons.bellOff,
              color: _reminderOn ? AppColors.emerald : AppColors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder Alarm',
                    style: AppTextStyles.bodySemiBold.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _reminderOn ? 'Alarm enabled for this habit' : 'Tap to enable alarm notifications',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _reminderOn,
              onChanged: (value) {
                setState(() {
                  _reminderOn = value;
                });
              },
              activeColor: AppColors.emerald,
              activeTrackColor: AppColors.emerald.withOpacity(0.3),
            ),
          ],
        ),
      );

  Widget _timeField() => GestureDetector(
        onTap: _selectTime,
        child: AbsorbPointer(
          child: TextFormField(
            controller: _timeController,
            style: AppTextStyles.body,
            decoration: const InputDecoration(
              prefixIcon:
                  Icon(LucideIcons.clock, color: AppColors.textTertiary),
              suffixIcon: Icon(LucideIcons.chevronDown,
                  color: AppColors.textTertiary),
            ),
          ),
        ),
      );

  Widget _dateField(String label, DateTime date, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border.all(color: AppColors.glassBorder),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Row(children: [
            const Icon(LucideIcons.calendar,
                color: AppColors.textTertiary, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Text('${date.day}/${date.month}/${date.year}',
                style: AppTextStyles.body),
          ]),
        ),
      );

  Widget _frequencySelector() => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _FrequencyChip('Daily', 'daily', _frequency, _updateFrequency),
          _FrequencyChip('Weekdays', 'weekdays', _frequency, _updateFrequency),
          _FrequencyChip('Weekends', 'weekends', _frequency, _updateFrequency),
          _FrequencyChip('Custom', 'custom', _frequency, _updateFrequency),
        ],
      );

  Widget _colorPicker() {
    final colors = [
      AppColors.emerald,
      AppColors.cyan,
      AppColors.warning,
      AppColors.purple,
      AppColors.rose
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Habit Color',
            style: AppTextStyles.captionSmall
                .copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: colors
              .map((c) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _selectedColor == c
                                ? Colors.white
                                : Colors.transparent,
                            width: 2),
                      ),
                    ),
                  ))
              .toList(),
        )
      ],
    );
  }

  Widget _commitButton() => SizedBox(
        width: double.infinity,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _submitForm,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              child: Center(
                child: Text('Commit ${_selectedType.capitalize()}',
                    style: AppTextStyles.bodySemiBold
                        .copyWith(color: Colors.black)),
              ),
            ),
          ),
        ),
      );

  // ---------------------------------------------------------
  // 🧠 MANAGE TAB (fixed + upgraded visuals)
  // ---------------------------------------------------------
  Widget _buildManageTab() {
    final habitEngine = ref.watch(habitEngineProvider);
    final filtered = habitEngine.habits
        .where((h) => h.isScheduledForDate(_selectedDate))
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.calendar,
                  size: 48, color: AppColors.textQuaternary),
              const SizedBox(height: AppSpacing.md),
              Text('No habits or tasks for this day',
                  style: AppTextStyles.bodySemiBold
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.sm),
              Text('Pick another date above or create a new one below.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => await ref.read(habitEngineProvider).loadHabits(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 
          0, 
          AppSpacing.lg, 
          150, // Extra bottom padding for breathing room
        ),
        itemCount: filtered.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildHabitCard(filtered[i]),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // 🎨 PROFESSIONAL HABIT CARD (matches reference image style)
  // ---------------------------------------------------------
  Widget _buildHabitCard(Habit habit) {
    final accent = habit.color ?? // use saved color
        (habit.type == 'habit' ? AppColors.emerald : AppColors.cyan);
    
    // Calculate progress percentage based on current streak
    final progressPercent = habit.streak > 0 ? (habit.streak % 10) / 10 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.baseDark2,
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji or icon on left
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        border: Border.all(
                          color: accent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: habit.emoji != null
                          ? Center(
                              child: Text(
                                habit.emoji!,
                                style: const TextStyle(fontSize: 32),
                              ),
                            )
                          : Icon(
                              habit.type == 'habit' 
                                  ? LucideIcons.flame 
                                  : LucideIcons.checkCircle,
                              color: accent,
                              size: 28,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Title and metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            habit.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          // Type and intensity
                          Row(
                            children: [
                              Text(
                                habit.type.toUpperCase(),
                                style: AppTextStyles.captionSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                ' • ',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              Text(
                                _getFrequencyText(habit.repeatDays),
                                style: AppTextStyles.captionSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Settings menu icon
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        ),
                        child: Icon(
                          LucideIcons.settings,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _editHabit(habit);
                        } else if (value == 'delete') {
                          _deleteHabit(habit);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(LucideIcons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(LucideIcons.trash, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Time display
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                        border: Border.all(
                          color: accent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            habit.time,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Streak indicator
                    Icon(
                      LucideIcons.flame,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.streak}d',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Progress bar at bottom
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppBorderRadius.xl),
                bottomRight: Radius.circular(AppBorderRadius.xl),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppBorderRadius.xl),
                bottomRight: Radius.circular(AppBorderRadius.xl),
              ),
              child: LinearProgressIndicator(
                value: progressPercent > 0 ? progressPercent : 0.15,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequencyText(List<int> days) {
    if (days.length == 7) return 'Daily';
    if (days.length == 5 && days.contains(1) && days.contains(5)) return 'Weekdays';
    if (days.length == 2 && days.contains(0) && days.contains(6)) return 'Weekends';
    return '${days.length} days/week';
  }

  void _editHabit(Habit h) {
    _tabController.animateTo(0);
    setState(() {
      _titleController.text = h.title;
      _timeController.text = h.time;
      _selectedType = h.type;
      _startDate = h.startDate;
      _endDate = h.endDate;
      for (int i = 0; i < 7; i++) {
        _repeatDays[i] = h.repeatDays.contains(i);
      }
    });
  }

  void _deleteHabit(Habit h) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.baseDark2,
        title: Text('Delete ${h.type.capitalize()}',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete "${h.title}"?',
            style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(habitEngineProvider.notifier).deleteHabit(h.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${h.title} deleted'),
        backgroundColor: AppColors.error.withOpacity(0.9),
      ));
    }
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final String value;
  final String currentFrequency;
  final Function(String) onSelected;

  const _FrequencyChip(
      this.label, this.value, this.currentFrequency, this.onSelected,
      {super.key});

  @override
  Widget build(BuildContext context) {
    final sel = currentFrequency == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              sel ? AppColors.emerald.withOpacity(0.2) : AppColors.glassBackground,
          border:
              Border.all(color: sel ? AppColors.emerald : AppColors.glassBorder),
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
        ),
        child: Text(label,
            style: AppTextStyles.captionSmall
                .copyWith(color: sel ? AppColors.emerald : AppColors.textTertiary)),
      ),
    );
  }
}

extension StringC on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
