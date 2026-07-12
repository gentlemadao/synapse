import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Title of the Synapse application
  ///
  /// In en, this message translates to:
  /// **'Synapse 3D Editor'**
  String get appTitle;

  /// No description provided for @bevyViewport.
  ///
  /// In en, this message translates to:
  /// **'Bevy Viewport'**
  String get bevyViewport;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @wireframe.
  ///
  /// In en, this message translates to:
  /// **'Wireframe'**
  String get wireframe;

  /// No description provided for @autoOrbit.
  ///
  /// In en, this message translates to:
  /// **'Auto Orbit'**
  String get autoOrbit;

  /// No description provided for @joinCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Join Collaboration'**
  String get joinCollaboration;

  /// No description provided for @invokeRustFfiGreet.
  ///
  /// In en, this message translates to:
  /// **'Invoke Rust FFI Greet'**
  String get invokeRustFfiGreet;

  /// No description provided for @activeWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Active Workspace: {workspace}'**
  String activeWorkspace(String workspace);

  /// No description provided for @targetCompiledNative.
  ///
  /// In en, this message translates to:
  /// **'Target Compiled Native'**
  String get targetCompiledNative;

  /// No description provided for @x86SIMD.
  ///
  /// In en, this message translates to:
  /// **'x86_64 / arm64 SIMD Enable'**
  String get x86SIMD;

  /// No description provided for @sceneHierarchy.
  ///
  /// In en, this message translates to:
  /// **'SCENE HIERARCHY (ECS)'**
  String get sceneHierarchy;

  /// No description provided for @activeNodeInfo.
  ///
  /// In en, this message translates to:
  /// **'Active Node Info'**
  String get activeNodeInfo;

  /// No description provided for @entityId.
  ///
  /// In en, this message translates to:
  /// **'Entity ID'**
  String get entityId;

  /// No description provided for @entityName.
  ///
  /// In en, this message translates to:
  /// **'Entity Name'**
  String get entityName;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @transformPosition.
  ///
  /// In en, this message translates to:
  /// **'TRANSFORM (POSITION)'**
  String get transformPosition;

  /// No description provided for @pbrColor.
  ///
  /// In en, this message translates to:
  /// **'PBR COLOR REGISTRY'**
  String get pbrColor;

  /// No description provided for @pbrVisibility.
  ///
  /// In en, this message translates to:
  /// **'PBR VISIBILITY CONTROL'**
  String get pbrVisibility;

  /// No description provided for @visible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @consoleHeader.
  ///
  /// In en, this message translates to:
  /// **'SYNAPSE TERMINAL CONSOLE'**
  String get consoleHeader;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @noNodeSelected.
  ///
  /// In en, this message translates to:
  /// **'No Node Selected'**
  String get noNodeSelected;

  /// No description provided for @entityMetadata.
  ///
  /// In en, this message translates to:
  /// **'ENTITY METADATA'**
  String get entityMetadata;

  /// No description provided for @scaleMultiplier.
  ///
  /// In en, this message translates to:
  /// **'SCALE MULTIPLIER'**
  String get scaleMultiplier;

  /// No description provided for @physicallyBasedMaterial.
  ///
  /// In en, this message translates to:
  /// **'PHYSICALLY BASED MATERIAL'**
  String get physicallyBasedMaterial;

  /// No description provided for @pbrAlbedoColor.
  ///
  /// In en, this message translates to:
  /// **'PBR Albedo Color Preset'**
  String get pbrAlbedoColor;

  /// No description provided for @metallicFactor.
  ///
  /// In en, this message translates to:
  /// **'Metallic Factor'**
  String get metallicFactor;

  /// No description provided for @roughnessFactor.
  ///
  /// In en, this message translates to:
  /// **'Roughness Factor'**
  String get roughnessFactor;

  /// No description provided for @alphaMode.
  ///
  /// In en, this message translates to:
  /// **'Alpha Mode'**
  String get alphaMode;

  /// No description provided for @opaque.
  ///
  /// In en, this message translates to:
  /// **'Opaque'**
  String get opaque;

  /// No description provided for @positionX.
  ///
  /// In en, this message translates to:
  /// **'Position X'**
  String get positionX;

  /// No description provided for @positionY.
  ///
  /// In en, this message translates to:
  /// **'Position Y'**
  String get positionY;

  /// No description provided for @positionZ.
  ///
  /// In en, this message translates to:
  /// **'Position Z'**
  String get positionZ;

  /// No description provided for @uniformScale.
  ///
  /// In en, this message translates to:
  /// **'Uniform Scale'**
  String get uniformScale;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
