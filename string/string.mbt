// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Convert char array to string.
///
/// ```
/// let s = @string.from_array(['H', 'e', 'l', 'l', 'o'])
/// assert_eq!(s, "Hello")
/// ```
///
/// Do not convert large datas to `Array[Char]` and build a string with `String::from_array`.
///
/// For efficiency considerations, it's recommended to use `Buffer` instead.
pub fn String::from_array(chars : Array[Char]) -> String {
  let buf = StringBuilder::new(size_hint=chars.length() * 4)
  for c in chars {
    buf.write_char(c)
  }
  buf.to_string()
}

///| same as `String::from_array`
pub fn from_array(chars : Array[Char]) -> String {
  String::from_array(chars)
}

///|
/// Convert char iterator to string,
/// a simple wrapper for `from_array`.
pub fn String::from_iter(iter : Iter[Char]) -> String {
  let chars = iter.collect()
  String::from_array(chars)
}

///|
/// same as `String::from_iter`
pub fn from_iter(iter : Iter[Char]) -> String {
  let chars = iter.collect()
  String::from_array(chars)
}

///|
/// Concatenate strings.
///
/// ```
/// let s = @string.concat(["Hello", ", ", "world!"])
/// assert_eq!(s, "Hello, world!")
/// let s = @string.concat(["a", "b", "c"], separator=",")
/// assert_eq!(s, "a,b,c")
/// ```
pub fn String::concat(
  strings : Array[String],
  separator~ : String = ""
) -> String {
  match strings {
    [] => ""
    [hd, .. tl] => {
      let mut size_hint = hd.length()
      for s in tl {
        size_hint += s.length() + separator.length()
      }
      size_hint = size_hint << 1
      let buf = StringBuilder::new(size_hint~)
      buf.write_string(hd)
      if separator == "" {
        for s in tl {
          buf.write_string(s)
        }
      } else {
        for s in tl {
          buf.write_string(separator)
          buf.write_string(s)
        }
      }
      buf.to_string()
    }
  }
}

///|
/// same as `String::concat`
pub fn concat(strings : Array[String], separator~ : String = "") -> String {
  String::concat(strings, separator~)
}

///|
/// Compare two strings.
/// String with longer length is bigger.
/// strings of the same length are compared in lexicalgraphic order.
pub impl Compare for String with compare(self, other) {
  let len = self.length()
  match len.compare(other.length()) {
    0 => {
      for i in 0..<len {
        let order = self
          .unsafe_charcode_at(i)
          .compare(other.unsafe_charcode_at(i))
        if order != 0 {
          return order
        }
      }
      0
    }
    order => order
  }
}

///|
/// The empty string
pub impl Default for String with default() {
  ""
}

///|
/// same as `String::default`
pub fn default() -> String {
  ""
}

///|
/// `String` holds a sequence of UTF-16 code units encoded in little endian format
pub fn to_bytes(self : String) -> Bytes {
  Bytes::of_string(self)
}

///|
/// Converts the String into an array of Chars.
pub fn to_array(self : String) -> Array[Char] {
  self
  .iter()
  .fold(init=Array::new(capacity=self.length()), fn(rv, c) {
    rv.push(c)
    rv
  })
}

