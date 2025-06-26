## 1.0.3

- The default reader automatically updates the file length and adjusts the stream when the file is appended to

## 1.0.2

- Fixed a bug where the reader would overwrite stale data when the window size was bigger than the file.
- Added fixture to force the reader to capture data using `refresh`
- Introduced `ChunkedWindowedFileReader` and `DefaultWindowedFileReader.chunked()` which abstracts calculating chunk size for structured data.

## 1.0.1

- Fixed up the readme's icon

## 1.0.0

- Initial version.
