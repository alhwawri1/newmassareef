#!/usr/bin/env node
/**
 * Attaches MasareefWidget extension target, App Group entitlements,
 * and AppIcon assets to the generated Capacitor ios/App/App.xcodeproj.
 */
const fs = require('fs');
const path = require('path');
const xcode = require('xcode');

const projectRoot = process.cwd();
const iosAppDir = path.join(projectRoot, 'ios', 'App');
const pbxprojPath = path.join(iosAppDir, 'App.xcodeproj', 'project.pbxproj');

if (!fs.existsSync(pbxprojPath)) {
  console.error('Error: project.pbxproj not found at', pbxprojPath);
  process.exit(1);
}

const proj = xcode.project(pbxprojPath);
proj.parseSync();

const appBundleId = process.env.BUNDLE_ID || 'com.alhawari.masareef';
const widgetBundleId = process.env.WIDGET_BUNDLE_ID || 'com.alhawari.masareef.widget';
const appGroupId = process.env.APP_GROUP_ID || 'group.com.alhawari.masareef';

// Set bundle ID and App Group entitlements on main App target
proj.updateBuildProperty('PRODUCT_BUNDLE_IDENTIFIER', appBundleId);
proj.updateBuildProperty('CODE_SIGN_ENTITLEMENTS', 'App/App.entitlements');
proj.updateBuildProperty('IPHONEOS_DEPLOYMENT_TARGET', '16.0');

// Add bridge Swift file to main target if present
const bridgeRel = 'App/MasareefAppGroupBridge.swift';
if (fs.existsSync(path.join(iosAppDir, bridgeRel))) {
  try {
    proj.addSourceFile(bridgeRel, { target: proj.getFirstTarget().uuid });
  } catch (e) {
    console.warn('Note adding bridge file:', e.message);
  }
}

// Add MasareefWidget extension target if not already present
const existingTargets = proj.hash.project.objects.PBXNativeTarget || {};
const alreadyHasWidget = Object.values(existingTargets).some(
  (t) => t && (t.name === 'MasareefWidget' || t.name === '"MasareefWidget"')
);

if (!alreadyHasWidget) {
  const widgetTarget = proj.addTarget(
    'MasareefWidget',
    'app_extension',
    'MasareefWidget',
    widgetBundleId
  );

  if (widgetTarget && widgetTarget.uuid) {
    const widgetSwiftRel = 'MasareefWidget/MasareefWidget.swift';
    if (fs.existsSync(path.join(iosAppDir, widgetSwiftRel))) {
      proj.addSourceFile(widgetSwiftRel, { target: widgetTarget.uuid });
    }

    // Configure build settings for widget target
    const configs = proj.pbxXCBuildConfigurationSection();
    for (const key in configs) {
      const cfg = configs[key];
      if (!cfg || typeof cfg !== 'object' || !cfg.buildSettings) continue;
      if (
        cfg.buildSettings.PRODUCT_BUNDLE_IDENTIFIER === widgetBundleId ||
        cfg.buildSettings.INFOPLIST_FILE === 'MasareefWidget/Info.plist'
      ) {
        cfg.buildSettings.CODE_SIGN_ENTITLEMENTS = 'MasareefWidget/MasareefWidget.entitlements';
        cfg.buildSettings.INFOPLIST_FILE = 'MasareefWidget/Info.plist';
        cfg.buildSettings.IPHONEOS_DEPLOYMENT_TARGET = '16.0';
        cfg.buildSettings.SWIFT_VERSION = '5.0';
        cfg.buildSettings.CODE_SIGN_STYLE = 'Manual';
      }
    }
  }
}

fs.writeFileSync(pbxprojPath, proj.writeSync(), 'utf8');
console.log('Successfully configured Xcode project with App Group:', appGroupId);
