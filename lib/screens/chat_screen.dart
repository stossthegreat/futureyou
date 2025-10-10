import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../design/tokens.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import '../widgets/date_strip.dart';
import '../providers/habit_provider.dart';
import '../services/api_client.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      role: 'future',
      text: "I'm Future You. Tell me who you want to be and by when. I'll turn it into daily commitments.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];
  
  List<QuickCommit> _quickCommits = [];
  bool _isLoading = false;
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: message,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _messageController.clear();
    });
    
    _scrollToBottom();
    
    // Generate AI response (mock for now)
    await Future.delayed(const Duration(seconds: 1));
    
    final futureResponse = _generateFutureYouResponse(message);
    final responseMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'future',
      text: futureResponse.message,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(responseMessage);
      _quickCommits = futureResponse.quickCommits ?? [];
      _isLoading = false;
    });
    
    _scrollToBottom();
    
    // TODO: Replace with actual API call
    // final response = await ApiClient.sendChatMessage(message);
  }
  
  ChatResponse _generateFutureYouResponse(String userMessage) {
    final title = userMessage.replaceAll(RegExp(r'by .*', caseSensitive: false), '').trim();
    final cleanTitle = title.length > 60 ? title.substring(0, 60) : title;
    
    final quickCommits = [
      QuickCommit(
        label: 'Add Habit (Weekdays 7:00)',
        type: 'habit',
        title: cleanTitle.isNotEmpty ? cleanTitle : 'New Habit',
        time: '07:00',
      ),
      QuickCommit(
        label: 'Add Habit (Daily 6:00)',
        type: 'habit',
        title: cleanTitle.isNotEmpty ? cleanTitle : 'New Habit',
        time: '06:00',
      ),
      QuickCommit(
        label: 'Add Task (Today 9:00)',
        type: 'task',
        title: cleanTitle.isNotEmpty ? cleanTitle : 'New Task',
        time: '09:00',
      ),
    ];
    
    return ChatResponse(
      message: "Locked on. I queued quick-commit options for ${DateFormat('MMM d').format(_selectedDate)}. Tap one to make it real.",
      quickCommits: quickCommits,
    );
  }
  
  Future<void> _handleQuickCommit(QuickCommit commit) async {
    try {
      await ref.read(habitEngineProvider).createHabit(
        title: commit.title,
        type: commit.type,
        time: commit.time,
        startDate: _selectedDate,
        repeatDays: commit.type == 'habit' ? [1, 2, 3, 4, 5] : [_selectedDate.weekday % 7],
      );
      
      // Add confirmation message
      final confirmationMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'future',
        text: "✅ Perfect! I've locked in '${commit.title}' at ${commit.time}. Your future self is already thanking you.",
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(confirmationMessage);
        _quickCommits.clear();
      });
      
      _scrollToBottom();
      
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create ${commit.type}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date strip
        DateStrip(
          selectedDate: _selectedDate,
          onDateSelected: _onDateSelected,
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Chat messages
        Expanded(
          child: GlassCard(
            height: 420,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.glassBackground,
                            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.emerald,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Future You is thinking...',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Quick commits
        if (_quickCommits.isNotEmpty) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Commit',
                style: AppTextStyles.captionSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _quickCommits.map<Widget>((commit) {
                  return GlassButton(
                    onPressed: () => _handleQuickCommit(commit),
                    backgroundColor: AppColors.emerald.withOpacity(0.15),
                    borderColor: AppColors.emerald.withOpacity(0.3),
                    child: Text(
                      commit.label,
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        
        // Input field
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _messageController,
                style: AppTextStyles.body,
                decoration: const InputDecoration(
                  hintText: 'Tell Future You your goal…',
                ),
                onFieldSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GlassButton(
              onPressed: _sendMessage,
              gradient: AppColors.primaryGradient,
              width: 48,
              height: 48,
              child: const Icon(
                LucideIcons.send,
                size: 20,
                color: Colors.black,
              ),
            ),
          ],
        ),
        
        // Bottom padding for navigation
        const SizedBox(height: 100),
      ],
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.sparkles,
                size: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.emerald.withOpacity(0.2)
                    : AppColors.glassBackground,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(
                  color: isUser
                      ? AppColors.emerald.withOpacity(0.3)
                      : AppColors.glassBorder,
                ),
              ),
              child: Text(
                message.text,
                style: AppTextStyles.body.copyWith(
                  color: isUser
                      ? AppColors.emerald
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.glassBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(
                LucideIcons.user,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
