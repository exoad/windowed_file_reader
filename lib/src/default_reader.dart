import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:windowed_file_reader/windowed_file_reader.dart';

/// The default sliding window implementation that can be used for most tasks with various safety checks.
class DefaultWindowedFileReader extends WindowedFileReader<Uint8List> {
  final int _windowSize;

  late int _ptrStart;
  late int _ptrEnd;
  late int _fileLength;

  int _actualDataLength = 0;
  final Uint8List _window;
  RandomAccessFile? _raf;
  bool _isReading = false;
  bool _isInitialized = false;

  DefaultWindowedFileReader(super.file, {required int windowSize})
    : _window = Uint8List(windowSize),
      _windowSize = windowSize,
      assert(windowSize > 0, "Window size must be greater than 0!");

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    if (!await file.exists()) {
      throw WindowedFileReaderException("File does not exist: ${file.path}");
    }
    _raf = await file.open();
    _fileLength = await _raf!.length();
    _isInitialized = true;
  }

  @override
  Future<bool> canJumpTo(int position) async {
    await _ensureInitialized();
    return super.canJumpTo(position);
  }

  @override
  Future<void> jumpTo(int position) async {
    if (await canJumpTo(position)) {
      _ptrStart = position;
      _ptrEnd = _ptrStart + _windowSize;
      await _read();
    }
  }

  @override
  Future<bool> canShiftBy(int increment) async {
    await _ensureInitialized();
    final int newStart = _ptrStart + increment;
    final int newEnd = _ptrEnd + increment;
    return newStart >= 0 && newEnd <= _fileLength && newStart < newEnd;
  }

  @override
  Future<void> shiftBy(int increment) async {
    if (!await canShiftBy(increment)) {
      throw WindowedFileReaderException(
        "Cannot shift by $increment: would move pointers out of bounds "
        "(current: $_ptrStart-$_ptrEnd, file length: $_fileLength)",
      );
    }
    _ptrStart += increment;
    _ptrEnd += increment;
    final int absIncrement = increment.abs();
    if (absIncrement >= windowSize) {
      await _read();
    } else if (increment > 0) {
      await _shiftForward(increment);
    } else if (increment < 0) {
      await _shiftBackward(absIncrement);
    }
  }

  @override
  Uint8List view() {
    return _window.asUnmodifiableView();
  }

  /// Returns the current data held as a [String] if possible.
  String viewAsString() {
    if (_actualDataLength == 0) {
      return "";
    }
    try {
      return utf8.decode(_window.sublist(0, _actualDataLength));
    } catch (e) {
      return String.fromCharCodes(_window.sublist(0, _actualDataLength));
    }
  }

  int get leadingPointer {
    return _ptrStart;
  }

  int get trailingPointer {
    return _ptrEnd;
  }

  bool get isReading {
    return _isReading;
  }

  @override
  int get fileLengthInBytes {
    return _fileLength;
  }

  int get actualDataLength {
    return _actualDataLength;
  }

  @override
  Future<void> dispose() async {
    await _raf?.close();
    _raf = null;
    _isInitialized = false;
  }

  @override
  int get windowSize {
    return _windowSize;
  }

  Future<void> _shiftForward(int increment) async {
    _isReading = true;
    try {
      final int keepCount = windowSize - increment;
      _window.setRange(0, keepCount, _window, increment);
      final int readStart = _ptrStart + keepCount;
      if (readStart < _fileLength) {
        await _raf!.setPosition(readStart);
        final Uint8List bytes = await _raf!.read((increment).clamp(0, _fileLength - readStart));
        _window.setRange(keepCount, keepCount + bytes.length, bytes);
        _actualDataLength = keepCount + bytes.length;
      } else {
        _actualDataLength = keepCount;
      }
    } finally {
      _isReading = false;
    }
  }

  Future<void> _shiftBackward(int decrement) async {
    _isReading = true;
    try {
      final int keepCount = windowSize - decrement;
      final Uint8List temp = Uint8List(keepCount);
      temp.setRange(0, keepCount, _window, 0);
      _window.setRange(decrement, decrement + keepCount, temp);
      await _raf!.setPosition(_ptrStart);
      final Uint8List bytes = await _raf!.read(decrement.clamp(0, _fileLength - _ptrStart));
      _window.setRange(0, bytes.length, bytes);
      _actualDataLength = bytes.length + keepCount;
    } finally {
      _isReading = false;
    }
  }

  Future<void> _read() async {
    _isReading = true;
    try {
      await _raf!.setPosition(_ptrStart);
      final Uint8List bytes = await _raf!.read(
        (_ptrEnd - _ptrStart).clamp(0, _fileLength - _ptrStart),
      );
      _window.setRange(0, bytes.length, bytes);
      _actualDataLength = bytes.length;
    } finally {
      _isReading = false;
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  @override
  Future<void> refresh() async {
    await _read();
  }
}
