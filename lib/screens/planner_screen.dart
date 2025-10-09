import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../design/tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/date_strip.dart';
import '../logic/habit_engine.dart';
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
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  String _selectedType = 'habit';
  String _frequency = 'daily'; // daily, weekdays, weekends, custom, everyN
  int _everyNDays = 2;
  
  final _titleController = TextEditingController();
  final _timeController = TextEditingController(text: '07:00');
  final _formKey = GlobalKey<FormState>();
  
  late TabController _tabController;
  
  // Repeat days (0=Sun, 1=Mon, ..., 6=Sat)
  final List<bool> _repeatDays = List.generate(7, (index) => false);
  final List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Default to weekdays for habits
    _repeatDays[1] = true; // Mon
    _repeatDays[2] = true; // Tue
    _repeatDays[3] = true; // Wed
    _repeatDays[4] = true; // Thu
    _repeatDays[5] = true; // Fri
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }
  
  void _onTypeChanged(String type) {
    setState(() {
      _selectedType = type;
      
      // Update default repeat days based on type
      if (type == 'habit') {
        // Reset to weekdays
        for (int i = 0; i < 7; i++) {
          _repeatDays[i] = i >= 1 && i <= 5; // Mon-Fri
        }
      } else {
        // Reset to today only for tasks
        for (int i = 0; i < 7; i++) {
          _repeatDays[i] = i == DateTime.now().weekday % 7;
        }
      }
    });
  }
  
  void _toggleRepeatDay(int dayIndex) {
    setState(() {
      _repeatDays[dayIndex] = !_repeatDays[dayIndex];
    });
  }
  
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.emerald,
              onSurface: AppColors.textPrimary,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.baseDark2,
              dialBackgroundColor: AppColors.baseDark3,
              hourMinuteTextColor: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }
  
  List<int> _getRepeatDays() {
    switch (_frequency) {
      case 'daily':
        return [0, 1, 2, 3, 4, 5, 6]; // All days
      case 'weekdays':
        return [1, 2, 3, 4, 5]; // Mon-Fri
      case 'weekends':
        return [0, 6]; // Sun, Sat
      case 'custom':
        final selected = <int>[];
        for (int i = 0; i < _repeatDays.length; i++) {
          if (_repeatDays[i]) selected.add(i);
        }
        return selected;
      case 'everyN':
        // For everyN, we'll use a different approach in the habit engine
        return [_startDate.weekday % 7]; // Start with the start date's weekday
      default:
        return [1, 2, 3, 4, 5]; // Default to weekdays
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final selectedRepeatDays = _getRepeatDays();
      
      if (selectedRepeatDays.isEmpty && _frequency == 'custom') {
        _showErrorSnackBar('Please select at least one day');
        return;
      }
      
      try {
        await ref.read(habitEngineProvider.notifier).createHabit(
          title: _titleController.text.trim(),
          type: _selectedType,
          time: _timeController.text,
          startDate: _startDate,
          endDate: _endDate,
          repeatDays: selectedRepeatDays,
        );
        
        // Clear form
        _titleController.clear();
        _timeController.text = '07:00';
        setState(() {
          _frequency = 'daily';
          _startDate = DateTime.now();
          _endDate = DateTime.now().add(const Duration(days: 365));
          // Reset to default weekdays for habits
          for (int i = 0; i < 7; i++) {
            _repeatDays[i] = (_selectedType == 'habit') ? (i >= 1 && i <= 5) : false;
          }
        });
        
        // Show success message
        _showSuccessSnackBar('${_selectedType.capitalize()} created successfully!');
        
        // Switch to manage tab to show the new habit
        _tabController.animateTo(1);
        
      } catch (e) {
        _showErrorSnackBar('Failed to create ${_selectedType}: $e');
      }
    }
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitEngineState = ref.watch(habitEngineProvider);
    
    return Column(
      children: [
        // Date strip
        DateStrip(
          selectedDate: _selectedDate,
          onDateSelected: _onDateSelected,
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Add New'),
              Tab(text: 'Manage'),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAddNewTab(),
              _buildManageTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAddNewTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Main form card
          GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type selector
                  Row(
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
                          child: Text(
                            'Habit',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _selectedType == 'habit'
                                  ? Colors.black
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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
                          child: Text(
                            'Task',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _selectedType == 'task'
                                  ? Colors.black
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Title field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Title',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _titleController,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: 'Add a ${_selectedType} title...',
                          prefixIcon: Icon(
                            _selectedType == 'habit' ? LucideIcons.flame : LucideIcons.alarmCheck,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Time field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _selectTime,
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _timeController,
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              hintText: 'Select time',
                              prefixIcon: Icon(
                                LucideIcons.clock,
                                color: AppColors.textTertiary,
                              ),
                              suffixIcon: Icon(
                                LucideIcons.chevronDown,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Start Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _selectStartDate(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.glassBackground,
                            border: Border.all(color: AppColors.glassBorder),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.calendar, color: AppColors.textTertiary, size: 16),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // End Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _selectEndDate(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.glassBackground,
                            border: Border.all(color: AppColors.glassBorder),
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.calendar, color: AppColors.textTertiary, size: 16),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Frequency
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frequency',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _FrequencyChip('Daily', 'daily'),
                          _FrequencyChip('Weekdays', 'weekdays'),
                          _FrequencyChip('Weekends', 'weekends'),
                          _FrequencyChip('Custom', 'custom'),
                          _FrequencyChip('Every N Days', 'everyN'),
                        ],
                      ),
                    ],
                  ),
                  
                  if (_frequency == 'everyN') ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Text('Every', style: AppTextStyles.body),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 60,
                          child: TextFormField(
                            initialValue: _everyNDays.toString(),
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.body,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            onChanged: (value) {
                              _everyNDays = int.tryParse(value) ?? 2;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('days', style: AppTextStyles.body),
                      ],
                    ),
                  ],
                  
                  if (_frequency == 'custom') ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: List.generate(7, (index) {
                        final isSelected = _repeatDays[index];
                        return GlassButton(
                          onPressed: () => _toggleRepeatDay(index),
                          width: 40,
                          height: 40,
                          backgroundColor: isSelected
                              ? AppColors.emerald.withOpacity(0.2)
                              : AppColors.glassBackground,
                          borderColor: isSelected
                              ? AppColors.emerald
                              : AppColors.glassBorder,
                          child: Text(
                            _dayNames[index],
                            style: AppTextStyles.captionSmall.copyWith(
                              color: isSelected
                                  ? AppColors.emerald
                                  : AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final habitEngineState = ref.watch(habitEngineProvider);
                        return Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: habitEngineState.isLoading ? null : _submitForm,
                              borderRadius: BorderRadius.circular(AppBorderRadius.md),
                              child: Center(
                                child: habitEngineState.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                      )
                                    : Text(
                                        'Commit ${_selectedType.capitalize()}',
                                        style: AppTextStyles.bodySemiBold.copyWith(
                                          color: Colors.black,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom padding for navigation
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  Widget _buildManageTab() {
    final habitEngineState = ref.watch(habitEngineProvider);
    final allHabits = habitEngineState.habits;
    
    if (allHabits.isEmpty) {
      return Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.calendar,
                size: 48,
                color: AppColors.textQuaternary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No habits or tasks yet',
                style: AppTextStyles.bodySemiBold.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Create your first habit or task in the "Add New" tab.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        // Force reload habits from storage
        await ref.read(habitEngineProvider.notifier).reloadHabits();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: allHabits.length,
        itemBuilder: (context, index) {
          final habit = allHabits[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildHabitManageCard(habit),
          );
        },
      ),
    );
  }
  
  Widget _buildHabitManageCard(Habit habit) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.glassBackground,
            AppColors.glassBackground.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: habit.type == 'habit' 
              ? AppColors.emerald.withOpacity(0.3)
              : AppColors.cyan.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (habit.type == 'habit' ? AppColors.emerald : AppColors.cyan).withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: habit.type == 'habit' 
                      ? AppColors.emerald.withOpacity(0.2)
                      : AppColors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  border: Border.all(
                    color: habit.type == 'habit' 
                        ? AppColors.emerald.withOpacity(0.5)
                        : AppColors.cyan.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  habit.type.toUpperCase(),
                  style: AppTextStyles.captionSmall.copyWith(
                    color: habit.type == 'habit' ? AppColors.emerald : AppColors.cyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 16),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editHabit(habit);
                  } else if (value == 'delete') {
                    _deleteHabit(habit);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(LucideIcons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          Text(
            habit.title,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          Row(
            children: [
              Icon(
                LucideIcons.clock,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                habit.time,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                LucideIcons.calendar,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                _getFrequencyText(habit.repeatDays),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          Row(
            children: [
              Text(
                'Streak: ${habit.streak} days',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Created: ${habit.startDate.day}/${habit.startDate.month}/${habit.startDate.year}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getFrequencyText(List<int> repeatDays) {
    if (repeatDays.length == 7) return 'Daily';
    if (repeatDays.length == 5 && 
        repeatDays.contains(1) && repeatDays.contains(2) && 
        repeatDays.contains(3) && repeatDays.contains(4) && 
        repeatDays.contains(5)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 && 
        repeatDays.contains(0) && repeatDays.contains(6)) {
      return 'Weekends';
    }
    return '${repeatDays.length} days/week';
  }
  
  void _editHabit(Habit habit) {
    // Switch to Add New tab and populate form
    _tabController.animateTo(0);
    setState(() {
      _titleController.text = habit.title;
      _timeController.text = habit.time;
      _selectedType = habit.type;
      _startDate = habit.startDate;
      _endDate = habit.endDate;
      
      // Set repeat days
      for (int i = 0; i < 7; i++) {
        _repeatDays[i] = habit.repeatDays.contains(i);
      }
      
      // Set frequency based on repeat days
      if (habit.repeatDays.length == 7) {
        _frequency = 'daily';
      } else if (habit.repeatDays.length == 5 && 
                 habit.repeatDays.contains(1) && habit.repeatDays.contains(5)) {
        _frequency = 'weekdays';
      } else if (habit.repeatDays.length == 2 && 
                 habit.repeatDays.contains(0) && habit.repeatDays.contains(6)) {
        _frequency = 'weekends';
      } else {
        _frequency = 'custom';
      }
    });
  }
  
  void _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.baseDark2,
        title: Text(
          'Delete ${habit.type.capitalize()}',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${habit.title}"? This action cannot be undone.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: AppTextStyles.body.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await ref.read(habitEngineProvider.notifier).deleteHabit(habit.id);
        _showSuccessSnackBar('${habit.type.capitalize()} deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete ${habit.type}: $e');
      }
    }
  }

  Widget _FrequencyChip(String label, String value) {
    final isSelected = _frequency == value;
    return GestureDetector(
      onTap: () => setState(() => _frequency = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald.withOpacity(0.2) : AppColors.glassBackground,
          border: Border.all(
            color: isSelected ? AppColors.emerald : AppColors.glassBorder,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionSmall.copyWith(
            color: isSelected ? AppColors.emerald : AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
