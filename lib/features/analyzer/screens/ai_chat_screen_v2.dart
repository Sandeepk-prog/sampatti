import 'package:finsight/features/analyzer/models/chat_models.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart' hide ChatMessage;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../services/llm_chat_service.dart';
import '../../profile/providers/ai_configuration_provider.dart';
import '../../../core/utils/ai_config_helper.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../genui/chat_catalog.dart';

class AiChatScreenV2 extends StatefulWidget {
  const AiChatScreenV2({super.key});

  @override
  State<AiChatScreenV2> createState() => _AiChatScreenV2State();
}

class _AiChatScreenV2State extends State<AiChatScreenV2> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  // GenUI Controller
  late final SurfaceController _surfaceController;

  @override
  void initState() {
    super.initState();
    _surfaceController = SurfaceController(catalogs: [chatCatalog]);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async  {
      await Provider.of<AIConfigurationProvider>(context, listen: false).loadStoredKeys();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _surfaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final aiConfig = context.watch<AIConfigurationProvider>();
    final isConfigured = aiConfig.isAnyProviderConfigured;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: !isConfigured
                ? _buildConfigRequiredState()
                : chatProvider.messages.length <= 1 && !chatProvider.isLoading
                    ? _buildHeroSection(chatProvider)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                        itemCount: chatProvider.messages.length + (chatProvider.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatProvider.messages.length) {
                            return const _TypingIndicator();
                          }
                          return _ChatBubble(
                            message: chatProvider.messages[index],
                            controller: _surfaceController,
                          );
                        },
                      ),
          ),
          if (isConfigured) _buildInputArea(chatProvider),
        ],
      ),
    );
  }

  Widget _buildConfigRequiredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.sparkles,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'AI Key Required',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To start chatting with Sampatti AI, please configure your Gemini or OpenAI API key in the settings.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => AIConfigHelper.showAIConfigGuidance(context),
              icon: const Icon(LucideIcons.settings2, size: 18),
              label: const Text('Configure Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(ChatProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.primary, Color(0xFFEC4899)],
            ).createShader(bounds),
            child: Text(
              'Hello,\nhow can I help?',
              style: GoogleFonts.inter(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Ask me anything about your balance, transaction history, or bank policies.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 48),
          if (provider.suggestedActions.isNotEmpty) ...[
            Text(
              'SUGGESTED FOR YOU',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary.withOpacity(0.5),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: provider.suggestedActions.map((action) => _buildActionChip(action, provider)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, ChatProvider provider) {
    return InkWell(
      onTap: () => _handleActionClick(label, provider),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 14),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.3))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 5,
                      minLines: 1,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask Sampatti AI...',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14,horizontal: 6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _handleSend(provider),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sendHorizontal, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSend(ChatProvider provider) {
    if (_controller.text.trim().isEmpty) return;
    final text = _controller.text;
    _controller.clear();
    _focusNode.unfocus();
    provider.sendMessage(text).then((_) => _scrollToBottom());
  }

  void _handleActionClick(String action, ChatProvider provider) {
    provider.sendMessage(action).then((_) => _scrollToBottom());
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final SurfaceController controller;
  
  const _ChatBubble({required this.message, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isAI = !message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bot, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isAI ? const Color(0xFFF1F5F9) : AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isAI ? 4 : 20),
                  bottomRight: Radius.circular(isAI ? 20 : 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormattedText(
                    text: message.text,
                    style: GoogleFonts.inter(
                      color: isAI ? AppColors.textPrimary : Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isAI && message.widgetData != null) ...[
                    const SizedBox(height: 12),
                    _GenUiRenderer(
                      message: message,
                      controller: controller,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isAI) ...[
            const SizedBox(width: 12),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.user, color: AppColors.textSecondary, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _GenUiRenderer extends StatefulWidget {
  final ChatMessage message;
  final SurfaceController controller;

  const _GenUiRenderer({required this.message, required this.controller});

  @override
  State<_GenUiRenderer> createState() => _GenUiRendererState();
}

class _GenUiRendererState extends State<_GenUiRenderer> {
  @override
  void initState() {
    super.initState();
    _initializeSurface();
  }

  void _initializeSurface() async {
    final widgetName = widget.message.widgetData!['widget'];
    final data = widget.message.widgetData!['data'];
    final surfaceId = widget.message.id;
    
    try {
      print('Initializing surface for widget: $widgetName');
      
      // 1. Create the surface
      widget.controller.handleMessage(
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': surfaceId,
            'catalogId': 'default',
          }
        })
      );
      //await Future.delayed(const Duration(milliseconds: 100));

      // 2. Update data model (state)
      widget.controller.handleMessage(
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'updateDataModel': {
            'surfaceId': surfaceId,
            'data': data,
          }
        })
      );
      //await Future.delayed(const Duration(milliseconds: 100));

      // 3. Set the root component
      widget.controller.handleMessage(
        A2uiMessage.fromJson({
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': surfaceId,
            'components': [
              {
                'id': 'root',
                'component': widgetName,
                'props': data,
              }
            ]
          }
        })
      );
    } catch (e) {
      print('Error initializing GenUI surface: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final context =
    widget.controller.contextFor(widget.message.id);
    final ctx = widget.controller.contextFor(widget.message.id);
    print("Context:" '${ctx}');

    return Surface(
      key: Key(widget.message.id),
      surfaceContext: widget.controller.contextFor(widget.message.id),
    );
  }
}


class _FormattedText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _FormattedText({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    final spans = <TextSpan>[];

    for (var i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        spans.add(TextSpan(
          text: parts[i],
          style: style.copyWith(fontWeight: FontWeight.w900, color: style.color),
        ));
      } else {
        spans.add(TextSpan(text: parts[i], style: style));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.bot, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final value = (0.5 + 0.5 * (1.0 - ((_controller.value + delay) % 1.0))).clamp(0.0, 1.0);
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(value),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
