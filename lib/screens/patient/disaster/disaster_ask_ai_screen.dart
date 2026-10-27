import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/disaster_provider.dart';
import '../../../services/disaster/disaster_ai_service.dart';

class DisasterAskAiScreen extends StatefulWidget {
  const DisasterAskAiScreen({super.key});

  @override
  State<DisasterAskAiScreen> createState() => _DisasterAskAiScreenState();
}

class _DisasterAskAiScreenState extends State<DisasterAskAiScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _isProcessing = false;

  final List<String> _suggestedPrompts = [
    'Is it safe to go outside right now?',
    'What should I drink for hydration?',
    'Where is the nearest verified safe shelter?',
    'My heart rate is elevated, what should I do?',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message with disclaimer
    _messages.add(
      AiChatMessage(
        sender: 'ai',
        text: 'Hello, I am your G1Care Disaster Safety Assistant.\n\n'
            'I monitor your live biometrics, ambient environment, and active disaster alerts to provide personalized safety guidance.\n\n'
            '${LocalDisasterAiService.disclaimer}',
        timestamp: DateTime.now(),
        isDisclaimer: true,
      ),
    );
  }

  Future<void> _handleSubmitted(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isProcessing) return;

    _textController.clear();
    setState(() {
      _messages.add(AiChatMessage(
        sender: 'user',
        text: query,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
    });

    _scrollToBottom();

    final disasterProvider = Provider.of<DisasterProvider>(context, listen: false);

    try {
      final response = await disasterProvider.aiService.askDisasterAssistant(
        query: query,
        health: disasterProvider.health,
        environment: disasterProvider.environment,
        disaster: disasterProvider.disaster,
        riskLevel: disasterProvider.riskLevel,
        baseline: disasterProvider.baseline,
      );

      if (mounted) {
        setState(() {
          _messages.add(AiChatMessage(
            sender: 'ai',
            text: response,
            timestamp: DateTime.now(),
          ));
          _isProcessing = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(AiChatMessage(
            sender: 'ai',
            text: 'I could not process your query at this moment. Please consult official emergency channels.',
            timestamp: DateTime.now(),
          ));
          _isProcessing = false;
        });
        _scrollToBottom();
      }
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
    final disasterProvider = Provider.of<DisasterProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask G1Care AI'),
      ),
      body: Column(
        children: [
          // Contextual Live Telemetry Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.primaryLight,
            child: Row(
              children: [
                Icon(
                  disasterProvider.disaster.type.icon,
                  color: disasterProvider.disaster.type.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Context: ${disasterProvider.disaster.type.displayName} • Risk: ${disasterProvider.riskLevel.displayName} • HR: ${disasterProvider.health.heartRate} BPM',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: disasterProvider.riskLevel.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    disasterProvider.riskLevel.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.sender == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.primary
                          : (msg.isDisclaimer ? const Color(0xFFFFF8E1) : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(2),
                        bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                      ),
                      border: Border.all(
                        color: msg.isDisclaimer ? Colors.amber.shade300 : AppColors.cardBorder,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUser ? Icons.person : Icons.smart_toy_rounded,
                              size: 14,
                              color: isUser ? Colors.white70 : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isUser ? 'You' : 'G1Care AI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isUser ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isUser ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'G1Care AI analyzing live health & disaster telemetry...',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

          // Suggested Prompts Carousel
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _suggestedPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _suggestedPrompts[index];
                return ActionChip(
                  label: Text(
                    prompt,
                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                  ),
                  backgroundColor: AppColors.background,
                  side: const BorderSide(color: AppColors.cardBorder),
                  onPressed: () => _handleSubmitted(prompt),
                );
              },
            ),
          ),

          // Input Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  // Microphone Icon button indicating future 2nd wristband hardware mic button
                  IconButton(
                    icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
                    tooltip: 'Voice Input (Future Hardware Wristband Flow)',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Voice microphone interface ready for wristband hardware pairing.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleSubmitted,
                      decoration: InputDecoration(
                        hintText: 'Ask safety or health question...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: () => _handleSubmitted(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
