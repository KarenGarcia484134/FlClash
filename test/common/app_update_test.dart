import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:fl_clash/common/app_update.dart';
import 'package:fl_clash/features/update/app_updater.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = 'https://github.com/KarenGarcia484134/FlClash/releases/download';

Map<String, dynamic> _release({bool withSums = true}) => {
  'tag_name': 'v0.9.21',
  'assets': [
    for (final name in [
      'FlClash-0.9.21-android-arm64-v8a.apk',
      'FlClash-0.9.21-android-armeabi-v7a.apk',
      'FlClash-0.9.21-android-x86_64.apk',
      'FlClash-0.9.21-windows-amd64-setup.exe',
      'FlClash-0.9.21-windows-amd64.zip',
      'FlClash-0.9.21-macos-arm64.dmg',
      'FlClash-0.9.21-macos-amd64.dmg',
      'FlClash-0.9.21-linux-amd64.AppImage',
      if (withSums) checksumsAssetName,
    ])
      {
        'name': name,
        'size': 10,
        'browser_download_url': '$_base/v0.9.21/$name',
      },
  ],
};

void main() {
  group('selectUpdateAsset', () {
    test('Android takes the first supported ABI it publishes', () {
      final selection = selectUpdateAsset(
        _release(),
        platform: UpdatePlatform.android,
        androidAbis: ['x86', 'armeabi-v7a', 'armeabi'],
      )!;
      expect(selection.asset.name, 'FlClash-0.9.21-android-armeabi-v7a.apk');
      expect(selection.asset.kind, UpdateInstallKind.apk);
      expect(selection.checksumRequired, isTrue);
      expect(selection.checksumsUrl, '$_base/v0.9.21/SHA256SUMS');
    });

    test('Android with no published ABI falls back to the page', () {
      expect(
        selectUpdateAsset(
          _release(),
          platform: UpdatePlatform.android,
          androidAbis: ['mips'],
        ),
        isNull,
      );
    });

    test('Windows takes the installer, never the zip', () {
      final selection = selectUpdateAsset(
        _release(),
        platform: UpdatePlatform.windows,
      )!;
      expect(selection.asset.name, 'FlClash-0.9.21-windows-amd64-setup.exe');
      expect(selection.asset.kind, UpdateInstallKind.installer);
      final release = _release();
      (release['assets'] as List).removeWhere(
        (asset) => (asset as Map)['name'].toString().endsWith('.exe'),
      );
      expect(
        selectUpdateAsset(release, platform: UpdatePlatform.windows),
        isNull,
      );
    });

    test('macOS matches the chip', () {
      String name(bool arm) => selectUpdateAsset(
        _release(),
        platform: UpdatePlatform.macos,
        macArm64: arm,
      )!.asset.name;
      expect(name(true), 'FlClash-0.9.21-macos-arm64.dmg');
      expect(name(false), 'FlClash-0.9.21-macos-amd64.dmg');
    });

    test('Linux opens the page', () {
      expect(
        selectUpdateAsset(_release(), platform: UpdatePlatform.linux),
        isNull,
      );
    });

    test('a release without assets builds the URLs from the names', () {
      final selection = selectUpdateAsset(
        {'tag_name': 'v0.9.21'},
        platform: UpdatePlatform.android,
        androidAbis: ['arm64-v8a'],
      )!;
      expect(
        selection.asset.url,
        '$_base/v0.9.21/FlClash-0.9.21-android-arm64-v8a.apk',
      );
      expect(selection.checksumRequired, isFalse);
    });

    test('a release without SHA256SUMS needs no checksum', () {
      final selection = selectUpdateAsset(
        _release(withSums: false),
        platform: UpdatePlatform.windows,
      )!;
      expect(selection.checksumsUrl, isNull);
    });
  });

  test('parseChecksums reads sha256sum output', () {
    final hash = 'a' * 64;
    expect(
      parseChecksums('$hash  ./FlClash.apk\n${'B' * 64} *other.dmg\njunk\n'),
      {'FlClash.apk': hash, 'other.dmg': 'b' * 64},
    );
  });

  group('downloadAndVerifyUpdate', () {
    late Directory directory;
    final bytes = utf8.encode('apk bytes');
    final hash = sha256.convert(bytes).toString();

    setUpAll(() => AppLocalizations.load(const Locale('en')));
    setUp(() => directory = Directory.systemTemp.createTempSync('update'));
    tearDown(() => directory.deleteSync(recursive: true));

    UpdateSelection selection({bool required = true}) => UpdateSelection(
      asset: const UpdateAsset(
        name: 'FlClash.apk',
        url: 'https://example/FlClash.apk',
        kind: UpdateInstallKind.apk,
      ),
      checksumsUrl: 'https://example/SHA256SUMS',
      checksumRequired: required,
    );

    Future<void> fakeDownload(
      String url,
      String path,
      CancelToken token,
      void Function(int, int)? progress,
    ) async {
      File(path).writeAsBytesSync(bytes);
      progress?.call(bytes.length, bytes.length);
    }

    test('keeps a file that matches its checksum', () async {
      final file = File('${directory.path}/FlClash.apk');
      await downloadAndVerifyUpdate(
        selection(),
        file,
        cancelToken: CancelToken(),
        fetchChecksums: (_) async => '$hash  FlClash.apk',
        download: fakeDownload,
      );
      expect(file.existsSync(), isTrue);
    });

    test('deletes a file that fails its checksum', () async {
      final file = File('${directory.path}/FlClash.apk');
      await expectLater(
        downloadAndVerifyUpdate(
          selection(),
          file,
          cancelToken: CancelToken(),
          fetchChecksums: (_) async => '${'0' * 64}  FlClash.apk',
          download: fakeDownload,
        ),
        throwsA(isA<UpdateFailure>()),
      );
      expect(file.existsSync(), isFalse);
    });

    test(
      'a listed but unreadable SHA256SUMS fails before downloading',
      () async {
        var downloaded = false;
        await expectLater(
          downloadAndVerifyUpdate(
            selection(),
            File('${directory.path}/FlClash.apk'),
            cancelToken: CancelToken(),
            fetchChecksums: (_) async => throw const SocketException('down'),
            download: (url, path, token, progress) async => downloaded = true,
          ),
          throwsA(isA<UpdateFailure>()),
        );
        expect(downloaded, isFalse);
      },
    );

    test('an optional SHA256SUMS that is missing is skipped', () async {
      final file = File('${directory.path}/FlClash.apk');
      await downloadAndVerifyUpdate(
        selection(required: false),
        file,
        cancelToken: CancelToken(),
        fetchChecksums: (_) async => throw const SocketException('404'),
        download: fakeDownload,
      );
      expect(file.existsSync(), isTrue);
    });

    test('a download error becomes a failure with the page fallback', () async {
      await expectLater(
        downloadAndVerifyUpdate(
          selection(required: false),
          File('${directory.path}/FlClash.apk'),
          cancelToken: CancelToken(),
          fetchChecksums: (_) async => null,
          download: (url, path, token, progress) async => throw DioException(
            requestOptions: RequestOptions(path: url),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        throwsA(isA<UpdateFailure>()),
      );
    });
  });
}
