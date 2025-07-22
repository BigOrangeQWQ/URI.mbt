/// IP address parsing utilities for IPv4, IPv6, and IPvFuture

///| Parse a decimal octet (0-255)
/// dec-octet = DIGIT / %x31-39 DIGIT / "1" 2DIGIT / "2" %x30-34 DIGIT / "25" %x30-35
fn parse_dec_octet(s : String) -> Bool {
  if s.is_empty() || s.length() > 3 {
    return false
  }

  // Check all characters are digits
  for c in s {
    if not(is_digit(c)) {
      return false
    }
  }

  // Convert to integer and check range
  let n = parse_int_simple(s)
  n >= 0 && n <= 255
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
  let len = s.length()
  if len < 1 || len > 4 {
    return false
  }

  // Check all characters are hex digits
  for c in s {
    if not(is_hexdig(c)) {
      return false
    }
  }
  true
}

///| Simplified IPv6 address validation
/// This is a simplified version that checks basic structure
/// A full implementation would need to handle all IPv6 compression rules
pub fn parse_ipv6_address(s : String) -> URIResult[String] {
  // Check for invalid patterns like ":::"
  if s.contains(":::") {
    return Err(InvalidHost("Invalid IPv6 address: triple colon not allowed"))
  }
  let double_colon_count = count_substring_occurrences(s, "::")
  if double_colon_count > 1 {
    return Err(InvalidHost("IPv6 address can have at most one double colon"))
  }
  let colon_count = count_char_occurrences(s, ':')
  // Basic validation - IPv6 should have 2-7 colons  
  if colon_count < 2 || colon_count > 7 {
    return Err(InvalidHost("Invalid IPv6 address structure"))
  }

  // Validate parts
  let parts = s.split(":").collect()
  for i = 0; i < parts.length(); i = i + 1 {
    let part = parts[i].to_string()
    if part.length() > 0 {
      if i == parts.length() - 1 && part.contains(".") {
        // Last part might be IPv4
        match parse_ipv4_address(part) {
          Err(_) => return Err(InvalidHost("Invalid IPv4 suffix in IPv6"))
          Ok(_) => continue
        }
      } else if not(parse_h16(part)) {
        return Err(InvalidHost("Invalid hex segment in IPv6"))
      }
    }
  }
  Ok(s)
}

///| 计算字符在字符串中的出现次数
fn count_char_occurrences(s : String, c : Char) -> Int {
  let mut count = 0
  for ch in s {
    if ch == c {
      count += 1
    }
  }
  count
}

///| 计算子字符串在字符串中的出现次数
fn count_substring_occurrences(s : String, substr : String) -> Int {
  if substr.is_empty() {
    return 0
  }
  let mut count = 0
  let mut pos = 0
  let s_len = s.length()
  let sub_len = substr.length()
  while pos <= s_len - sub_len {
    if s.substring(start=pos, end=pos + sub_len) == substr {
      count += 1
      pos += sub_len
    } else {
      pos += 1
    }
  }
  count
}

///| Parse IPvFuture: "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )
pub fn parse_ipv_future(s : String) -> URIResult[String] {
  if s.length() < 4 || not(s.has_prefix("v")) {
    return Err(InvalidHost("IPvFuture must start with 'v'"))
  }
  match s.find(".") {
    None => Err(InvalidHost("IPvFuture must contain a dot"))
    Some(dot_pos) => {
      if dot_pos == 1 {
        return Err(InvalidHost("IPvFuture must have version number after 'v'"))
      }
      if dot_pos == s.length() - 1 {
        return Err(InvalidHost("IPvFuture must have content after dot"))
      }

      // Check version part (hex digits)
      let version_part = s.substring(start=1, end=dot_pos)
      for c in version_part {
        if not(is_hexdig(c)) {
          return Err(InvalidHost("IPvFuture version must be hex digits"))
        }
      }

      // Check content part
      let content_part = s.substring(start=dot_pos + 1)
      for c in content_part {
        if not(is_unreserved(c) || is_sub_delim(c) || c == ':') {
          return Err(InvalidHost("Invalid characters in IPvFuture"))
        }
      }
      Ok(s)
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
