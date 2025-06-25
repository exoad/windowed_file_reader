import 'dart:io';
import 'dart:typed_data';

import 'package:windowed_file_reader/windowed_file_reader.dart';

/// An unsafe windowed file reader that does not perform additional bounds checking and initialization checking. Useful
// for decently footprint critical tasks, but does equate to almost the same performance as the default implementation.
/// **Reserve the usage of this reader to where the bounds and everything can be guranteed STATICALLY.**
class UnsafeWindowedFileReader extends WindowedFileReader<Uint8List> {
  final int _windowSize;

  late int _ptrStart;
  late int _ptrEnd;
  late int _fileLength;

  int _actualDataLength = 0;
  final Uint8List _window;
  late RandomAccessFile _raf;

  UnsafeWindowedFileReader(super.file, {required int windowSize})
    : _window = Uint8List(windowSize),
      _windowSize = windowSize;

  @override
  Future<void> initialize() async {
    _raf = await file.open();
    _fileLength = await _raf.length();
  }

  @override
  Future<bool> canJumpTo(int position) async {
    return super.canJumpTo(position);
  }

  @override
  Future<void> jumpTo(int position) async {
    _ptrStart = position;
    _ptrEnd = _ptrStart + _windowSize;
    await _raf.setPosition(_ptrStart);
    final Uint8List bytes = await _raf.read(_ptrEnd - _ptrStart);
    _window.setRange(0, bytes.length, bytes);
    _actualDataLength = bytes.length;
  }

  @override
  Future<bool> canShiftBy(int increment) async {
    final int newStart = _ptrStart + increment;
    final int newEnd = _ptrEnd + increment;
    return newStart >= 0 && newEnd <= _fileLength && newStart < newEnd;
  }

  @override
  Future<void> shiftBy(int increment) async {
    _ptrStart += increment;
    _ptrEnd += increment;
    await _raf.setPosition(_ptrStart);
    final Uint8List bytes = await _raf.read(
      _windowSize,
    ); // no more optimization logic and just "full reads"
    _window.setRange(0, bytes.length, bytes);
    _actualDataLength = bytes.length;
  }

  @override
  Uint8List view() {
    return _window;
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
    await _raf.close();
  }

  @override
  int get windowSize {
    return _windowSize;
  }
}
