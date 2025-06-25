import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:windowed_file_reader/src/default_reader.dart';

void t(String name, dynamic real, dynamic e) {
  test(name, () => expect(real, e));
}

/// [args] - the first position of args will contain the relative output folder
void generateTestFile(
  String input, {
  required int totalLines,
  required int charsPerLine,
  required int batchSize,
}) async {
  final File output = File(input);
  output.createSync();
  final IOSink outWriter = output.openWrite();
  final Random rng = Random.secure();
  final List<int> upperCaseChars = List<int>.generate(26, (int i) => 65 + i);
  final List<int> lowerCaseChars = List<int>.generate(26, (int i) => 97 + i);
  final StringBuffer batchBuffer = StringBuffer();
  for (int batch = 0; batch < totalLines; batch += batchSize) {
    final int currentBatchSize = (batch + batchSize > totalLines) ? totalLines - batch : batchSize;
    for (int i = 0; i < currentBatchSize; i++) {
      final List<int> lineChars = List<int>.filled(charsPerLine - 1, 0);
      for (int j = 0; j < charsPerLine - 1; j++) {
        final bool isUpperCase = rng.nextBool();
        final int charIndex = rng.nextInt(26);
        lineChars[j] = isUpperCase ? upperCaseChars[charIndex] : lowerCaseChars[charIndex];
      }
      batchBuffer.writeln(String.fromCharCodes(lineChars));
    }
    outWriter.write(batchBuffer.toString());
    batchBuffer.clear();
    if (batch % 100000 == 0) {
      print("Generated ${batch + currentBatchSize} lines...");
    }
  }
  await outWriter.close();
  print("Done generating $totalLines lines.");
}

void main() async {
  generateTestFile(
    "./generated_test_file.txt",
    totalLines: 1000,
    charsPerLine: 100,
    batchSize: 100,
  );
  final File testFile = File("./generated_test_file.txt");
  final String testContent = await testFile.readAsString();
  t("DefaultReader: window size is correct", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    final int result = reader.windowSize;
    await reader.dispose();
    return result;
  }(), equals(256));
  t("DefaultReader: file length is positive", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    final int result = reader.fileLengthInBytes;
    await reader.dispose();
    return result;
  }(), greaterThan(0));
  t("DefaultReader: initially not reading", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    final bool result = reader.isReading;
    await reader.dispose();
    return result;
  }(), isFalse);
  t("DefaultReader: jump to start sets pointers correctly", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    await reader.jumpTo(0);
    final int leading = reader.leadingPointer;
    final int trailing = reader.trailingPointer;
    await reader.dispose();
    return <dynamic>[leading, trailing];
  }(), equals(<int>[0, 256]));
  t("DefaultReader: view returns Uint8List with correct length", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    await reader.jumpTo(0);
    final Uint8List view = reader.view();
    await reader.dispose();
    return view.length;
  }(), equals(256));
  t("DefaultReader: viewAsString matches file content", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    await reader.jumpTo(0);
    final String viewString = reader.viewAsString();
    await reader.dispose();
    return viewString;
  }(), equals(testContent.substring(0, 256)));
  t("DefaultReader: forward shift updates pointers", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    await reader.jumpTo(0);
    await reader.shiftBy(10);
    final int leading = reader.leadingPointer;
    final int trailing = reader.trailingPointer;
    await reader.dispose();
    return <dynamic>[leading, trailing];
  }(), equals(<int>[10, 266]));
  t("DefaultReader: backward shift works", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    await reader.jumpTo(50);
    await reader.shiftBy(-20);
    final int leading = reader.leadingPointer;
    final int trailing = reader.trailingPointer;
    await reader.dispose();
    return <dynamic>[leading, trailing];
  }(), equals(<int>[30, 286]));
  t("DefaultReader: large shift forces full read", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    await reader.jumpTo(0);
    await reader.shiftBy(500);
    final int leading = reader.leadingPointer;
    final int trailing = reader.trailingPointer;
    await reader.dispose();
    return <dynamic>[leading, trailing];
  }(), equals(<int>[500, 756]));
  t("DefaultReader: canJumpTo validates positive cases", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    final bool canJumpStart = await reader.canJumpTo(0);
    final bool canJumpMiddle = await reader.canJumpTo(100);
    await reader.dispose();
    return <dynamic>[canJumpStart, canJumpMiddle];
  }(), equals(<bool>[true, true]));
  t("DefaultReader: canJumpTo validates negative cases", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    final bool canJumpNegative = await reader.canJumpTo(-1);
    final bool canJumpPastEnd = await reader.canJumpTo(reader.fileLengthInBytes);
    await reader.dispose();
    return <dynamic>[canJumpNegative, canJumpPastEnd];
  }(), equals(<bool>[false, false]));
  t("DefaultReader: canShiftBy validates correctly", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    await reader.jumpTo(100);
    final bool canShiftForward = await reader.canShiftBy(50);
    final bool canShiftBackward = await reader.canShiftBy(-50);
    final bool cannotShiftTooFarBack = await reader.canShiftBy(-200);
    await reader.dispose();
    return <dynamic>[canShiftForward, canShiftBackward, cannotShiftTooFarBack];
  }(), equals(<bool>[true, true, false]));
  t("DefaultReader: jump to start sets pointers correctly", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    await reader.jumpTo(0);
    final int leading = reader.leadingPointer;
    final int trailing = reader.trailingPointer;
    await reader.dispose();
    return <dynamic>[leading, trailing];
  }(), equals(<int>[0, 256]));
  t("DefaultReader: jump to middle position", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 128);
    await reader.initialize();
    await reader.jumpTo(500);
    final int leading = reader.leadingPointer;
    final int trailing = reader.trailingPointer;
    await reader.dispose();
    return <dynamic>[leading, trailing];
  }(), equals(<int>[500, 628]));
  t("DefaultReader: view returns Uint8List with correct length", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    await reader.jumpTo(0);
    final Uint8List view = reader.view();
    await reader.dispose();
    return view.length;
  }(), equals(256));
  t("DefaultReader: view is unmodifiable", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 64);
    await reader.initialize();
    await reader.jumpTo(0);
    final Uint8List view = reader.view();
    bool isUnmodifiable = false;
    try {
      view[0] = 255;
    } catch (e) {
      isUnmodifiable = true;
    }
    await reader.dispose();
    return isUnmodifiable;
  }(), isTrue);
  t("DefaultReader: viewAsString matches file content", await () async {
    final DefaultWindowedFileReader reader = DefaultWindowedFileReader(testFile, windowSize: 256);
    await reader.initialize();
    await reader.jumpTo(0);
    final String viewString = reader.viewAsString();
    await reader.dispose();
    return viewString;
  }(), equals(testContent.substring(0, 256)));
}
