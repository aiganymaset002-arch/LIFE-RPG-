#!/usr/bin/env python3
"""Генерирует LifeRPG.xcodeproj (как в KKSU): все Swift-файлы из LifeRPG/ подключаются автоматически.

Запуск после добавления новых файлов:  python3 scripts/gen_xcodeproj.py
"""
import hashlib
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = "LifeRPG"
BUNDLE_ID = "kz.aiganym.liferpg"
DISPLAY = "LIFE RPG"


def oid(*parts):
    return hashlib.md5("|".join(parts).encode()).hexdigest()[:24].upper()


groups = {}  # folder -> [files]
for folder in sorted(os.listdir(os.path.join(ROOT, APP))):
    p = os.path.join(ROOT, APP, folder)
    if os.path.isdir(p) and not folder.endswith(".xcassets"):
        groups[folder] = sorted(f for f in os.listdir(p) if f.endswith(".swift"))

swift = [(g, f) for g, fs in groups.items() for f in fs]

T = {k: oid(k) for k in ["project", "target", "main", "app_group", "support", "products", "product",
                          "sources", "frameworks", "resources", "cfg_proj", "cfg_target",
                          "proj_debug", "proj_release", "tgt_debug", "tgt_release",
                          "assets_ref", "assets_build", "privacy_ref", "privacy_build", "readme_ref"]}
for g in groups:
    T["group_" + g] = oid("group", g)

out = []
w = out.append
w("// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 56;\n\tobjects = {\n")

w("/* Begin PBXBuildFile section */\n")
for g, f in swift:
    w(f"\t\t{oid('build', g, f)} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {oid('ref', g, f)} /* {f} */; }};\n")
w(f"\t\t{T['assets_build']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {T['assets_ref']} /* Assets.xcassets */; }};\n")
w(f"\t\t{T['privacy_build']} /* PrivacyInfo.xcprivacy in Resources */ = {{isa = PBXBuildFile; fileRef = {T['privacy_ref']} /* PrivacyInfo.xcprivacy */; }};\n")
w("/* End PBXBuildFile section */\n\n")

w("/* Begin PBXFileReference section */\n")
for g, f in swift:
    w(f"\t\t{oid('ref', g, f)} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{f}\"; sourceTree = \"<group>\"; }};\n")
w(f"\t\t{T['assets_ref']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};\n")
w(f"\t\t{T['privacy_ref']} /* PrivacyInfo.xcprivacy */ = {{isa = PBXFileReference; lastKnownFileType = text.xml; path = PrivacyInfo.xcprivacy; sourceTree = \"<group>\"; }};\n")
w(f"\t\t{T['readme_ref']} /* README.md */ = {{isa = PBXFileReference; lastKnownFileType = net.daringfireball.markdown; path = README.md; sourceTree = \"<group>\"; }};\n")
w(f"\t\t{T['product']} /* {APP}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = \"{APP}.app\"; sourceTree = BUILT_PRODUCTS_DIR; }};\n")
w("/* End PBXFileReference section */\n\n")

w(f"/* Begin PBXFrameworksBuildPhase section */\n\t\t{T['frameworks']} /* Frameworks */ = {{\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n/* End PBXFrameworksBuildPhase section */\n\n")

