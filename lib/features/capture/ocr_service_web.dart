/// OCR untuk web memakai Tesseract.js. Gambar diproses di browser; pustaka dan
/// data bahasanya diunduh dari CDN saat pertama dipakai, jadi butuh internet.
library;

import 'dart:async';
import 'dart:js_interop';

const _scriptUrl =
    'https://cdn.jsdelivr.net/npm/tesseract.js@7.0.0/dist/tesseract.min.js';
const _languages = 'ind+eng';
const _timeout = Duration(seconds: 90);

@JS('Tesseract')
external JSObject? get _tesseract;

@JS('Tesseract.createWorker')
external JSPromise<_Worker> _createWorker(String languages);

extension type _Worker._(JSObject _) implements JSObject {
  external JSPromise<_Result> recognize(String image);
  external JSPromise<JSAny?> terminate();
}

extension type _Result._(JSObject _) implements JSObject {
  external _Data get data;
}

extension type _Data._(JSObject _) implements JSObject {
  external String get text;
}

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external _Script createElement(String tag);
  external _Head get head;
}

extension type _Head._(JSObject _) implements JSObject {
  external void appendChild(JSObject child);
}

extension type _Script._(JSObject _) implements JSObject {
  external set src(String value);
  external set onload(JSFunction value);
  external set onerror(JSFunction value);
  external void remove();
}

class OcrService {
  static Future<void>? _loading;
  Future<_Worker>? _worker;

  /// [imagePath] di web berupa URL "blob:" dari image_picker.
  Future<String> readText(String imagePath) async {
    await _loadScript().timeout(_timeout);
    final pending = _worker ??= _createWorker(_languages).toDart;
    try {
      final worker = await pending.timeout(_timeout);
      final result =
          await worker.recognize(imagePath).toDart.timeout(_timeout);
      return result.data.text;
    } catch (_) {
      await dispose(); // percobaan berikutnya mulai dari awal
      rethrow;
    }
  }

  Future<void> dispose() async {
    final pending = _worker;
    _worker = null;
    if (pending == null) return;
    // Tidak ditunggu: worker yang macet jangan sampai menahan layar.
    unawaited(
      pending
          .then((worker) => worker.terminate().toDart)
          .then<void>((_) {}, onError: (Object _) {}),
    );
  }

  static Future<void> _loadScript() {
    if (_tesseract != null) return Future<void>.value();
    return _loading ??= _injectScript();
  }

  static Future<void> _injectScript() {
    final done = Completer<void>();
    final script = _document.createElement('script');
    void onLoad(JSAny? event) => done.complete();
    void onError(JSAny? event) {
      _loading = null;
      script.remove();
      done.completeError(StateError('Gagal memuat Tesseract.js'));
    }

    script.src = _scriptUrl;
    script.onload = onLoad.toJS;
    script.onerror = onError.toJS;
    _document.head.appendChild(script);
    return done.future;
  }
}