///|
/// Returns an iterator over the Unicode characters in the string.
///
/// Note: This iterator yields Unicode characters, not Utf16 code units.
/// As a result, the count of characters returned by `iter().count()` may not be equal to the length of the string returned by `length()`.
///
/// ```
/// let s = "Hello, World!🤣";
/// assert_eq!(s.iter().count(), 14); // Unicode characters
/// assert_eq!(s.length(), 15); // Utf16 code units
/// ```
pub fn iter(self : String) -> Iter[Char] {
  Iter::new(fn(yield_) {
    let len = self.length()
    for index in 0..<len {
      let c1 = self.unsafe_charcode_at(index)
      if is_leading_surrogate(c1) && index + 1 < len {
        let c2 = self.unsafe_charcode_at(index + 1)
        if is_trailing_surrogate(c2) {
          let c = code_point_of_surrogate_pair(c1, c2)
          guard yield_(c) is IterContinue else { break IterEnd }
          continue index + 2
        }
      }
      //TODO: handle garbage input
      guard yield_(Char::from_int(c1)) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
pub fn iter2(self : String) -> Iter2[Int, Char] {
  Iter2::new(fn(yield_) {
    let len = self.length()
    for index = 0, n = 0; index < len; index = index + 1, n = n + 1 {
      let c1 = self.unsafe_charcode_at(index)
      if is_leading_surrogate(c1) && index + 1 < len {
        let c2 = self.unsafe_charcode_at(index + 1)
        if is_trailing_surrogate(c2) {
          let c = code_point_of_surrogate_pair(c1, c2)
          guard yield_(n, c) is IterContinue else { break IterEnd }
          continue index + 2, n + 1
        }
      }
      //TODO: handle garbage input
      guard yield_(n, Char::from_int(c1)) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
/// Note: This method operates on Unicode characters, not Utf16 code units.
/// As a result, the count of characters passed to the folding function may not be equal to the length of the string.
pub fn fold[A](self : String, init~ : A, f : (A, Char) -> A) -> A {
  let mut rv = init
  for c in self {
    rv = f(rv, c)
  }
  rv
}

///|
pub fn rev_fold[A](self : String, init~ : A, f : (A, Char) -> A) -> A {
  let mut rv = init
  for c in self.rev_iter() {
    rv = f(rv, c)
  }
  rv
}

///|
/// Returns an iterator that yields characters from the end to the start of the string. This function handles
/// Unicode surrogate pairs correctly, ensuring that characters are not split across surrogate pairs.
///
/// # Parameters
///
/// - `self` : The input `String` to be iterated in reverse.
///
/// # Returns
///
/// - An `Iter[Char]` that yields characters from the end to the start of the string.
///
/// # Behavior
///
/// - The function iterates over the string in reverse order.
/// - If a trailing surrogate is encountered, it checks for a preceding leading surrogate to form a complete Unicode code point.
/// - Yields each character or combined code point to the iterator.
/// - Stops iteration if the `yield_` function returns `IterEnd`.
///
/// # Examples
///
/// ```
/// let input = "Hello, World!"
/// let reversed = input.rev_iter().collect()
/// assert_eq!(reversed, ['!', 'd', 'l', 'r', 'o', 'W', ' ', ',', 'o', 'l', 'l', 'e', 'H'])
/// ```
pub fn rev_iter(self : String) -> Iter[Char] {
  Iter::new(fn(yield_) {
    let len = self.length()
    for index = len - 1; index >= 0; index = index - 1 {
      let c1 = self.unsafe_charcode_at(index)
      if is_trailing_surrogate(c1) && index - 1 >= 0 {
        let c2 = self.unsafe_charcode_at(index - 1)
        if is_leading_surrogate(c2) {
          let c = code_point_of_surrogate_pair(c2, c1)
          guard yield_(c) is IterContinue else { break IterEnd }
          continue index - 2
        }
      }
      // TODO: handle garbage input
      guard yield_(Char::from_int(c1)) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
/// Removes all leading and trailing spaces.
pub fn trim_space(self : String) -> String {
  self.trim(" \n\r\t")
}

///|
/// Removes all leading and trailing chars contained in the given string.
pub fn trim(self : String, trim_set : String) -> String {
  if self == "" || trim_set == "" {
    self
  } else {
    self.trim_start(trim_set).trim_end(trim_set)
  }
}

///|
pub fn contains_char(self : String, c : Char) -> Bool {
  self.iter().any(fn(ch) { ch == c })
}

///|
/// Removes all leading chars contained in the given string.
pub fn trim_start(self : String, trim_set : String) -> String {
  let len = self.length()
  for i in 0..<len {
    let c1 = self.unsafe_charcode_at(i)
    // check surrogate pair
    if is_leading_surrogate(c1) && i + 1 < len {
      let c2 = self.unsafe_charcode_at(i + 1)
      if is_trailing_surrogate(c2) {
        let ch = code_point_of_surrogate_pair(c1, c2)
        if trim_set.contains_char(ch) {
          continue i + 2
        } else {
          return self.substring(start=i)
        }
      }
    }
    if not(trim_set.contains_char(Char::from_int(self.unsafe_charcode_at(i)))) {
      return self.substring(start=i)
    }
  } else {
    ""
  }
}

///|
/// Removes all trailing chars contained in the given string.
pub fn trim_end(self : String, trim_set : String) -> String {
  let len = self.length()
  for i = len - 1; i >= 0; i = i - 1 {
    let c2 = self.unsafe_charcode_at(i)
    // check surrogate pair
    if is_trailing_surrogate(c2) && i - 1 >= 0 {
      let c1 = self.unsafe_charcode_at(i - 1)
      if is_leading_surrogate(c1) {
        let ch = code_point_of_surrogate_pair(c1, c2)
        if trim_set.contains_char(ch) {
          continue i - 2
        } else {
          return self.substring(end=i + 1)
        }
      }
    }
    if not(trim_set.contains_char(Char::from_int(self.unsafe_charcode_at(i)))) {
      return self.substring(end=i + 1)
    }
  } else {
    ""
  }
}

///|
/// Returns true if this string is empty.
pub fn is_empty(self : String) -> Bool {
  self == ""
}

///|
/// Returns true if this string is blank.
pub fn is_blank(self : String) -> Bool {
  self.trim_space() == ""
}

///|
/// Returns the first index of the sub string.
pub fn index_of(self : String, str : String, from~ : Int = 0) -> Int {
  let len = self.length()
  let sub_len = str.length()

  // Handle empty substring case
  if sub_len == 0 {
    // Return 0 for empty string in empty string
    if len == 0 {
      return 0
    }
    // Bound from within valid range and return it
    return if from < 0 { 0 } else if from >= len { len } else { from }
  }

  // If substring is longer than string, it can't be found
  if sub_len > len {
    return -1
  }

  // Bound the starting position
  let from = if from < 0 { 0 } else if from >= len { len - 1 } else { from }
  let max_idx = len - sub_len
  let first = str.unsafe_charcode_at(0)
  let mut i = from
  while i <= max_idx {
    // find first character
    while i < len && self.unsafe_charcode_at(i) != first {
      i += 1
    }
    // check the rest
    if i <= max_idx {
      for j in 1..<sub_len {
        if self.unsafe_charcode_at(i + j) != str.unsafe_charcode_at(j) {
          break
        }
      } else {
        // the substring is found
        return i
      }
    }
    i += 1
  }
  -1
}

///|
/// Returns the last index of the sub string.
pub fn last_index_of(
  self : String,
  str : String,
  from~ : Int = self.length()
) -> Int {
  let from = if from < 0 {
    0
  } else if from > self.length() {
    self.length()
  } else {
    from
  }
  let len = self.length()
  let sub_len = str.length()
  if sub_len == 0 {
    return from
  }
  if len < sub_len {
    return -1
  }
  let min = sub_len - 1
  let last = str.unsafe_charcode_at(sub_len - 1)
  let mut i = from - 1
  while i >= 0 {
    // find last character
    while i >= min && self.unsafe_charcode_at(i) != last {
      i -= 1
    }
    if i < min {
      return -1
    }
    let mut j = i - 1
    let mut k = sub_len - 2
    let start = i - sub_len
    let found = while j > start {
      if self.unsafe_charcode_at(j) != str.unsafe_charcode_at(k) {
        break false
      }
      j -= 1
      k -= 1
    } else {
      true
    }
    if found {
      return start + 1
    }
    i -= 1
  }
  -1
}

///|
/// Returns true if this string contains given sub string.
pub fn contains(self : String, str : String) -> Bool {
  self.index_of(str) >= 0
}

///|
/// Returns true if this string starts with a sub string.
pub fn starts_with(self : String, str : String) -> Bool {
  if str.length() > self.length() {
    false
  } else {
    self.index_of(str) == 0
  }
}

///|
/// Returns true if this string ends with a sub string.
pub fn ends_with(self : String, str : String) -> Bool {
  let len = self.length()
  let sub_len = str.length()
  if sub_len > len {
    false
  } else {
    self.last_index_of(str) == len - sub_len
  }
}

///|
/// Splits the input `String` into an `Iter` of `String` using the specified `separator`.
///
/// # Parameters
///
/// - `self` : The input `String` to be split.
/// - `separator` : The `String` used as the delimiter for splitting.
///
/// # Returns
///
/// - An `Iter` of `String` where each element is a substring of the original string, separated by the `separator`.
///
/// # Behavior
///
/// - If the `separator` is an empty string (`""`), the function returns an `Iter` where each element is a single character from the input string converted to a `String`.
/// - If the `separator` is not empty, the function searches for occurrences of the `separator` in the input string and yields substrings between these occurrences.
/// - If no more occurrences of the `separator` are found, the remaining part of the string is yielded as the last element of the `Iter`.
///
/// # Examples
///
/// ```
/// let input = "a,b,c,d"
/// let separator = ","
/// let result = input.split(separator).collect()
/// assert_eq!(result, ["a", "b", "c", "d"])
/// ```
pub fn split(self : String, separator : String) -> Iter[String] {
  let len = self.length()
  let sep_len = separator.length()
  if sep_len == 0 {
    return self.iter().map(fn(c) { c.to_string() })
  }
  Iter::new(fn(yield_) {
    let mut start = 0
    while start < len {
      let end = self.index_of(separator, from=start)
      if end < 0 {
        if yield_(self.substring(start~)) == IterEnd {
          break IterEnd
        }
        break IterContinue
      }
      if yield_(self.substring(start~, end~)) == IterEnd {
        break IterEnd
      }
      start = end + sep_len
    } else {
      IterContinue
    }
  })
}

///|
/// Replace the first old string in this string to new string.
pub fn replace(self : String, old~ : String, new~ : String) -> String {
  let old_idx = self.index_of(old)
  if old_idx < 0 {
    self
  } else {
    self.substring(end=old_idx) +
    new +
    self.substring(start=old_idx + old.length())
  }
}

///|
/// Replace all old string in this string to new string.
pub fn replace_all(self : String, old~ : String, new~ : String) -> String {
  let buf = StringBuilder::new()
  let len = self.length()
  let old_len = old.length()
  if old_len == 0 {
    buf.write_string(new)
    self
    .iter()
    .each(fn(c) {
      buf.write_char(c)
      buf.write_string(new)
    })
  } else {
    let mut start = 0
    while start < len {
      let end = self.index_of(old, from=start)
      if end < 0 {
        buf.write_string(self.substring(start~))
        break
      }
      buf.write_string(self.substring(start~, end~))
      buf.write_string(new)
      start = end + old_len
    }
  }
  buf.to_string()
}

///|
/// Converts this string to lowercase.
pub fn to_lower(self : String) -> String {
  // TODO: deal with non-ascii characters
  let buf = StringBuilder::new(size_hint=self.length())
  for c in self {
    if c >= 'A' && c <= 'Z' {
      buf.write_char(Char::from_int(c.to_int() + 32))
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Converts this string to uppercase.
pub fn to_upper(self : String) -> String {
  // TODO: deal with non-ascii characters
  let buf = StringBuilder::new(size_hint=self.length())
  for c in self {
    if c >= 'a' && c <= 'z' {
      buf.write_char(Char::from_int(c.to_int() - 32))
    } else {
      buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Reverse string
/// It respects Unicode characters and surrogate pairs but not grapheme clusters.
/// TODO: make it an intrinsic function
pub fn rev(self : String) -> String {
  let buf = StringBuilder::new(size_hint=self.length())
  for c in self.rev_iter() {
    buf.write_char(c)
  }
  buf.to_string()
}

///|
/// Repeats the string `n` times.
pub fn repeat(self : String, n : Int) -> String {
  if n <= 0 {
    return ""
  }
  if n == 1 {
    return self
  }
  let len = self.length()
  let buf = StringBuilder::new(size_hint=len * n)
  for _ in 0..<n {
    buf.write_string(self)
  }
  buf.to_string()
}

///|
/// `pad_start` is a new string with `padding_char`s prefixed to `self` if `self.length() < total_width`. The length of the
/// returned string is `total_width`.
///
/// Example:
///
/// ```
/// assert_eq!("2".pad_start(3, '0'), "002")
/// ```
pub fn pad_start(
  self : String,
  total_width : Int,
  padding_char : Char
) -> String {
  let len = self.length()
  if len >= total_width {
    self
  } else {
    let buf = StringBuilder::new(size_hint=total_width)
    for i in 0..<(total_width - len) {
      buf.write_char(padding_char)
    }
    buf.write_string(self)
    buf.to_string()
  }
}

///|
/// `pad_end` is a new String with `padding_char`s suffixed to `self` if `self.length() < total_width`. The length of the
/// returned string is `total_width`.
///
/// Example:
///
/// ```
/// assert_eq!("2".pad_end(3, 'x'), "2xx")
/// ```
pub fn pad_end(self : String, total_width : Int, padding_char : Char) -> String {
  let len = self.length()
  if len >= total_width {
    self
  } else {
    let buf = StringBuilder::new(size_hint=total_width)
    buf.write_string(self)
    for i in 0..<(total_width - len) {
      buf.write_char(padding_char)
    }
    buf.to_string()
  }
}

///|
/// Returns the character at the given index from the end of the string.
///
/// # Examples
///
/// ```moonbit
/// let s = "Hello🤣🤣🤣"
/// inspect!(s.rev_get(0), content="🤣")
/// inspect!(s.rev_get(4), content="l")
/// ```
///
/// # Panics
///
/// @alert unsafe "Panics if the index is out of bounds."
pub fn String::rev_get(self : String, index : Int) -> Char {
  guard index >= 0 else { abort("index out of bounds") }
  for utf16_offset = self.length() - 1, char_count = 0
      utf16_offset >= 0 && char_count < index
      utf16_offset = utf16_offset - 1, char_count = char_count + 1 {
    let c1 = self.unsafe_charcode_at(utf16_offset)
    if is_trailing_surrogate(c1) && utf16_offset - 1 >= 0 {
      let c2 = self.unsafe_charcode_at(utf16_offset - 1)
      if is_leading_surrogate(c2) {
        continue utf16_offset - 2, char_count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    guard char_count == index && utf16_offset >= 0 else {
      abort("index out of bounds")
    }
    let c1 = self.unsafe_charcode_at(utf16_offset)
    if is_trailing_surrogate(c1) && utf16_offset - 1 >= 0 {
      let c2 = self.unsafe_charcode_at(utf16_offset - 1)
      if is_leading_surrogate(c2) {
        code_point_of_surrogate_pair(c2, c1)
      } else {
        abort("invalid surrogate pair")
      }
    } else {
      Char::from_int(c1)
    }
  }
}

///|
/// Test if the length of the string is equal to the given length.
///
/// This has O(n) complexity where n is the length in the parameter.
pub fn String::length_eq(self : String, len : Int) -> Bool {
  let codeunit_len = self.length()
  for index = 0, count = 0
      index < codeunit_len && count < len
      index = index + 1, count = count + 1 {
    let c1 = self.unsafe_charcode_at(index)
    if is_leading_surrogate(c1) && index + 1 < codeunit_len {
      let c2 = self.unsafe_charcode_at(index + 1)
      if is_trailing_surrogate(c2) {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    count == len && index == codeunit_len
  }
}

///|
/// Test if the length of the string is greater than or equal to the given length.
///
/// This has O(n) complexity where n is the length in the parameter.
pub fn String::length_ge(self : String, len : Int) -> Bool {
  let codeunit_len = self.length()
  for index = 0, count = 0
      index < codeunit_len && count < len
      index = index + 1, count = count + 1 {
    let c1 = self.unsafe_charcode_at(index)
    if is_leading_surrogate(c1) && index + 1 < codeunit_len {
      let c2 = self.unsafe_charcode_at(index + 1)
      if is_trailing_surrogate(c2) {
        continue index + 2, count + 1
      } else {
        abort("invalid surrogate pair")
      }
    }
  } else {
    count >= len
  }
}
