import 'package:flutter/material.dart';

class StickyActionBar extends StatelessWidget {
  final VoidCallback onReceive;
  final VoidCallback onIssue;
  final VoidCallback onAdjust;

  const StickyActionBar({
    Key? key,
    required this.onReceive,
    required this.onIssue,
    required this.onAdjust,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Semantics(
                  label: 'Receive stock',
                  hint: 'Add items to inventory',
                  child: _buildActionButton(
                    label: 'Receive',
                    icon: Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: onReceive,
                    isPrimary: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  label: 'Issue stock',
                  hint: 'Remove items from inventory',
                  child: _buildActionButton(
                    label: 'Issue',
                    icon: Icons.remove_circle_outline,
                    color: Colors.orange,
                    onPressed: onIssue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                label: 'Adjust stock',
                hint: 'Manually adjust inventory quantity',
                child: _buildIconButton(
                  icon: Icons.tune,
                  color: Colors.grey.shade600,
                  onPressed: onAdjust,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isPrimary ? 2 : 0,
        minimumSize: const Size(0, 48),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isPrimary ? 15 : 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textScaleFactor: 1.0, // Prevent text scaling issues
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}