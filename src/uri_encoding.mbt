/// Percent-encoding and decoding utilities based on RFC 3986

///| Check if a string contains valid percent-encoding
/// pct-encoded = "%" HEXDIG HEXDIG
pub fn is_valid_percent_encoding(s : String) -> Bool {
  let chars = s.to_array()
  let len = chars.length()
  fn check_from(i : Int) -> Bool {
    if i >= len {
      true
    } else if chars[i] == '%' {
      if i + 2 < len && is_hexdig(chars[i + 1]) && is_hexdig(chars[i + 2]) {
        check_from(i + 3)
      } else {
        false
      }
    } else {
      check_from(i + 1)
    }
  }

  check_from(0)
}

///| Decode a percent-encoded string
pub fn percent_decode(s : String) -> URIResult[String] {
  let chars = s.to_array()
  let len = chars.length()
  let mut result = ""
  fn decode_from(i : Int) -> URIResult[Unit] {
    if i >= len {
      Ok(())
    } else if chars[i] == '%' {
      if i + 2 < len {
        match (hex_to_int(chars[i + 1]), hex_to_int(chars[i + 2])) {
          (Some(h1), Some(h2)) => {
            let byte_val = h1 * 16 + h2
            // Convert byte value back to character
            // Note: This is a simplified approach for ASCII characters
            if byte_val >= 0 && byte_val <= 127 {
              result = result + byte_val.unsafe_to_char().to_string()
              decode_from(i + 3)
            } else {
              Err(InvalidPercentEncoding("Invalid byte value: \{byte_val}"))
            }
          }
          _ =>
            Err(InvalidPercentEncoding("Invalid hex digits at position \{i}"))
        }
      } else {
        Err(InvalidPercentEncoding("Incomplete percent encoding at end"))
      }
    } else {
      result = result + chars[i].to_string()
      decode_from(i + 1)
    }
  }

  match decode_from(0) {
    Ok(_) => Ok(result)
    Err(e) => Err(e)
  }
}

///| Encode a string with percent-encoding for characters that need it
/// The predicate function determines which characters should be encoded
pub fn percent_encode(s : String, should_encode : (Char) -> Bool) -> String {
  let chars = s.to_array()
  let mut result = ""
  for i = 0; i < chars.length(); i = i + 1 {
    let c = chars[i]
    if should_encode(c) {
      let byte_val = Char::to_int(c)
      if byte_val <= 255 {
        let h1 = byte_val / 16
        let h2 = byte_val % 16
        result = result + "%"
        match int_to_hex(h1) {
          Some(ch) => {
            let upper_ch = if ch >= 'a' && ch <= 'f' {
              (Char::to_int(ch) - 32).unsafe_to_char() // Convert to uppercase
            } else {
              ch
            }
            result = result + upper_ch.to_string()
          }
          None => continue // Should not happen for valid bytes
        }
        match int_to_hex(h2) {
          Some(ch) => {
            let upper_ch = if ch >= 'a' && ch <= 'f' {
              (Char::to_int(ch) - 32).unsafe_to_char() // Convert to uppercase  
            } else {
              ch
            }
            result = result + upper_ch.to_string()
          }
          None => continue // Should not happen for valid bytes
        }
      } else {
        // For non-ASCII characters, we'll just include them as-is
        // In a complete implementation, you'd want proper UTF-8 encoding
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
  char_validator : (Char) -> Bool
) -> Bool {
  let chars = s.to_array()
  let len = chars.length()
  fn check_from(i : Int) -> Bool {
    if i >= len {
      true
    } else if chars[i] == '%' {
      if i + 2 < len && is_hexdig(chars[i + 1]) && is_hexdig(chars[i + 2]) {
        check_from(i + 3)
      } else {
        false
      }
    } else if char_validator(chars[i]) {
      check_from(i + 1)
    } else {
      false
    }
  }

  check_from(0)
}
