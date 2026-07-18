#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import sys
import xml.etree.ElementTree as ET
import shutil
import re
from pathlib import Path

ANDROID_NS = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", ANDROID_NS)
A = f"{{{ANDROID_NS}}}"

APP_CONFIG = {
    "passenger_flutter": {
        "label": "ASTRIDE",
        "package_id": "com.nexo.astride.passenger",
        "permissions": [
            "android.permission.INTERNET",
            "android.permission.ACCESS_NETWORK_STATE",
            "android.permission.ACCESS_FINE_LOCATION",
            "android.permission.ACCESS_COARSE_LOCATION",
            "android.permission.POST_NOTIFICATIONS",
            "android.permission.CAMERA",
        ],
        "plist": {
            "NSCameraUsageDescription": "ASTRIDE uses the camera for vehicle QR Scan & Go and only for photos/documents you choose.",
            "NSPhotoLibraryUsageDescription": "ASTRIDE accesses selected photos only when you choose a profile photo or document.",
            "NSLocationWhenInUseUsageDescription": "ASTRIDE uses your location to select pickup points and track an active ride.",
            "NSUserNotificationUsageDescription": "ASTRIDE notifications provide booking and safety updates.",
            "FirebaseAppDelegateProxyEnabled": True,
        },
    },
    "partner_flutter": {
        "label": "ASTRIDE Partner",
        "package_id": "com.nexo.astride.partner",
        "permissions": [
            "android.permission.INTERNET",
            "android.permission.ACCESS_NETWORK_STATE",
            "android.permission.POST_NOTIFICATIONS",
            "android.permission.CAMERA",
        ],
        "plist": {
            "NSCameraUsageDescription": "ASTRIDE Partner uses the camera only for selected photos or documents.",
            "NSPhotoLibraryUsageDescription": "ASTRIDE accesses selected photos only when you choose a profile photo or document.",
            "NSUserNotificationUsageDescription": "ASTRIDE Partner notifications provide driver performance and settlement updates.",
            "FirebaseAppDelegateProxyEnabled": True,
        },
    },
    "driver_flutter": {
        "label": "ASTRIDE Driver",
        "package_id": "com.nexo.astride.driver",
        "permissions": [
            "android.permission.INTERNET",
            "android.permission.ACCESS_NETWORK_STATE",
            "android.permission.ACCESS_FINE_LOCATION",
            "android.permission.ACCESS_COARSE_LOCATION",
            "android.permission.ACCESS_BACKGROUND_LOCATION",
            "android.permission.FOREGROUND_SERVICE",
            "android.permission.FOREGROUND_SERVICE_LOCATION",
            "android.permission.POST_NOTIFICATIONS",
            "android.permission.CAMERA",
            "android.permission.NFC",
        ],
        "plist": {
            "NSCameraUsageDescription": "ASTRIDE Driver uses the camera for approved route-card QR fallback and selected photos/documents.",
            "NSPhotoLibraryUsageDescription": "ASTRIDE accesses selected photos only when you choose a profile photo or document.",
            "NSLocationWhenInUseUsageDescription": "ASTRIDE Driver uses your location to receive nearby ride requests.",
            "NSLocationAlwaysAndWhenInUseUsageDescription": "Background location is used only while you are online or completing an active ride.",
            "NSUserNotificationUsageDescription": "ASTRIDE Driver notifications provide ride requests and safety updates.",
            "NFCReaderUsageDescription": "ASTRIDE Driver reads provisioned ASTRIDE prepaid cards for route Tap & Go.",
            "UIBackgroundModes": ["location", "fetch", "remote-notification"],
            "FirebaseAppDelegateProxyEnabled": True,
        },
    },
}


