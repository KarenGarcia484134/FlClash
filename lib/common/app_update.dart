import 'dart:io';

import 'package:crypto/crypto.dart';

import 'constant.dart';

enum UpdatePlatform { android, windows, macos, linux, other }

enum UpdateInstallKind { apk, installer, dmg }

class UpdateAsset {
  const UpdateAsset({
    required this.name,
    required this.url,
    required this.kind,
    this.size,
  });

  final String name;
  final String url;
  final UpdateInstallKind kind;
  final int? size;
}

const checksumsAssetName = 'SHA256SUMS';

String? releaseVersionOf(String? tag) {
  final match = RegExp(r'^v?(\d+\.\d+\.\d+)$').firstMatch(tag?.trim() ?? '');
  return match?.group(1);
}

String releaseDownloadUrl(String tag, String name) =>
    'https://github.com/$repository/releases/download/$tag/$name';

/// The candidate file names for this device, best first.
List<(String, UpdateInstallKind)> updateAssetCandidates({
  required String version,
  required UpdatePlatform platform,
  List<String> androidAbis = const [],
  bool macArm64 = false,
}) {
  final prefix = 'FlClash-$version';
  switch (platform) {
    case UpdatePlatform.android:
      return [
        for (final abi in androidAbis)
          if (const ['arm64-v8a', 'armeabi-v7a', 'x86_64'].contains(abi))
            ('$prefix-android-$abi.apk', UpdateInstallKind.apk),
        ('$prefix-android-universal.apk', UpdateInstallKind.apk),
        ('$prefix-android.apk', UpdateInstallKind.apk),
      ];
    case UpdatePlatform.windows:
      return [('$prefix-windows-amd64-setup.exe', UpdateInstallKind.installer)];
    case UpdatePlatform.macos:
      return [
        if (macArm64) ('$prefix-macos-arm64.dmg', UpdateInstallKind.dmg),
        ('$prefix-macos-amd64.dmg', UpdateInstallKind.dmg),
      ];
    case UpdatePlatform.linux:
    case UpdatePlatform.other:
      return const [];
  }
}

/// Picks what to download from [release], or null to open the page instead.
///
/// The redirect fallback of the update check carries no asset list; the
/// names the release workflow gives its files stand in for it then.
UpdateSelection? selectUpdateAsset(
  Map<String, dynamic> release, {
  required UpdatePlatform platform,
  List<String> androidAbis = const [],
  bool macArm64 = false,
}) {
  final tag = release['tag_name'];
  final version = tag is String ? releaseVersionOf(tag) : null;
  if (version == null) {
    return null;
  }
  final candidates = updateAssetCandidates(
    version: version,
    platform: platform,
    androidAbis: androidAbis,
    macArm64: macArm64,
  );
  if (candidates.isEmpty) {
    return null;
  }
  final rawAssets = release['assets'];
  if (rawAssets is! List) {
    final (name, kind) = candidates.first;
    return UpdateSelection(
      asset: UpdateAsset(
        name: name,
        url: releaseDownloadUrl(tag as String, name),
        kind: kind,
      ),
      checksumsUrl: releaseDownloadUrl(tag, checksumsAssetName),
      checksumRequired: false,
    );
  }
  final assets = <String, Map>{
    for (final asset in rawAssets.whereType<Map>())
      if (asset['name'] is String) asset['name'] as String: asset,
  };
  for (final (name, kind) in candidates) {
    final asset = assets[name];
    final url = asset?['browser_download_url'];
    if (url is! String) {
      continue;
    }
    final sums = assets[checksumsAssetName]?['browser_download_url'];
    return UpdateSelection(
      asset: UpdateAsset(
        name: name,
        url: url,
        kind: kind,
        size: asset!['size'] is int ? asset['size'] as int : null,
      ),
      checksumsUrl: sums is String ? sums : null,
      checksumRequired: sums is String,
    );
  }
  return null;
}

class UpdateSelection {
  const UpdateSelection({
    required this.asset,
    required this.checksumsUrl,
    required this.checksumRequired,
  });

  final UpdateAsset asset;
  final String? checksumsUrl;

  /// The release listed SHA256SUMS, so failing to read it is an error.
  final bool checksumRequired;
}

/// Reads `sha256sum` output: `<hex>  <name>` or `<hex> *<name>` per line.
Map<String, String> parseChecksums(String text) {
  final sums = <String, String>{};
  for (final line in text.split('\n')) {
    final match = RegExp(
      r'^([0-9a-fA-F]{64})\s+\*?(.+?)\s*$',
    ).firstMatch(line.trim());
    if (match != null) {
      final name = match.group(2)!.split('/').last;
      sums[name] = match.group(1)!.toLowerCase();
    }
  }
  return sums;
}

Future<String> sha256OfFile(File file) async {
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}
