import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class ButtonTabBar extends StatelessWidget {
  final List<String> tabs;
  final String selectedTab;
  final ValueChanged<String> onTabSelected;

  const ButtonTabBar({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = tab == selectedTab;

          return InkWell(
            onTap: () => onTabSelected(tab),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.background.withAlpha(200),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.primary.withAlpha(55),
                ),
              ),
              child: Center(
                child: Text(
                  tab,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: selected ? AppColors.background : AppColors.primary,
                    fontWeight: .bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
