import 'package:windowed_file_reader/windowed_file_reader.dart';

/// A high level abstraction ontop of [DefaultWindowedFileReader] that allows for reading
/// structured data in predefined chunks without having to keep track of the chunk size externally.
///
/// This means that for methods like [shiftBy], they are multiplied by [chunkSize].
class ChunkedWindowedFileReader extends DefaultWindowedFileReader {
  final int chunkSize;

  /// Similar implementation to [DefaultWindowedFileReader.chunked]
  /// A handy constructor for when you have properly structured data that needs to be read in full without being cutoff.
  /// However, this will still require you to keep track of the chunk size externally. You can take a look at [ChunkedWindowedFileReader] if you don't want something more high level.
  ///
  /// - [chunkSize] How big each of the structured data is in bytes
  /// - [containsSeparator] Whether there is an additional byte that is used for separating these structured data chunks, like new line
  /// - [chunksPerWindow] How many chunks to read.
  ChunkedWindowedFileReader(
    super.file, {
    required int chunkSize,
    bool containsNewLine = true,
    required int chunksPerWindow,
  }) : assert(chunkSize > 0, "Chunk size must be greater than zero!"),
       assert(chunksPerWindow > 0, "Chunks per window must be greater than zero!"),
       this.chunkSize = chunkSize + (containsNewLine ? 0 : 1),
       super(windowSize: (chunkSize + (containsNewLine ? 0 : 1)) * chunksPerWindow);

  @override
  Future<void> shiftBy(int increment) async {
    await super.shiftBy(chunkSize * increment);
  }

  @override
  Future<bool> canShiftBy(int increment) async {
    return await super.canShiftBy(chunkSize * increment);
  }
}
