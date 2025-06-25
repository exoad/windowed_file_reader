<h1 align="center">
<img src="https://raw.githubusercontent.com/exoad/windowed_file_reader/refs/heads/main/meta/logo.png" width=86/><br/>windowed_file_reader
<br/>
<img src="https://github.com/exoad/windowed_file_reader/actions/workflows/dart.yml/badge.svg" />
</h1>

**A memory efficient [sliding window](https://stackoverflow.com/a/64111403/14501343) file reader.**

**Why?**

Especially for large files, this method only reads a small portion of a file using a [sliding window](https://stackoverflow.com/a/64111403/14501343) and you can
move this window around to read other portions of the file. For smaller files, such as just simple configuration files, it is not as necessary to use this method
and instead you should just read everything into memory instead.

## Installation

`dart pub add windowed_file_reader`

`flutter pub add windowed_file_reader`

```dart
import "package:windowed_file_reader/windowed_file_reader.dart";
```

## Usage

The default API uses a single class `WindowedFileReader` to grab the builtin implementations:

1. `defaultReader(...)`
2. `unsafeReader(...)`

### Default Reader

This is the common one you can use and handles most common tasks and has bounds checking. You should
stick to using this method for the majority.

### Unsafe Reader

This reader sacrifices a lot of bounds checking and other numerical clampping as well as sanity checks to
be faster for reading a file with speed. However, this is method can significantly be eliminated with the
JIT compiler, thus mileage for this implementation may vary.

## Chores

Here is are the current high priority chores that will hopefully make its way into the code soon!

- [ ] A resizable window implementation that can allow for third parties to alter the `windowSize` parameter and adjust accordingly
- [ ] Additional sanity checks and exception throwing for all safe readers when certain operations are not deemed standard (i.e. clamping)

---

BSD 3-Clause License

Copyright (c) 2025, Jiaming Meng

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
