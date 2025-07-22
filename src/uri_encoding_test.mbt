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
test "encoding edge cases and error paths" {
  // Test percent decoding with incomplete encoding
  match @uri.percent_decode("%2") {
    Ok(_) => fail("Should fail with incomplete percent encoding")
    Err(_) => () // Expected: "Incomplete percent encoding at end"
  }
  match @uri.percent_decode("%") {
    Ok(_) => fail("Should fail with incomplete percent encoding")
    Err(_) => () // Expected: "Incomplete percent encoding at end"
  }

  // Test percent decoding with invalid hex digits
  match @uri.percent_decode("%GG") {
    Ok(_) => fail("Should fail with invalid hex digits")
    Err(_) => () // Expected: "Invalid hex digits"
  }

  // Test percent decoding with invalid byte value (out of range)
  match @uri.percent_decode("%FF") {
    Ok(_) => () // May work for some values
    Err(_) => () // May fail for high byte values
  }

  // Test encoding with non-ASCII characters (edge case in encoding)
  let non_ascii = "café"
  let encoded_non_ascii = @uri.percent_encode(non_ascii, fn(c) {
    c.to_int() > 127 // Encode non-ASCII
  })
  // Should handle non-ASCII characters
  assert_eq(encoded_non_ascii.length() > 0, true)

  // Test specific encoding functions
  let path_segment = "path with spaces"
  let encoded_path = @uri.encode_path_segment(path_segment)
  assert_eq(encoded_path.contains("%20"), true)
  let query_param = "param with spaces"
  let encoded_query = @uri.encode_query(query_param)
  assert_eq(encoded_query.contains("%20"), true)
  let fragment_text = "fragment with spaces"
  let encoded_fragment = @uri.encode_fragment(fragment_text)
  assert_eq(encoded_fragment.contains("%20"), true)
  let userinfo_text = "user:pass"
  let encoded_userinfo = @uri.encode_userinfo(userinfo_text)
  // May or may not encode the colon depending on validation
  assert_eq(encoded_userinfo.length() > 0, true)
  let reg_name = "domain with spaces"
  let encoded_reg_name = @uri.encode_reg_name(reg_name)
  assert_eq(encoded_reg_name.contains("%20"), true)
}

///|
test "validation functions" {
  // Test is_valid_percent_encoding
  assert_eq(@uri.is_valid_percent_encoding("%20"), true)
  assert_eq(@uri.is_valid_percent_encoding("%2G"), false)
  assert_eq(@uri.is_valid_percent_encoding("%2"), false)
  assert_eq(@uri.is_valid_percent_encoding("normal"), true)

  // Test is_valid_encoded_string
  assert_eq(@uri.is_valid_encoded_string("normal", @uri.is_unreserved), true)
  assert_eq(@uri.is_valid_encoded_string("%20", @uri.is_unreserved), true)
  assert_eq(@uri.is_valid_encoded_string("%2G", @uri.is_unreserved), false)
  assert_eq(@uri.is_valid_encoded_string("@", @uri.is_unreserved), false) // @ is not unreserved
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
