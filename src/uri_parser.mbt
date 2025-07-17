pub fn parse_uri(uri_string : String) -> URIResult[URI] {
  if uri_string.is_empty() {
    return Err(MalformedURI("URI cannot be empty"))
  }

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


fn parse_hier_part_and_rest(scheme : String, remaining : String) -> URIResult[URI] {
  let (before_fragment, fragment) = split_at_last_char(remaining, '#')
  let (hier_part, query) = split_at_last_char(before_fragment, '?')

  match parse_hier_part(hier_part) {
    Err(e) => Err(e)
    Ok((authority, path, path_type)) => {
      let validated_query = match query {
        Some(q) => match parse_query(q) {
          Ok(valid_q) => Some(valid_q)
          Err(e) => return Err(e)
        }
        None => None
      }

      let validated_fragment = match fragment {
        Some(f) => match parse_fragment(f) {
          Ok(valid_f) => Some(valid_f)
          Err(e) => return Err(e)
        }
        None => None
      }
      
      Ok({ scheme, authority, path, path_type, query: validated_query, fragment: validated_fragment })
    }
  }
}

fn split_at_last_char(s : String, delimiter : Char) -> (String, String?) {
  match s.rev_find(delimiter.to_string()) {
    Some(pos) => (s.substring(start=0, end=pos), Some(s.substring(start=pos + 1)))
    None => (s, None)
  }
}

fn parse_hier_part(hier_part : String) -> URIResult[(Authority?, String, PathType)] {
  if hier_part.has_prefix("//") {
    parse_authority_and_path_abempty(hier_part.substring(start=2))
  } else {
    match classify_and_validate_path(hier_part) {
      Ok((path_type, path)) => Ok((None, path, path_type))
      Err(e) => Err(e)
    }
  }
}

fn parse_authority_and_path_abempty(s : String) -> URIResult[(Authority?, String, PathType)] {
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
      Ok(authority) => match validate_path_abempty(path) {
        Err(e) => Err(e)
        Ok(validated_path) => Ok((Some(authority), validated_path, AbEmpty))
      }
    }
  }
}

fn find_authority_end(s : String) -> Int? {
  let mut in_brackets = false
  let mut index = 0
  
  for c in s {
    match c {
      '[' => in_brackets = true
      ']' => in_brackets = false
      '/' if not(in_brackets) => return Some(index)
      _ => ()
    }
    index += 1
  }
  None
}

pub fn parse_uri_reference(uri_ref_string : String) -> URIResult[URI] {
  if uri_ref_string.is_empty() {
    return Err(MalformedURI("URI reference cannot be empty"))
  }

  match find_scheme_end(uri_ref_string) {
    Some(_) => parse_uri(uri_ref_string)
    None => parse_relative_reference(uri_ref_string)
  }
}

fn find_scheme_end(s : String) -> Int? {
  if s.is_empty() {
    return None
  }
  
  let chars = s.to_array()
  if not(is_alpha(chars[0])) {
    return None
  }

  let mut index = 1
  for c in s.substring(start=1) {
    if c == ':' {
      // Check if everything before this colon is valid scheme
      let scheme_part = s.substring(start=1, end=index)
      for sc in scheme_part {
        if not(is_scheme_char(sc)) {
          return None
        }
      }
      return Some(index)
    } else if not(is_scheme_char(c)) {
      return None
    }
    index += 1
  }
  None
}

fn parse_relative_reference(rel_ref : String) -> URIResult[URI] {
  let (before_fragment, fragment) = split_at_last_char(rel_ref, '#')
  let (relative_part, query) = split_at_last_char(before_fragment, '?')

  match parse_relative_part(relative_part) {
    Err(e) => Err(e)
    Ok((authority, path, path_type)) => {
      let validated_query = match query {
        Some(q) => match parse_query(q) {
          Ok(valid_q) => Some(valid_q)
          Err(e) => return Err(e)
        }
        None => None
      }

      let validated_fragment = match fragment {
        Some(f) => match parse_fragment(f) {
          Ok(valid_f) => Some(valid_f)
          Err(e) => return Err(e)
        }
        None => None
      }
      
      Ok({ scheme: "", authority, path, path_type, query: validated_query, fragment: validated_fragment })
    }
  }
}

fn parse_relative_part(relative_part : String) -> URIResult[(Authority?, String, PathType)] {
  if relative_part.has_prefix("//") {
    parse_authority_and_path_abempty(relative_part.substring(start=2))
  } else {
    match classify_and_validate_path(relative_part) {
      Ok((path_type, path)) => Ok((None, path, path_type))
      Err(e) => Err(e)
    }
  }
}
