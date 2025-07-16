/// Main URI parsing functionality
/// URI = scheme ":" hier-part [ "?" query ] [ "#" fragment ]

///| Parse a complete URI string
pub fn parse_uri(uri_string : String) -> URIResult[URI] {
  if uri_string.is_empty() {
    return Err(MalformedURI("URI cannot be empty"))
  }

  // Find the scheme (everything before first ':')
  let colon_pos = find_char_index(uri_string, ':')
  match colon_pos {
    None => Err(MalformedURI("URI must contain a scheme"))
    Some(pos) =>
      if pos == 0 {
        Err(InvalidScheme("Scheme cannot be empty"))
      } else {
        let scheme_str = uri_string.substring(start=0, end=pos)
        let remaining = uri_string.substring(start=pos + 1)
        match parse_scheme(scheme_str) {
          Err(e) => Err(e)
          Ok(scheme) => parse_hier_part_and_rest(scheme, remaining)
        }
      }
  }
}



///| Parse hier-part and optional query/fragment
/// hier-part = "//" authority path-abempty / path-absolute / path-rootless / path-empty
fn parse_hier_part_and_rest(
  scheme : String,
  remaining : String
) -> URIResult[URI] {
  // Check for fragment first (everything after '#')
  let (before_fragment, fragment) = split_at_last_char(remaining, '#')

  // Then check for query (everything after '?' but before fragment)
  let (hier_part, query) = split_at_last_char(before_fragment, '?')

  // Parse hier-part
  match parse_hier_part(hier_part) {
    Err(e) => Err(e)
    Ok((authority, path, path_type)) => {
      // Validate query
      let validated_query = match query {
        Some(q) =>
          match parse_query(q) {
            Ok(valid_q) => Some(valid_q)
            Err(e) => return Err(e)
          }
        None => None
      }

      // Validate fragment  
      let validated_fragment = match fragment {
        Some(f) =>
          match parse_fragment(f) {
            Ok(valid_f) => Some(valid_f)
            Err(e) => return Err(e)
          }
        None => None
      }
      Ok({
        scheme,
        authority,
        path,
        path_type,
        query: validated_query,
        fragment: validated_fragment,
      })
    }
  }
}

///| Split string at the last occurrence of a character
fn split_at_last_char(s : String, delimiter : Char) -> (String, String?) {
  match find_last_index_str(s, delimiter.to_string()) {
    Some(pos) => {
      let before = s.substring(start=0, end=pos)
      let after = s.substring(start=pos + 1)
      (before, Some(after))
    }
    None => (s, None)
  }
}

///| Parse hier-part component
fn parse_hier_part(
  hier_part : String
) -> URIResult[(Authority?, String, PathType)] {
  if hier_part.has_prefix("//") {
    // Authority present
    parse_authority_and_path_abempty(hier_part.substring(start=2))
  } else {
    // No authority, determine path type
    match classify_and_validate_path(hier_part) {
      Ok((path_type, path)) => Ok((None, path, path_type))
      Err(e) => Err(e)
    }
  }
}

///| Parse authority followed by path-abempty

///|
fn parse_authority_and_path_abempty(
  s : String
) -> URIResult[(Authority?, String, PathType)] {
  // Find where authority ends and path begins
  // Authority ends at the first '/' that starts the path
  let slash_pos = find_authority_end(s)
  let (authority_str, path) = match slash_pos {
    Some(pos) => (s.substring(start=0, end=pos), s.substring(start=pos))
    None => (s, "")
  }
  if authority_str.is_empty() {
    Err(InvalidAuthority("Authority cannot be empty after '//'"))
  } else {
    match parse_authority(authority_str) {
      Err(e) => Err(e)
      Ok(authority) =>
        match validate_path_abempty(path) {
          Err(e) => Err(e)
          Ok(validated_path) => Ok((Some(authority), validated_path, AbEmpty))
        }
    }
  }
}

///| Find where authority component ends (at first '/' that starts path)
/// This is tricky because IPv6 addresses in brackets can contain '/'
fn find_authority_end(s : String) -> Int? {
  let chars = s.to_array()
  let len = chars.length()
  let mut in_brackets = false
  for i = 0; i < len; i = i + 1 {
    match chars[i] {
      '[' => in_brackets = true
      ']' => in_brackets = false
      '/' => if not(in_brackets) { return Some(i) }
      _ => ()
    }
  }
  None
}

///| Parse a URI reference (URI or relative reference)
/// URI-reference = URI / relative-ref
pub fn parse_uri_reference(uri_ref_string : String) -> URIResult[URI] {
  if uri_ref_string.is_empty() {
    return Err(MalformedURI("URI reference cannot be empty"))
  }

  // Try to parse as URI first (look for scheme)
  let colon_pos = find_scheme_end(uri_ref_string)
  match colon_pos {
    Some(_) =>
      // Has scheme, parse as URI
      parse_uri(uri_ref_string)
    None =>
      // No scheme, parse as relative reference
      parse_relative_reference(uri_ref_string)
  }
}

///| Find the end of a scheme (first ':' that's not part of IPv6 address or port)
fn find_scheme_end(s : String) -> Int? {
  let chars = s.to_array()
  let len = chars.length()

  // Scheme must start with ALPHA
  if len == 0 || not(is_alpha(chars[0])) {
    return None
  }

  // Look for first ':' that could end a scheme
  for i = 1; i < len; i = i + 1 {
    let c = chars[i]
    if c == ':' {
      // Check if this looks like a scheme (all previous chars are scheme chars)
      let mut is_scheme = true
      for j = 1; j < i; j = j + 1 {
        if not(is_scheme_char(chars[j])) {
          is_scheme = false
          break
        }
      }
      if is_scheme {
        return Some(i)
      }
    } else if not(is_scheme_char(c)) {
      // Invalid scheme character, so no scheme
      return None
    }
  }
  None
}

///| Parse relative reference
/// relative-ref = relative-part [ "?" query ] [ "#" fragment ]
fn parse_relative_reference(rel_ref : String) -> URIResult[URI] {
  // Use empty scheme for relative references
  let scheme = ""

  // Parse similar to URI but without scheme
  let (before_fragment, fragment) = split_at_last_char(rel_ref, '#')
  let (relative_part, query) = split_at_last_char(before_fragment, '?')

  // Parse relative-part
  match parse_relative_part(relative_part) {
    Err(e) => Err(e)
    Ok((authority, path, path_type)) => {
      // Validate query
      let validated_query = match query {
        Some(q) =>
          match parse_query(q) {
            Ok(valid_q) => Some(valid_q)
            Err(e) => return Err(e)
          }
        None => None
      }

      // Validate fragment
      let validated_fragment = match fragment {
        Some(f) =>
          match parse_fragment(f) {
            Ok(valid_f) => Some(valid_f)
            Err(e) => return Err(e)
          }
        None => None
      }
      Ok({
        scheme,
        authority,
        path,
        path_type,
        query: validated_query,
        fragment: validated_fragment,
      })
    }
  }
}

///| Parse relative-part
/// relative-part = "//" authority path-abempty / path-absolute / path-noscheme / path-empty
fn parse_relative_part(
  relative_part : String
) -> URIResult[(Authority?, String, PathType)] {
  if relative_part.has_prefix("//") {
    // Authority present
    parse_authority_and_path_abempty(relative_part.substring(start=2))
  } else {
    // No authority, classify path type
    match classify_and_validate_path(relative_part) {
      Ok((path_type, path)) => Ok((None, path, path_type))
      Err(e) => Err(e)
    }
  }
}
