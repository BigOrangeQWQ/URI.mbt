/// URI creation and building utilities

///| Create a new URI with all components
pub fn create_uri(
  scheme : String,
  authority : Authority?,
  path : String,
  query : String?,
  fragment : String?,
) -> URIResult[URI] {
  // Determine path type based on context
  let path_type = match authority {
    Some(_) => AbEmpty
    None =>
      match classify_and_validate_path(path) {
        Ok((ptype, _)) => ptype
        Err(_) => Empty
      }
  }
  let uri = { scheme, authority, path, path_type, query, fragment }

  // Validate the complete URI
  match validate_uri_comprehensive(uri) {
    Ok(_) => Ok(uri)
    Err(e) => Err(e)
  }
}

///| Create a simple URI with just scheme and path
pub fn create_simple_uri(scheme : String, path : String) -> URIResult[URI] {
  create_uri(scheme, None, path, None, None)
}

///| Create an HTTP URI
pub fn create_http_uri(
  host : String,
  port : Int?,
  path : String,
  query : String?,
  fragment : String?,
) -> URIResult[URI] {
  let host_type = HostType::RegName(host)
  let authority = create_authority(None, host_type, port)
  create_uri("http", Some(authority), path, query, fragment)
}

///| Create an HTTPS URI  
pub fn create_https_uri(
  host : String,
  port : Int?,
  path : String,
  query : String?,
  fragment : String?,
) -> URIResult[URI] {
  let host_type = HostType::RegName(host)
  let authority = create_authority(None, host_type, port)
  create_uri("https", Some(authority), path, query, fragment)
}

///| Create a file URI
pub fn create_file_uri(path : String) -> URIResult[URI] {
  let normalized_path = if path.has_prefix("/") { path } else { "/" + path }
  // File URIs typically have empty authority, which results in file:///path
  let empty_authority = create_authority(None, HostType::RegName(""), None)
  create_uri("file", Some(empty_authority), normalized_path, None, None)
}

///| URI Builder for fluent construction
pub struct URIBuilder {
  mut scheme : String
  mut authority : Authority?
  mut path : String
  mut query : String?
  mut fragment : String?
} derive(Show)

///| Create a new URI builder
pub fn new_builder() -> URIBuilder {
  { scheme: "", authority: None, path: "", query: None, fragment: None }
}

///| Set the scheme
pub fn URIBuilder::scheme(self : URIBuilder, scheme : String) -> URIBuilder {
  self.scheme = scheme
  self
}

///| Set the authority
pub fn URIBuilder::authority(
  self : URIBuilder,
  authority : Authority,
) -> URIBuilder {
  self.authority = Some(authority)
  self
}

///| Set the host (creates authority if needed)
pub fn URIBuilder::host(self : URIBuilder, host : String) -> URIBuilder {
  let host_type : HostType = HostType::RegName(host)
  match self.authority {
    Some(auth) => self.authority = Some({ ..auth, host: host_type })
    None => self.authority = Some(create_authority(None, host_type, None))
  }
  self
}

///| Set the port
pub fn URIBuilder::port(self : URIBuilder, port : Int) -> URIBuilder {
  match self.authority {
    Some(auth) => self.authority = Some({ ..auth, port: Some(port) })
    None => {
      // Create authority with empty host
      let host_type : HostType = HostType::RegName("")
      self.authority = Some(create_authority(None, host_type, Some(port)))
    }
  }
  self
}

///| Set the userinfo
pub fn URIBuilder::userinfo(self : URIBuilder, userinfo : String) -> URIBuilder {
  match self.authority {
    Some(auth) => self.authority = Some({ ..auth, userinfo: Some(userinfo) })
    None => {
      // Create authority with empty host
      let host_type : HostType = HostType::RegName("")
      self.authority = Some(create_authority(Some(userinfo), host_type, None))
    }
  }
  self
}

///| Set the path
pub fn URIBuilder::path(self : URIBuilder, path : String) -> URIBuilder {
  self.path = path
  self
}