def patch_manifest(app_dir: Path, app: str) -> None:
    path = app_dir / "android/app/src/main/AndroidManifest.xml"
    tree = ET.parse(path)
    root = tree.getroot()
    existing = {el.get(A + "name") for el in root.findall("uses-permission")}
    insert_at = 0
    for permission in APP_CONFIG[app]["permissions"]:
        if permission not in existing:
            node = ET.Element("uses-permission", {A + "name": permission})
            root.insert(insert_at, node)
            insert_at += 1

    if app == "driver_flutter":
        feature = next((el for el in root.findall("uses-feature") if el.get(A + "name") == "android.hardware.nfc"), None)
        if feature is None:
            feature = ET.Element("uses-feature", {A + "name": "android.hardware.nfc", A + "required": "false"})
            root.insert(insert_at, feature)

    application = root.find("application")
    if application is None:
        raise RuntimeError("Generated AndroidManifest.xml has no application element")
    application.set(A + "label", APP_CONFIG[app]["label"])
    application.set(A + "usesCleartextTraffic", "false")

    if app != "partner_flutter":
        metadata_name = "com.google.android.geo.API_KEY"
        metadata = None
        for item in application.findall("meta-data"):
            if item.get(A + "name") == metadata_name:
                metadata = item
                break
        if metadata is None:
            metadata = ET.SubElement(application, "meta-data")
            metadata.set(A + "name", metadata_name)
        metadata.set(A + "value", "@string/google_maps_key")

    if app == "driver_flutter":
        service = None
        for item in application.findall("service"):
            if item.get(A + "name") == ".LocationForegroundService":
                service = item
                break
        if service is None:
            service = ET.SubElement(application, "service")
        service.set(A + "name", ".LocationForegroundService")
        service.set(A + "exported", "false")
        service.set(A + "foregroundServiceType", "location")

    path.parent.mkdir(parents=True, exist_ok=True)
    tree.write(path, encoding="utf-8", xml_declaration=True)

    package_id = APP_CONFIG[app]["package_id"]
    for build_name in ("build.gradle.kts", "build.gradle"):
        build_file = app_dir / "android/app" / build_name
        if not build_file.exists():
            continue
        content = build_file.read_text(encoding="utf-8")
        content = re.sub(r'namespace\s*=\s*["\'][^"\']+["\']', f'namespace = "{package_id}"', content)
        content = re.sub(r'applicationId\s*=\s*["\'][^"\']+["\']', f'applicationId = "{package_id}"', content)
        if app != "partner_flutter":
            if build_name.endswith('.kts'):
                if 'id("com.google.gms.google-services")' not in content:
                    content = content.replace('id("dev.flutter.flutter-gradle-plugin")', 'id("dev.flutter.flutter-gradle-plugin")\n    id("com.google.gms.google-services")')
            else:
                if "com.google.gms.google-services" not in content:
                    content = content.replace("id 'dev.flutter.flutter-gradle-plugin'", "id 'dev.flutter.flutter-gradle-plugin'\n    id 'com.google.gms.google-services'")
        build_file.write_text(content, encoding="utf-8")

    settings_file = app_dir / "android/settings.gradle.kts"
    if app != "partner_flutter" and settings_file.exists():
        content = settings_file.read_text(encoding="utf-8")
        if 'com.google.gms.google-services' not in content:
            marker = 'id("org.jetbrains.kotlin.android")'
            content = content.replace(marker, 'id("com.google.gms.google-services") version "4.4.2" apply false\n    ' + marker)
        settings_file.write_text(content, encoding="utf-8")

    # Move generated MainActivity into the canonical package.
    target = app_dir / "android/app/src/main/kotlin" / Path(*package_id.split('.'))
    target.mkdir(parents=True, exist_ok=True)
    for main_activity in list((app_dir / "android/app/src/main/kotlin").rglob("MainActivity.kt")):
        content = main_activity.read_text(encoding="utf-8")
        content = re.sub(r'^package\s+[^\n]+', f'package {package_id}', content, count=1, flags=re.M)
        destination = target / "MainActivity.kt"
        destination.write_text(content, encoding="utf-8")
        if main_activity.resolve() != destination.resolve():
            main_activity.unlink()

    if app == "driver_flutter":
        source = app_dir / "android_native/app/src/main/kotlin/in/astride/driver"
        for native_file in source.glob("*.kt"):
            content = native_file.read_text(encoding="utf-8")
            content = content.replace("package `in`.astride.driver", f"package {package_id}")
            (target / native_file.name).write_text(content, encoding="utf-8")

    patch_flag_secure(target / "MainActivity.kt")

    if app != "partner_flutter":
        values = app_dir / "android/app/src/main/res/values"
        values.mkdir(parents=True, exist_ok=True)
        (values / "astride_keys.xml").write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<resources>\n'
            '    <!-- Replaced in CI or local builds. Empty keeps compile-only builds safe. -->\n'
            '    <string name="google_maps_key">${GOOGLE_MAPS_ANDROID_KEY}</string>\n'
            '</resources>\n',
            encoding="utf-8",
        )


