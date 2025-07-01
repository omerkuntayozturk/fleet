import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AboutUsDialog extends StatefulWidget {
  const AboutUsDialog({Key? key}) : super(key: key);

  @override
  State<AboutUsDialog> createState() => _AboutUsDialogState();
}

class _AboutUsDialogState extends State<AboutUsDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final contentPadding = EdgeInsets.all(isSmallScreen ? 16.0 : 24.0);
        
        return Stack(
          children: [
            Padding(
              padding: contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 20 : 32),
                  
                  // Main content in scrollable area
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Company overview section
                          _buildCompanySection(isSmallScreen),
                          SizedBox(height: isSmallScreen ? 20 : 32),
                          
                          // Mission and vision section
                          _buildMissionVisionSection(isSmallScreen),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Add X button in the top-right corner
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                color: Colors.grey[700],
                tooltip: tr('aboutus_close'),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          )),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business,
                  size: isSmallScreen ? 28 : 36,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  tr('aboutus_title'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: isSmallScreen ? 20 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
            ),
          ),
          child: Text(
            tr('aboutus_subtitle'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: isSmallScreen ? 14 : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanySection(bool isSmallScreen) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.2, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller, 
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('aboutus_company_profile'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: isSmallScreen ? 18 : null,
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                tr('aboutus_company_intro'),
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16, height: 1.6),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Text(
                tr('aboutus_company_description'),
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionVisionSection(bool isSmallScreen) {
    // On small screens, stack mission and vision vertically
    if (isSmallScreen) {
      return Column(
        children: [
          _buildMissionCard(isSmallScreen),
          const SizedBox(height: 20),
          _buildVisionCard(isSmallScreen),
        ],
      );
    }
    
    // On larger screens, display side by side
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildMissionCard(isSmallScreen)),
        const SizedBox(width: 24),
        Expanded(child: _buildVisionCard(isSmallScreen)),
      ],
    );
  }

  Widget _buildMissionCard(bool isSmallScreen) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      size: isSmallScreen ? 20 : 24,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('aboutus_our_mission'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: isSmallScreen ? 16 : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                tr('aboutus_mission_text'),
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisionCard(bool isSmallScreen) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: _controller,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.visibility_outlined,
                      size: isSmallScreen ? 20 : 24,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('aboutus_our_vision'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                        fontSize: isSmallScreen ? 16 : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                tr('aboutus_vision_text'),
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
