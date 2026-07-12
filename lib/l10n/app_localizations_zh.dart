// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Synapse 3D 编辑器';

  @override
  String get bevyViewport => 'Bevy 3D 视口';

  @override
  String get grid => '网格';

  @override
  String get wireframe => '线框';

  @override
  String get autoOrbit => '自动旋转';

  @override
  String get joinCollaboration => '加入协同';

  @override
  String get invokeRustFfiGreet => '调用 FFI 问候';

  @override
  String activeWorkspace(String workspace) {
    return '当前工作空间: $workspace';
  }

  @override
  String get targetCompiledNative => '目标原生静态编译';

  @override
  String get x86SIMD => 'x86_64 / arm64 SIMD 开启';

  @override
  String get sceneHierarchy => '场景节点层级 (ECS)';

  @override
  String get activeNodeInfo => '活动节点属性';

  @override
  String get entityId => '实体 ID';

  @override
  String get entityName => '实体名称';

  @override
  String get type => '类型';

  @override
  String get transformPosition => '物理空间位置 (XYZ)';

  @override
  String get pbrColor => 'PBR 物理材质颜色';

  @override
  String get pbrVisibility => 'PBR 视口可见性';

  @override
  String get visible => '可见';

  @override
  String get hidden => '隐藏';

  @override
  String get consoleHeader => 'SYNAPSE 终端控制台';

  @override
  String get clear => '清空';

  @override
  String get noNodeSelected => '未选中任何节点';

  @override
  String get entityMetadata => '实体元数据';

  @override
  String get scaleMultiplier => '缩放比例系数';

  @override
  String get physicallyBasedMaterial => 'PBR 物理基础材质';

  @override
  String get pbrAlbedoColor => 'PBR 反照率颜色预设';

  @override
  String get metallicFactor => '金属度系数';

  @override
  String get roughnessFactor => '粗糙度系数';

  @override
  String get alphaMode => '混合模式 (Alpha Mode)';

  @override
  String get opaque => '不透明 (Opaque)';

  @override
  String get positionX => '空间位置 X';

  @override
  String get positionY => '空间位置 Y';

  @override
  String get positionZ => '空间位置 Z';

  @override
  String get uniformScale => '等比缩放';
}
