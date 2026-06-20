import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:macin/core/constants/app_colors.dart';
import 'package:macin/core/constants/app_dimensions.dart';
import 'package:macin/router/app_routes.dart';



/// Scaffold principal de MACIN avec BottomNavigationBar.
///
/// Utilisé comme shell dans go_router (ShellRoute).
/// L'[IndexedStack] garde l'état de chaque onglet en mémoire :
/// si l'utilisateur scrolle dans le catalogue et va dans son profil,
/// en revenant au catalogue il retrouve sa position.
///
/// Les badges de notification (ex: nouveau message du tuteur IA)
/// seront ajoutés en issue #42 via StreamBuilder.
class MainScaffold extends StatefulWidget {
  /// Widget de la page active, fourni par go_router ShellRoute.
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  /// Correspondance index → route go_router.
  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
      route: AppRoutes.home,
    ),
    _NavItem(
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle_rounded,
      label: 'Cours',
      route: AppRoutes.catalog,
    ),
    _NavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
      label: 'IA Tuteur',
      route: AppRoutes.aiTutor,
    ),
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Wallet',
      route: AppRoutes.wallet,
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
      route: AppRoutes.profile,
    ),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Double-tap sur l'onglet actif → scroll to top (sera géré par chaque page)
      return;
    }
    setState(() => _currentIndex = index);
    context.goNamed(_items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _MacinBottomNav(
        currentIndex: _currentIndex,
        items: _items,
        onTap: _onTabTapped,
      ),
    );
  }
}

/// BottomNavigationBar custom de MACIN.
///
/// Séparé en widget distinct pour pouvoir être testé indépendamment
/// et facilement modifier son apparence sans toucher au scaffold.
class _MacinBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _MacinBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.bottomNavHeight +
          MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isActive = index == currentIndex;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                splashColor: AppColors.primarySurface,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Indicateur actif (pill au-dessus de l'icône)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 32 : 0,
                      height: 3,
                      margin: const EdgeInsets.only(
                          bottom: AppDimensions.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusRound),
                      ),
                    ),
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      size: AppDimensions.iconLg,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
