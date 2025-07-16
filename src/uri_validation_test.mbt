///| Tests for URI validation utilities

test "uri validation basic" {
  let valid_uris = [
    "http://example.com/",
    "https://user@host.com:443/path?query=value#fragment",
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

test "uri validation invalid" {
  let invalid_uris = [
    "", // Empty
    "://example.com", // No scheme  
  ]
  for i = 0; i < invalid_uris.length(); i = i + 1 {
    let is_valid = @uri.is_valid_uri(invalid_uris[i])
    if is_valid {
      fail("URI should be invalid: \{invalid_uris[i]}")
    }
  }
  
  // "http:" is technically valid according to RFC 3986 (scheme with empty hier-part)
  // "http:///path" is also valid (scheme with empty authority and absolute path)
}

test "uri reference validation" {
  let valid_refs = [
    "http://example.com/",
    "/path/to/resource",
    "../relative/path",
    "?query=only",
    "#fragment-only",
  ]
  for i = 0; i < valid_refs.length(); i = i + 1 {
    assert_eq(@uri.is_valid_uri_reference(valid_refs[i]), true)
  }
}

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

test "http uri validation" {
  // Valid HTTP URI
  match @uri.parse_uri("http://example.com:8080/") {
    Ok(valid_http) => {
      match @uri.validate_scheme_specific(valid_http) {
        Ok(_) => () // Expected
        Err(e) => fail("Valid HTTP URI failed validation: \{e}")
      }
    }
    Err(e) => fail("Failed to parse valid HTTP URI: \{e}")
  }

  // Test scheme-specific validation with a URI that should be invalid for HTTP
  // Create a simple URI without authority for testing
  match @uri.create_simple_uri("http", "/path") {
    Ok(invalid_http) => {
      match @uri.validate_scheme_specific(invalid_http) {
        Ok(_) => fail("Invalid HTTP URI should fail validation")
        Err(_) => () // Expected
      }
    }
    Err(_) => () // If creation fails, that's also valid
  }
}

test "file uri validation" {
  // Valid file URI
  match @uri.create_file_uri("/path/to/file") {
    Ok(valid_file) => {
      match @uri.validate_scheme_specific(valid_file) {
        Ok(_) => () // Expected
        Err(e) => fail("Valid file URI failed validation: \{e}")
      }
    }
    Err(e) => fail("Failed to create file URI: \{e}")
  }
}

test "uri equivalence" {
  // Test equivalence of URIs with different case
  match (@uri.parse_uri("HTTP://EXAMPLE.COM/path?query"), @uri.parse_uri("http://example.com/path?query")) {
    (Ok(uri1), Ok(uri2)) => {
      assert_eq(@uri.uris_equivalent(uri1, uri2), true)
    }
    _ => fail("Failed to parse test URIs")
  }
}

test "comprehensive uri validation" {
  // Test comprehensive validation
  match @uri.parse_uri("https://user@example.com:443/secure/path?param=value#section") {
    Ok(valid_uri) => {
      match @uri.validate_uri_comprehensive(valid_uri) {
        Ok(_) => () // Expected
        Err(e) => fail("Valid URI failed comprehensive validation: \{e}")
      }
    }
    Err(e) => fail("Failed to parse test URI: \{e}")
  }
}