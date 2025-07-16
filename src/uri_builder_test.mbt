///| Tests for URI builder and creation functions
test "uri builder basic" {
  match
    @uri.new_builder()
    .scheme("https")
    .host("example.com")
    .port(443)
    .path("/path")
    .query("query=value")
    .fragment("fragment")
    .build() {
    Ok(uri) => {
      assert_eq(uri.scheme, "https")
      match uri.authority {
        Some(auth) => {
          match auth.host {
            HostType::RegName(host) => assert_eq(host, "example.com")
            _ => fail("Expected RegName host")
          }
          assert_eq(auth.port, Some(443))
        }
        None => fail("Expected authority")
      }
      assert_eq(uri.path, "/path")
      assert_eq(uri.query, Some("query=value"))
      assert_eq(uri.fragment, Some("fragment"))
    }
    Err(e) => fail("Builder failed: \{e}")
  }
}

///|
test "uri builder with query params" {
  match
    @uri.new_builder()
    .scheme("http")
    .host("api.example.com")
    .path("/users")
    .add_query_param("limit", "10")
    .add_query_param("offset", "0")
    .add_query_param("sort", "name")
    .build() {
    Ok(uri) => {
      let uri_str = @uri.uri_to_string(uri)
      assert_eq(
        uri_str, "http://api.example.com/users?limit=10&offset=0&sort=name",
      )
    }
    Err(e) => fail("Builder failed: \{e}")
  }
}

///|
test "uri builder with path segments" {
  let builder = @uri.new_builder().scheme("https").host("example.com")
  ignore(builder.add_path_segment("api"))
  ignore(builder.add_path_segment("v1"))
  ignore(builder.add_path_segment("users"))
  ignore(builder.add_path_segment("123"))
  match builder.build() {
    Ok(uri) => {
      // The exact path format depends on implementation
      // but should contain all segments
      let uri_str = @uri.uri_to_string(uri)
      assert_eq(uri_str.contains("api"), true)
      assert_eq(uri_str.contains("v1"), true)
      assert_eq(uri_str.contains("users"), true)
      assert_eq(uri_str.contains("123"), true)
    }
    Err(e) => fail("Builder failed: \{e}")
  }
}

///|
test "create uri functions" {
  // Test HTTP URI creation
  match
    @uri.create_http_uri(
      "example.com",
      Some(8080),
      "/path",
      Some("q=v"),
      Some("frag"),
    ) {
    Ok(uri) => {
      assert_eq(uri.scheme, "http")
      let uri_str = @uri.uri_to_string(uri)
      assert_eq(uri_str, "http://example.com:8080/path?q=v#frag")
    }
    Err(e) => fail("HTTP URI creation failed: \{e}")
  }

  // Test HTTPS URI creation
  match @uri.create_https_uri("secure.example.com", None, "/", None, None) {
    Ok(uri) => {
      assert_eq(uri.scheme, "https")
      let uri_str = @uri.uri_to_string(uri)
      assert_eq(uri_str, "https://secure.example.com/")
    }
    Err(e) => fail("HTTPS URI creation failed: \{e}")
  }

  // Test file URI creation
  match @uri.create_file_uri("/path/to/file.txt") {
    Ok(uri) => {
      assert_eq(uri.scheme, "file")
      let uri_str = @uri.uri_to_string(uri)
      assert_eq(uri_str, "file:///path/to/file.txt")
    }
    Err(e) => fail("File URI creation failed: \{e}")
  }
}

///|
test "uri to string conversion" {
  let test_cases = [
    ("http", Some("example.com"), "/", None, None, "http://example.com/"),
    (
      "https",
      Some("user@host.com:443"),
      "/path",
      Some("q=v"),
      Some("frag"),
      "https://user@host.com:443/path?q=v#frag",
    ),
    ("file", Some(""), "/path/file", None, None, "file:///path/file"),
    (
      "ftp",
      Some("ftp.example.com"),
      "/dir/file.txt",
      None,
      None,
      "ftp://ftp.example.com/dir/file.txt",
    ),
  ]
  for i = 0; i < test_cases.length(); i = i + 1 {
    let (scheme, auth_str, path, query, fragment, expected) = test_cases[i]
    let authority = match auth_str {
      Some(s) =>
        if s.is_empty() {
          // Special case for empty authority (like file://)
          Some(@uri.create_authority(None, @uri.make_reg_name_host(""), None))
        } else {
          match @uri.parse_authority(s) {
            Ok(auth) => Some(auth)
            Err(_) => None
          }
        }
      None => None
    }
    match @uri.create_uri(scheme, authority, path, query, fragment) {
      Ok(uri) => {
        let uri_str = @uri.uri_to_string(uri)
        assert_eq(uri_str, expected)
      }
      Err(e) => fail("URI creation failed for case \{i}: \{e}")
    }
  }
}

///|
test "uri resolution" {
  // Test resolving relative reference against base URI
  match
    (
      @uri.parse_uri("http://example.com/a/b/c"),
      @uri.parse_uri_reference("../d"),
    ) {
    (Ok(base), Ok(relative)) =>
      match @uri.resolve_reference(base, relative) {
        Ok(resolved) => {
          let resolved_str = @uri.uri_to_string(resolved)
          assert_eq(resolved_str, "http://example.com/a/d")
        }
        Err(e) => fail("Resolution failed: \{e}")
      }
    _ => fail("Failed to parse test URIs")
  }

  // Test resolving absolute reference (should return reference as-is)
  match
    (
      @uri.parse_uri("http://example.com/a/b"),
      @uri.parse_uri("https://other.com/x"),
    ) {
    (Ok(base), Ok(absolute)) =>
      match @uri.resolve_reference(base, absolute) {
        Ok(resolved) => {
          let resolved_str = @uri.uri_to_string(resolved)
          assert_eq(resolved_str, "https://other.com/x")
        }
        Err(e) => fail("Absolute resolution failed: \{e}")
      }
    _ => fail("Failed to parse test URIs")
  }
}
