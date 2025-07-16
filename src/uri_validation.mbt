/// URI validation utilities

///| Validate a complete URI string without parsing it fully
pub fn is_valid_uri(uri_string : String) -> Bool {
  match parse_uri(uri_string) {
    Ok(_) => true
    Err(_) => false
  }
}

///| Validate a URI reference string
pub fn is_valid_uri_reference(uri_ref_string : String) -> Bool {
  match parse_uri_reference(uri_ref_string) {
    Ok(_) => true
    Err(_) => false
  }
}

///| Check if URI is absolute (has scheme)
pub fn is_absolute_uri(uri : URI) -> Bool {
  not(uri.scheme.is_empty())
}

///| Check if URI is relative (no scheme)
pub fn is_relative_uri(uri : URI) -> Bool {
  uri.scheme.is_empty()
}

///| Validate URI according to specific scheme requirements
pub fn validate_scheme_specific(uri : URI) -> URIResult[Unit] {
  match uri.scheme {
    "http" | "https" => validate_http_uri(uri)
    "ftp" => validate_ftp_uri(uri)
    "file" => validate_file_uri(uri)
    _ => Ok(()) // Unknown schemes are allowed
  }
}

///| Validate HTTP/HTTPS URIs
fn validate_http_uri(uri : URI) -> URIResult[Unit] {
  // HTTP URIs should have authority
  match uri.authority {
    None => Err(InvalidAuthority("HTTP URIs must have an authority component"))
    Some(auth) =>
      // Check for valid port ranges
      match auth.port {
        Some(port) =>
          if port < 1 || port > 65535 {
            Err(InvalidPort("HTTP port must be between 1 and 65535"))
          } else {
            Ok(())
          }
        None => Ok(())
      }
  }
}

///| Validate FTP URIs
fn validate_ftp_uri(uri : URI) -> URIResult[Unit] {
  // FTP URIs should have authority
  match uri.authority {
    None => Err(InvalidAuthority("FTP URIs must have an authority component"))
    Some(_) => Ok(())
  }
}

///| Validate file URIs
fn validate_file_uri(uri : URI) -> URIResult[Unit] {
  // File URIs have specific path requirements
  if uri.scheme == "file" {
    match uri.authority {
      Some(auth) =>
        // Authority can be empty (localhost) or a host name
        match auth.host {
          HostType::RegName(name) =>
            if name != "localhost" && not(name.is_empty()) {
              // Non-empty, non-localhost hostnames in file URIs are implementation-dependent
              Ok(())
            } else {
              Ok(())
            }
          _ => Err(InvalidHost("File URIs should use reg-name for host"))
        }
      None => Ok(()) // Authority can be omitted
    }
  } else {
    Ok(())
  }
}

///| Check if two URIs are equivalent (after normalization)
pub fn uris_equivalent(uri1 : URI, uri2 : URI) -> Bool {
  let norm1 = normalize_uri_case(uri1)
  let norm2 = normalize_uri_case(uri2)

  // Compare normalized forms
  norm1.scheme == norm2.scheme &&
  authorities_equivalent(norm1.authority, norm2.authority) &&
  normalize_path(norm1.path) == normalize_path(norm2.path) &&
  norm1.query == norm2.query &&
  norm1.fragment == norm2.fragment
}

///| Check if two authorities are equivalent
fn authorities_equivalent(auth1 : Authority?, auth2 : Authority?) -> Bool {
  match (auth1, auth2) {
    (None, None) => true
    (Some(a1), Some(a2)) =>
      a1.userinfo == a2.userinfo &&
      hosts_equivalent(a1.host, a2.host) &&
      ports_equivalent(a1.port, a2.port, a1.host)
    _ => false
  }
}

///| Check if two hosts are equivalent
fn hosts_equivalent(host1 : HostType, host2 : HostType) -> Bool {
  match (host1, host2) {
    (HostType::IPv4(addr1), HostType::IPv4(addr2)) => addr1 == addr2
    (HostType::IPv6(addr1), HostType::IPv6(addr2)) =>
      normalize_ipv6(addr1) == normalize_ipv6(addr2)
    (HostType::IPvFuture(addr1), HostType::IPvFuture(addr2)) => addr1 == addr2
    (HostType::RegName(name1), HostType::RegName(name2)) =>
      name1.to_lower() == name2.to_lower()
    _ => false
  }
}

///| Check if two ports are equivalent (considering default ports)
fn ports_equivalent(port1 : Int?, port2 : Int?, host : HostType) -> Bool {
  let default_port = get_default_port_for_scheme_and_host(host)
  let effective_port1 = match port1 {
    Some(p) => p
    None => default_port
  }
  let effective_port2 = match port2 {
    Some(p) => p
    None => default_port
  }
  effective_port1 == effective_port2
}

///| Get default port for common schemes
fn get_default_port_for_scheme_and_host(_ : HostType) -> Int {
  // This is simplified - in practice you'd need the scheme
  80 // HTTP default
}

///| Simplified IPv6 normalization (removes leading zeros, etc.)
fn normalize_ipv6(addr : String) -> String {
  // This is a simplified implementation
  // Full IPv6 normalization is quite complex
  addr.to_lower()
}

///| Perform comprehensive URI validation
pub fn validate_uri_comprehensive(uri : URI) -> URIResult[Unit] {
  // Basic component validation
  match
    validate_uri_components(
      uri.scheme,
      uri.authority,
      uri.path,
      uri.query,
      uri.fragment,
    ) {
    Err(e) => Err(e)
    Ok(_) =>
      // Scheme-specific validation
      match validate_scheme_specific(uri) {
        Err(e) => Err(e)
        Ok(_) =>
          // Additional structural validation
          validate_uri_structure(uri)
      }
  }
}

///| Validate URI structural requirements
fn validate_uri_structure(uri : URI) -> URIResult[Unit] {
  // Path validation based on authority presence
  match uri.authority {
    Some(_) =>
      // With authority, path must be empty or start with '/'
      if not(uri.path.is_empty()) && not(uri.path.has_prefix("/")) {
        Err(
          InvalidPath(
            "Path must be empty or start with '/' when authority is present",
          ),
        )
      } else {
        Ok(())
      }
    None =>
      // Without authority, path cannot start with '//'
      if uri.path.has_prefix("//") {
        Err(InvalidPath("Path cannot start with '//' without authority"))
      } else {
        Ok(())
      }
  }
}
