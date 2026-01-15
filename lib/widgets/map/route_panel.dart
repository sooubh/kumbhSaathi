import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/route_model.dart';
import '../../providers/routing_provider.dart';
import '../../core/theme/app_colors.dart';

/// Route panel showing route details and navigation instructions
class RoutePanel extends ConsumerWidget {
  final NavigationRoute route;
  final VoidCallback? onClose;
  final VoidCallback? onStartNavigation;

  const RoutePanel({
    super.key,
    required this.route,
    this.onClose,
    this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routingState = ref.watch(routingProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            route.formattedTotalDistance,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textDarkDark
                                  : AppColors.textDarkLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            route.formattedTotalDuration,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (route.endName != null)
                        Text(
                          'To ${route.endName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
              ],
            ),
          ),

          // Steps list
          if (!routingState.isNavigating)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: route.steps.length,
                itemBuilder: (context, index) {
                  final step = route.steps[index];
                  final isFirst = index == 0;
                  final isLast = index == route.steps.length - 1;

                  return _buildStepItem(
                    context,
                    isDark,
                    step,
                    index + 1,
                    isFirst,
                    isLast,
                  );
                },
              ),
            ),

          // Navigation active view
          if (routingState.isNavigating && routingState.currentStepIndex != null)
            _buildActiveNavigation(
              context,
              isDark,
              route.steps[routingState.currentStepIndex!],
              routingState.currentStepIndex! + 1,
              route.steps.length,
              ref,
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: routingState.isNavigating
                ? _buildNavigationButtons(context, isDark, ref)
                : _buildStartButton(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    bool isDark,
    RouteStep step,
    int stepNumber,
    bool isFirst,
    bool isLast,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isFirst || isLast
                  ? AppColors.primaryBlue
                  : (isDark ? AppColors.cardDark : const Color(0xFFF9FAFB)),
              shape: BoxShape.circle,
              border: Border.all(
                color: isFirst || isLast
                    ? AppColors.primaryBlue
                    : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
              ),
            ),
            child: Center(
              child: isLast
                  ? const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 18,
                    )
                  : Text(
                      stepNumber.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isFirst
                            ? Colors.white
                            : (isDark
                                ? AppColors.textDarkDark
                                : AppColors.textDarkLight),
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Step details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textDarkDark
                        : AppColors.textDarkLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      step.formattedDistance,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      step.formattedDuration,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveNavigation(
    BuildContext context,
    bool isDark,
    RouteStep currentStep,
    int stepNumber,
    int totalSteps,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentStep.instruction,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkDark
                            : AppColors.textDarkLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentStep.formattedDistance} • ${currentStep.formattedDuration}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: stepNumber / totalSteps,
            backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
          ),
          const SizedBox(height: 8),
          Text(
            'Step $stepNumber of $totalSteps',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onStartNavigation,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Start Navigation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, bool isDark, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              ref.read(routingProvider.notifier).stopNavigation();
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.emergency),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(0, 52),
            ),
            child: Text(
              'Stop',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.emergency,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ref.read(routingProvider.notifier).nextStep();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(0, 52),
            ),
            child: const Text(
              'Next Step',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
