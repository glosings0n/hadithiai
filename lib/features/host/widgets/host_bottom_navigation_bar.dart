import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class HostBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLiveTap;

  const HostBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onLiveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(top: BorderSide(color: AppColors.primary.withAlpha(35))),
      ),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: [
          _NavItem(
            icon: AppIcons.home,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onDestinationSelected(0),
          ),
          MainGridCard(
            onTap: onLiveTap,
            height: 64,
            width: 64,
            iconSize: 26,
            icon: AppIcons.mic,
            iconColor: AppColors.background,
            backgroundColor: AppColors.secondary,
          ),
          _NavItem(
            icon: AppIcons.library,
            label: 'Library',
            selected: currentIndex == 1,
            onTap: () => onDestinationSelected(1),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: .circular(12),
      child: Padding(
        padding: const .symmetric(horizontal: 6.0, vertical: 2),
        child: Column(
          mainAxisAlignment: .center,
          spacing: 4,
          children: [
            Icon(icon, color: color, size: 22),
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: selected ? .bold : .normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
