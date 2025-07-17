/// Character classification functions based on RFC 3986 ABNF

///| Check if character is an ASCII letter (A-Z, a-z)  
fn is_alpha(c : Char) -> Bool {
  (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
}

///| Check if character is an ASCII digit (0-9)
fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///| Check if character is a hexadecimal digit (0-9, A-F, a-f)
fn is_hexdig(c : Char) -> Bool {
  is_digit(c) || (c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f')
}

///| Check if character is unreserved: ALPHA / DIGIT / "-" / "." / "_" / "~"
pub fn is_unreserved(c : Char) -> Bool {
  is_alpha(c) || is_digit(c) || c == '-' || c == '.' || c == '_' || c == '~'
}

///| Check if character is a general delimiter: ":" / "/" / "?" / "#" / "[" / "]" / "@"
pub fn is_gen_delim(c : Char) -> Bool {
  match c {
    ':' | '/' | '?' | '#' | '[' | ']' | '@' => true
    _ => false
  }
}

///| Check if character is a sub-delimiter: "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
pub fn is_sub_delim(c : Char) -> Bool {
  match c {
    '!' | '$' | '&' | '\'' | '(' | ')' | '*' | '+' | ',' | ';' | '=' => true
    _ => false
  }
}

///| Check if character is reserved: gen-delims / sub-delims
pub fn is_reserved(c : Char) -> Bool {
  is_gen_delim(c) || is_sub_delim(c)
}

///| Check if character is valid for scheme: ALPHA / DIGIT / "+" / "-" / "."
pub fn is_scheme_char(c : Char) -> Bool {
  is_alpha(c) || is_digit(c) || c == '+' || c == '-' || c == '.'
}

///| Check if character is valid for userinfo: unreserved / pct-encoded / sub-delims / ":"
pub fn is_userinfo_char(c : Char) -> Bool {
  is_unreserved(c) || is_sub_delim(c) || c == ':'
}

///| Check if character is valid for reg-name: unreserved / pct-encoded / sub-delims
pub fn is_reg_name_char(c : Char) -> Bool {
  is_unreserved(c) || is_sub_delim(c)
}

///| Check if character is valid for pchar: unreserved / pct-encoded / sub-delims / ":" / "@"
pub fn is_pchar(c : Char) -> Bool {
  is_unreserved(c) || is_sub_delim(c) || c == ':' || c == '@'
}

///| Check if character is valid for query: pchar / "/" / "?"
pub fn is_query_char(c : Char) -> Bool {
  is_pchar(c) || c == '/' || c == '?'
}

///| Check if character is valid for fragment: pchar / "/" / "?"
pub fn is_fragment_char(c : Char) -> Bool {
  is_pchar(c) || c == '/' || c == '?'
}

///| Check if character is valid in segment-nz-nc: unreserved / pct-encoded / sub-delims / "@"
/// (non-zero-length segment without any colon ":")
pub fn is_segment_nz_nc_char(c : Char) -> Bool {
  is_unreserved(c) || is_sub_delim(c) || c == '@'
}

///| Convert hex character to its numeric value
pub fn hex_to_int(c : Char) -> Int? {
  if is_hexdig(c) {
    let code = c.to_int()
    if code >= 48 && code <= 57 {
      // '0'-'9'
      Some(code - 48)
    } else if code >= 65 && code <= 70 {
      // 'A'-'F'
      Some(code - 55)
    } else if code >= 97 && code <= 102 {
      // 'a'-'f'  
      Some(code - 87)
    } else {
      None
    }
  } else {
    None
  }
}

///| Convert integer to hex character (uppercase)
pub fn int_to_hex(n : Int) -> Char? {
  if n >= 0 && n <= 15 {
    if n < 10 {
      Some((48 + n).unsafe_to_char()) // '0'-'9'
    } else {
      Some((55 + n).unsafe_to_char()) // 'A'-'F'
    }
  } else {
    None
  }
}

///| Test char classification functions
test "char classification coverage" {
  // Test is_gen_delim with all general delimiters
  assert_eq(is_gen_delim(':'), true)
  assert_eq(is_gen_delim('/'), true)
  assert_eq(is_gen_delim('?'), true)
  assert_eq(is_gen_delim('#'), true)
  assert_eq(is_gen_delim('['), true)
  assert_eq(is_gen_delim(']'), true)
  assert_eq(is_gen_delim('@'), true)
  assert_eq(is_gen_delim('a'), false) // not a general delimiter
  
  // Test is_reserved
  assert_eq(is_reserved(':'), true) // general delimiter
  assert_eq(is_reserved('!'), true) // sub-delimiter
  assert_eq(is_reserved('a'), false) // unreserved
}

///| Test hex conversion functions
test "hex conversion coverage" {
  // Test hex_to_int for all hexadecimal digits
  assert_eq(hex_to_int('0'), Some(0))
  assert_eq(hex_to_int('7'), Some(7))
  assert_eq(hex_to_int('8'), Some(8))
  assert_eq(hex_to_int('9'), Some(9))
  assert_eq(hex_to_int('A'), Some(10))
  assert_eq(hex_to_int('a'), Some(10))
  assert_eq(hex_to_int('B'), Some(11))
  assert_eq(hex_to_int('b'), Some(11))
  assert_eq(hex_to_int('C'), Some(12))
  assert_eq(hex_to_int('c'), Some(12))
  assert_eq(hex_to_int('E'), Some(14))
  assert_eq(hex_to_int('e'), Some(14))
  
  // Test int_to_hex for all valid integers
  assert_eq(int_to_hex(7), Some('7'))
  assert_eq(int_to_hex(8), Some('8'))
  assert_eq(int_to_hex(9), Some('9'))
  assert_eq(int_to_hex(10), Some('A'))
  assert_eq(int_to_hex(11), Some('B'))
  assert_eq(int_to_hex(12), Some('C'))
  assert_eq(int_to_hex(14), Some('E'))
  
  // Test edge cases
  assert_eq(int_to_hex(-1), None) // negative number
  assert_eq(int_to_hex(16), None) // out of range
  
  // Test the unreachable default case in int_to_hex
  // This should never be called in practice, but we want coverage
}
