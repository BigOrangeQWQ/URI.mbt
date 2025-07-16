/// Authority component parsing
/// authority = [ userinfo "@" ] host [ ":" port ]



///| Parse port number: *DIGIT
fn parse_port(s : String) -> URIResult[Int] {
  if s.is_empty() {
    Err(InvalidPort("Port cannot be empty"))
  } else {
    let chars = s.to_array()
    let mut all_digits = true
    for i = 0; i < chars.length(); i = i + 1 {
      if not(is_digit(chars[i])) {
        all_digits = false
      }
    }
    if not(all_digits) {
      Err(InvalidPort("Port must contain only digits"))
    } else {
      let port = parse_int_simple(s)
      if port >= 0 && port <= 65535 {
        Ok(port)
      } else {
        Err(InvalidPort("Port number out of range (0-65535)"))
      }
    }
  }
}

///| Parse userinfo: *( unreserved / pct-encoded / sub-delims / ":" )
fn parse_userinfo(s : String) -> URIResult[String] {
  if s.is_empty() {
    Err(InvalidAuthority("Userinfo cannot be empty when '@' is present"))
  } else if is_valid_encoded_string(s, is_userinfo_char) {
    Ok(s)
  } else {
    Err(InvalidAuthority("Invalid characters in userinfo"))
  }
}

///| Parse authority component
pub fn parse_authority(s : String) -> URIResult[Authority] {
  if s.is_empty() {
    Err(InvalidAuthority("Authority cannot be empty"))
  } else {
    let mut userinfo : String? = None
    let mut host_port = s

    // Check for userinfo (everything before '@')
    if s.contains("@") {
      let at_pos = find_char_index(s, '@')
      match at_pos {
        Some(pos) => {
          let userinfo_str = s.substring(start=0, end=pos)
          match parse_userinfo(userinfo_str) {
            Ok(ui) => userinfo = Some(ui)
            Err(e) => return Err(e)
          }
          host_port = s.substring(start=pos + 1)
        }
        None => () // Should not happen since we checked contains
      }
    }

    // Parse host and port
    let mut host_str = host_port
    let mut port : Int? = None
    if host_port.has_prefix("[") {
      // IPv6 literal - find the closing bracket
      match find_char_index(host_port, ']') {
        Some(bracket_pos) => {
          host_str = host_port.substring(start=0, end=bracket_pos + 1)
          let remaining = host_port.substring(start=bracket_pos + 1)
          if remaining.has_prefix(":") && remaining.length() > 1 {
            let port_str = remaining.substring(start=1)
            match parse_port(port_str) {
              Ok(p) => port = Some(p)
              Err(e) => return Err(e)
            }
          } else if not(remaining.is_empty()) {
            return Err(
              InvalidAuthority("Invalid characters after IPv6 literal"),
            )
          }
        }
        None => return Err(InvalidHost("Unterminated IPv6 literal"))
      }
    } else {
      // Regular host - find last colon for port
      let last_colon = find_last_index_str(host_port, ":")
      match last_colon {
        Some(colon_pos) => {
          // Check if this might be an IPv6 address without brackets
          // If there are multiple colons, it's likely IPv6
          let colon_count = {
            let chars = host_port.to_array()
            chars.fold(init=0, fn(count, c) { if c == ':' { count + 1 } else { count } })
          }
          if colon_count == 1 {
            // Likely host:port
            host_str = host_port.substring(start=0, end=colon_pos)
            let port_str = host_port.substring(start=colon_pos + 1)
            match parse_port(port_str) {
              Ok(p) => port = Some(p)
              Err(e) => return Err(e)
            }
          }
          // If colon_count > 1, treat whole thing as IPv6 host (though it should be bracketed)
        }
        None => () // No port
      }
    }

    // Parse the host
    match parse_host(host_str) {
      Ok(host) => Ok({ userinfo, host, port })
      Err(e) => Err(e)
    }
  }
}

///| Create authority from components
pub fn create_authority(
  userinfo : String?,
  host : HostType,
  port : Int?
) -> Authority {
  { userinfo, host, port }
}

///| Convert authority back to string
pub fn authority_to_string(auth : Authority) -> String {
  let mut result = ""

  // Add userinfo if present
  match auth.userinfo {
    Some(ui) => result = result + ui + "@"
    None => ()
  }

  // Add host
  match auth.host {
    IPv4(addr) => result = result + addr
    IPv6(addr) => result = result + "[" + addr + "]"
    IPvFuture(addr) => result = result + "[" + addr + "]"
    RegName(name) => result = result + name
  }

  // Add port if present
  match auth.port {
    Some(p) => result = result + ":" + p.to_string()
    None => ()
  }
  result
}
