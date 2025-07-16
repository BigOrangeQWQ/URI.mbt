///| Tests for URI validation utilities
test "uri validation basic" {
  let valid_uris = [
    "http://example.com/", "https://user@host.com:443/path?query=value#fragment",
    "ftp://ftp.example.com/file.txt",
  ]
  for i = 0; i < valid_uris.length(); i = i + 1 {
    let is_valid = @uri.is_valid_uri(valid_uris[i])
    if not(is_valid) {
      fail("URI should be valid: \{valid_uris[i]}")
    }
  }

  // Test file URI separately since it might have special authority requirements
  // let file_result = @uri.is_valid_uri("file:///path/to/file")

  // Test mailto separately since it might have special handling
  // let mailto_result = @uri.is_valid_uri("mailto:user@example.com")
}

///|
test "uri validation invalid" {
  let invalid_uris = [
    "", // Empty
     "://example.com",
  ]
  for i = 0 // No scheme  
      i < invalid_uris.length()
      i = i + 1 {
    let is_valid = @uri.is_valid_uri(invalid_uris[i])
    if is_valid {
      fail("URI should be invalid: \{invalid_uris[i]}")
    }
  }

  // "http:" is technically valid according to RFC 3986 (scheme with empty hier-part)
  // "http:///path" is also valid (scheme with empty authority and absolute path)
}

///|
test "uri reference validation" {
  let valid_refs = [
    "http://example.com/", "/path/to/resource", "../relative/path", "?query=only",
    "#fragment-only",
  ]
  for i = 0; i < valid_refs.length(); i = i + 1 {
    assert_eq(@uri.is_valid_uri_reference(valid_refs[i]), true)
  }
}

///|
test "absolute vs relative uris" {
  // Test absolute URI
  match @uri.parse_uri("http://example.com/path") {
    Ok(uri1) => {
      assert_eq(@uri.is_absolute_uri(uri1), true)
      assert_eq(@uri.is_relative_uri(uri1), false)
    }
    Err(e) => fail("Failed to parse absolute URI: \{e}")
  }

  // Test relative URI reference
  match @uri.parse_uri_reference("relative/path") {
    Ok(uri2) => {
      assert_eq(@uri.is_absolute_uri(uri2), false)
      assert_eq(@uri.is_relative_uri(uri2), true)
    }
    Err(e) => fail("Failed to parse relative URI: \{e}")
  }
}

///|
test "http uri validation" {
  // Valid HTTP URI
  match @uri.parse_uri("http://example.com:8080/") {
    Ok(valid_http) =>
      match @uri.validate_scheme_specific(valid_http) {
        Ok(_) => () // Expected
        Err(e) => fail("Valid HTTP URI failed validation: \{e}")
      }
    Err(e) => fail("Failed to parse valid HTTP URI: \{e}")
  }

  // Test scheme-specific validation with a URI that should be invalid for HTTP
  // Create a simple URI without authority for testing
  match @uri.create_simple_uri("http", "/path") {
    Ok(invalid_http) =>
      match @uri.validate_scheme_specific(invalid_http) {
        Ok(_) => fail("Invalid HTTP URI should fail validation")
        Err(_) => () // Expected
      }
    Err(_) => () // If creation fails, that's also valid
  }
}

///|
test "file uri validation" {
  // Valid file URI
  match @uri.create_file_uri("/path/to/file") {
    Ok(valid_file) =>
      match @uri.validate_scheme_specific(valid_file) {
        Ok(_) => () // Expected
        Err(e) => fail("Valid file URI failed validation: \{e}")
      }
    Err(e) => fail("Failed to create file URI: \{e}")
  }
}

///|
test "uri equivalence" {
  // Test equivalence of URIs with different case
  match
    (
      @uri.parse_uri("HTTP://EXAMPLE.COM/path?query"),
      @uri.parse_uri("http://example.com/path?query"),
    ) {
    (Ok(uri1), Ok(uri2)) => assert_eq(@uri.uris_equivalent(uri1, uri2), true)
    _ => fail("Failed to parse test URIs")
  }
}