///| 简化的路径段添加
pub fn URIBuilder::add_path_segment(
  self : URIBuilder,
  segment : String,
) -> URIBuilder {
  let encoded_segment = encode_path_segment(segment)
  self.path = match (self.path.is_empty(), self.authority) {
    (true, Some(_)) => "/" + encoded_segment // 有权威时以 / 开头
    (true, None) => encoded_segment // 无权威时直接添加
    (false, _) =>
      if self.path.has_suffix("/") {
        self.path + encoded_segment
      } else {
        self.path + "/" + encoded_segment
      }
  }
  self
}

///| Set the query
pub fn URIBuilder::query(self : URIBuilder, query : String) -> URIBuilder {
  self.query = Some(query)
  self
}

///| Set query parameters
pub fn URIBuilder::query_params(
  self : URIBuilder,
  params : Array[(String, String)],
) -> URIBuilder {
  let query_string = build_query_string(params)
  self.query = if query_string.is_empty() { None } else { Some(query_string) }
  self
}

///| 简化的查询参数添加
pub fn URIBuilder::add_query_param(
  self : URIBuilder,
  key : String,
  value : String,
) -> URIBuilder {
  let param = if value.is_empty() {
    encode_query(key)
  } else {
    encode_query(key) + "=" + encode_query(value)
  }
  self.query = match self.query {
    Some(existing) => Some(existing + "&" + param)
    None => Some(param)
  }
  self
}

///| Set the fragment
pub fn URIBuilder::fragment(self : URIBuilder, fragment : String) -> URIBuilder {
  self.fragment = Some(fragment)
  self
}

///| Build the URI
pub fn URIBuilder::build(self : URIBuilder) -> URIResult[URI] {
  create_uri(self.scheme, self.authority, self.path, self.query, self.fragment)
}

///| 简化的 URI 转字符串函数
pub fn uri_to_string(uri : URI) -> String {
  let parts = [
    // scheme
    if uri.scheme.is_empty() {
      ""
    } else {
      uri.scheme + ":"
    },
    // authority
    match uri.authority {
      Some(auth) => "//" + authority_to_string(auth)
      None => ""
    },
    // path
    uri.path,
    // query
    match uri.query {
      Some(q) => "?" + q
      None => ""
    },
    // fragment
    match uri.fragment {
      Some(f) => "#" + f
      None => ""
    },
  ]
  parts.join("")
}

///| Resolve a relative reference against a base URI
pub fn resolve_reference(base : URI, reference : URI) -> URIResult[URI] {
  if not(reference.scheme.is_empty()) {
    // Reference is absolute, return as-is
    Ok(reference)
  } else {
    // Reference is relative, resolve against base
    let target_scheme = base.scheme
    let (target_authority, target_path) = match reference.authority {
      Some(ref_auth) =>
        // Reference has authority
        (Some(ref_auth), normalize_path(reference.path))
      None =>
        // Reference has no authority
        if reference.path.is_empty() {
          // Reference has empty path
          let target_query = match reference.query {
            Some(_) => reference.query
            None => base.query
          }
          return Ok({
            scheme: target_scheme,
            authority: base.authority,
            path: base.path,
            path_type: base.path_type,
            query: target_query,
            fragment: reference.fragment,
          })
        } else if reference.path.has_prefix("/") {
          // Reference has absolute path
          (base.authority, normalize_path(reference.path))
        } else {
          // Reference has relative path, merge with base
          let merged_path = merge_paths(base.path, reference.path)
          (base.authority, normalize_path(merged_path))
        }
    }
    let target_path_type = match target_authority {
      Some(_) => AbEmpty
      None => Absolute
    }
    Ok({
      scheme: target_scheme,
      authority: target_authority,
      path: target_path,
      path_type: target_path_type,
      query: reference.query,
      fragment: reference.fragment,
    })
  }
}

///| Merge base path with relative path
fn merge_paths(base_path : String, relative_path : String) -> String {
  if base_path.is_empty() {
    "/" + relative_path
  } else {
    // Remove everything after the last '/' in base path
    let last_slash = find_last_index_str(base_path, "/")
    match last_slash {
      Some(pos) => base_path.substring(start=0, end=pos + 1) + relative_path
      None => "/" + relative_path
    }
  }
}
