import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('\x1B[36m[Client] Connecting to synapse-server at ws://127.0.0.1:4000/ws/room/test_room...\x1B[0m');
  
  try {
    final socket = await WebSocket.connect('ws://127.0.0.1:4000/ws/room/test_room');
    print('\x1B[32m[Client] Connected to synapse-server successfully!\x1B[0m');
    
    socket.listen((data) {
      if (data is String) {
        try {
          final json = jsonDecode(data);
          if (json['type'] == 'sync_nodes') {
            print('\n\x1B[35m[Client] Received scene tree update from server:\x1B[0m');
            print('\x1B[1m┌──────────────────────────────────────┬─────────────┬───────────────────────────┬───────────┐\x1B[0m');
            print('\x1B[1m│ Name                                 │ Type        │ Coordinates (X, Y, Z)     │ Color     │\x1B[0m');
            print('\x1B[1m├──────────────────────────────────────┼─────────────┼───────────────────────────┼───────────┤\x1B[0m');
            final nodes = json['nodes'] as List;
            for (final n in nodes) {
              final name = n['name'].toString().padRight(36);
              final type = n['type'].toString().padRight(11);
              final coords = '(${n['px'].toStringAsFixed(2)}, ${n['py'].toStringAsFixed(2)}, ${n['pz'].toStringAsFixed(2)})'.padRight(25);
              final color = n['color'].toString().padRight(9);
              print('│ $name │ $type │ $coords │ $color │');
            }
            print('\x1B[1m└──────────────────────────────────────┴─────────────┴───────────────────────────┴───────────┘\x1B[0m');
            
            // Check if the AI node has been added!
            final hasAiNode = nodes.any((n) => n['name'] == 'AI Intelligent Twin Globe');
            if (hasAiNode) {
              print('\n\x1B[32;1m🎉 SUCCESS! AI Intelligent Twin Globe has been detected in the client scene tree!\x1B[0m');
              print('\x1B[36m[Client] Real-time MCP-to-Client sync verified perfectly. Exiting...\x1B[0m');
              exit(0);
            }
          }
        } catch (e) {
          print('[Client] Error parsing message: $e');
        }
      }
    }, onDone: () {
      print('[Client] WebSocket connection closed.');
    }, onError: (e) {
      print('[Client] WebSocket error: $e');
    });
  } catch (e) {
    print('[Client] Connection failed: $e');
    exit(1);
  }
}
