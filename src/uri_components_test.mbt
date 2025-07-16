///| Tests for URI component parsing
test "scheme parsing valid" {
  let valid_schemes = ["http", "https", "ftp", "file", "mailto", "tel", "HTTP", "HTTPS"]
  for i = 0; i < valid_schemes.length(); i = i + 1 {
    match @uri.parse_scheme(valid_schemes[i]) {
      Ok(scheme) => {
        // Schemes should be normalized to lowercase
        assert_eq(scheme, valid_schemes[i].to_lower())
      }
      Err(e) => fail("Should be valid scheme \{valid_schemes[i]}: \{e}")
    }
  }
}

test "scheme parsing invalid" {
  let invalid_schemes = ["", "123", "_http", "http:", "ht@tp", "http//"]
  for i = 0; i < invalid_schemes.length(); i = i + 1 {
    match @uri.parse_scheme(invalid_schemes[i]) {
      Ok(_) => fail("Should be invalid scheme: \{invalid_schemes[i]}")
      Err(_) => () // Expected
    }
  }
}

test "query parsing" {
  let valid_queries = ["", "key=value", "a=1&b=2", "key", "complex%20query"]
  for i = 0; i < valid_queries.length(); i = i + 1 {
    match @uri.parse_query(valid_queries[i]) {
      Ok(query) => assert_eq(query, valid_queries[i])
      Err(e) => fail("Should be valid query \{valid_queries[i]}: \{e}")
    }
  }
}

test "fragment parsing" {
  let valid_fragments = ["", "section1", "complex%20fragment", "frag?with=query"]
  for i = 0; i < valid_fragments.length(); i = i + 1 {
    match @uri.parse_fragment(valid_fragments[i]) {
      Ok(fragment) => assert_eq(fragment, valid_fragments[i])
      Err(e) => fail("Should be valid fragment \{valid_fragments[i]}: \{e}")
    }
  }
}

test "query parameter parsing" {
  let test_cases = [
    ("", []),
    ("key=value", [("key", "value")]),
    ("a=1&b=2", [("a", "1"), ("b", "2")]),
    ("key", [("key", "")]),
    ("a=1&b&c=3", [("a", "1"), ("b", ""), ("c", "3")]),
    ("hello%20world=test", [("hello world", "test")]),
  ]
  for i = 0; i < test_cases.length(); i = i + 1 {
    let (query, expected) = test_cases[i]
    let result = @uri.parse_query_params(query)
    assert_eq(result.length(), expected.length())
    for j = 0; j < expected.length(); j = j + 1 {
      assert_eq(result[j], expected[j])
    }
  }
}

test "query string building" {
  let test_cases = [
    ([], ""),
    ([("key", "value")], "key=value"),
    ([("a", "1"), ("b", "2")], "a=1&b=2"),
    ([("key", "")], "key"),
    ([("hello world", "test")], "hello%20world=test"),
  ]
  for i = 0; i < test_cases.length(); i = i + 1 {
    let (params, expected) = test_cases[i]
    let result = @uri.build_query_string(params)
    assert_eq(result, expected)
  }
}

test "scheme comparison" {
  assert_eq(@uri.schemes_equal("http", "HTTP"), true)
  assert_eq(@uri.schemes_equal("https", "https"), true)
  assert_eq(@uri.schemes_equal("http", "https"), false)
}

test "uri case normalization" {
  // Create a URI using parse_uri instead of manual construction
  let uri_str = "HTTP://EXAMPLE.COM:80/Path?Query=Value#Fragment"
  match @uri.parse_uri(uri_str) {
    Ok(uri) => {
      let normalized = @uri.normalize_uri_case(uri)
      assert_eq(normalized.scheme, "http")
      match normalized.authority {
        Some(auth) => {
          match auth.host {
            @uri.HostType::RegName(name) => assert_eq(name, "example.com")
            _ => fail("Expected RegName host")
          }
        }
        None => fail("Expected authority")
      }
    }
    Err(e) => fail("Failed to parse test URI: \{e}")
  }
}