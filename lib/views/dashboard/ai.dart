import 'dart:convert';
import 'dart:async'; // Add this import for Timer
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fleet/info_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';

class ChatMessage {
  final bool isUser;
  final String text;
  final DateTime? timestamp;

  ChatMessage({
    required this.isUser,
    required this.text,
    this.timestamp,
  });
}

// Completely redesigned AI Chat Button
class AIChatButton extends StatefulWidget {
  const AIChatButton({Key? key}) : super(key: key);

  @override
  State<AIChatButton> createState() => _AIChatButtonState();
}

class _AIChatButtonState extends State<AIChatButton> with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovering = false;
  bool _showPrompt = false; // Track prompt visibility
  Timer? _promptTimer; // Timer for showing/hiding the prompt

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start the timer to show/hide the prompt every 5 seconds
    _startPromptTimer();
  }

  void _startPromptTimer() {
    _promptTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _showPrompt = !_showPrompt;
        });
        
        // Auto-hide prompt after 3 seconds if it's showing
        if (_showPrompt) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showPrompt = false;
              });
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    _promptTimer?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showChatOverlay(BuildContext context) {
    _removeOverlay();

    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    // Responsive sizing for different devices
    final double chatWidth = isMobile 
        ? screenSize.width * 0.95  // Almost full width on mobile
        : (screenSize.width < 900 ? screenSize.width * 0.7 : 400); // Adaptive width for tablets
    
    final double chatHeight = isMobile 
        ? screenSize.height * 0.8  // Taller on mobile
        : screenSize.height * 0.7;

    // Responsive positioning
    final double rightPosition = isMobile ? 10 : 20;
    final double bottomPosition = isMobile ? 70 : 80;

    // Create the overlay entry with responsive positioning
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        right: rightPosition,
        bottom: bottomPosition,
        width: chatWidth,
        height: chatHeight,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: ChatBubble(
              onClose: _removeOverlay,
              child: const AskAIPage(),
            ),
          ),
        ),
      ),
    );

    // Add to overlay
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    return Stack(
      children: [
        // The speech bubble prompt
        if (_showPrompt)
          Positioned(
            right: isMobile ? 60 : 70, // Adjust based on device
            bottom: isMobile ? 18 : 23, // Adjust based on device
            child: _buildSpeechBubble(context),
          ),
        
        // The FAB button
        CompositedTransformTarget(
          link: _layerLink,
          child: MouseRegion(
            onEnter: (_) {
              setState(() {
                _isHovering = true;
                _showPrompt = true; // Also show prompt when hovering
              });
              _animationController.forward();
              
              // Hide the prompt after 3 seconds
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && _isHovering) {
                  setState(() {
                    _showPrompt = false;
                  });
                }
              });
            },
            onExit: (_) {
              setState(() => _isHovering = false);
              _animationController.reverse();
            },
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FloatingActionButton(
                heroTag: 'aiChatButton',
                onPressed: () {
                  setState(() => _showPrompt = false); // Hide prompt when clicked
                  _showChatOverlay(context);
                },
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 6,
                hoverElevation: 10,
                highlightElevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                  side: _isHovering 
                    ? BorderSide(color: Colors.white.withOpacity(0.3), width: 2)
                    : BorderSide.none,
                ),
                child: Icon(
                  Icons.support_agent, 
                  color: Colors.white, 
                  size: isMobile ? 24 : 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // New method to build the speech bubble
  Widget _buildSpeechBubble(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final double maxWidth = isMobile ? 150 : 200;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.centerRight,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16, 
          vertical: isMobile ? 8 : 12
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Theme.of(context).primaryColor,
              size: isMobile ? 16 : 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                tr('ai_chat_help_prompt'),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  

// Simplified Chat Bubble widget with responsive improvements
class ChatBubble extends StatefulWidget {
  final Widget child;
  final VoidCallback onClose;

  const ChatBubble({
    Key? key,
    required this.child,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    return ScaleTransition(
      scale: _animation,
      alignment: Alignment.bottomRight,
      child: Card(
        elevation: isMobile ? 4 : 8, // Less elevation on mobile
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    return Container(
      color: Theme.of(context).primaryColor,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16, 
        vertical: isMobile ? 8 : 12
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 4 : 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isMobile ? 4 : 6),
            ),
            child: Icon(
              Icons.support_agent, 
              color: Colors.white, 
              size: isMobile ? 16 : 18
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Text(
            tr('ask_ai_appbar_title'),
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: isMobile ? 20 : 24),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero, // Reduce padding on mobile
            constraints: BoxConstraints(minWidth: isMobile ? 32 : 40, minHeight: isMobile ? 32 : 40),
            onPressed: () {
              _animationController.reverse().then((_) => widget.onClose());
            },
          ),
        ],
      ),
    );
  }
}

class AskAIPage extends StatefulWidget {
  const AskAIPage({Key? key}) : super(key: key);

  @override
  _AskAIPageState createState() => _AskAIPageState();
}

class _AskAIPageState extends State<AskAIPage> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  int membershipStatus = 1;
  int dailyQuestionCount = 0;
  String userLanguage = 'en'; // Default language is English
  
  // Define quota constants based on membership status
  static const int STARTER_QUOTA = 5;
  static const int PREMIUM_QUOTA = 20;
  static const int MAX_RESPONSE_TOKENS = 500;

  String? infoCardMessage;
  String? infoCardTitle;
  Color infoCardColor = Colors.green;
  IconData infoCardIcon = Icons.check_circle;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      // Handle different types of membershipStatus
      var membershipData = userDoc.data()?['membershipStatus'];
      int membershipValue = 1; // Default value

      if (membershipData is int) {
        membershipValue = membershipData;
      } else if (membershipData is String) {
        // Try to parse string to int, use default if fails
        membershipValue = int.tryParse(membershipData) ?? 1;
      }

      setState(() {
        membershipStatus = membershipValue;
        dailyQuestionCount = userDoc.data()?['dailyQuestionCount'] ?? 0;

        // Get user language code
        userLanguage = userDoc.data()?['language'] ?? 'en';
      });
    }
  }

  Future<void> _incrementDailyQuestionCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final today = DateTime.now();
    final formattedDate = "${today.year}-${today.month}-${today.day}";
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'dailyQuestionCount': FieldValue.increment(1),
      'lastQuestionDate': formattedDate,
    });
  }

  Future<void> _resetDailyQuestionCountIfNeeded() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final today = DateTime.now();
    final formattedDate = "${today.year}-${today.month}-${today.day}";
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final lastQuestionDate = userDoc.data()?['lastQuestionDate'];
    if (lastQuestionDate != formattedDate) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'dailyQuestionCount': 0,
        'lastQuestionDate': formattedDate,
      });
      setState(() {
        dailyQuestionCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  void _showInfoCard(String title, String message, Color color, IconData icon) {
    // Show the info card using the static method
    InfoCard.showInfoCard(
      context,
      message,
      color,
      icon: icon,
    );

    // Store the message details for reference
    setState(() {
      infoCardTitle = title;
      infoCardMessage = message;
      infoCardColor = color;
      infoCardIcon = icon;
    });

    // Clear the message after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          infoCardMessage = null;
        });
      }
    });
  }

  // Get maximum questions allowed based on membership status
  int get _maxQuestionsAllowed {
    return membershipStatus == 0 ? PREMIUM_QUOTA : STARTER_QUOTA;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.grey[50];

    return Material(
      color: backgroundColor,
      child: Column(
        children: [
          // Stats-like card
          _buildQuotaInfoCard(),
          
          // Chat messages - Expanded to take available space
          Expanded(
            child: _buildChatList(),
          ),
          
          // Input area - Keep this at the bottom
          _buildMessageInput(),
        ],
      ),
    );
  }

  // New method to show the user's question quota in a dashboard-style card
  Widget _buildQuotaInfoCard() {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16, 
        vertical: isMobile ? 6 : 8
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
            ),
            child: Icon(
              membershipStatus == 0 ? Icons.workspace_premium : Icons.analytics,
              color: Theme.of(context).primaryColor,
              size: isMobile ? 16 : 20,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('ask_ai_available_questions'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
                const SizedBox(height: 3),
                // Linear progress indicator for quota
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: dailyQuestionCount / _maxQuestionsAllowed,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      dailyQuestionCount >= _maxQuestionsAllowed ? Colors.red : Theme.of(context).primaryColor
                    ),
                    minHeight: isMobile ? 4 : 6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_maxQuestionsAllowed - dailyQuestionCount} ${tr('ask_ai_questions_left')}',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    if (userId == null) {
      return _buildEmptyState(tr('ask_ai_no_sign_in'), Icons.login);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('questions')
          .orderBy('questionTimestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(tr('ask_ai_no_questions_yet'), Icons.chat_bubble_outline);
        }
        
        final messages = snapshot.data!.docs;
        List<ChatMessage> chatMessages = [];
        
        // Process messages...
        for (var message in messages) {
          chatMessages.add(ChatMessage(
            isUser: true,
            text: message['question'],
            timestamp: (message['questionTimestamp'] as Timestamp?)?.toDate(),
          ));
          
          if (message['answer'] != null) {
            chatMessages.add(ChatMessage(
              isUser: false,
              text: message['answer'],
              timestamp: (message['answerTimestamp'] as Timestamp?)?.toDate(),
            ));
          } else {
            chatMessages.add(ChatMessage(
              isUser: false,
              text: tr('ask_ai_waiting_answer'),
              timestamp: null,
            ));
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16, 
            vertical: isMobile ? 8 : 12
          ),
          reverse: true,
          itemCount: chatMessages.length,
          itemBuilder: (context, index) {
            final chatMessage = chatMessages[chatMessages.length - 1 - index];
            return _buildMessageBubble(chatMessage);
          },
        );
      },
    );
  }

  // Empty state widget styled like dashboard empty states
  Widget _buildEmptyState(String message, IconData icon) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isMobile ? 48 : 64, color: Colors.grey[400]),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              message,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage chatMessage) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    // Use colors that match the dashboard theme
    final userBubbleColor = Theme.of(context).primaryColor.withOpacity(0.1);
    final aiBubbleColor = Colors.white;
    final time = chatMessage.timestamp != null
        ? "${chatMessage.timestamp!.hour.toString().padLeft(2, '0')}:${chatMessage.timestamp!.minute.toString().padLeft(2, '0')}"
        : '';

    BorderRadius bubbleBorderRadius(bool isFromAI) {
      return BorderRadius.only(
        topLeft: Radius.circular(isFromAI ? 0 : (isMobile ? 12 : 16)),
        topRight: Radius.circular(isFromAI ? (isMobile ? 12 : 16) : 0),
        bottomLeft: Radius.circular(isMobile ? 12 : 16),
        bottomRight: Radius.circular(isMobile ? 12 : 16),
      );
    }

    final isFromAI = !chatMessage.isUser;
    final horizontalPadding = isMobile ? 12.0 : 16.0;
    final verticalPadding = isMobile ? 8.0 : 12.0;
    final iconSize = isMobile ? 14.0 : 16.0;
    final fontSize = isMobile ? 14.0 : 15.0;
    final timeSize = isMobile ? 9.0 : 11.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
      child: Row(
        mainAxisAlignment:
            chatMessage.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isFromAI)
            Container(
              margin: EdgeInsets.only(right: 8, bottom: isMobile ? 2 : 4),
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent, color: Colors.white, size: iconSize),
            ),
          
          Flexible(
            child: Column(
              crossAxisAlignment: chatMessage.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Message bubble with shadow like dashboard cards
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, 
                    vertical: verticalPadding
                  ),
                  decoration: BoxDecoration(
                    color: chatMessage.isUser ? userBubbleColor : aiBubbleColor,
                    borderRadius: bubbleBorderRadius(isFromAI),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: chatMessage.text == tr('ask_ai_waiting_answer')
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: isMobile ? 14 : 16,
                              height: isMobile ? 14 : 16,
                              child: CircularProgressIndicator(
                                color: Theme.of(context).primaryColor,
                                strokeWidth: isMobile ? 1.5 : 2,
                              ),
                            ),
                            SizedBox(width: isMobile ? 8 : 12),
                            Text(
                              tr('ask_ai_waiting_answer'),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                                fontSize: fontSize - 1,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          chatMessage.text,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: fontSize,
                          ),
                        ),
                ),
                
                if (time.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: isMobile ? 2 : 4, 
                      left: isMobile ? 2 : 4, 
                      right: isMobile ? 2 : 4
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: timeSize,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final primaryColor = Theme.of(context).primaryColor;
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              style: TextStyle(fontSize: isMobile ? 14 : 16),
              decoration: InputDecoration(
                hintText: tr('ask_ai_message_placeholder'),
                hintStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 8 : 10,
                ),
                isDense: isMobile, // More compact on mobile
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty && !_isSending) {
                  _askQuestion();
                }
              },
            ),
          ),
          SizedBox(width: isMobile ? 6 : 8),
          Material(
            color: primaryColor,
            borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
            child: InkWell(
              onTap: _isSending ? null : _askQuestion,
              borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
              child: Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                child: _isSending
                  ? SizedBox(
                      width: isMobile ? 20 : 24,
                      height: isMobile ? 20 : 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: isMobile ? 1.5 : 2,
                      ),
                    )
                  : Icon(Icons.send, color: Colors.white, size: isMobile ? 20 : 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modify _askQuestion to properly check for empty input and quota limits
  void _askQuestion() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final questionText = _questionController.text.trim();
    
    if (userId == null || questionText.isEmpty) {
      _showInfoCard(
        tr('ask_ai_error_title'),
        tr('ask_ai_please_login_and_ask'),
        Colors.orange,
        Icons.warning,
      );
      return;
    }

    await _resetDailyQuestionCountIfNeeded();

    // Use the new maxQuestionsAllowed property for limit checking
    if (dailyQuestionCount >= _maxQuestionsAllowed) {
      _showInfoCard(
        tr('ask_ai_quota_finished_title'),
        membershipStatus == 0 
            ? tr('ask_ai_premium_quota_finished_message') 
            : tr('ask_ai_quota_finished_message'),
        Colors.red,
        Icons.info,
      );
      return;
    }

    setState(() {
      _isSending = true;
    });
    try {
      final questionTimestamp = DateTime.now();
      DocumentReference questionRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('questions')
          .add({
        'question': questionText,
        'questionTimestamp': questionTimestamp,
        'answer': tr('ask_ai_waiting_answer'),
        'answerTimestamp': null,
      });
      _questionController.clear();
      _scrollToBottom();

      final answer = await _getAIResponse(questionText);
      if (answer != null) {
        await questionRef.update({
          'answer': answer,
          'answerTimestamp': DateTime.now(),
        });
      } else {
        await questionRef.update({
          'answer': tr('ask_ai_no_answer_received'),
          'answerTimestamp': DateTime.now(),
        });
      }
      await _incrementDailyQuestionCount();
      setState(() {
        dailyQuestionCount += 1;
      });
    } catch (e) {
      debugPrint('Hata: $e');
      _showInfoCard(
        tr('ask_ai_error_title'),
        "${tr('ask_ai_send_error')} $e",
        Colors.red,
        Icons.error,
      );
    } finally {
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    }
  }

  Future<String?> _getAIResponse(String question) async {
    // Check if dotenv is loaded and get the API key
    String? apiKey;
    try {
      // Make sure dotenv is loaded before accessing environment variables
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: ".env");
      }
      
      apiKey = dotenv.env['OPENAI_API_KEY'];
      
      // Check if API key is null or empty
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('API anahtarı bulunamadı: OPENAI_API_KEY');
        _showInfoCard(
          tr('ask_ai_error_title'),
          tr('ask_ai_api_key_missing'),
          Colors.red,
          Icons.error,
        );
        return tr('ask_ai_api_key_missing_response');
      }
    } catch (e) {
      // Handle dotenv initialization error
      debugPrint('DotEnv hatası: $e');
      try {
        // Try loading from alternative location
        await dotenv.load(fileName: "assets/.env");
        apiKey = dotenv.env['OPENAI_API_KEY'];
        
        if (apiKey == null || apiKey.isEmpty) {
          _showInfoCard(
            tr('ask_ai_error_title'),
            tr('ask_ai_api_key_missing'),
            Colors.red,
            Icons.error,
          );
          return tr('ask_ai_api_key_missing_response');
        }
      } catch (secondError) {
        _showInfoCard(
          tr('ask_ai_error_title'),
          "${tr('ask_ai_env_error')} $secondError",
          Colors.red,
          Icons.error,
        );
        return tr('ask_ai_system_error_response');
      }
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
                'role': 'system',
                'content': '''
        You are an HR assistant named GOYA HR Assistant. Your only job is to help users with human resources processes, policies, and best practices. You support topics such as:

        - Recruitment and onboarding
        - Leave and absence management
        - Performance evaluation
        - Payroll and compensation
        - Employee relations and communication
        - HR compliance and documentation
        - Training and development

        Your responsibilities:
        - Answer questions about HR concepts, procedures, and legal requirements
        - Guide users on how to use HR features in the GOYA HR application
        - Provide step-by-step instructions for HR tasks (e.g., requesting leave, submitting documents, tracking attendance)
        - Suggest best practices for HR management
        - Keep answers clear, concise, and under 500 characters when possible

        If you cannot answer or the issue is technical, advise the user to contact HR support at info@goyaapp.com.

        Always respond only in ${userLanguage}, regardless of the question's language.
        '''
              },
              {'role': 'user', 'content': question},
            ],
            'max_tokens': MAX_RESPONSE_TOKENS,
            'temperature': 0.7,
          }),
        );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        String aiResponse = responseBody['choices'][0]['message']['content'];
        try {
          aiResponse = utf8.decode(latin1.encode(aiResponse));
        } catch (e) {
          debugPrint('Encoding correction failed: $e');
        }
        return aiResponse;
      } else {
        debugPrint('OpenAI API Hatası: ${response.body}');
        _showInfoCard(
          tr('ask_ai_error'),
          "${tr('openai_error')} ${response.statusCode}",
          Colors.red,
          Icons.error,
        );
      }
    } catch (e) {
      debugPrint('OpenAI API isteği başarısız: $e');
      _showInfoCard(
        tr('ask_ai_error_title'),
        "OpenAI API ${tr('ask_ai.send_error')} $e",
        Colors.red,
        Icons.error,
      );
    }
    return null;
  }
}
