import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide Matrix4;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synapse/src/rust/api/simple.dart';
import 'package:synapse/src/rust/frb_generated.dart';
import 'package:synapse/state/editor_state.dart';
import 'package:synapse/src/bevy_viewport.dart';
import 'package:synapse/l10n/app_localizations.dart';

Future<void> main() async {
  // Ensure the Rust library is initialized before launching the Flutter UI
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  // Wrap the application in a ProviderScope to initialize Riverpod
  runApp(const ProviderScope(child: SynapseApp()));
}

class SynapseApp extends StatelessWidget {
  const SynapseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0C10),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const EditorDashboard(),
    );
  }
}

class EditorDashboard extends ConsumerStatefulWidget {
  const EditorDashboard({super.key});

  @override
  ConsumerState<EditorDashboard> createState() => _EditorDashboardState();
}

class _EditorDashboardState extends ConsumerState<EditorDashboard>
    with TickerProviderStateMixin {
  // Console logging state
  final List<String> _consoleLogs = [];
  final ScrollController _consoleScrollController = ScrollController();

  // Rendering settings
  bool _showGrid = true;
  bool _wireframeMode = false;
  bool _autoRotate = false;
  double _rotationAngle = 0.5;

  // Handlers for manual view orbiting
  double _horizontalAngle = 0.5;
  double _verticalAngle = 0.3;

  late AnimationController _rotationController;
  Timer? _physicsTimer;
  WebSocket? _socket;

  @override
  void initState() {
    super.initState();
    _log('System: Synapse 3D Editor Initialised.');
    _log('Dart-VM: Loaded and bound memory.');
    _log('Riverpod v2: State Management & CodeGen Active.');
    _log('FFI-v2: Establishing synchronous channel to Rust.');

    // Call Rust Greet API immediately!
    _callRustGreet('System Bootloader');

    // Sync initial nodes list to native side immediately!
    Future.microtask(() => _syncNodesToNative(ref.read(bevyNodesProvider)));

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    );
    _rotationController.addListener(() {
      if (_autoRotate) {
        setState(() {
          _rotationAngle = _rotationController.value * 2 * math.pi;
        });
      }
    });
    _rotationController.repeat();

    // Start a periodic mock Rust physics events stream log
    _physicsTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        // Read the currently active node safely from Riverpod state
        final nodes = ref.read(bevyNodesProvider);
        final selectedIndex = ref.read(selectedNodeIndexProvider);
        if (selectedIndex >= 0 && selectedIndex < nodes.length) {
          final activeNode = nodes[selectedIndex];
          _log(
            'Rust::Rapier3D: Solved constraints for [${activeNode.name}] - 0 intersections.',
          );
        }
      }
    });

    // Establish WebSocket Connection to synapse-server!
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    try {
      _log('Client: Connecting to synapse-server at ws://127.0.0.1:4000...');
      _socket = await WebSocket.connect(
        'ws://127.0.0.1:4000/ws/room/test_room',
      );
      _log('Client: Connected to synapse-server!');

      _socket!.listen(
        (data) {
          if (data is String) {
            try {
              final json = jsonDecode(data);
              if (json['type'] == 'sync_nodes') {
                final nodesList = json['nodes'] as List;
                final List<BevyNode> parsedNodes = [];
                for (final n in nodesList) {
                  parsedNodes.add(
                    BevyNode(
                      id: n['id'],
                      name: n['name'],
                      type: n['type'],
                      px: (n['px'] as num).toDouble(),
                      py: (n['py'] as num).toDouble(),
                      pz: (n['pz'] as num).toDouble(),
                      scale: (n['scale'] as num).toDouble(),
                      color: Color(
                        int.parse(n['color'].replaceAll('#', '0xFF')),
                      ),
                      visible: n['visible'] as bool,
                    ),
                  );
                }
                // Update Riverpod state!
                ref.read(bevyNodesProvider.notifier).setNodes(parsedNodes);
                _log(
                  'Client: Received remote scene tree synchronisation (${parsedNodes.length} nodes).',
                );
              }
            } catch (e) {
              _log('Client Socket JSON Error: $e');
            }
          }
        },
        onDone: () {
          _log('Client: WebSocket connection closed.');
        },
        onError: (e) {
          _log('Client Socket Error: $e');
        },
      );
    } catch (e) {
      _log('Client WebSocket connection failed: $e');
    }
  }

  @override
  void dispose() {
    _socket?.close();
    _physicsTimer?.cancel();
    _rotationController.dispose();
    _consoleScrollController.dispose();
    super.dispose();
  }

  void _log(String msg) {
    if (!mounted) return;
    setState(() {
      _consoleLogs.add(
        '[${DateTime.now().toLocal().toString().split(' ').last.substring(0, 8)}] $msg',
      );
    });
    // Scroll to bottom safely without delayed timers to pass widget tests
    Future.microtask(() {
      if (mounted && _consoleScrollController.hasClients) {
        try {
          final position = _consoleScrollController.position;
          if (position.hasContentDimensions) {
            _consoleScrollController.animateTo(
              position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        } catch (e) {
          // Ignore transient layout constraints timing errors
        }
      }
    });
  }

  void _callRustGreet(String operatorName) {
    try {
      // Synchronous FFI call directly into Rust compiled binary!
      final rustResponse = greet(name: operatorName);
      _log('Rust FFI Response: $rustResponse');
    } catch (e) {
      _log('Error calling Rust Greet: $e');
    }
  }

  Future<void> _syncNodesToNative(List<BevyNode> nodes) async {
    try {
      final List<Map<String, dynamic>> jsonList = nodes
          .map(
            (n) => {
              'id': n.id,
              'name': n.name,
              'type': n.type,
              'px': n.px,
              'py': n.py,
              'pz': n.pz,
              'scale': n.scale,
              'color':
                  '#${n.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
              'visible': n.visible,
            },
          )
          .toList();

      const channel = MethodChannel('synapse/viewport');
      await channel.invokeMethod('updateNodes', {
        'nodes': jsonEncode(jsonList),
      });
    } catch (e) {
      debugPrint('Error syncing nodes to native: $e');
    }
  }

  Future<void> _syncAnglesToNative(double hAngle, double vAngle) async {
    try {
      const channel = MethodChannel('synapse/viewport');
      await channel.invokeMethod('updateAngles', {
        'hAngle': hAngle,
        'vAngle': vAngle,
      });
    } catch (e) {
      debugPrint('Error syncing angles to native: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch and listen to Bevy Nodes list to sync changes to the native 3D renderer over MethodChannel!
    ref.listen<List<BevyNode>>(bevyNodesProvider, (previous, next) {
      _syncNodesToNative(next);
    });

    // Watch state providers via Riverpod ref!
    final selectedNodeIndex = ref.watch(selectedNodeIndexProvider);
    final nodes = ref.watch(bevyNodesProvider);
    final activeNode = nodes[selectedNodeIndex];

    final double globalAngle = _autoRotate ? _rotationAngle : _horizontalAngle;
    final double verticalAngle = _verticalAngle;

    // Sync active camera angles to the native 3D renderer over FFI
    _syncAnglesToNative(globalAngle, verticalAngle);

    final screenWidth = MediaQuery.of(context).size.width;
    final bool showLeft = screenWidth > 750;
    final bool showRight = screenWidth > 950;
    final double leftWidth = screenWidth > 1100 ? 280 : 200;
    final double rightWidth = screenWidth > 1100 ? 320 : 240;

    return Scaffold(
      backgroundColor: const Color(0xFF090A0F),
      body: Row(
        children: [
          // 1. LEFT SIDEBAR: ECS HIERARCHY
          if (showLeft) _buildLeftSidebar(nodes, selectedNodeIndex, leftWidth),

          // 2. CENTER AREA: 3D VIEWPORT & TERMINAL CONSOLE
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // Top control bar
                _buildTopControlBar(),

                // 3D Visual Viewport
                Expanded(flex: 3, child: _build3DViewport(nodes)),

                // Bottom Terminal Console
                Expanded(flex: 1, child: _buildTerminalConsole()),
              ],
            ),
          ),

          // 3. RIGHT SIDEBAR: PROPERTY INSPECTOR
          if (showRight)
            _buildRightSidebar(activeNode, selectedNodeIndex, rightWidth),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar(
    List<BevyNode> nodes,
    int selectedNodeIndex,
    double width,
  ) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFF11121A),
        border: Border(right: BorderSide(color: Color(0xFF1E202E), width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workspace header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E202E))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.hub,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SYNAPSE 3D',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.activeWorkspace('WebGPU'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
            child: Text(
              AppLocalizations.of(context)!.sceneHierarchy,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.white30,
              ),
            ),
          ),

          // Entity List
          Expanded(
            child: ListView.builder(
              itemCount: nodes.length,
              itemBuilder: (context, index) {
                final node = nodes[index];
                final isSelected = index == selectedNodeIndex;

                return GestureDetector(
                  onTap: () {
                    // Update state via Riverpod!
                    ref.read(selectedNodeIndexProvider.notifier).select(index);
                    _log('Editor: Selected entity [${node.name}]');
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blueAccent.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blueAccent.withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          node.type == 'GLB Mesh'
                              ? Icons.view_in_ar
                              : node.type == 'Sphere'
                              ? Icons.lens_blur
                              : Icons.widgets_outlined,
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            node.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          node.type,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Platform info tag
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E202E))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.terminal,
                      color: Colors.greenAccent,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.targetCompiledNative,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.x86SIMD,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 9, color: Colors.white30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControlBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF11121A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E202E), width: 1.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.bevyViewport,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildViewportToggle(
                        label: AppLocalizations.of(context)!.grid,
                        icon: Icons.grid_4x4,
                        value: _showGrid,
                        onChanged: (val) {
                          setState(() => _showGrid = val);
                          _log(
                            'Editor: Grid display toggled ${_showGrid ? "ON" : "OFF"}.',
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildViewportToggle(
                        label: AppLocalizations.of(context)!.wireframe,
                        icon: Icons.filter_center_focus,
                        value: _wireframeMode,
                        onChanged: (val) {
                          setState(() => _wireframeMode = val);
                          _log(
                            'Editor: Render mode set to ${_wireframeMode ? "Wireframe" : "Shaded Solid"}.',
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildViewportToggle(
                        label: AppLocalizations.of(context)!.autoOrbit,
                        icon: Icons.rotate_right,
                        value: _autoRotate,
                        onChanged: (val) {
                          setState(() => _autoRotate = val);
                          _log(
                            'Editor: Auto Rotation set to ${_autoRotate ? "ON" : "OFF"}.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (barWidth > 450) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: Text(
                    AppLocalizations.of(context)!.invokeRustFfiGreet,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _callRustGreet('Synapse WebOperator'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewportToggle({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value
              ? Colors.blueAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value
                ? Colors.blueAccent.withValues(alpha: 0.5)
                : const Color(0xFF1E202E),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? Colors.blueAccent : Colors.white30,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? Colors.white : Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DViewport(List<BevyNode> nodes) {
    return Container(
      color: const Color(0xFF0A0B0E),
      child: Stack(
        children: [
          // Background subtle grid & lighting glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF1E2030), Color(0xFF090A0F)],
                  radius: 1.2,
                ),
              ),
            ),
          ),

          // Custom Canvas drawing 3D scene (rotating diorama cube)
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _horizontalAngle -= details.delta.dx * 0.007;
                  _verticalAngle = (_verticalAngle + details.delta.dy * 0.007)
                      .clamp(0.05, math.pi / 2.2);
                  _autoRotate = false; // Disable auto rotation during drag
                });
              },
              child:
                  (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
                  ? const BevyViewport()
                  : CustomPaint(
                      painter: SimulatedViewportPainter(
                        nodes: nodes,
                        showGrid: _showGrid,
                        wireframe: _wireframeMode,
                        globalAngle: _autoRotate
                            ? _rotationAngle
                            : _horizontalAngle,
                        verticalAngle: _verticalAngle,
                      ),
                    ),
            ),
          ),

          // Viewport stats HUD
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E202E)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEBGL2 / WebGPU INSTANCE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'FPS: 119.8 (Hardware-Vsync)',
                    style: TextStyle(fontSize: 11, color: Colors.greenAccent),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Vertices: 104,242  |  DrawCalls: 22',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),

          // Drag prompt helper
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.white54, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Drag to orbit 3D Bevy space',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalConsole() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1015),
        border: Border(top: BorderSide(color: Color(0xFF1E202E), width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Console header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF161720),
              border: Border(bottom: BorderSide(color: Color(0xFF1E202E))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.terminal,
                        color: Colors.blueAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.consoleHeader,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _consoleLogs.clear();
                    });
                  },
                  child: Text(
                    AppLocalizations.of(context)!.clear,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white30,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Terminal logs stream
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFF08090C),
              child: ListView.builder(
                controller: _consoleScrollController,
                itemCount: _consoleLogs.length,
                itemBuilder: (context, index) {
                  final log = _consoleLogs[index];
                  Color logColor = Colors.white70;
                  if (log.contains('Rust FFI')) {
                    logColor = Colors.greenAccent;
                  } else if (log.contains('Rapier3D')) {
                    logColor = Colors.orangeAccent;
                  } else if (log.contains('Error')) {
                    logColor = Colors.redAccent;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        color: logColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar(
    BevyNode activeNode,
    int selectedNodeIndex,
    double width,
  ) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFF11121A),
        border: Border(left: BorderSide(color: Color(0xFF1E202E), width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inspector Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E202E))),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.activeNodeInfo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Settings body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Entity Metadata
                _buildSectionHeader(
                  AppLocalizations.of(context)!.entityMetadata,
                ),
                const SizedBox(height: 12),
                _buildMetadataRow(
                  AppLocalizations.of(context)!.entityId,
                  activeNode.id,
                ),
                _buildMetadataRow(
                  AppLocalizations.of(context)!.entityName,
                  activeNode.name,
                ),
                _buildMetadataRow(
                  AppLocalizations.of(context)!.type,
                  activeNode.type,
                ),
                const SizedBox(height: 24),

                // Translation (Position)
                _buildSectionHeader(
                  AppLocalizations.of(context)!.transformPosition,
                ),
                const SizedBox(height: 12),
                _buildInspectorSlider(
                  label: AppLocalizations.of(context)!.positionX,
                  value: activeNode.px,
                  min: -3.0,
                  max: 3.0,
                  onChanged: (val) {
                    ref
                        .read(bevyNodesProvider.notifier)
                        .updatePositionX(selectedNodeIndex, val);
                    _log(
                      'Transform: Mutated [${activeNode.name}] Translation.X = ${val.toStringAsFixed(2)}',
                    );
                  },
                ),
                _buildInspectorSlider(
                  label: AppLocalizations.of(context)!.positionY,
                  value: activeNode.py,
                  min: -3.0,
                  max: 3.0,
                  onChanged: (val) {
                    ref
                        .read(bevyNodesProvider.notifier)
                        .updatePositionY(selectedNodeIndex, val);
                    _log(
                      'Transform: Mutated [${activeNode.name}] Translation.Y = ${val.toStringAsFixed(2)}',
                    );
                  },
                ),
                _buildInspectorSlider(
                  label: AppLocalizations.of(context)!.positionZ,
                  value: activeNode.pz,
                  min: -3.0,
                  max: 3.0,
                  onChanged: (val) {
                    ref
                        .read(bevyNodesProvider.notifier)
                        .updatePositionZ(selectedNodeIndex, val);
                    _log(
                      'Transform: Mutated [${activeNode.name}] Translation.Z = ${val.toStringAsFixed(2)}',
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Scale
                _buildSectionHeader(
                  AppLocalizations.of(context)!.scaleMultiplier,
                ),
                const SizedBox(height: 12),
                _buildInspectorSlider(
                  label: AppLocalizations.of(context)!.uniformScale,
                  value: activeNode.scale,
                  min: 0.1,
                  max: 2.5,
                  onChanged: (val) {
                    ref
                        .read(bevyNodesProvider.notifier)
                        .updateScale(selectedNodeIndex, val);
                    _log(
                      'Transform: Scale set on [${activeNode.name}] to ${val.toStringAsFixed(2)}',
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Bevy PBR Material Config
                _buildSectionHeader(AppLocalizations.of(context)!.pbrColor),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.pbrAlbedoColor,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white30,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildPbrColorBubble(
                      activeNode,
                      selectedNodeIndex,
                      Colors.blueAccent,
                    ),
                    _buildPbrColorBubble(
                      activeNode,
                      selectedNodeIndex,
                      Colors.redAccent,
                    ),
                    _buildPbrColorBubble(
                      activeNode,
                      selectedNodeIndex,
                      Colors.cyanAccent,
                    ),
                    _buildPbrColorBubble(
                      activeNode,
                      selectedNodeIndex,
                      Colors.orangeAccent,
                    ),
                    _buildPbrColorBubble(
                      activeNode,
                      selectedNodeIndex,
                      const Color(0xFFFFD1A9),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMetadataRow(
                  AppLocalizations.of(context)!.metallicFactor,
                  '0.85 (Chrome)',
                ),
                _buildMetadataRow(
                  AppLocalizations.of(context)!.roughnessFactor,
                  '0.15 (Glossy)',
                ),
                _buildMetadataRow(
                  AppLocalizations.of(context)!.alphaMode,
                  AppLocalizations.of(context)!.opaque,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white30,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.white,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildPbrColorBubble(
    BevyNode node,
    int selectedNodeIndex,
    Color color,
  ) {
    final bool isSelected = node.color == color;
    return GestureDetector(
      onTap: () {
        ref
            .read(bevyNodesProvider.notifier)
            .updateColor(selectedNodeIndex, color);
        _log('Material: Modified [${node.name}] Pbr.AlbedoColor preset.');
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
              : null,
        ),
      ),
    );
  }
}

// Custom Painter to project 3D wireframe sandbox scene onto 2D Canvas!
class SimulatedViewportPainter extends CustomPainter {
  final List<BevyNode> nodes;
  final bool showGrid;
  final bool wireframe;
  final double globalAngle;
  final double verticalAngle;

  SimulatedViewportPainter({
    required this.nodes,
    required this.showGrid,
    required this.wireframe,
    required this.globalAngle,
    required this.verticalAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double scale = math.min(size.width, size.height) * 0.15;

    // View Projection Matrix components
    final double cosY = math.cos(globalAngle);
    final double sinY = math.sin(globalAngle);
    final double cosX = math.cos(verticalAngle);
    final double sinX = math.sin(verticalAngle);

    // 3D Point Projection function
    Offset project(double x, double y, double z) {
      // 1. Rotate around Y-axis (yaw)
      double rx1 = x * cosY - z * sinY;
      double rz1 = x * sinY + z * cosY;

      // 2. Rotate around X-axis (pitch)
      double ry2 = y * cosX - rz1 * sinX;
      double rz2 = y * sinX + rz1 * cosX;

      // 3. Perspective Projection
      double dist = 4.0;
      double perspective = dist / (dist + rz2);

      return Offset(
        cx + rx1 * scale * perspective,
        cy - ry2 * scale * perspective,
      );
    }

    // A. Draw Grid floor
    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFF1E293B).withValues(alpha: 0.3)
        ..strokeWidth = 1.0;

      for (double i = -2; i <= 2; i += 0.5) {
        // Parallel X gridlines
        canvas.drawLine(project(-2, -0.84, i), project(2, -0.84, i), gridPaint);
        // Parallel Z gridlines
        canvas.drawLine(project(i, -0.84, -2), project(i, -0.84, 2), gridPaint);
      }
    }

    // B. Draw Coordinate Center Axes
    final axisPaintX = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    final axisPaintY = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;
    final axisPaintZ = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.4)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      project(0, -0.84, 0),
      project(1, -0.84, 0),
      axisPaintX,
    ); // X-axis
    canvas.drawLine(
      project(0, -0.84, 0),
      project(0, 0.16, 0),
      axisPaintY,
    ); // Y-axis
    canvas.drawLine(
      project(0, -0.84, 0),
      project(0, -0.84, 1),
      axisPaintZ,
    ); // Z-axis

    // C. Draw the Bevy Nodes (Diorama sandtable boxes and elements)
    for (final node in nodes) {
      if (!node.visible) continue;

      final nodePaint = Paint()
        ..color = wireframe ? node.color.withValues(alpha: 0.8) : node.color
        ..style = wireframe ? PaintingStyle.stroke : paintStyleCustom(node.id)
        ..strokeWidth = 1.5;

      // Calculate translation
      final double tx = node.px;
      final double ty = node.py;
      final double tz = node.pz;
      final double halfSize = 0.4 * node.scale;

      // Calculate Box Corners
      final p000 = project(tx - halfSize, ty - halfSize, tz - halfSize);
      final p100 = project(tx + halfSize, ty - halfSize, tz - halfSize);
      final p110 = project(tx + halfSize, ty + halfSize, tz - halfSize);
      final p010 = project(tx - halfSize, ty + halfSize, tz - halfSize);
      final p001 = project(tx - halfSize, ty - halfSize, tz + halfSize);
      final p101 = project(tx + halfSize, ty - halfSize, tz + halfSize);
      final p111 = project(tx + halfSize, ty + halfSize, tz + halfSize);
      final p011 = project(tx - halfSize, ty + halfSize, tz + halfSize);

      // Draw cube lines/edges (Wireframe representation)
      if (wireframe ||
          node.type == 'GLB Mesh' ||
          node.type == 'Cylinder' ||
          node.type == 'Sphere') {
        canvas.drawLine(p000, p100, nodePaint);
        canvas.drawLine(p100, p110, nodePaint);
        canvas.drawLine(p110, p010, nodePaint);
        canvas.drawLine(p010, p000, nodePaint);

        canvas.drawLine(p001, p101, nodePaint);
        canvas.drawLine(p101, p111, nodePaint);
        canvas.drawLine(p111, p011, nodePaint);
        canvas.drawLine(p011, p001, nodePaint);

        canvas.drawLine(p000, p001, nodePaint);
        canvas.drawLine(p100, p101, nodePaint);
        canvas.drawLine(p110, p111, nodePaint);
        canvas.drawLine(p010, p011, nodePaint);
      } else {
        // Draw solid flat colored shapes by polygons
        final fillPaint = Paint()
          ..color = node.color.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;

        void drawFace(Offset a, Offset b, Offset c, Offset d) {
          final path = Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy)
            ..lineTo(c.dx, c.dy)
            ..lineTo(d.dx, d.dy)
            ..close();
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, nodePaint);
        }

        // Draw 3 primary visible faces for 3D illusion
        drawFace(p001, p101, p111, p011); // Front
        drawFace(p100, p101, p111, p110); // Right
        drawFace(p010, p110, p111, p011); // Top
      }
    }
  }

  PaintingStyle paintStyleCustom(String id) {
    // Floor is large, draw solid, others are wireframe for schematic CAD feel
    if (id == 'node_0') return PaintingStyle.fill;
    return PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant SimulatedViewportPainter oldDelegate) {
    return true; // Keep updating dynamically
  }
}
