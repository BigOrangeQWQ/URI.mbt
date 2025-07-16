///| Tests for URI authority parsing
test "authority with all components" {
  let authority_str = "user:pass@example.com:8080"
  match @uri.parse_authority(authority_str) {
    Ok(auth) => {
      assert_eq(auth.userinfo, Some("user:pass"))
      match auth.host {
        HostType::RegName(host) => assert_eq(host, "example.com")
        _ => fail("Expected RegName host")
      }
      assert_eq(auth.port, Some(8080))
    }
    Err(e) => fail("Authority parsing failed: \{e}")
  }
}

///|
test "authority host only" {
  let authority_str = "example.com"
  match @uri.parse_authority(authority_str) {
    Ok(auth) => {
      assert_eq(auth.userinfo, None)
      match auth.host {
        HostType::RegName(host) => assert_eq(host, "example.com")
        _ => fail("Expected RegName host")
      }
      assert_eq(auth.port, None)
    }
    Err(e) => fail("Authority parsing failed: \{e}")
  }
}

///|
test "authority with port only" {
  let authority_str = "example.com:443"
  match @uri.parse_authority(authority_str) {
    Ok(auth) => {
      assert_eq(auth.userinfo, None)
      match auth.host {
        HostType::RegName(host) => assert_eq(host, "example.com")
        _ => fail("Expected RegName host")
      }
      assert_eq(auth.port, Some(443))
    }
    Err(e) => fail("Authority parsing failed: \{e}")
  }
}

///|
test "authority with userinfo only" {
  let authority_str = "user@example.com"
  match @uri.parse_authority(authority_str) {
    Ok(auth) => {
      assert_eq(auth.userinfo, Some("user"))
      match auth.host {
        HostType::RegName(host) => assert_eq(host, "example.com")
        _ => fail("Expected RegName host")
      }
      assert_eq(auth.port, None)
    }
    Err(e) => fail("Authority parsing failed: \{e}")
  }
}

///|
test "authority with ipv6 host" {
  let authority_str = "[2001:db8::1]:8080"
  match @uri.parse_authority(authority_str) {
    Ok(auth) => {
      assert_eq(auth.userinfo, None)
      match auth.host {
        IPv6(host) => assert_eq(host, "2001:db8::1")
        _ => fail("Expected IPv6 host")
      }
      assert_eq(auth.port, Some(8080))
    }
    Err(e) => fail("Authority parsing failed: \{e}")
  }
}

///|
test "authority with ipv4 host" {
  let authority_str = "192.168.1.1:80"
  match @uri.parse_authority(authority_str) {
    Ok(auth) => {
      assert_eq(auth.userinfo, None)
      match auth.host {
        IPv4(host) => assert_eq(host, "192.168.1.1")
        _ => fail("Expected IPv4 host")
      }
      assert_eq(auth.port, Some(80))
    }
    Err(e) => fail("Authority parsing failed: \{e}")
  }
}

///|
test "invalid authority" {
  let invalid_authorities = [
    "", // Empty
     "@example.com", // Empty userinfo
     "example.com:", // Empty port
     "example.com:99999", // Port out of range
     "example.com:abc", // Non-numeric port
     "[::1", // Unterminated IPv6
     "[::1]:abc", // Invalid port with IPv6
  ]
  for i = 0; i < invalid_authorities.length(); i = i + 1 {
    match @uri.parse_authority(invalid_authorities[i]) {
      Ok(_) => fail("Should be invalid authority: \{invalid_authorities[i]}")
      Err(_) => () // Expected
    }
  }
}

///|
test "authority creation and string conversion" {
  let userinfo = Some("user:pass")
  let host = @uri.make_reg_name_host("example.com")
  let port = Some(8080)
  let auth = @uri.create_authority(userinfo, host, port)
  let auth_str = @uri.authority_to_string(auth)
  assert_eq(auth_str, "user:pass@example.com:8080")

  // Round trip test
  match @uri.parse_authority(auth_str) {
    Ok(parsed_auth) => {
      assert_eq(parsed_auth.userinfo, userinfo)
      assert_eq(parsed_auth.port, port)
      // Note: host comparison would need custom logic
    }
    Err(e) => fail("Round trip failed: \{e}")
  }
}

///|
test "authority with different host types" {
  let test_cases = [
    (None, @uri.make_ipv4_host("192.168.1.1"), None, "192.168.1.1"),
    (None, @uri.make_ipv6_host("::1"), None, "[::1]"),
    (None, @uri.make_ipv_future_host("v1.abc"), None, "[v1.abc]"),
    (None, @uri.make_reg_name_host("example.com"), None, "example.com"),
    (
      Some("user"),
      @uri.make_reg_name_host("example.com"),
      Some(80),
      "user@example.com:80",
    ),
  ]
  for i = 0; i < test_cases.length(); i = i + 1 {
    let (userinfo, host, port, expected) = test_cases[i]
    let auth = @uri.create_authority(userinfo, host, port)
    let auth_str = @uri.authority_to_string(auth)
    assert_eq(auth_str, expected)
  }
}