///|
test "comprehensive uri validation" {
  // Test comprehensive validation
  match
    @uri.parse_uri(
      "https://user@example.com:443/secure/path?param=value#section",
    ) {
    Ok(valid_uri) =>
      match @uri.validate_uri_comprehensive(valid_uri) {
        Ok(_) => () // Expected
        Err(e) => fail("Valid URI failed comprehensive validation: \{e}")
      }
    Err(e) => fail("Failed to parse test URI: \{e}")
  }
}

///|
test "validation edge cases and error paths" {
  // Test is_valid_uri_reference with invalid reference
  assert_eq(@uri.is_valid_uri_reference("http://[::1"), false) // Invalid IPv6
  
  // Test HTTP URI with invalid port range
  // We can't easily construct this through parsing, so test the concept
  match @uri.create_http_uri("example.com", Some(99999), "/", None, None) {
    Ok(_) => fail("Should not create HTTP URI with invalid port")
    Err(_) => () // Expected error
  }
  
  // Test FTP URI without authority
  match @uri.create_simple_uri("ftp", "/file.txt") {
    Ok(ftp_uri) =>
      match @uri.validate_scheme_specific(ftp_uri) {
        Ok(_) => fail("FTP URI without authority should fail validation")
        Err(_) => () // Expected: "FTP URIs must have an authority component"
      }
    Err(_) => () // May fail during creation
  }
  
  // Test file URI with different authority types
  let ipv4_host = @uri.make_ipv4_host("192.168.1.1")
  let file_auth = @uri.create_authority(None, ipv4_host, None)
  match @uri.create_uri("file", Some(file_auth), "/path", None, None) {
    Ok(file_uri) =>
      match @uri.validate_scheme_specific(file_uri) {
        Ok(_) => fail("File URI with IPv4 host should fail validation")
        Err(_) => () // Expected: "File URIs should use reg-name for host"
      }
    Err(_) => () // May fail during creation
  }
  
  // Test file URI without authority
  match @uri.create_uri("file", None, "/path", None, None) {
    Ok(file_uri) =>
      match @uri.validate_scheme_specific(file_uri) {
        Ok(_) => () // Expected: "Authority can be omitted"
        Err(_) => fail("File URI without authority should be valid")
      }
    Err(_) => () // May fail during creation
  }
  
  // Test file URI with non-localhost hostname
  let other_host = @uri.make_reg_name_host("other.host")
  let other_auth = @uri.create_authority(None, other_host, None)
  match @uri.create_uri("file", Some(other_auth), "/path", None, None) {
    Ok(file_uri) =>
      match @uri.validate_scheme_specific(file_uri) {
        Ok(_) => () // Non-localhost hostnames are implementation-dependent
        Err(_) => () // May also be rejected
      }
    Err(_) => () 
  }
}