w("/* Begin PBXGroup section */\n")
w(f"\t\t{T['main']} /* Main */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{T['app_group']} /* {APP} */,\n\t\t\t\t{T['support']} /* Supporting Files */,\n\t\t\t\t{T['products']} /* Products */,\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
w(f"\t\t{T['app_group']} /* {APP} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n")
for g in groups:
    w(f"\t\t\t\t{T['group_' + g]} /* {g} */,\n")
w(f"\t\t\t\t{T['assets_ref']} /* Assets.xcassets */,\n\t\t\t);\n\t\t\tpath = {APP};\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
for g, fs in groups.items():
    w(f"\t\t{T['group_' + g]} /* {g} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n")
    for f in fs:
        w(f"\t\t\t\t{oid('ref', g, f)} /* {f} */,\n")
    w(f"\t\t\t);\n\t\t\tpath = {g};\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
w(f"\t\t{T['support']} /* Supporting Files */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{T['privacy_ref']} /* PrivacyInfo.xcprivacy */,\n\t\t\t\t{T['readme_ref']} /* README.md */,\n\t\t\t);\n\t\t\tname = \"Supporting Files\";\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
w(f"\t\t{T['products']} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{T['product']} /* {APP}.app */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
w("/* End PBXGroup section */\n\n")

w(f"""/* Begin PBXNativeTarget section */
\t\t{T['target']} /* {APP} */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {T['cfg_target']} /* Build configuration list for PBXNativeTarget "{APP}" */;
\t\t\tbuildPhases = (
\t\t\t\t{T['sources']} /* Sources */,
\t\t\t\t{T['frameworks']} /* Frameworks */,
\t\t\t\t{T['resources']} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = {APP};
\t\t\tproductName = {APP};
\t\t\tproductReference = {T['product']} /* {APP}.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{T['project']} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1600;
\t\t\t\tLastUpgradeCheck = 1600;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{T['target']} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {T['cfg_proj']} /* Build configuration list for PBXProject "{APP}" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = ru;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\tru,
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {T['main']};
\t\t\tproductRefGroup = {T['products']} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{T['target']} /* {APP} */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{T['resources']} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{T['assets_build']} /* Assets.xcassets in Resources */,
\t\t\t\t{T['privacy_build']} /* PrivacyInfo.xcprivacy in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{T['sources']} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
""")
for g, f in swift:
    w(f"\t\t\t\t{oid('build', g, f)} /* {f} in Sources */,\n")
w("\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n/* End PBXSourcesBuildPhase section */\n\n")

common_proj = """\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;
\t\t\t\tMTL_FAST_MATH = YES;
\t\t\t\tSDKROOT = iphoneos;
"""
debug_extra = """\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
"""
release_extra = """\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;
"""
target_settings = f"""\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "{DISPLAY}";
\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.education";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIStatusBarStyle = UIStatusBarStyleLightContent;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
\t\t\t\tSUPPORTS_MACCATALYST = NO;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
"""


def cfg(key, name, body):
    return f"\t\t{T[key]} /* {name} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {{\n{body}\t\t\t}};\n\t\t\tname = {name};\n\t\t}};\n"


w("/* Begin XCBuildConfiguration section */\n")
w(cfg("proj_debug", "Debug", common_proj + debug_extra))
w(cfg("proj_release", "Release", common_proj + release_extra))
w(cfg("tgt_debug", "Debug", target_settings))
w(cfg("tgt_release", "Release", target_settings))
w("/* End XCBuildConfiguration section */\n\n")

w(f"""/* Begin XCConfigurationList section */
\t\t{T['cfg_proj']} /* Build configuration list for PBXProject "{APP}" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{T['proj_debug']} /* Debug */,
\t\t\t\t{T['proj_release']} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{T['cfg_target']} /* Build configuration list for PBXNativeTarget "{APP}" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{T['tgt_debug']} /* Debug */,
\t\t\t\t{T['tgt_release']} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {T['project']} /* Project object */;
}}
""")

proj_dir = os.path.join(ROOT, APP + ".xcodeproj")
os.makedirs(os.path.join(proj_dir, "xcshareddata", "xcschemes"), exist_ok=True)
with open(os.path.join(proj_dir, "project.pbxproj"), "w") as fh:
    fh.write("".join(out))

ref = f"""BuildableIdentifier = "primary"
               BlueprintIdentifier = "{T['target']}"
               BuildableName = "{APP}.app"
               BlueprintName = "{APP}"
               ReferencedContainer = "container:{APP}.xcodeproj\""""
scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               {ref}>
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            {ref.replace(chr(10) + '               ', chr(10) + '            ')}>
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            {ref.replace(chr(10) + '               ', chr(10) + '            ')}>
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
with open(os.path.join(proj_dir, "xcshareddata", "xcschemes", APP + ".xcscheme"), "w") as fh:
    fh.write(scheme)
print(f"OK: {len(swift)} Swift files → {APP}.xcodeproj")
