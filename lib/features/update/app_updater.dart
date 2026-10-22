import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:fl_clash/common/app_update.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

/// What this device can install, as [selectUpdateAsset] wants it.
Future<UpdateSelection?> selectUpdateForThisDevice(
  Map<String, dynamic> release,
) async {
  if (Platform.isAndroid) {
    final info = await DeviceInfoPlugin().androidInfo;
    return selectUpdateAsset(
      release,
      platform: UpdatePlatform.android,
      androidAbis: info.supportedAbis,
    );
  }
  if (Platform.isWindows) {
    return selectUpdateAsset(release, platform: UpdatePlatform.windows);
  }
  if (Platform.isMacOS) {
    return selectUpdateAsset(
      release,
      platform: UpdatePlatform.macos,
      macArm64: await _isAppleSilicon(),
    );
  }
  return null;
}

/// sysctl answers for the machine even when the app runs under Rosetta.
Future<bool> _isAppleSilicon() async {
  try {
    final result = await Process.run('sysctl', ['-n', 'hw.optional.arm64']);
    return result.stdout.toString().trim() == '1';
  } catch (_) {
    return false;
  }
}

class UpdateFailure implements Exception {
  const UpdateFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Downloads, checks and opens the update. Returns false when the user
/// cancelled; throws [UpdateFailure] for anything the page could fix.
Future<bool> runAppUpdate(
  UpdateSelection selection, {
  required Future<void> Function() exitApp,
}) async {
  final directory = Directory(
    join((await getTemporaryDirectory()).path, 'flclash-update'),
  );
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
  await directory.create(recursive: true);
  final file = File(join(directory.path, selection.asset.name));
  final downloaded = await dialogs.showCommonDialog<Object>(
    dismissible: false,
    child: _UpdateDownloadDialog(selection: selection, file: file),
  );
  if (downloaded is UpdateFailure) {
    throw downloaded;
  }
  if (downloaded != true) {
    return false;
  }
  await _install(selection.asset, file, exitApp: exitApp);
  return true;
}

Future<void> _install(
  UpdateAsset asset,
  File file, {
  required Future<void> Function() exitApp,
}) async {
  final appLocalizations = currentAppLocalizations;
  try {
    switch (asset.kind) {
      case UpdateInstallKind.apk:
        var state = await App().installApk(file.path);
        while (state == 'permission') {
          final again = await dialogs.showMessage(
            message: TextSpan(text: appLocalizations.allowUnknownAppsTip),
            confirmText: appLocalizations.continueInstall,
          );
          if (again != true) {
            return;
          }
          state = await App().installApk(file.path);
        }
      case UpdateInstallKind.installer:
        await Process.start(
          file.path,
          const [],
          mode: ProcessStartMode.detached,
        );
        await exitApp();
      case UpdateInstallKind.dmg:
        final result = await Process.run('open', [file.path]);
        if (result.exitCode != 0) {
          throw ProcessException('open', [file.path], '${result.stderr}');
        }
        unawaited(
          dialogs.showMessage(
            message: TextSpan(text: appLocalizations.updateDmgOpened),
            cancelable: false,
          ),
        );
    }
  } catch (error) {
    throw UpdateFailure(
      appLocalizations.updateInstallFailed(compactError(error)),
    );
  }
}

/// Downloads [selection] into [file] and checks it, popping true when it is
/// ready, an [UpdateFailure], or null when cancelled.
Future<void> downloadAndVerifyUpdate(
  UpdateSelection selection,
  File file, {
  required CancelToken cancelToken,
  void Function(int received, int total)? onProgress,
  Future<String?> Function(String url)? fetchChecksums,
  Future<void> Function(
    String url,
    String path,
    CancelToken cancelToken,
    void Function(int, int)? onProgress,
  )?
  download,
}) async {
  final fetch = fetchChecksums ?? _fetchChecksums;
  final get =
      download ??
      (url, path, token, progress) => request.downloadToFile(
        url,
        path,
        cancelToken: token,
        onProgress: progress,
      );
  final appLocalizations = currentAppLocalizations;
  String? expected;
  final sumsUrl = selection.checksumsUrl;
  if (sumsUrl != null) {
    String? text;
    try {
      text = await fetch(sumsUrl);
    } catch (error) {
      if (selection.checksumRequired) {
        throw UpdateFailure(
          appLocalizations.updateDownloadFailed(compactError(error)),
        );
      }
    }
    if (text != null) {
      expected = parseChecksums(text)[selection.asset.name];
      if (expected == null && selection.checksumRequired) {
        throw UpdateFailure(appLocalizations.updateChecksumMismatch);
      }
    }
  }
  try {
    await get(selection.asset.url, file.path, cancelToken, onProgress);
  } on DioException catch (error) {
    if (CancelToken.isCancel(error)) {
      rethrow;
    }
    throw UpdateFailure(
      appLocalizations.updateDownloadFailed(compactError(error)),
    );
  }
  if (expected != null && await sha256OfFile(file) != expected) {
    await file.delete();
    throw UpdateFailure(appLocalizations.updateChecksumMismatch);
  }
}

Future<String?> _fetchChecksums(String url) async {
  final response = await request.getTextResponseForUrl(url);
  return response.data;
}

class _UpdateDownloadDialog extends StatefulWidget {
  const _UpdateDownloadDialog({required this.selection, required this.file});

  final UpdateSelection selection;
  final File file;

  @override
  State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  final _cancelToken = CancelToken();
  final _progress = ValueNotifier<(int, int)>((0, 0));

  @override
  void initState() {
    super.initState();
    _progress.value = (0, widget.selection.asset.size ?? 0);
    unawaited(_start());
  }

  Future<void> _start() async {
    Object? result;
    try {
      await downloadAndVerifyUpdate(
        widget.selection,
        widget.file,
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          _progress.value = (
            received,
            total > 0 ? total : widget.selection.asset.size ?? 0,
          );
        },
      );
      result = true;
    } on UpdateFailure catch (failure) {
      result = failure;
    } on DioException catch (error) {
      result = CancelToken.isCancel(error)
          ? null
          : UpdateFailure(
              currentAppLocalizations.updateDownloadFailed(compactError(error)),
            );
    } catch (error) {
      result = UpdateFailure(
        currentAppLocalizations.updateDownloadFailed(compactError(error)),
      );
    }
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  void dispose() {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel();
    }
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonDialog(
      title: appLocalizations.downloadingUpdate,
      actions: [
        TextButton(
          onPressed: () => _cancelToken.cancel(),
          child: Text(appLocalizations.cancel),
        ),
      ],
      child: ValueListenableBuilder(
        valueListenable: _progress,
        builder: (_, value, _) {
          final (received, total) = value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(widget.selection.asset.name),
              LinearProgressIndicator(
                value: total > 0 ? (received / total).clamp(0, 1) : null,
              ),
              Text(
                total > 0
                    ? '${received.traffic.show} / ${total.traffic.show}'
                    : received.traffic.show,
              ),
            ],
          );
        },
      ),
    );
  }
}