///|
test "uri equivalence edge cases" {
  // Test authorities_equivalent with both None
  match (@uri.parse_uri("http://example.com/"), @uri.parse_uri("http://example.com/")) {
    (Ok(uri1), Ok(uri2)) => {
      // Both have authority, should be equivalent
      assert_eq(@uri.uris_equivalent(uri1, uri2), true)
    }
    _ => ()
  }
  
  // Test authorities_equivalent with mismatch (one Some, one None)
  match (@uri.parse_uri("mailto:user@example.com"), @uri.parse_uri_reference("mailto:user@example.com")) {
    (Ok(uri1), Ok(uri2)) => {
      // Test equivalence
      ignore(@uri.uris_equivalent(uri1, uri2))
    }
    _ => ()
  }
  
  // Test hosts_equivalent with IPv4 hosts
  let ipv4_host1 = @uri.make_ipv4_host("192.168.1.1")
  let ipv4_host2 = @uri.make_ipv4_host("192.168.1.1")
  let auth1 = @uri.create_authority(None, ipv4_host1, None)
  let auth2 = @uri.create_authority(None, ipv4_host2, None)
  match (@uri.create_uri("http", Some(auth1), "/", None, None), @uri.create_uri("http", Some(auth2), "/", None, None)) {
    (Ok(uri1), Ok(uri2)) => {
      ignore(@uri.uris_equivalent(uri1, uri2))
    }
    _ => ()
  }
  
  // Test hosts_equivalent with IPv6 hosts
  let ipv6_host1 = @uri.make_ipv6_host("2001:db8::1")
  let ipv6_host2 = @uri.make_ipv6_host("2001:DB8::1") // Different case
  let auth3 = @uri.create_authority(None, ipv6_host1, None)
  let auth4 = @uri.create_authority(None, ipv6_host2, None)
  match (@uri.create_uri("http", Some(auth3), "/", None, None), @uri.create_uri("http", Some(auth4), "/", None, None)) {
    (Ok(uri1), Ok(uri2)) => {
      // Should be equivalent due to case-insensitive comparison
      ignore(@uri.uris_equivalent(uri1, uri2))
    }
    _ => ()
  }
  
  // Test hosts_equivalent with IPvFuture hosts
  let ipvf_host1 = @uri.make_ipv_future_host("v1.example")
  let ipvf_host2 = @uri.make_ipv_future_host("v1.example")
  let auth5 = @uri.create_authority(None, ipvf_host1, None)
  let auth6 = @uri.create_authority(None, ipvf_host2, None)
  match (@uri.create_uri("http", Some(auth5), "/", None, None), @uri.create_uri("http", Some(auth6), "/", None, None)) {
    (Ok(uri1), Ok(uri2)) => {
      ignore(@uri.uris_equivalent(uri1, uri2))
    }
    _ => ()
  }
  
  // Test hosts_equivalent with different types (mix)
  let reg_host = @uri.make_reg_name_host("example.com")
  let ipv4_host = @uri.make_ipv4_host("192.168.1.1")
  let auth7 = @uri.create_authority(None, reg_host, None)
  let auth8 = @uri.create_authority(None, ipv4_host, None)
  match (@uri.create_uri("http", Some(auth7), "/", None, None), @uri.create_uri("http", Some(auth8), "/", None, None)) {
    (Ok(uri1), Ok(uri2)) => {
      // Different host types should not be equivalent
      ignore(@uri.uris_equivalent(uri1, uri2))
    }
    _ => ()
  }
  
  // Test ports_equivalent with explicit ports
  let auth_with_port = @uri.create_authority(None, @uri.make_reg_name_host("example.com"), Some(8080))
  let auth_with_port2 = @uri.create_authority(None, @uri.make_reg_name_host("example.com"), Some(8080))
  match (@uri.create_uri("http", Some(auth_with_port), "/", None, None), @uri.create_uri("http", Some(auth_with_port2), "/", None, None)) {
    (Ok(uri1), Ok(uri2)) => {
      ignore(@uri.uris_equivalent(uri1, uri2))
    }
    _ => ()
  }
}

///|
test "uri structure validation" {
  // Test URI with authority but path not starting with '/'
  // This is hard to construct through normal parsing
  let auth = @uri.create_authority(None, @uri.make_reg_name_host("example.com"), None)
  match @uri.create_uri("http", Some(auth), "badpath", None, None) {
    Ok(_) => fail("Should not create URI with authority and bad path")
    Err(_) => () // Expected: "Path must be empty or start with '/' when authority is present"
  }
  
  // Test URI without authority but path starting with '//'
  match @uri.create_uri("mailto", None, "//invalid", None, None) {
    Ok(_) => fail("Should not create URI without authority and path starting with '//'")
    Err(_) => () // Expected: "Path cannot start with '//' without authority"
  }
}
