import 'package:flutter/material.dart';

class MetricsCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  
  const MetricsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return _buildMetricsCard(context);
  }
  
  Widget _buildMetricsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildCardContent(context),
      ),
    );
  }
  
  Widget _buildCardContent(BuildContext context) {
    return Row(
      children: [
        _buildIconSection(),
        const SizedBox(width: 16),
        _buildMetricsInfo(context),
      ],
    );
  }
  
  Widget _buildIconSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon, 
        size: 32, 
        color: color,
      ),
    );
  }
  
  Widget _buildMetricsInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}