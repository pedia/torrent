// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// Class that converts enum value names to enum entries and vice versa.
///
/// Example usage:
/// enum Color {
///   red, green, blue
/// }
/// ```
///   EnumUtils<Color>(Color.values).enumEntry('red'); // returns Color.red
/// ```
class EnumUtils<T> {
  EnumUtils(List<T> enumValues) {
    for (final val in enumValues) {
      final enumDescription = describeEnum(val!);
      _lookupTable[enumDescription] = val;
      _reverseLookupTable[val] = enumDescription;
    }
  }

  final Map<String, T> _lookupTable = {};
  final Map<T, String> _reverseLookupTable = {};

  T? enumEntry(String? enumName) =>
      enumName != null ? _lookupTable[enumName] : null;

  String? name(T enumEntry) => _reverseLookupTable[enumEntry];
}

///
/// Example usage:
/// ```dart
///   enum Size with EnumIndexOrdering {ex, sm}
/// ```
mixin EnumIndexOrdering<T extends Enum> on Enum implements Comparable<T> {
  @override
  int compareTo(T other) => index.compareTo(other.index);

  bool operator <(T other) {
    return index < other.index;
  }

  bool operator >(T other) {
    return index > other.index;
  }

  bool operator >=(T other) {
    return index >= other.index;
  }

  bool operator <=(T other) {
    return index <= other.index;
  }
}
