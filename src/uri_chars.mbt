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
  match c {
    '0' => Some(0)
    '1' => Some(1)
    '2' => Some(2)
    '3' => Some(3)
    '4' => Some(4)
    '5' => Some(5)
    '6' => Some(6)
    '7' => Some(7)
    '8' => Some(8)
    '9' => Some(9)
    'A' | 'a' => Some(10)
    'B' | 'b' => Some(11)
    'C' | 'c' => Some(12)
    'D' | 'd' => Some(13)
    'E' | 'e' => Some(14)
    'F' | 'f' => Some(15)
    _ => None
  }
}

///| Convert integer to hex character (lowercase)
pub fn int_to_hex(n : Int) -> Char? {
  if n >= 0 && n <= 15 {
    match n {
      0 => Some('0')
      1 => Some('1')
      2 => Some('2')
      3 => Some('3')
      4 => Some('4')
      5 => Some('5')
      6 => Some('6')
      7 => Some('7')
      8 => Some('8')
      9 => Some('9')
      10 => Some('a')
      11 => Some('b')
      12 => Some('c')
      13 => Some('d')
      14 => Some('e')
      15 => Some('f')
      _ => None
    }
  } else {
    None
  }
}
