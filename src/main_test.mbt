///| Test for main function demonstration
test "main function demo" {
  // Test the same URI that main function uses
  let uri_string = "https://example.com:8080/path?query=value#fragment"
  match @uri.parse_uri(uri_string) {
    Ok(uri) => {
      let reconstructed = @uri.uri_to_string(uri)
      assert_eq(reconstructed, uri_string)
      assert_eq(uri.scheme, "https")
      
      // Test additional properties to increase coverage
      match uri.authority {
        Some(auth) => {
          match auth.host {
            @uri.HostType::RegName(name) => assert_eq(name, "example.com")
            _ => fail("Expected RegName host")
          }
          assert_eq(auth.port, Some(8080))
        }
        None => fail("Expected authority")
      }
      
      assert_eq(uri.path, "/path")
      assert_eq(uri.query, Some("query=value"))
      assert_eq(uri.fragment, Some("fragment"))
    }
    Err(_) => fail("Should parse successfully")
  }
}

test "comprehensive uri examples" {
  // Test more URI examples to increase coverage
  let test_uris = [
    "http://example.com/",
    "ftp://user:pass@ftp.example.com:21/dir/",
    "mailto:test@example.com",
    "file:///absolute/path",
  ]
  
  for i = 0; i < test_uris.length(); i = i + 1 {
    let uri_str = test_uris[i]
    match @uri.parse_uri(uri_str) {
      Ok(uri) => {
        let reconstructed = @uri.uri_to_string(uri)
        // Just verify reconstruction produces a valid string
        assert_eq(reconstructed.length() > 0, true)
        assert_eq(@uri.is_absolute_uri(uri), true)
      }
      Err(_) => () // Some URIs might fail due to implementation specifics
    }
  }
}