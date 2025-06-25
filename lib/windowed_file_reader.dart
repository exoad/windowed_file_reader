import "dart:io";

import "package:windowed_file_reader/src/default_reader.dart";
import "package:windowed_file_reader/src/unsafe_reader.dart";

export "src/exception.dart";
export "src/unsafe_reader.dart";
export "src/default_reader.dart";

/// Provides the default abstraction as well as serving for the basis for creating builtin
/// implementations such as [DefaultWindowedFileReader] through static methods.
///
/// The default abstraction for defining any kind of behavior for
/// the sliding window file readers.
abstract class WindowedFileReader<T> {
  /// Retrieves an instance of the default sliding window reader
  /// This reader provides proper safety checks and is able to cover most common tasks.
  static DefaultWindowedFileReader defaultReader({required File file, required int windowSize}) {
    return DefaultWindowedFileReader(file, windowSize: windowSize);
  }

  /// Retrieves an instance of the unsafe sliding window reader.
  /// This reader should be used with cautions as all bounds must be manually checked by external
  /// implementations or guranteed statically.
  static UnsafeWindowedFileReader unsafereader({required File file, required int windowSize}) {
    return UnsafeWindowedFileReader(file, windowSize: windowSize);
  }

  /// The file being read from.
  final File file;

  WindowedFileReader(this.file);

  /// Returns the size of the files in bytes
  int get fileLengthInBytes;

  /// Returns the window size (the internal data buffer size).
  int get windowSize;

  /// Facilitates lazy initialization for any I/O resources.
  Future<void> initialize();

  /// Jumps the window to [position], where [position] is always assigned to the leading pointer and the trailing
  /// pointer is calculated by subtracting using [windowSize]
  Future<void> jumpTo(int position);

  /// Checks if [position] is a valid position in the file, where [position] is always assigned to the leading pointer
  /// and the trailing pointer is calculated by subtracting using [windowSize]
  Future<bool> canJumpTo(int position) async {
    return position >= 0 && (position + windowSize) <= fileLengthInBytes;
  }

  /// Returns current internal buffer data
  T view();

  /// A helper function that calls [jumpTo] with `0` to move the window to the start of the file.
  Future<void> jumpToStart() async {
    await jumpTo(0);
  }

  /// A helper function that calls [jumpTo] with [fileLengthInBytes] minutes windowSize to move the window to the
  /// end of the file.
  Future<void> jumpToEnd() async {
    await jumpTo((fileLengthInBytes - windowSize).abs());
  }

  /// Shifts the window by [increment].
  Future<void> shiftBy(int increment);

  /// Checks if given [increment], the window can be moved by [increment] amount.
  Future<bool> canShiftBy(int increment);

  /// Releases the resources.
  Future<void> dispose();
}
