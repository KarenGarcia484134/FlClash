import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/common/request.dart';
import 'package:flutter_test/flutter_test.dart';

class _StalledHttpClient extends Fake implements HttpClient {
  @override
  Duration? connectionTimeout;

  @override
  String Function(Uri url)? findProxy;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Completer<HttpClientRequest>().future;
}

class _HostAdapter implements HttpClientAdapter {
  _HostAdapter(this.byHost);

  final Map<String, ResponseBody Function()> byHost;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return byHost[options.uri.host]!();
  }

  @override
  void close({bool force = false}) {}
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.uris);

  final List<Uri> uris;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    uris.add(options.uri);
    return ResponseBody.fromString(
      '{"tag_name":"v0.9.16"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getTextResponseForUrl propagates the typed DioException', () async {
    // flutter_test's mocked HttpClient answers every request with HTTP 400,
    // which Dio surfaces as a badResponse DioException.
    await expectLater(
      request.getTextResponseForUrl('http://127.0.0.1/anything'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.badResponse,
        ),
      ),
    );
  });

  test('getFileResponseForUrl propagates the typed DioException', () async {
    await expectLater(
      request.getFileResponseForUrl('http://127.0.0.1/anything'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.badResponse,
        ),
      ),
    );
  });

  group('latestRelease', () {
    Request requestAnswering(Map<String, ResponseBody Function()> byHost) {
      return Request()..dio.httpClientAdapter = _HostAdapter(byHost);
    }

    test('reads the release from the API', () async {
      final request = requestAnswering({
        'api.github.com': () => ResponseBody.fromString(
          '{"tag_name":"v1.2.3","body":"notes"}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      });

      expect(await request.latestRelease(), {
        'tag_name': 'v1.2.3',
        'body': 'notes',
      });
    });

    test(
      'falls back to the release page when the API is rate limited',
      () async {
        final request = requestAnswering({
          'api.github.com': () => ResponseBody.fromString('{}', 403),
          'github.com': () => ResponseBody.fromString(
            '',
            302,
            headers: {
              HttpHeaders.locationHeader: [
                'https://github.com/owner/repo/releases/tag/v1.2.4',
              ],
            },
          ),
        });

        expect(await request.latestRelease(), {'tag_name': 'v1.2.4'});
      },
    );

    test('fails instead of answering when neither endpoint does', () async {
      final request = requestAnswering({
        'api.github.com': () => ResponseBody.fromString('{}', 403),
        'github.com': () => ResponseBody.fromString('', 503),
      });

      await expectLater(request.latestRelease(), throwsA(isA<DioException>()));
    });
  });

  group('isNewerRelease', () {
    Map<String, dynamic> release(
      String tag, {
      bool prerelease = false,
      bool draft = false,
    }) => {'tag_name': tag, 'prerelease': prerelease, 'draft': draft};

    test('a higher release tag is an update', () {
      expect(isNewerRelease(release('v0.9.16'), '0.9.15'), isTrue);
      expect(isNewerRelease(release('v0.10.0'), '0.9.15'), isTrue);
      expect(isNewerRelease({'tag_name': 'v0.9.16'}, '0.9.15'), isTrue);
    });

    test('the same or an older tag is not', () {
      expect(isNewerRelease(release('v0.9.15'), '0.9.15'), isFalse);
      expect(isNewerRelease(release('v0.9.9'), '0.9.15'), isFalse);
      // Upstream's numbering is behind the fork's.
      expect(isNewerRelease(release('v0.9.1'), '0.9.15'), isFalse);
    });

    test('preview builds, prereleases and drafts never prompt', () {
      expect(
        isNewerRelease(
          release('build-main-20261018-abc1234', prerelease: true),
          '0.9.15',
        ),
        isFalse,
      );
      expect(
        isNewerRelease(release('build-main-20261018-abc1234'), '0.9.15'),
        isFalse,
      );
      expect(
        isNewerRelease(release('v0.9.16', prerelease: true), '0.9.15'),
        isFalse,
      );
      expect(isNewerRelease(release('v0.9.16-pre.1'), '0.9.15'), isFalse);
      expect(
        isNewerRelease(release('v0.9.16', draft: true), '0.9.15'),
        isFalse,
      );
      expect(isNewerRelease({'tag_name': null}, '0.9.15'), isFalse);
    });
  });

  group('release links', () {
    test('point at the fork', () {
      expect(repository, 'KarenGarcia484134/FlClash');
      expect(
        releasePageUrl('v0.9.16'),
        'https://github.com/KarenGarcia484134/FlClash/releases/tag/v0.9.16',
      );
    });

    test('fall back to the latest release without a usable tag', () {
      const latest =
          'https://github.com/KarenGarcia484134/FlClash/releases/latest';
      expect(releasePageUrl(null), latest);
      expect(releasePageUrl(' '), latest);
      expect(releasePageUrl('a/b'), latest);
    });

    test('the latest-release lookup asks the fork', () async {
      final hosts = <Uri>[];
      final request = Request()
        ..dio.httpClientAdapter = _RecordingAdapter(hosts);

      await request.latestRelease();

      expect(
        hosts.single.toString(),
        'https://api.github.com/repos/KarenGarcia484134/FlClash/releases/latest',
      );
    });
  });

  group('downloadTarget', () {
    test('sends a URL without credentials unchanged', () {
      final target = downloadTarget('https://example.com/a.yaml?x=1');

      expect(target.uri.toString(), 'https://example.com/a.yaml?x=1');
      expect(target.headers, isEmpty);
    });

    test('moves decoded credentials into the Authorization header', () {
      for (final url in [
        'https://me@mail.com:p:w@dav.example.com/dav/a.yaml',
        'https://me%40mail.com:p%3Aw@dav.example.com/dav/a.yaml',
      ]) {
        final target = downloadTarget(url);

        expect(target.uri.toString(), 'https://dav.example.com/dav/a.yaml');
        expect(
          target.headers[HttpHeaders.authorizationHeader],
          'Basic ${base64.encode(utf8.encode('me@mail.com:p:w'))}',
        );
      }
    });
  });

  group('decompressUnlabeled', () {
    final yaml = utf8.encode('proxies: []\n');

    test('inflates a gzip or zlib body that arrived unlabeled', () {
      for (final codec in [gzip, zlib]) {
        final body = Uint8List.fromList(codec.encode(yaml));

        expect(decompressUnlabeled(body), yaml);
      }
    });

    test('leaves a plain body untouched', () {
      final body = Uint8List.fromList(yaml);

      expect(decompressUnlabeled(body), same(body));
    });

    test('keeps a body that only starts like gzip', () {
      final body = Uint8List.fromList([0x1f, 0x8b, 1, 2, 3]);

      expect(decompressUnlabeled(body), same(body));
    });
  });

  testWidgets('a stalled download fails at the shared download deadline', (
    tester,
  ) async {
    late final Future<Response<String>> pending;
    HttpOverrides.runZoned(() {
      pending = Request().getTextResponseForUrl('http://127.0.0.1/stalled');
    }, createHttpClient: (_) => _StalledHttpClient());
    var settled = false;
    final outcome = expectLater(
      pending.whenComplete(() => settled = true),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.receiveTimeout,
        ),
      ),
    );

    await tester.pump(downloadTimeoutDuration - const Duration(seconds: 1));
    expect(settled, isFalse);
    await tester.pump(const Duration(seconds: 1));
    await outcome;
  });
}
