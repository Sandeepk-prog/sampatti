import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SupportQueryDetailsScreen extends StatelessWidget {
  final String ticketId;
  final bool isClosed;

  const SupportQueryDetailsScreen({
    super.key,
    this.ticketId = 'TKT-770',
    this.isClosed = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    _buildChatBubble(
                      sender: 'Admin',
                      message: 'Hello! How can we help you today with your SIP inquiry?',
                      timestamp: '22 Jan 26, 10:00 AM',
                      context: context
                    ),
                    _buildChatBubble(
                      sender: 'Customer',
                      message: 'My monthly SIP for Mutual Funds was not auto-debited today.',
                      timestamp: '22 Jan 26, 10:15 AM',
                      context: context
                    ),
                    _buildChatBubble(
                      sender: 'Admin',
                      message: 'Thank you for bringing this to our attention. We\'ve identified the issue and it will be resolved by EOD.',
                      timestamp: '22 Jan 26, 11:30 AM',
                      context: context
                    ),
                    _buildChatBubble(
                      sender: 'Admin',
                      message: 'The issue has been resolved. Your SIP will be processed by tomorrow morning.',
                      timestamp: '23 Jan 26, 09:00 AM',
                      context: context
                    ),
                  ],
                ),
              ),
              _buildBottomSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_ios_new, size: 18, color: theme.colorScheme.onSurface),
            ),
          ),
          Row(
            children: [
              Text(
                'Ticket No: $ticketId',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isClosed ? theme.colorScheme.primary : const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isClosed ? 'Closed' : 'Open',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble({required String sender, required String message, required String timestamp,required BuildContext context}) {
    final theme = Theme.of(context);
    bool isAdmin = sender == 'Admin';
    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAdmin ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isAdmin ? Radius.zero : const Radius.circular(12),
            bottomRight: isAdmin ? const Radius.circular(12) : Radius.zero,
          ),
          border: isAdmin ? null : Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isAdmin ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timestamp,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    final theme = Theme.of(context);
    if (isClosed) {
      return Column(
        children: [
          Divider(height: 1, thickness: 1, color: theme.dividerColor.withOpacity(0.1)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              'The ticket has been closed',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(LucideIcons.paperclip, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Transform.rotate(
              angle: -0.5,
              child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
            ),
          )],
      ),
    );
  }
}
