import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/ai_suggestion_chip.dart';
import '../../../../shared/widgets/chat_bubble.dart';

/// Page Tuteur IA — chat fonctionnel localement (sans backend FastAPI
/// branché encore).
///
/// FONCTIONNEMENT TEMPLATE :
/// Quand l'étudiant envoie un message, [_generateSimulatedReply]
/// pioche une réponse plausible dans un petit corpus local après un
/// délai simulé (comme un vrai appel réseau). Ça permet de tester
/// l'UX complète du chat — défilement, bulles, indicateur de frappe,
/// suggestions — avant de brancher l'endpoint réel `/tutor-chat`
/// de FastAPI (voir roadmap M5, issue #41).
///
/// Pour brancher le vrai backend plus tard : remplacer uniquement
/// [_generateSimulatedReply] par un appel à la Cloud Function proxy
/// vers FastAPI, et persister les échanges dans [AiSessionModel]
/// via Firestore au lieu de la liste locale [_messages].
class AiTutorPage extends StatefulWidget {
  const AiTutorPage({super.key});

  @override
  State<AiTutorPage> createState() => _AiTutorPageState();
}

class _AiTutorPageState extends State<AiTutorPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _random = Random();

  final List<AiMessageModel> _messages = [
    AiMessageModel(
      role: 'ai',
      content:
      "Salut ! Je suis ton tuteur IA MACIN 👋\n\nPose-moi une question sur tes cours, ou choisis une suggestion ci-dessous pour commencer.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  bool _isTyping = false;

  static const _suggestions = [
    "Explique-moi les Widgets Flutter",
    "Qu'est-ce qu'un StatefulWidget ?",
    "Comment fonctionne Firestore ?",
    "Je suis bloqué sur mon quiz",
  ];

  // Corpus de réponses simulées, choisies selon des mots-clés simples
  // dans le message de l'utilisateur — juste pour le réalisme du
  // design, pas une vraie compréhension du langage.
  static const _repliesByKeyword = {
    'widget': "Un Widget est l'unité de base de toute interface Flutter. Il existe deux familles principales : `StatelessWidget` (immuable) et `StatefulWidget` (qui peut se reconstruire avec `setState()`). Tu veux un exemple de code ?",
    'stateful': "`StatefulWidget` est utilisé quand une partie de ton interface doit changer en réponse à une interaction ou un événement. Il fonctionne avec une classe `State` séparée qui contient les données mutables. Veux-tu que je te montre le cycle de vie complet ?",
    'firestore': "Firestore est une base de données NoSQL en temps réel. Dans MACIN, on l'utilise avec des `StreamBuilder` pour que l'interface se mette à jour automatiquement dès qu'un document change — par exemple ta progression ou ton solde wallet.",
    'quiz': "Pas de souci, regardons ça ensemble ! Sur quel exercice précisément bloques-tu ? Dis-moi le nom du cours ou colle-moi la question, et je t'aide à comprendre le raisonnement (pas juste la réponse 😉).",
    'bloqu': "Je comprends, c'est normal de buter sur un concept. Peux-tu me dire exactement à quelle étape tu es ? On va décomposer le problème ensemble.",
  };

  static const _defaultReplies = [
    "Bonne question ! Peux-tu préciser un peu plus le contexte ? Par exemple, dans quel cours ou quelle leçon tu es actuellement ?",
    "Je note ça. D'après ta progression, je pense que revoir le module précédent pourrait t'aider. Veux-tu que je te propose un plan de révision ?",
    "C'est un sujet intéressant. Veux-tu une explication simple d'abord, ou tu préfères directement un exemple de code ?",
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? presetText]) {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(AiMessageModel(
        role: 'user',
        content: text,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Simule la latence d'un vrai appel réseau au backend FastAPI.
    final delay = Duration(milliseconds: 900 + _random.nextInt(700));
    Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _messages.add(AiMessageModel(
          role: 'ai',
          content: _generateSimulatedReply(text),
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  String _generateSimulatedReply(String userText) {
    final lower = userText.toLowerCase();
    for (final entry in _repliesByKeyword.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return _defaultReplies[_random.nextInt(_defaultReplies.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.aiSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.aiPrimary, size: 18),
            ),
            const SizedBox(width: AppDimensions.sm),
            Text('Tuteur IA', style: AppTextStyles.heading2),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
                vertical: AppDimensions.base,
              ),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const TypingIndicator();
                }
                final message = _messages[index];
                return ChatBubble(text: message.content, isUser: message.isUser);
              },
            ),
          ),

          // ── Suggestions rapides (visibles seulement au début) ──
          if (_messages.length <= 1)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePaddingH,
                  ),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.sm),
                  itemBuilder: (context, index) => AiSuggestionChip(
                    label: _suggestions[index],
                    onTap: () => _sendMessage(_suggestions[index]),
                  ),
                ),
              ),
            ),

          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.sm,
        AppDimensions.pagePaddingH,
        AppDimensions.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
                style: AppTextStyles.body1,
                decoration: InputDecoration(
                  hintText: 'Pose ta question...',
                  hintStyle: AppTextStyles.body2.copyWith(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.base,
                    vertical: AppDimensions.md,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          InkWell(
            onTap: () => _sendMessage(),
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.aiPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