def patch_flag_secure(main_activity: Path) -> None:
    if not main_activity.exists():
        return
    content = main_activity.read_text(encoding="utf-8")
    if "android.os.Bundle" not in content:
        import_match = re.search(r"^import\s+", content, flags=re.M)
        imports = "import android.os.Bundle\nimport android.view.WindowManager\n"
        if import_match:
            content = content[:import_match.start()] + imports + content[import_match.start():]
        else:
            package_match = re.search(r"^package\s+[^\n]+\n", content, flags=re.M)
            if package_match:
                content = content[:package_match.end()] + "\n" + imports + content[package_match.end():]
            else:
                content = imports + content
    if "FLAG_SECURE" not in content:
        bodyless = re.compile(r"class\s+MainActivity\s*:\s*FlutterActivity\(\)\s*$", re.M)
        secure_class = (
            "class MainActivity : FlutterActivity() {\n"
            "    override fun onCreate(savedInstanceState: Bundle?) {\n"
            "        super.onCreate(savedInstanceState)\n"
            "        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)\n"
            "    }\n"
            "}"
        )
        if bodyless.search(content):
            content = bodyless.sub(secure_class, content, count=1)
        else:
            marker = "class MainActivity : FlutterActivity() {"
            override = (
                marker
                + "\n    override fun onCreate(savedInstanceState: Bundle?) {"
                + "\n        super.onCreate(savedInstanceState)"
                + "\n        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)"
                + "\n    }"
            )
            if marker not in content:
                raise RuntimeError(f"Unsupported MainActivity structure: {main_activity}")
            content = content.replace(marker, override, 1)
    main_activity.write_text(content, encoding="utf-8")


def patch_plist(app_dir: Path, app: str) -> None:
    path = app_dir / "ios/Runner/Info.plist"
    with path.open("rb") as fh:
        data = plistlib.load(fh)
    data.update(APP_CONFIG[app]["plist"])
    data["CFBundleDisplayName"] = APP_CONFIG[app]["label"]
    with path.open("wb") as fh:
        plistlib.dump(data, fh, sort_keys=False)

    if app == "driver_flutter":
        entitlements = app_dir / "ios/Runner/Runner.entitlements"
        entitlement_data = {}
        if entitlements.exists():
            with entitlements.open("rb") as fh:
                entitlement_data = plistlib.load(fh)
        entitlement_data["com.apple.developer.nfc.readersession.formats"] = ["TAG"]
        with entitlements.open("wb") as fh:
            plistlib.dump(entitlement_data, fh, sort_keys=False)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: patch_native.py <repo-root> passenger_flutter|driver_flutter|partner_flutter", file=sys.stderr)
        return 2
    root = Path(sys.argv[1]).resolve()
    app = sys.argv[2]
    if app not in APP_CONFIG:
        print(f"Unsupported app: {app}", file=sys.stderr)
        return 2
    app_dir = root / "apps" / app
    patch_manifest(app_dir, app)
    patch_plist(app_dir, app)
    print(f"Patched generated native projects for {app}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
