fn main {
  let uri_string = "https://example.com:8080/path?query=value#fragment"
  match parse_uri(uri_string) {
    Ok(uri) => {
      let reconstructed = uri_to_string(uri)
      println("Original: \{uri_string}")
      println("Reconstructed: \{reconstructed}")
    }
    Err(e) => println("Parse error: \{e}")
  }
}
