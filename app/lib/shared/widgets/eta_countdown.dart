import 'dart:async';
import 'package:flutter/material.dart';

class EtaCountdown extends StatefulWidget {
  final int initialMinutes;
  const EtaCountdown({super.key, required this.initialMinutes});

  @override
  State<EtaCountdown> createState() => _EtaCountdownState();
}

class _EtaCountdownState extends State<EtaCountdown> {
  late int _secondsLeft;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.initialMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return Text(
      '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }
}
