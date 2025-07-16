/// URI component parsing (scheme, query, fragment)

///| Find first occurrence of character in string
fn find_char_in_str(s : String, c : Char) -> Int? {
  let chars = s.to_array()
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == c {
      return Some(i)
    }
  }
  None
}

///| Parse scheme: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
pub fn parse_scheme(s : String) -> URIResult[String] {
  if s.is_empty() {
    Err(InvalidScheme("Scheme cannot be empty"))
  } else {
    let chars = s.to_array()

    // First character must be ALPHA
    if not(is_alpha(chars[0])) {
      Err(InvalidScheme("Scheme must start with a letter"))
    } else {
      // Check remaining characters
      let mut valid = true
      for i = 1; i < chars.length(); i = i + 1 {
        if not(is_scheme_char(chars[i])) {
          valid = false
        }
      }
      if valid {
        Ok(s.to_lower()) // Schemes are case-insensitive, normalize to lowercase
      } else {
        Err(InvalidScheme("Invalid characters in scheme"))
      }
    }
  }
}

///| Parse query: *( pchar / "/" / "?" )
pub fn parse_query(s : String) -> URIResult[String] {
  if is_valid_encoded_string(s, is_query_char) {
    Ok(s)
  } else {
    Err(InvalidQuery("Invalid characters in query"))
  }
}

///| Parse fragment: *( pchar / "/" / "?" )
pub fn parse_fragment(s : String) -> URIResult[String] {
  if is_valid_encoded_string(s, is_fragment_char) {
    Ok(s)
  } else {
    Err(InvalidFragment("Invalid characters in fragment"))
  }
}

///| Split query string into key-value pairs
pub fn parse_query_params(query : String) -> Array[(String, String)] {
  if query.is_empty() {
    return []
  }
  let pairs = query.split("&")
  let result : Array[(String, String)] = []
  for pair in pairs {
    let pair_str = pair.to_string()
    if pair_str.contains("=") {
      let eq_pos = find_char_in_str(pair_str, '=')
      match eq_pos {
        Some(pos) => {
          let key = pair_str.substring(start=0, end=pos)
          let value = pair_str.substring(start=pos + 1)
          // Decode percent-encoded values
          match (percent_decode(key), percent_decode(value)) {
            (Ok(decoded_key), Ok(decoded_value)) =>
              result.push((decoded_key, decoded_value))
            _ =>
              // If decoding fails, keep original values
              result.push((key, value))
          }
        }
        None => () // Should not happen since we checked contains
      }
    } else {
      // Key without value
      match percent_decode(pair_str) {
        Ok(decoded_key) => result.push((decoded_key, ""))
        Err(_) => result.push((pair_str, ""))
      }
    }
  }
  result
}

///| Build query string from key-value pairs
pub fn build_query_string(params : Array[(String, String)]) -> String {
  if params.is_empty() {
    return ""
  }
  let parts : Array[String] = []
  for i = 0; i < params.length(); i = i + 1 {
    let (key, value) = params[i]
    let encoded_key = encode_query(key)
    if value.is_empty() {
      parts.push(encoded_key)
    } else {
      let encoded_value = encode_query(value)
      parts.push(encoded_key + "=" + encoded_value)
    }
  }
  parts.join("&")
}

///| Validate that all URI components are properly formed
pub fn validate_uri_components(
  scheme : String,
  authority : Authority?,
  path : String,
  query : String?,
  fragment : String?
) -> URIResult[Unit] {
  // Validate scheme
  match parse_scheme(scheme) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }

  // Validate query if present
  match query {
    Some(q) =>
      match parse_query(q) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
    None => ()
  }

  // Validate fragment if present
  match fragment {
    Some(f) =>
      match parse_fragment(f) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
    None => ()
  }

  // Authority validation is done during parsing

  // Path validation depends on whether authority is present
  match authority {
    Some(_) =>
      // With authority, path must be path-abempty
      match validate_path_abempty(path) {
        Ok(_) => Ok(())
        Err(e) => Err(e)
      }
    None =>
      // Without authority, validate based on path type
      match classify_and_validate_path(path) {
        Ok(_) => Ok(())
        Err(e) => Err(e)
      }
  }
}

///| Case-insensitive scheme comparison
pub fn schemes_equal(scheme1 : String, scheme2 : String) -> Bool {
  scheme1.to_lower() == scheme2.to_lower()
}

///| Normalize URI component case (schemes and host names are case-insensitive)
pub fn normalize_uri_case(uri : URI) -> URI {
  let normalized_authority = match uri.authority {
    Some(auth) => {
      let normalized_host = match auth.host {
        HostType::RegName(name) => HostType::RegName(name.to_lower())
        other => other
      }
      Some({ ..auth, host: normalized_host })
    }
    None => None
  }
  { ..uri, scheme: uri.scheme.to_lower(), authority: normalized_authority }
}
