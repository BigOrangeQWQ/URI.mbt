/// Percent-encoding and decoding utilities based on RFC 3986

///| Check if a string contains valid percent-encoding
/// pct-encoded = "%" HEXDIG HEXDIG 
pub fn is_valid_percent_encoding(s : String) -> Bool {
  let chars = s.to_array()
  let len = chars.length()
  for i = 0; i < len; i = i + 1 {
    if chars[i] == '%' {
      if i + 2 >= len ||
        not(is_hexdig(chars[i + 1])) ||
        not(is_hexdig(chars[i + 2])) {
        return false
      }
      // Skip the next two hex digits since we validated them
      continue
    }
  }
  true
}

///| Decode a percent-encoded string
pub fn percent_decode(s : String) -> URIResult[String] {
  let chars = s.to_array()
  let len = chars.length()
  let mut result = ""
  let mut i = 0
  while i < len {
    if chars[i] == '%' {
      if i + 2 >= len {
        return Err(InvalidPercentEncoding("Incomplete percent encoding at end"))
      }
      match (hex_to_int(chars[i + 1]), hex_to_int(chars[i + 2])) {
        (Some(h1), Some(h2)) => {
          let byte_val = h1 * 16 + h2
          if byte_val >= 0 && byte_val <= 127 {
            let char_result = byte_val.unsafe_to_char()
            result = result + char_result.to_string()
            i = i + 3
          } else {
            return Err(
              InvalidPercentEncoding("Invalid byte value: \{byte_val}"),
            )
          }
        }
        _ =>
          return Err(
            InvalidPercentEncoding("Invalid hex digits at position \{i}"),
          )
      }
    } else {
      result = result + chars[i].to_string()
      i = i + 1
    }
  }
  Ok(result)
}

///| Encode a string with percent-encoding for characters that need it
/// The predicate function determines which characters should be encoded
pub fn percent_encode(s : String, should_encode : (Char) -> Bool) -> String {
  let mut result = ""
  for c in s {
    if should_encode(c) {
      let byte_val = c.to_int()
      if byte_val <= 255 {
        let h1 = byte_val / 16
        let h2 = byte_val % 16
        match (int_to_hex(h1), int_to_hex(h2)) {
          (Some(ch1), Some(ch2)) =>
            result = result + "%" + ch1.to_string() + ch2.to_string()
          _ => result = result + c.to_string() // Fallback
        }
      } else {
        // For non-ASCII characters, include them as-is for simplicity
        result = result + c.to_string()
      }
    } else {
      result = result + c.to_string()
    }
  }
  result
}

///| Encode a string for use in URI path segments
pub fn encode_path_segment(s : String) -> String {
  percent_encode(s, fn(c) { not(is_pchar(c)) && c != '%' })
}

///| Encode a string for use in URI query
pub fn encode_query(s : String) -> String {
  percent_encode(s, fn(c) { not(is_query_char(c)) && c != '%' })
}

///| Encode a string for use in URI fragment
pub fn encode_fragment(s : String) -> String {
  percent_encode(s, fn(c) { not(is_fragment_char(c)) && c != '%' })
}

///| Encode a string for use in URI userinfo
pub fn encode_userinfo(s : String) -> String {
  percent_encode(s, fn(c) { not(is_userinfo_char(c)) && c != '%' })
}

///| Encode a string for use in URI reg-name (domain names)
pub fn encode_reg_name(s : String) -> String {
  percent_encode(s, fn(c) { not(is_reg_name_char(c)) && c != '%' })
}

///| Check if a string is already properly percent-encoded and contains only valid characters
pub fn is_valid_encoded_string(
  s : String,
  char_validator : (Char) -> Bool,
) -> Bool {
  let chars = s.to_array()
  let len = chars.length()
  let mut i = 0
  while i < len {
    if chars[i] == '%' {
      if i + 2 >= len ||
        not(is_hexdig(chars[i + 1])) ||
        not(is_hexdig(chars[i + 2])) {
        return false
      }
      i = i + 3
    } else if char_validator(chars[i]) {
      i = i + 1
    } else {
      return false
    }
  }
  true
}
