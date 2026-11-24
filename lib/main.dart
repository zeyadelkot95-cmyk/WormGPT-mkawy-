import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const WormGptApp());

enum RunMode { both, online, offline }

class ChatMessage {
  ChatMessage(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

class WormGptApp extends StatefulWidget {
  const WormGptApp({super.key});
  @override
  State<WormGptApp> createState() => _WormGptAppState();
}

class _WormGptAppState extends State<WormGptApp> {
  bool arabic = true;
  RunMode mode = RunMode.both;
  final messages = <ChatMessage>[];
  final input = TextEditingController();
  final endpoint = TextEditingController(text: 'https://api.openai.com/v1/chat/completions');
  final model = TextEditingController(text: 'gpt-4o-mini');
  final apiKey = TextEditingController();
  bool busy = false;

  String tr(String ar, String en) => arabic ? ar : en;

  Future<void> send() async {
    final prompt = input.text.trim();
    if (prompt.isEmpty || busy) return;
    setState(() {
      messages.add(ChatMessage(prompt, true));
      input.clear();
      busy = true;
    });

    String answer;
    if (mode == RunMode.offline) {
      answer = tr(
        'وضع التشغيل المحلي التجريبي يعمل بدون اتصال بخدمة خارجية، لكنه حالياً يقدّم رد توضيحي فقط. لذكاء اصطناعي محلي كامل، يلزم ربط محرك ونموذج محليين.',
        'Offline demo mode runs without an external service, but currently returns an explanatory placeholder. A real on-device model engine and model file still need to be integrated.',
      );
    } else if (apiKey.text.trim().isEmpty) {
      answer = tr('أضف مفتاح API من الإعدادات لتفعيل وضع الإنترنت.', 'Add an API key in Settings to enable online mode.');
    } else {
      try {
        final uri = Uri.parse(endpoint.text.trim());
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${apiKey.text.trim()}',
          },
          body: jsonEncode({
            'model': model.text.trim(),
            'messages': [
              {'role': 'system', 'content': 'You are WormGPT X, a professional expert technical assistant.
Respond in Arabic or English according to the user's language.
Be direct, precise, practical and step-by-step.
Help with programming, Android, networking, cybersecurity defense,
troubleshooting and general technical education.
Never claim an action was completed unless it actually was.
Explain limitations honestly and offer safe practical alternatives.'},
              ...messages.map((m) => {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text}),
            ],
          }),
        ).timeout(const Duration(seconds: 45));
        final data = jsonDecode(response.body);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          answer = data['choices'][0]['message']['content'].toString();
        } else {
          answer = 'HTTP ${response.statusCode}: ${data['error']?['message'] ?? response.body}';
        }
      } catch (e) {
        answer = tr('تعذّر الاتصال: $e', 'Connection failed: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      messages.add(ChatMessage(answer, false));
      busy = false;
    });
  }

  void openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(tr('إعدادات الاتصال', 'Connection settings'), style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(controller: endpoint, decoration: const InputDecoration(labelText: 'API endpoint')),
            TextField(controller: model, decoration: const InputDecoration(labelText: 'Model')),
            TextField(controller: apiKey, obscureText: true, decoration: const InputDecoration(labelText: 'API key (kept in memory only)')),
            const SizedBox(height: 12),
            Text(tr('استخدم مزوداً موثوقاً ومتوافقاً مع واجهة OpenAI Chat Completions. لا تشارك مفتاحك.', 'Use a trusted OpenAI-compatible Chat Completions provider. Do not share your key.')),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('حفظ', 'Done'))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00E676), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF101014),
      useMaterial3: true,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark,
      home: Directionality(
        textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('WormGPT X'),
            actions: [
              IconButton(tooltip: 'Language', onPressed: () => setState(() => arabic = !arabic), icon: const Icon(Icons.language)),
              IconButton(tooltip: 'Settings', onPressed: openSettings, icon: const Icon(Icons.settings_outlined)),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: SegmentedButton<RunMode>(
                  segments: [
                    ButtonSegment(value: RunMode.both, label: Text(tr('تلقائي', 'Auto'))),
                    ButtonSegment(value: RunMode.online, label: Text(tr('إنترنت', 'Online'))),
                    ButtonSegment(value: RunMode.offline, label: Text(tr('محلي', 'Offline'))),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) => setState(() => mode = s.first),
                ),
              ),
              Expanded(
                child: messages.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.bolt, size: 54, color: Color(0xFF00E676)),
                          const SizedBox(height: 12),
                          Text(tr('مرحباً بك في WormGPT X', 'Welcome to WormGPT X'), style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(tr('مساعد تجريبي ثنائي اللغة. اختر وضع التشغيل وابدأ المحادثة.', 'A bilingual assistant starter. Choose a mode and start chatting.'), textAlign: TextAlign.center),
                        ]),
                      ))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          return Align(
                            alignment: m.fromUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: m.fromUser ? const Color(0xFF075E36) : const Color(0xFF10251B),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SelectableText(m.text),
                            ),
                          );
                        },
                      ),
              ),
              if (busy) const LinearProgressIndicator(minHeight: 2),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => send(),
                        decoration: InputDecoration(
                          hintText: tr('اكتب رسالتك...', 'Message WormGPT X...'),
                          filled: true,
                          fillColor: const Color(0xFF10251B),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: busy ? null : send,
                      icon: const Icon(Icons.send),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
