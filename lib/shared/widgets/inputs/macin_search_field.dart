import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Barre de recherche réutilisable.
///
/// Différente de [MacinTextField] (formulaires) : pas de label
/// au-dessus, fond plus arrondi façon "pill", icône clear qui
/// n'apparaît que si du texte est saisi.
///
/// Usage :
/// ```dart
/// MacinSearchField(
///   controller: _searchController,
///   hint: 'Rechercher un cours...',
///   onChanged: (query) => _filterCourses(query),
/// )
/// ```
class MacinSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const MacinSearchField({
    super.key,
    required this.controller,
    this.hint = 'Rechercher...',
    this.onChanged,
    this.onClear,
  });

  @override
  State<MacinSearchField> createState() => _MacinSearchFieldState();
}

class _MacinSearchFieldState extends State<MacinSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        style: AppTextStyles.body1,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTextStyles.body2.copyWith(color: AppColors.textTertiary),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textTertiary,
            size: AppDimensions.iconLg,
          ),
          suffixIcon: hasText
              ? IconButton(
            icon: const Icon(Icons.close_rounded,
                size: AppDimensions.iconMd,
                color: AppColors.textTertiary),
            onPressed: () {
              widget.controller.clear();
              widget.onChanged?.call('');
              widget.onClear?.call();
            },
          )
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppDimensions.md,
          ),
        ),
      ),
    );
  }
}