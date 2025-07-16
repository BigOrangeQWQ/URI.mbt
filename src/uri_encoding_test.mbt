///| Tests for URI encoding utilities
test "percent encoding basic" {
  let test_cases = [
    (" ", "%20"),
    ("!", "%21"),
    ("@", "%40"),
    ("#", "%23"),
    ("%", "%25"),
  ]
  for i = 0; i < test_cases.length(); i = i + 1 {
    let (input, expected) = test_cases[i]
    let encoded = @uri.percent_encode(input, fn(c) {
      not(@uri.is_unreserved(c))
    })
    assert_eq(encoded, expected)
  }
}

///|
test "percent decoding basic" {
  let test_cases = [
    ("%20", " "),
    ("%21", "!"),
    ("%40", "@"),
    ("%23", "#"),
    ("%25", "%"),
  ]
  for i = 0; i < test_cases.length(); i = i + 1 {
    let (input, expected) = test_cases[i]
    match @uri.percent_decode(input) {
      Ok(decoded) => assert_eq(decoded, expected)
      Err(e) => fail("Decoding failed for \{input}: \{e}")
    }
  }
}

///|
test "percent encoding roundtrip" {
  let test_strings = [
    "hello world", "user@domain.com", "path/with spaces/and!symbols", "query=value&another=param",
    "fragment#with#hashes",
  ]
  for i = 0; i < test_strings.length(); i = i + 1 {
    let original = test_strings[i]
    let encoded = @uri.percent_encode(original, fn(c) {
      not(@uri.is_unreserved(c)) && c != '%'
    })
    match @uri.percent_decode(encoded) {
      Ok(decoded) => assert_eq(decoded, original)
      Err(e) => fail("Roundtrip failed for \{original}: \{e}")
    }
  }
}

///|
test "invalid percent encoding" {
  let invalid_cases = [
    "%", // Incomplete
     "%2", // Incomplete
     "%ZZ", // Invalid hex
     "%2G", // Invalid hex
     "hello%world",
  ]
  for i = 0 // No hex digits
      i < invalid_cases.length()
      i = i + 1 {
    match @uri.percent_decode(invalid_cases[i]) {
      Ok(_) => fail("Should have failed for: \{invalid_cases[i]}")
      Err(_) => () // Expected
    }
  }
}

///|
test "component specific encoding" {
  // Test different encoding functions for different URI components
  let test_string = "hello world!@#$"
  let path_encoded = @uri.encode_path_segment(test_string)
  let query_encoded = @uri.encode_query(test_string)
  let fragment_encoded = @uri.encode_fragment(test_string)
  let userinfo_encoded = @uri.encode_userinfo(test_string)
  let regname_encoded = @uri.encode_reg_name(test_string)

  // All should produce encoded versions
  assert_not_eq(path_encoded, test_string)
  assert_not_eq(query_encoded, test_string)
  assert_not_eq(fragment_encoded, test_string)
  assert_not_eq(userinfo_encoded, test_string)
  assert_not_eq(regname_encoded, test_string)
}
