import "dart:io";
import "package:windowed_file_reader/windowed_file_reader.dart";

void main() async {
  final DefaultWindowedFileReader reader = WindowedFileReader.defaultReader(
    file: File("large_file.txt"),
    windowSize: 1024,
  );
  await reader.initialize();
  await reader.refresh();
  print("Current window content:");
  print(reader.viewAsString());
  if (await reader.canShiftBy(512)) {
    await reader.shiftBy(512);
    print("New window content:");
    print(reader.viewAsString());
  }
  await reader.dispose();
}
