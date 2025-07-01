import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class CurrentPlan extends StatelessWidget {
  final String? membershipPlan;
  final Timestamp? membershipEndDate;
  final AnimationController controller;
  final String Function(String?) getFormattedPlanText;

  const CurrentPlan({
    Key? key,
    required this.membershipPlan,
    required this.membershipEndDate,
    required this.controller,
    required this.getFormattedPlanText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildHeaderSection(context);
  }

  Widget buildHeaderSection(BuildContext context) {
    final endDate = membershipEndDate?.toDate();
    final daysRemaining = endDate != null ? endDate.difference(DateTime.now()).inDays : null;
    
    // Determine plan-specific colors
    Color planColor;
    IconData planIcon;
    
    switch (membershipPlan) {
      case 'free':
        planColor = Colors.grey[700]!;
        planIcon = Icons.card_giftcard;
        break;
      case 'monthly':
        planColor = Colors.blue;
        planIcon = Icons.calendar_month;
        break;
      case 'yearly':
        planColor = Colors.purple;
        planIcon = Icons.calendar_today;
        break;
      default:
        planColor = Theme.of(context).primaryColor;
        planIcon = Icons.card_membership;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define responsive breakpoints
        final isSmallMobile = constraints.maxWidth < 360;
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth < 900;
        
        // Responsive font sizes
        final titleFontSize = isSmallMobile ? 20.0 : isMobile ? 22.0 : 24.0;
        final subtitleFontSize = isSmallMobile ? 14.0 : 16.0;
        final planTitleFontSize = isSmallMobile ? 16.0 : isMobile ? 18.0 : 20.0;
        final iconSize = isSmallMobile ? 22.0 : isMobile ? 24.0 : 26.0;
        
        // Responsive padding
        final contentPadding = isSmallMobile 
            ? const EdgeInsets.all(12.0)
            : isMobile 
                ? const EdgeInsets.all(16.0) 
                : const EdgeInsets.all(20.0);
        
        // For smaller screens, stack the widgets vertically
        if (isTablet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title section
              _buildTitleSection(
                context, 
                titleFontSize: titleFontSize,
                subtitleFontSize: subtitleFontSize,
              ),
              
              SizedBox(height: isMobile ? 16 : 24),
              
              // Plan widget - full width on smaller screens
              _buildPlanWidget(
                context, 
                planColor, 
                planIcon, 
                endDate, 
                daysRemaining, 
                double.infinity,
                contentPadding: contentPadding,
                iconSize: iconSize,
                planTitleFontSize: planTitleFontSize,
                isSmallScreen: isMobile,
              ),
            ],
          );
        }
        
        // For wider screens, use a row layout
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title section - approximately half width
            Expanded(
              flex: 1,
              child: _buildTitleSection(
                context,
                titleFontSize: titleFontSize,
                subtitleFontSize: subtitleFontSize,
              ),
            ),
            
            SizedBox(width: isTablet ? 16 : 24),
            
            // Plan widget - approximately half width
            Expanded(
              flex: 1,
              child: _buildPlanWidget(
                context, 
                planColor, 
                planIcon, 
                endDate, 
                daysRemaining, 
                null,
                contentPadding: contentPadding,
                iconSize: iconSize,
                planTitleFontSize: planTitleFontSize,
                isSmallScreen: false,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitleSection(
    BuildContext context, {
    required double titleFontSize,
    required double subtitleFontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          )),
          child: Row(
            children: [
              Icon(
                Icons.star,
                color: const Color(0xFFFFD700),
                size: titleFontSize + 4, // Scale icon with text
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  tr("subscription_title"),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: titleFontSize,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: controller,
              curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
            ),
          ),
          child: Text(
            tr("subscription_upgrade_message"),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: subtitleFontSize,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanWidget(
    BuildContext context, 
    Color planColor, 
    IconData planIcon, 
    DateTime? endDate, 
    int? daysRemaining, 
    double? width, {
    required EdgeInsets contentPadding,
    required double iconSize,
    required double planTitleFontSize,
    required bool isSmallScreen,
  }) {
    return SizedBox(
      width: width,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: planColor.withOpacity(0.15),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: planColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header gradient section
              Container(
                height: isSmallScreen ? 6 : 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      planColor.withOpacity(0.8),
                      planColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: contentPadding,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Handle very narrow screens by stacking icon and text
                    if (constraints.maxWidth < 220) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: planColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: planColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                planIcon,
                                color: planColor,
                                size: iconSize,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getFormattedPlanText(membershipPlan),
                                style: TextStyle(
                                  fontSize: planTitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              if (membershipPlan != 'free')
                                Text(
                                  membershipPlan == 'monthly'
                                      ? tr('subscription_monthly_plan_description')
                                      : tr('subscription_yearly_plan_description'),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    }
                    
                    // Default row layout for wider screens
                    return Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            color: planColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: planColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            planIcon,
                            color: planColor,
                            size: iconSize,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getFormattedPlanText(membershipPlan),
                                style: TextStyle(
                                  fontSize: planTitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (membershipPlan != 'free')
                                Text(
                                  membershipPlan == 'monthly'
                                      ? tr('subscription_monthly_plan_description')
                                      : tr('subscription_yearly_plan_description'),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // Status badge if applicable
              if (endDate != null && daysRemaining != null && membershipPlan != 'free')
                Padding(
                  padding: EdgeInsets.only(
                    bottom: isSmallScreen ? 12.0 : 16.0,
                    left: isSmallScreen ? 12.0 : 20.0,
                    right: isSmallScreen ? 12.0 : 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 250) {
                            // For very narrow screens, stack the remaining days info
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('subscription_time_remaining'),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${daysRemaining} ${tr('subscription_days')}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: daysRemaining < 15 ? Colors.orange : planColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          }
                          
                          // Default row layout for wider screens
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tr('subscription_time_remaining'),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${daysRemaining} ${tr('subscription_days')}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: daysRemaining < 15 ? Colors.orange : planColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: daysRemaining / (membershipPlan == 'monthly' ? 30 : 365),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            daysRemaining < 15 ? Colors.orange : planColor,
                          ),
                          minHeight: isSmallScreen ? 6 : 8,
                        ),
                      ),
                      
                      if (daysRemaining < 15) ...[
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 6 : 8, 
                            horizontal: isSmallScreen ? 8 : 12
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: isSmallScreen ? 14 : 16,
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              Expanded(
                                child: Text(
                                  tr('subscription_expiring_soon_warning'),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
