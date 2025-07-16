/// IP address parsing utilities for IPv4, IPv6, and IPvFuture



///| Parse a decimal octet (0-255)
/// dec-octet = DIGIT / %x31-39 DIGIT / "1" 2DIGIT / "2" %x30-34 DIGIT / "25" %x30-35
fn parse_dec_octet(s : String) -> Bool {
  let chars = s.to_array()
  let len = chars.length()
  if len == 0 || len > 3 {
    false
  } else {
    let mut all_digits = true
    for i = 0; i < len; i = i + 1 {
      if not(is_digit(chars[i])) {
        all_digits = false
      }
    }
    if not(all_digits) {
      false
    } else {
      // Convert to integer and check range
      let n = parse_int_simple(s)
      n >= 0 && n <= 255
    }
  }
}

///| Parse IPv4 address: dec-octet "." dec-octet "." dec-octet "." dec-octet
pub fn parse_ipv4_address(s : String) -> URIResult[String] {
  let parts = s.split(".")
  let parts_arr = parts.collect()
  if parts_arr.length() != 4 {
    Err(InvalidHost("IPv4 address must have exactly 4 octets"))
  } else {
    let mut valid = true
    for i = 0; i < 4; i = i + 1 {
      if not(parse_dec_octet(parts_arr[i].to_string())) {
        valid = false
      }
    }
    if valid {
      Ok(s)
    } else {
      Err(InvalidHost("Invalid IPv4 octet values"))
    }
  }
}

///| Parse a 16-bit hex value (h16): 1*4HEXDIG
fn parse_h16(s : String) -> Bool {
  let chars = s.to_array()
  let len = chars.length()
  if len >= 1 && len <= 4 {
    let mut all_hex = true
    for i = 0; i < len; i = i + 1 {
      if not(is_hexdig(chars[i])) {
        all_hex = false
      }
    }
    all_hex
  } else {
    false
  }
}

///| Simplified IPv6 address validation
/// This is a simplified version that checks basic structure
/// A full implementation would need to handle all IPv6 compression rules
pub fn parse_ipv6_address(s : String) -> URIResult[String] {
  let chars = s.to_array()
  let mut colon_count = 0
  let mut has_double_colon = false

  // Check for invalid patterns like ":::"
  if s.contains(":::") {
    return Err(InvalidHost("Invalid IPv6 address: triple colon not allowed"))
  }

  // Count colons and check for double colons
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == ':' {
      colon_count += 1
      if i > 0 && chars[i - 1] == ':' {
        if not(has_double_colon) {
          has_double_colon = true
        } else {
          // Multiple double colons found
          return Err(
            InvalidHost("IPv6 address can have at most one double colon"),
          )
        }
      }
    }
  }

  // Basic validation - IPv6 should have 2-7 colons  
  if colon_count < 2 || colon_count > 7 {
    Err(InvalidHost("Invalid IPv6 address structure"))
  } else {
    // More detailed validation would be needed for production use
    // For now, we'll accept if it meets basic structural requirements
    let parts = s.split(":")
    let parts_arr = parts.collect()
    let mut valid = true
    for i = 0; i < parts_arr.length(); i = i + 1 {
      let part = parts_arr[i].to_string()
      if part.length() > 0 {
        if i == parts_arr.length() - 1 && part.contains(".") {
          // Last part might be IPv4
          match parse_ipv4_address(part) {
            Ok(_) => continue
            Err(_) => valid = false
          }
        } else if not(parse_h16(part)) {
          valid = false
        }
      }
    }
    if valid {
      Ok(s)
    } else {
      Err(InvalidHost("Invalid IPv6 address format"))
    }
  }
}

///| Parse IPvFuture: "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )
pub fn parse_ipv_future(s : String) -> URIResult[String] {
  let chars = s.to_array()
  let len = chars.length()
  if len < 4 || chars[0] != 'v' {
    Err(InvalidHost("IPvFuture must start with 'v'"))
  } else {
    // Find the dot
    let mut dot_pos = -1
    for i = 1; i < len; i = i + 1 {
      if chars[i] == '.' {
        dot_pos = i
        break
      }
    }
    if dot_pos == -1 || dot_pos == 1 {
      Err(InvalidHost("IPvFuture must have version number after 'v'"))
    } else {
      // Check hex digits in version
      let mut valid_version = true
      for i = 1; i < dot_pos; i = i + 1 {
        if not(is_hexdig(chars[i])) {
          valid_version = false
        }
      }
      if not(valid_version) {
        Err(InvalidHost("IPvFuture version must be hex digits"))
      } else if dot_pos == len - 1 {
        Err(InvalidHost("IPvFuture must have content after dot"))
      } else {
        // Check remaining characters
        let mut valid_content = true
        for i = dot_pos + 1; i < len; i = i + 1 {
          let c = chars[i]
          if not(is_unreserved(c) || is_sub_delim(c) || c == ':') {
            valid_content = false
          }
        }
        if valid_content {
          Ok(s)
        } else {
          Err(InvalidHost("Invalid characters in IPvFuture"))
        }
      }
    }
  }
}

///| Parse IP literal: "[" ( IPv6address / IPvFuture  ) "]"
pub fn parse_ip_literal(s : String) -> URIResult[HostType] {
  let len = s.length()
  if len < 3 ||
    s.charcode_at(0) != '['.to_int() ||
    s.charcode_at(len - 1) != ']'.to_int() {
    Err(InvalidHost("IP literal must be enclosed in brackets"))
  } else {
    let inner = s.substring(start=1, end=len - 1)
    if inner.has_prefix("v") {
      // IPvFuture
      match parse_ipv_future(inner) {
        Ok(addr) => Ok(IPvFuture(addr))
        Err(e) => Err(e)
      }
    } else {
      // IPv6
      match parse_ipv6_address(inner) {
        Ok(addr) => Ok(IPv6(addr))
        Err(e) => Err(e)
      }
    }
  }
}

///| Parse any host type: IP-literal / IPv4address / reg-name
pub fn parse_host(s : String) -> URIResult[HostType] {
  if s.is_empty() {
    Err(InvalidHost("Host cannot be empty"))
  } else if s.has_prefix("[") {
    // IP literal
    parse_ip_literal(s)
  } else if s.contains(":") {
    // Could be IPv6 without brackets (not standard) or reg-name with colon
    // We'll treat it as reg-name since proper IPv6 should be in brackets
    if is_valid_encoded_string(s, is_reg_name_char) {
      Ok(HostType::RegName(s))
    } else {
      Err(InvalidHost("Invalid characters in host name"))
    }
  } else {
    // Try IPv4 first, then reg-name
    match parse_ipv4_address(s) {
      Ok(addr) => Ok(IPv4(addr))
      Err(_) =>
        if is_valid_encoded_string(s, is_reg_name_char) {
          Ok(HostType::RegName(s))
        } else {
          Err(InvalidHost("Invalid characters in host name"))
        }
    }
  }
}
