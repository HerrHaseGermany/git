#!/usr/bin/env python3
"""Generate a dependency-free Xcode project for the macOS host and widget."""
from pathlib import Path
import hashlib, plistlib
root = Path(__file__).resolve().parents[1]
objects = {}
def ident(name): return hashlib.sha1(name.encode()).hexdigest()[:24].upper()
def add(name, body):
    key = ident(name); objects[key] = body; return key
def arr(values): return '(' + ', '.join(values) + ',)'
def q(s): return '"' + s + '"'
files = {}
for path in ['Shared/Contributions.swift', 'Shared/HeatmapView.swift', 'App/GitHubActivityApp.swift', 'Widget/ActivityWidget.swift', 'Shared/ProfileIntent.swift', 'Shared/ProfileLink.swift', 'Shared/WidgetAppearance.swift', 'Shared/GitHubAPI.swift', 'Shared/GitHubProfileStore.swift']:
    files[path] = add(path, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(path)}; sourceTree = "<group>";')
localized = [add('strings-' + lang, f'isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {lang}; path = Resources/{lang}.lproj/Localizable.strings; sourceTree = "<group>";') for lang in ['en', 'de']]
strings = add('strings', f'isa = PBXVariantGroup; children = {arr(localized)}; name = Localizable.strings; sourceTree = "<group>";')
icon = add('icon', 'isa = PBXFileReference; lastKnownFileType = image.icns; path = Resources/AppIcon.icns; sourceTree = "<group>";')
assets = add('assets', 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Resources/Assets.xcassets; sourceTree = "<group>";')
appProduct = add('app-product', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = "GitHub Activity.app"; sourceTree = BUILT_PRODUCTS_DIR;')
widgetProduct = add('widget-product', 'isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; path = GitHubActivityWidget.appex; sourceTree = BUILT_PRODUCTS_DIR;')
products = add('products', f'isa = PBXGroup; children = {arr([appProduct, widgetProduct])}; name = Products; sourceTree = "<group>";')
group = add('main-group', f'isa = PBXGroup; children = {arr(list(files.values()) + [strings, icon, assets, products])}; sourceTree = "<group>";')
projectID = ident('project')
widgetID = ident('Widget')
proxy = add('proxy', f'isa = PBXContainerItemProxy; containerPortal = {projectID}; proxyType = 1; remoteGlobalIDString = {widgetID}; remoteInfo = GitHubActivityWidget;')
dependency = add('dependency', f'isa = PBXTargetDependency; target = {widgetID}; targetProxy = {proxy};')
embedFile = add('embed-file', f'isa = PBXBuildFile; fileRef = {widgetProduct}; settings = {{ ATTRIBUTES = (RemoveHeadersOnCopy,); }};')
embed = add('embed', f'isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = {arr([embedFile])}; name = "Embed App Extensions"; runOnlyForDeploymentPostprocessing = 0;')
common = 'ALWAYS_SEARCH_USER_PATHS = NO; SDKROOT = macosx; MACOSX_DEPLOYMENT_TARGET = 14.0; SWIFT_VERSION = 5.0; CODE_SIGN_IDENTITY = "-"; CODE_SIGN_STYLE = Manual; ENABLE_HARDENED_RUNTIME = YES;'
def configs(name, settings):
    ids = []
    for mode in ['Debug', 'Release']:
        optimization = '-Onone' if mode == 'Debug' else '-O'
        ids.append(add(name + mode, f'isa = XCBuildConfiguration; buildSettings = {{ {common} {settings} SWIFT_OPTIMIZATION_LEVEL = "{optimization}"; }}; name = {mode};'))
    return add(name + 'configs', f'isa = XCConfigurationList; buildConfigurations = {arr(ids)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
targets=[]
for name, entry, product, bundle, productType in [
    ('App', 'App/GitHubActivityApp.swift', appProduct, 'de.raudzis.GitHubActivity', 'com.apple.product-type.application'),
    ('Widget', 'Widget/ActivityWidget.swift', widgetProduct, 'de.raudzis.GitHubActivity.Widget', 'com.apple.product-type.app-extension')]:
    signing_identifier = bundle
    bundle = bundle.lower()
    builds = [add(name + path, f'isa = PBXBuildFile; fileRef = {files[path]};') for path in ['Shared/Contributions.swift', 'Shared/HeatmapView.swift', 'Shared/ProfileIntent.swift', 'Shared/ProfileLink.swift', 'Shared/WidgetAppearance.swift', 'Shared/GitHubAPI.swift', 'Shared/GitHubProfileStore.swift', entry]]
    sources = add(name + 'sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {arr(builds)}; runOnlyForDeploymentPostprocessing = 0;')
    frameworks = add(name + 'frameworks', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
    resourceFile = add(name + 'strings-build', f'isa = PBXBuildFile; fileRef = {strings};')
    iconBuild = add(name + 'assets-build', f'isa = PBXBuildFile; fileRef = {assets};')
    resources = add(name + 'resources', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {arr([resourceFile, iconBuild])}; runOnlyForDeploymentPostprocessing = 0;')
    settings = f'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; PRODUCT_BUNDLE_IDENTIFIER = {bundle}; PRODUCT_NAME = {q("GitHub Activity" if name == "App" else "GitHubActivityWidget")}; INFOPLIST_FILE = {name}/Info.plist; CODE_SIGN_ENTITLEMENTS = {name}/{name}.entitlements; SKIP_INSTALL = {"YES" if name == "Widget" else "NO"};'
    if name == 'Widget': settings += ' APPLICATION_EXTENSION_API_ONLY = YES;'
    # Bundle IDs are case-insensitive, but the gallery bitmap resolver on this
    # Mac requires canonical lowercase IDs. Preserve signing IDs for Keychain ACLs.
    settings += f' OTHER_CODE_SIGN_FLAGS = "--identifier {signing_identifier}";'
    conf = configs(name, settings)
    phases = [sources, frameworks, resources] + ([embed] if name == 'App' else [])
    target = add(name, f'isa = PBXNativeTarget; buildConfigurationList = {conf}; buildPhases = {arr(phases)}; buildRules = (); dependencies = {arr([dependency]) if name == "App" else "()"}; name = {q("GitHubActivity" if name == "App" else "GitHubActivityWidget")}; productName = {name}; productReference = {product}; productType = {q(productType)};')
    targets.append(target)
    info = {'CFBundleDevelopmentRegion':'en', 'CFBundleExecutable':'$(EXECUTABLE_NAME)', 'CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)', 'CFBundleInfoDictionaryVersion':'6.0', 'CFBundleName':'$(PRODUCT_NAME)', 'CFBundlePackageType':'APPL' if name == 'App' else 'XPC!', 'CFBundleShortVersionString':'2.4', 'CFBundleVersion':'19', 'LSMinimumSystemVersion':'$(MACOSX_DEPLOYMENT_TARGET)'}
    info['CFBundleIconName'] = 'AppIcon'
    if name == 'Widget': info['NSExtension'] = {'NSExtensionPointIdentifier':'com.apple.widgetkit-extension'}
    else: info['NSPrincipalClass']='NSApplication'
    (root / name / 'Info.plist').write_bytes(plistlib.dumps(info))
    (root / name / f'{name}.entitlements').write_bytes(plistlib.dumps({'com.apple.security.app-sandbox':True,'com.apple.security.network.client':True}))
conf = configs('project', '')
add('project', f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; }}; buildConfigurationList = {conf}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (de, en, Base,); mainGroup = {group}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = {arr(targets)};')
proj = root / 'GitHubActivity.xcodeproj'
proj.mkdir(exist_ok=True)
(proj / 'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n' + '\n'.join(f'{key} = {{ {value} }};' for key,value in objects.items()) + f'\n}}; rootObject = {projectID}; }}\n')
