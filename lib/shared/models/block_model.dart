import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BlockType
// Correspond aux types saisies dans le champ "blocks" JSON de l'admin
// ─────────────────────────────────────────────────────────────────────────────

enum BlockType {
  heading,
  text,
  code,
  tip,
  warning,
  divider,
  image,
  unknown;

  static BlockType fromString(String? value) => switch (value) {
    'heading' => BlockType.heading,
    'text' => BlockType.text,
    'code' => BlockType.code,
    'tip' => BlockType.tip,
    'warning' => BlockType.warning,
    'divider' => BlockType.divider,
    'image' => BlockType.image,
    _ => BlockType.unknown,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// BlockModel
// Représente un bloc individuel dans lesson.blocks (tableau JSON Firestore)
//
// Structure admin (champ "Contenu enrichi avancé") :
// [
//   { "type": "heading", "level": 2, "content": "Mon titre" },
//   { "type": "text", "content": "Paragraphe de texte..." },
//   { "type": "code", "language": "dart", "content": "void main() {...}" },
//   { "type": "tip", "title": "Astuce", "content": "..." },
//   { "type": "warning", "title": "Attention", "content": "..." },
//   { "type": "divider" },
//   { "type": "image", "url": "https://...", "caption": "légende" }
// ]
// ─────────────────────────────────────────────────────────────────────────────

class BlockModel extends Equatable {
  final BlockType type;

  /// Contenu principal (text, code, tip, warning, heading)
  final String? content;

  /// Niveau pour les headings : 1 | 2 | 3
  final int? level;

  /// Langage pour les blocs code : 'dart' | 'yaml' | 'bash' | 'json'
  final String? language;

  /// Titre pour tip et warning
  final String? title;

  /// URL pour les blocs image
  final String? url;

  /// Légende pour les blocs image
  final String? caption;

  const BlockModel({
    required this.type,
    this.content,
    this.level,
    this.language,
    this.title,
    this.url,
    this.caption,
  });

  factory BlockModel.fromMap(Map<String, dynamic> data) {
    return BlockModel(
      type: BlockType.fromString(data['type'] as String?),
      content: data['content'] as String?,
      level: data['level'] as int?,
      language: data['language'] as String?,
      title: data['title'] as String?,
      url: data['url'] as String?,
      caption: data['caption'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    if (content != null) 'content': content,
    if (level != null) 'level': level,
    if (language != null) 'language': language,
    if (title != null) 'title': title,
    if (url != null) 'url': url,
    if (caption != null) 'caption': caption,
  };

  // ── Helpers ───────────────────────────────────────────────

  bool get isHeading => type == BlockType.heading;
  bool get isText => type == BlockType.text;
  bool get isCode => type == BlockType.code;
  bool get isTip => type == BlockType.tip;
  bool get isWarning => type == BlockType.warning;
  bool get isDivider => type == BlockType.divider;
  bool get isImage => type == BlockType.image;

  /// Retourne le niveau de titre normalisé entre 1 et 3
  int get headingLevel => (level ?? 2).clamp(1, 3);

  @override
  List<Object?> get props => [type, content, level, language, title, url];
}
