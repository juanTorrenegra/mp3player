import 'package:flutter/material.dart';

class VendingMachineFrame extends StatelessWidget {
  final Widget child;

  const VendingMachineFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyanAccent.withValues(alpha: .1),
            Colors.cyanAccent.withValues(alpha: .3),
            Colors.cyanAccent.withValues(alpha: .1),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: .5),
            width: 0,
          ),
        ),
        child: Stack(
          children: [
            // Efectos de esquina
            ..._buildCornerEffects(),
            child,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerEffects() {
    return [
      Positioned(top: 0, left: 0, child: _buildCornerWidget()),
      Positioned(top: 0, right: 0, child: _buildCornerWidget()),
      Positioned(bottom: 0, left: 0, child: _buildCornerWidget()),
      Positioned(bottom: 0, right: 0, child: _buildCornerWidget()),
    ];
  }

  Widget _buildCornerWidget() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.cyanAccent, width: 2),
          left: BorderSide(color: Colors.cyanAccent, width: 2),
          bottom: BorderSide(color: Colors.redAccent, width: 2),
          right: BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
