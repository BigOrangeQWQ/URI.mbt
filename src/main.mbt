///| Main function demonstrating URI library usage
fn main {
  println("URI Library")
  
  // Example URI parsing and reconstruction
  let uri_string = "https://example.com:8080/path?query=value#fragment"
  match parse_uri(uri_string) {
    Ok(uri) => {
      println("Successfully parsed URI:")
      let reconstructed = uri_to_string(uri)
      println("Original: \{uri_string}")
      println("Reconstructed: \{reconstructed}")
    }
    Err(e) => println("Failed to parse URI: \{e}")
  }
}