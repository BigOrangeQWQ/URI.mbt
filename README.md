# MoonBit URI Library (Vibe)

A comprehensive URI parsing and manipulation library for the MoonBit programming language, implementing RFC 3986 specification.

## Overview

This library provides robust parsing, validation, and creation of Uniform Resource Identifiers (URIs). It supports all standard URI components including schemes, authorities, paths, queries, and fragments, with proper percent-encoding handling and comprehensive validation.

## Installation

Add this package to your MoonBit project:

```bash
moon add BigOrangeQWQ/uri
```

Then import it in your `moon.pkg.json`:

```json
{
  "import": ["BigOrangeQWQ/uri"]
}
```

## Quick Start

### Basic URI Parsing

```moonbit
// Parse a complete URI
let uri_string = "https://example.com:8080/path?query=value#fragment"
match parse_uri(uri_string) {
  Ok(uri) => {
    println("Scheme: \{uri.scheme}")
    println("Host: \{uri.authority}")
    println("Path: \{uri.path}")
  }
  Err(error) => println("Parse error: \{error}")
}
```

### Creating URIs with Builder

```moonbit
// Build an HTTP URI fluently
let uri = new_builder()
  .scheme("https")
  .host("api.example.com")
  .port(443)
  .path("/v1/users")
  .add_query_param("limit", "10")
  .add_query_param("offset", "20")
  .fragment("results")
  .build()

match uri {
  Ok(u) => println("Built URI: \{uri_to_string(u)}")
  Err(e) => println("Build error: \{e}")
}
```

## API Reference

### Core Types

#### URI Structure

```moonbit
pub struct URI {
  scheme : String        // Required scheme (http, https, ftp, etc.)
  authority : Authority? // Optional authority component
  path : String          // Path component
  path_type : PathType   // Classification of path type
  query : String?        // Optional query string
  fragment : String?     // Optional fragment identifier
}
```

#### Authority Component

```moonbit
pub struct Authority {
  userinfo : String?  // Optional user information
  host : HostType     // Host (required in authority)
  port : Int?         // Optional port number
}

pub enum HostType {
  IPv4(String)      // IPv4 address (e.g., "192.168.1.1")
  IPv6(String)      // IPv6 address (e.g., "::1")
  IPvFuture(String) // Future IP version
  RegName(String)   // Regular domain name (e.g., "example.com")
}
```

### Parsing Functions

#### parse_uri(uri_string : String) -> URIResult[URI]

Parse a complete URI string. The URI must contain a scheme.

```moonbit
let result = parse_uri("https://user@example.com:8080/path?q=val#frag")
```

#### parse_uri_reference(uri_ref_string : String) -> URIResult[URI]

Parse either a complete URI or a relative reference.

```moonbit
// Absolute URI
let abs_uri = parse_uri_reference("https://example.com/path")

// Relative reference
let rel_ref = parse_uri_reference("/path?query=value")
```

### Creation Functions

#### create_uri() - Full URI Creation

```moonbit
pub fn create_uri(
  scheme : String,
  authority : Authority?,
  path : String,
  query : String?,
  fragment : String?
) -> URIResult[URI]
```

#### Convenience Creators

```moonbit
// Simple URI with scheme and path
create_simple_uri("file", "/path/to/file.txt")

// HTTP URI
create_http_uri("example.com", Some(8080), "/api", Some("v=1"), None)

// HTTPS URI
create_https_uri("secure.example.com", None, "/", None, Some("top"))

// File URI
create_file_uri("/home/user/document.pdf")
```

### URI Builder

The builder pattern provides a fluent interface for constructing URIs:

```moonbit
new_builder()
  .scheme("https")               // Set scheme
  .host("api.example.com")       // Set host (creates authority)
  .port(443)                     // Set port
  .userinfo("user:pass")         // Set userinfo
  .path("/v1/endpoint")          // Set path
  .add_path_segment("users")     // Add path segment
  .query("format=json")          // Set query string
  .add_query_param("page", "1")  // Add single parameter
  .fragment("section1")          // Set fragment
  .build()                       // Build final URI
```

### Utility Functions

#### uri_to_string(uri : URI) -> String

Convert a URI back to its string representation.

```moonbit
let uri_string = uri_to_string(parsed_uri)
```

#### resolve_reference(base : URI, reference : URI) -> URIResult[URI]

Resolve a relative reference against a base URI according to RFC 3986.

```moonbit
let base = parse_uri("https://example.com/base/path")
let reference = parse_uri_reference("../other/file")
let resolved = resolve_reference(base, reference)
```

## Error Handling

The library uses a comprehensive error system:

```moonbit
pub enum URIError {
  InvalidScheme(String)
  InvalidAuthority(String)
  InvalidHost(String)
  InvalidPort(String)
  InvalidPath(String)
  InvalidQuery(String)
  InvalidFragment(String)
  InvalidPercentEncoding(String)
  MalformedURI(String)
}
```

All parsing and creation functions return `URIResult[T]` which is an alias for `Result[T, URIError]`.

## Examples

### Simple Web URL

```moonbit
fn example_web_url() {
  let url = new_builder()
    .scheme("https")
    .host("www.example.com")
    .add_path_segment("products")
    .add_path_segment("123")
    .add_query_param("color", "blue")
    .add_query_param("size", "large")
    .build()

  match url {
    Ok(uri) => {
      // Output: https://www.example.com/products/123?color=blue&size=large
      println(uri_to_string(uri))
    }
    Err(e) => println("Error: \{e}")
  }
}
```

### File URI

```moonbit
fn example_file_uri() {
  let file_uri = create_file_uri("/home/user/documents/report.pdf")
  match file_uri {
    Ok(uri) => {
      // Output: file:///home/user/documents/report.pdf
      println(uri_to_string(uri))
    }
    Err(e) => println("Error: \{e}")
  }
}
```

### Complex URI with IPv6 Host

```moonbit
fn example_ipv6_uri() {
  let host_type = HostType::IPv6("2001:db8::1")
  let authority = { userinfo: None, host: host_type, port: Some(8080) }
  
  let uri = create_uri(
    "http", 
    Some(authority), 
    "/api/v1/data", 
    Some("format=json"), 
    Some("results")
  )
  
  match uri {
    Ok(u) => {
      // Output: http://[2001:db8::1]:8080/api/v1/data?format=json#results
      println(uri_to_string(u))
    }
    Err(e) => println("Error: \{e}")
  }
}
```

### Parsing and Validating User Input

```moonbit
fn validate_user_uri(input : String) -> Bool {
  match parse_uri_reference(input) {
    Ok(uri) => {
      // Additional validation can be performed here
      true
    }
    Err(_) => false
  }
}

fn example_validation() {
  let test_urls = [
    "https://example.com",
    "ftp://files.example.com/path",
    "/relative/path",
    "invalid::uri",
  ]
  
  for url in test_urls {
    if validate_user_uri(url) {
      println("\{url} is valid")
    } else {
      println("\{url} is invalid")
    }
  }
}
```

### Working with Query Parameters

```moonbit
fn example_query_handling() {
  let params = [
    ("search", "moon programming"),
    ("page", "1"),
    ("sort", "date"),
    ("order", "desc")
  ]
  
  let uri = new_builder()
    .scheme("https")
    .host("search.example.com")
    .path("/results")
    .query_params(params)
    .build()
  
  match uri {
    Ok(u) => {
      // Properly encoded query string
      println(uri_to_string(u))
    }
    Err(e) => println("Error: \{e}")
  }
}
```

## Testing

The library includes comprehensive tests for all functionality. Run tests with:

```bash
moon test
```

## License

Licensed under Apache 2.0 License.
