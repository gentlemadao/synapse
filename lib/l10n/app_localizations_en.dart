// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Synapse 3D Editor';

  @override
  String get bevyViewport => 'Bevy Viewport';

  @override
  String get grid => 'Grid';

  @override
  String get wireframe => 'Wireframe';

  @override
  String get autoOrbit => 'Auto Orbit';

  @override
  String get joinCollaboration => 'Join Collaboration';

  @override
  String get invokeRustFfiGreet => 'Invoke Rust FFI Greet';

  @override
  String activeWorkspace(String workspace) {
    return 'Active Workspace: $workspace';
  }

  @override
  String get targetCompiledNative => 'Target Compiled Native';

  @override
  String get x86SIMD => 'x86_64 / arm64 SIMD Enable';

  @override
  String get sceneHierarchy => 'SCENE HIERARCHY (ECS)';

  @override
  String get activeNodeInfo => 'Active Node Info';

  @override
  String get entityId => 'Entity ID';

  @override
  String get entityName => 'Entity Name';

  @override
  String get type => 'Type';

  @override
  String get transformPosition => 'TRANSFORM (POSITION)';

  @override
  String get pbrColor => 'PBR COLOR REGISTRY';

  @override
  String get pbrVisibility => 'PBR VISIBILITY CONTROL';

  @override
  String get visible => 'Visible';

  @override
  String get hidden => 'Hidden';

  @override
  String get consoleHeader => 'SYNAPSE TERMINAL CONSOLE';

  @override
  String get clear => 'Clear';

  @override
  String get noNodeSelected => 'No Node Selected';

  @override
  String get entityMetadata => 'ENTITY METADATA';

  @override
  String get scaleMultiplier => 'SCALE MULTIPLIER';

  @override
  String get physicallyBasedMaterial => 'PHYSICALLY BASED MATERIAL';

  @override
  String get pbrAlbedoColor => 'PBR Albedo Color Preset';

  @override
  String get metallicFactor => 'Metallic Factor';

  @override
  String get roughnessFactor => 'Roughness Factor';

  @override
  String get alphaMode => 'Alpha Mode';

  @override
  String get opaque => 'Opaque';

  @override
  String get positionX => 'Position X';

  @override
  String get positionY => 'Position Y';

  @override
  String get positionZ => 'Position Z';

  @override
  String get uniformScale => 'Uniform Scale';
}
