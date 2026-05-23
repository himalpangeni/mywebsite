import 'package:flutter/material.dart';
import '../ludo/game.dart';

class LudoConfigScreen extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onStart;
  const LudoConfigScreen({super.key, required this.onStart});

  @override
  State<LudoConfigScreen> createState() => _LudoConfigScreenState();
}

class _LudoConfigScreenState extends State<LudoConfigScreen> {
  List<Map<String, dynamic>> config = [
    {'color': LudoColor.red, 'isBot': false, 'isActive': true},
    {'color': LudoColor.green, 'isBot': true, 'isActive': true},
    {'color': LudoColor.yellow, 'isBot': true, 'isActive': true},
    {'color': LudoColor.blue, 'isBot': true, 'isActive': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B2F),
      appBar: AppBar(title: const Text('Ludo Setup'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('CHOOSE PLAYERS AND BOTS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, i) {
                final c = config[i];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: _getFlutterColor(c['color']), radius: 15),
                  title: Text(c['color'].toString().split('.').last.toUpperCase(), style: const TextStyle(color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Bot?', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Switch(
                        value: c['isBot'],
                        onChanged: (v) => setState(() => c['isBot'] = v),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent, minimumSize: const Size(double.infinity, 50)),
              onPressed: () => widget.onStart(config),
              child: const Text('START GAME'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getFlutterColor(LudoColor c) {
    switch(c) {
      case LudoColor.red: return Colors.red;
      case LudoColor.blue: return Colors.blue;
      case LudoColor.green: return Colors.green;
      case LudoColor.yellow: return Colors.yellow;
    }
  }
}
