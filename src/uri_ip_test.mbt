///| Tests for IP address parsing
test "ipv4 valid addresses" {
  let valid_ipv4 = [
    "0.0.0.0", "127.0.0.1", "192.168.1.1", "255.255.255.255", "10.0.0.1", "172.16.0.1",
  ]
  for i = 0; i < valid_ipv4.length(); i = i + 1 {
    match @uri.parse_ipv4_address(valid_ipv4[i]) {
      Ok(addr) => assert_eq(addr, valid_ipv4[i])
      Err(e) => fail("Should be valid IPv4 \{valid_ipv4[i]}: \{e}")
    }
  }
}

///|
test "ipv4 invalid addresses" {
  let invalid_ipv4 = [
    "256.1.1.1", // Octet too large
     "1.1.1", // Too few octets
     "1.1.1.1.1", // Too many octets
     "1.1.1.a", // Non-numeric
     "", // Empty
     "1.1.1.", // Trailing dot
     ".1.1.1", // Leading dot
  ]
  for i = 0; i < invalid_ipv4.length(); i = i + 1 {
    match @uri.parse_ipv4_address(invalid_ipv4[i]) {
      Ok(_) => fail("Should be invalid IPv4: \{invalid_ipv4[i]}")
      Err(_) => () // Expected
    }
  }
}

///|
test "ipv6 basic validation" {
  let valid_ipv6 = [
    "2001:db8::1", "::1", "2001:db8:85a3::8a2e:370:7334", "::", "2001:db8::8a2e:370:7334",
  ]
  for i = 0; i < valid_ipv6.length(); i = i + 1 {
    match @uri.parse_ipv6_address(valid_ipv6[i]) {
      Ok(addr) => assert_eq(addr, valid_ipv6[i])
      Err(e) => fail("Should be valid IPv6 \{valid_ipv6[i]}: \{e}")
    }
  }
}

///|
test "ipv6 invalid addresses" {
  let invalid_ipv6 = [
    "", // Empty
     ":", // Single colon
     ":::", // Triple colon
     "2001:db8::1::2", // Multiple double colons
     "gggg::1", // Invalid hex
  ]
  for i = 0;
      i < invalid_ipv6.length()
      i = i + 1 {
    match @uri.parse_ipv6_address(invalid_ipv6[i]) {
      Ok(_) => fail("Should be invalid IPv6: \{invalid_ipv6[i]}")
      Err(_) => () // Expected  
    }
  }
}

///|
test "ipv_future parsing" {
  let valid_future = ["v1.abc", "vA.test:123", "vFF.example.future-ip"]
  for i = 0; i < valid_future.length(); i = i + 1 {
    match @uri.parse_ipv_future(valid_future[i]) {
      Ok(addr) => assert_eq(addr, valid_future[i])
      Err(e) => fail("Should be valid IPvFuture \{valid_future[i]}: \{e}")
    }
  }
}

///|
test "ipv_future invalid" {
  let invalid_future = [
    "1.abc", // Missing 'v'
     "v.abc", // No version number
     "vg.abc", // Invalid hex in version
     "v1.", // No content after dot
     "v1.ab\u{07}c", // Invalid characters after dot
  ]
  for i = 0;
      i < invalid_future.length()
      i = i + 1 {
    match @uri.parse_ipv_future(invalid_future[i]) {
      Ok(_) => fail("Should be invalid IPvFuture: \{invalid_future[i]}")
      Err(_) => () // Expected
    }
  }
}

///|
test "ip literal parsing" {
  // IPv6 literals
  match @uri.parse_ip_literal("[2001:db8::1]") {
    Ok(IPv6(addr)) => assert_eq(addr, "2001:db8::1")
    Ok(_) => fail("Expected IPv6 type")
    Err(e) => fail("Parsing failed: \{e}")
  }

  // IPvFuture literals
  match @uri.parse_ip_literal("[v1.abc]") {
    Ok(IPvFuture(addr)) => assert_eq(addr, "v1.abc")
    Ok(_) => fail("Expected IPvFuture type")
    Err(e) => fail("Parsing failed: \{e}")
  }

  // Invalid literals
  let invalid_literals = [
    "2001:db8::1", // Missing brackets
     "[2001:db8::1", // Missing closing bracket
     "2001:db8::1]", // Missing opening bracket
     "[]",
  ]
  for i = 0 // Empty
      i < invalid_literals.length()
      i = i + 1 {
    match @uri.parse_ip_literal(invalid_literals[i]) {
      Ok(_) => fail("Should be invalid literal: \{invalid_literals[i]}")
      Err(_) => () // Expected
    }
  }
}

///|
test "host parsing" {
  // IPv4 host
  match @uri.parse_host("192.168.1.1") {
    Ok(IPv4(addr)) => assert_eq(addr, "192.168.1.1")
    Ok(_) => fail("Expected IPv4 type")
    Err(e) => fail("Parsing failed: \{e}")
  }

  // IPv6 host (bracketed)
  match @uri.parse_host("[::1]") {
    Ok(IPv6(addr)) => assert_eq(addr, "::1")
    Ok(_) => fail("Expected IPv6 type")
    Err(e) => fail("Parsing failed: \{e}")
  }

  // Regular name host
  match @uri.parse_host("example.com") {
    Ok(HostType::RegName(name)) => assert_eq(name, "example.com")
    Ok(_) => fail("Expected RegName type")
    Err(e) => fail("Parsing failed: \{e}")
  }

  // Invalid host
  match @uri.parse_host("") {
    Ok(_) => fail("Empty host should be invalid")
    Err(_) => () // Expected
  }
}
