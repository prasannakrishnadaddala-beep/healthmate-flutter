import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _sending = false;

  static const _chips = [
    'How are my vitals today?',
    'Give me healthy eating tips',
    'Did I take all my meds?',
    'Any appointment reminders?',
    'Suggest a meal for dinner',
  ];

  @override
  void initState() { super.initState(); _loadHistory(); }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final hist = await ApiService.getChatHistory();
      if (mounted) setState(() {
        _messages = hist.map((h) => Map<String, dynamic>.from(h as Map)).toList();
        _loading = false;
      });
      _scrollDown();
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _send([String? quick]) async {
    final msg = (quick ?? _ctrl.text).trim();
    if (msg.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': msg, 'timestamp': DateTime.now().toIso8601String()});
      _sending = true;
    });
    _scrollDown();
    try {
      final r = await ApiService.chat(msg);
      if (mounted) setState(() {
        _messages.add({'role': 'assistant', 'content': r['reply'] ?? '', 'timestamp': DateTime.now().toIso8601String()});
        _sending = false;
      });
      _scrollDown();
    } catch (e) {
      if (mounted) setState(() {
        _messages.add({'role': 'assistant', 'content': '⚠️ ${e.toString()}', 'timestamp': DateTime.now().toIso8601String()});
        _sending = false;
      });
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _clearChat() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: HMColors.surface,
        title: const Text('Clear Chat?', style: TextStyle(color: HMColors.text)),
        content: const Text('All chat history will be deleted.',
            style: TextStyle(color: HMColors.text2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: HMColors.text3))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear', style: TextStyle(color: HMColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      await ApiService.clearChat();
      if (mounted) setState(() => _messages.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HMColors.bg,
      appBar: AppBar(
        title: const Row(children: [
          Text('🤖', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text('AI Health Chat'),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.delete_sweep_rounded), onPressed: _clearChat),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: HMColors.accent))
            : _messages.isEmpty
                ? _emptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) return _typingIndicator();
                      final m = _messages[i];
                      final isUser = m['role'] == 'user';
                      return _MessageBubble(
                        content: m['content'] ?? '', isUser: isUser,
                        time: m['timestamp'] ?? '',
                      );
                    },
                  )),

        // Quick chips
        if (_messages.isEmpty || (!_sending && _messages.isNotEmpty))
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(_chips[i], style: const TextStyle(fontSize: 12, color: HMColors.text2)),
                onPressed: () => _send(_chips[i]),
                backgroundColor: HMColors.surface,
                side: const BorderSide(color: HMColors.border2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),

        // Input
        Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 10),
          decoration: const BoxDecoration(
            color: HMColors.bg2,
            border: Border(top: BorderSide(color: HMColors.border)),
          ),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              style: const TextStyle(color: HMColors.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask your AI health companion...',
                hintStyle: const TextStyle(color: HMColors.text3, fontSize: 13),
                filled: true, fillColor: HMColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: HMColors.border2)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: HMColors.border2)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: HMColors.accent, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: null, textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: _sending ? null : const LinearGradient(
                      colors: [HMColors.accent, HMColors.accent2]),
                  color: _sending ? HMColors.surface : null,
                  shape: BoxShape.circle,
                  boxShadow: _sending ? null : [BoxShadow(
                      color: HMColors.accent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: _sending
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: HMColors.accent))
                    : const Icon(Icons.send_rounded, color: Color(0xFF001a1a), size: 20)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _emptyState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [HMColors.accent, HMColors.accent2]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF060b14), size: 36),
      ),
      const SizedBox(height: 16),
      const Text('HealthMate AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: HMColors.text)),
      const SizedBox(height: 8),
      const Text('Your compassionate health companion.\nAsk me anything about your health.',
          style: TextStyle(fontSize: 13, color: HMColors.text3), textAlign: TextAlign.center),
    ]));
  }

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [HMColors.accent, HMColors.accent2]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF060b14), size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: HMColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4), topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
            ),
            border: Border.all(color: HMColors.border),
          ),
          child: Row(children: [
            for (int i = 0; i < 3; i++) _Dot(delay: i * 200),
          ]),
        ),
      ]),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, -4 * _anim.value),
          child: Container(width: 6, height: 6,
              decoration: const BoxDecoration(color: HMColors.text3, shape: BoxShape.circle)),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content, time;
  final bool isUser;
  const _MessageBubble({required this.content, required this.isUser, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [HMColors.accent, HMColors.accent2]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF060b14), size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? null : HMColors.surface,
                  gradient: isUser ? const LinearGradient(
                    colors: [Color(0x2600d4c8), Color(0x260099ff)]) : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isUser ? 14 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 14),
                  ),
                  border: Border.all(color: isUser ? const Color(0x3300d4c8) : HMColors.border),
                ),
                child: Text(content, style: const TextStyle(
                    fontSize: 14, color: HMColors.text, height: 1.5)),
              ),
              const SizedBox(height: 3),
              Text(_fmt(time), style: const TextStyle(fontSize: 10, color: HMColors.text3)),
            ],
          )),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: HMColors.surface3,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded, color: HMColors.text2, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(String ts) {
    try {
      return DateFormat('h:mm a').format(DateTime.parse(ts));
    } catch (_) { return ''; }
  }
}
