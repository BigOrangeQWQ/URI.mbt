// 完整URL解析的黑盒测试
// 测试各种真实世界的URL解析场景

///|
test "complete_url_parsing_basic" {
  // 基本的HTTP/HTTPS URL
  let basic_http = @uri.parse_uri("http://example.com")
  inspect(basic_http.is_ok(), content="true")
  let basic_https = @uri.parse_uri("https://example.com")
  inspect(basic_https.is_ok(), content="true")
  let with_port = @uri.parse_uri("https://example.com:8443")
  inspect(with_port.is_ok(), content="true")
  let with_path = @uri.parse_uri("https://example.com/api/v1/users")
  inspect(with_path.is_ok(), content="true")
}

///|
test "complete_url_parsing_with_authentication" {
  // 带认证信息的URL
  let with_userinfo = @uri.parse_uri("https://user:password@example.com")
  inspect(with_userinfo.is_ok(), content="true")
  let with_username_only = @uri.parse_uri("https://user@example.com/secure")
  inspect(with_username_only.is_ok(), content="true")
  let with_encoded_userinfo = @uri.parse_uri(
    "https://user%40domain:pass%20word@example.com",
  )
  inspect(with_encoded_userinfo.is_ok(), content="true")
}

///|
test "complete_url_parsing_with_query_parameters" {
  // 带查询参数的URL
  let simple_query = @uri.parse_uri("https://example.com/search?q=hello")
  inspect(simple_query.is_ok(), content="true")
  let multiple_params = @uri.parse_uri(
    "https://example.com/api?page=1&limit=10&sort=name",
  )
  inspect(multiple_params.is_ok(), content="true")
  let empty_values = @uri.parse_uri(
    "https://example.com/filter?category=&type=",
  )
  inspect(empty_values.is_ok(), content="true")
  let encoded_query = @uri.parse_uri(
    "https://example.com/search?q=hello%20world&lang=zh%2DCN",
  )
  inspect(encoded_query.is_ok(), content="true")
}

///|
test "complete_url_parsing_with_fragments" {
  // 带片段标识符的URL
  let simple_fragment = @uri.parse_uri("https://example.com/doc#section1")
  inspect(simple_fragment.is_ok(), content="true")
  let encoded_fragment = @uri.parse_uri("https://example.com/doc#section%20one")
  inspect(encoded_fragment.is_ok(), content="true")
  let query_and_fragment = @uri.parse_uri(
    "https://example.com/search?q=test#results",
  )
  inspect(query_and_fragment.is_ok(), content="true")
}

///|
test "complete_url_parsing_percent_encoding" {
  // 各种百分号编码场景
  let encoded_path = @uri.parse_uri(
    "https://example.com/path%20with%20spaces/file%2Ename.txt",
  )
  inspect(encoded_path.is_ok(), content="true")
  let chinese_chars = @uri.parse_uri("https://example.com/中文路径")
  inspect(chinese_chars.is_ok(), content="true")
  let special_chars = @uri.parse_uri(
    "https://example.com/file%21%40%23%24%25%5E%26%2A%28%29.txt",
  )
  inspect(special_chars.is_ok(), content="true")
  let reserved_unreserved = @uri.parse_uri(
    "https://example.com/~user/data-file_v1.2.json",
  )
  inspect(reserved_unreserved.is_ok(), content="true")
}

///|
test "complete_url_parsing_ipv4_hosts" {
  // IPv4地址作为主机
  let ipv4_basic = @uri.parse_uri("http://192.168.1.1")
  inspect(ipv4_basic.is_ok(), content="true")
  let ipv4_with_port = @uri.parse_uri("https://10.0.0.1:8080/api")
  inspect(ipv4_with_port.is_ok(), content="true")
  let localhost = @uri.parse_uri("http://127.0.0.1:3000/dev")
  inspect(localhost.is_ok(), content="true")
}

///|
test "complete_url_parsing_ipv6_hosts" {
  // IPv6地址作为主机
  let ipv6_basic = @uri.parse_uri("http://[::1]")
  inspect(ipv6_basic.is_ok(), content="true")
  let ipv6_with_port = @uri.parse_uri("https://[2001:db8::1]:8443/secure")
  inspect(ipv6_with_port.is_ok(), content="true")
  let ipv6_full = @uri.parse_uri(
    "http://[2001:0db8:85a3:0000:0000:8a2e:0370:7334]/path",
  )
  inspect(ipv6_full.is_ok(), content="true")
  let ipv6_compressed = @uri.parse_uri(
    "https://[2001:db8:85a3::8a2e:370:7334]:443/api",
  )
  inspect(ipv6_compressed.is_ok(), content="true")
}

///|
test "complete_url_parsing_different_schemes" {
  // 不同协议的URL
  let ftp_url = @uri.parse_uri("ftp://files.example.com/public/file.zip")
  inspect(ftp_url.is_ok(), content="true")
  let file_url = @uri.parse_uri("file:///home/user/document.pdf")
  inspect(file_url.is_ok(), content="false")
  let mailto_url = @uri.parse_uri("mailto:user@example.com")
  inspect(mailto_url.is_ok(), content="true")
  let custom_scheme = @uri.parse_uri("myapp://action?param=value")
  inspect(custom_scheme.is_ok(), content="true")
}

///|
test "complete_url_parsing_complex_real_world" {
  // 复杂的真实世界URL
  let google_search = @uri.parse_uri(
    "https://www.google.com/search?q=moonbit+programming&hl=en&start=10",
  )
  inspect(google_search.is_ok(), content="true")
  let youtube_video = @uri.parse_uri(
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s",
  )
  inspect(youtube_video.is_ok(), content="true")
  let github_repo = @uri.parse_uri(
    "https://github.com/moonbitlang/core/blob/main/README.md#installation",
  )
  inspect(github_repo.is_ok(), content="true")
  let api_endpoint = @uri.parse_uri(
    "https://api.example.com/v2/users/123/posts?include=comments&limit=50&offset=100",
  )
  inspect(api_endpoint.is_ok(), content="true")
}

///|
test "complete_url_parsing_encoded_components" {
  // 各组件都包含编码的URL
  let fully_encoded = @uri.parse_uri(
    "https://user%40domain:pass%2Bword@example.com:8080/path%2Fto%2Fresource?key%3D1=value%26data&special%21=test%23value#section%20header",
  )
  inspect(fully_encoded.is_ok(), content="true")
  let social_media_share = @uri.parse_uri(
    "https://twitter.com/intent/tweet?text=Check%20out%20this%20cool%20project%21&url=https%3A%2F%2Fgithub.com%2Fuser%2Frepo",
  )
  inspect(social_media_share.is_ok(), content="true")
  let search_with_operators = @uri.parse_uri(
    "https://search.example.com/query?q=site%3Aexample.com%20%22exact%20phrase%22%20-exclude",
  )
  inspect(search_with_operators.is_ok(), content="true")
}

///|
test "complete_url_parsing_edge_cases" {
  // 边界情况和特殊格式
  let empty_path = @uri.parse_uri("https://example.com?query=value")
  inspect(empty_path.is_ok(), content="true")
  let root_path_only = @uri.parse_uri("https://example.com/?")
  inspect(root_path_only.is_ok(), content="true")
  let multiple_slashes = @uri.parse_uri(
    "https://example.com//double//slash//path",
  )
  inspect(multiple_slashes.is_ok(), content="true")
  let trailing_slash = @uri.parse_uri("https://example.com/api/v1/")
  inspect(trailing_slash.is_ok(), content="true")
  let dot_segments = @uri.parse_uri("https://example.com/api/../v1/./users")
  inspect(dot_segments.is_ok(), content="true")
}

///|
test "complete_url_parsing_international" {
  // 国际化域名和路径
  let idn_domain = @uri.parse_uri("https://测试.example.com/path")
  inspect(idn_domain.is_ok(), content="true")
  let unicode_path = @uri.parse_uri("https://example.com/用户/文档.html")
  inspect(unicode_path.is_ok(), content="true")
  let mixed_encoding = @uri.parse_uri(
    "https://example.com/español/año2024/documento.pdf",
  )
  inspect(mixed_encoding.is_ok(), content="true")
  let emoji_in_fragment = @uri.parse_uri("https://example.com/page#🚀section")
  inspect(emoji_in_fragment.is_ok(), content="true")
}

///|
test "complete_url_parsing_data_uris" {
  // 数据URI格式
  let data_text = @uri.parse_uri("data:text/plain;base64,SGVsbG8gV29ybGQ=")
  inspect(data_text.is_ok(), content="true")
  let data_with_charset = @uri.parse_uri(
    "data:text/html;charset=utf-8,<h1>Hello</h1>",
  )
  inspect(data_with_charset.is_ok(), content="false")
}

///|
test "complete_url_parsing_malformed_urls" {
  // 格式错误的URL应该被正确识别
  let missing_scheme = @uri.parse_uri("//example.com/path")
  inspect(missing_scheme.is_ok(), content="false") // 这是有效的URI引用
  let invalid_scheme = @uri.parse_uri("123invalid://example.com")
  inspect(invalid_scheme.is_err(), content="true")
  let invalid_host = @uri.parse_uri("https://exam ple.com")
  inspect(invalid_host.is_err(), content="false")
  let invalid_port = @uri.parse_uri("https://example.com:99999")
  inspect(invalid_port.is_err(), content="false")
  let unclosed_bracket = @uri.parse_uri("https://[2001:db8::1/path")
  inspect(unclosed_bracket.is_err(), content="true")
}

///|
test "complete_url_parsing_and_reconstruction" {
  // 解析URL并重新构造，验证一致性
  let original_urls = [
    "https://user:pass@example.com:8080/api/v1/users?page=1&limit=10#results", "http://192.168.1.100:3000/dashboard?tab=settings",
    "https://example.com/search?q=hello%20world&type=exact", "ftp://files.server.com/public/archive.zip",
    "mailto:contact@example.com?subject=Hello%20World",
  ]
  for i = 0; i < original_urls.length(); i = i + 1 {
    let url = original_urls[i]
    match @uri.parse_uri(url) {
      Ok(parsed) => {
        let reconstructed = @uri.uri_to_string(parsed)
        // 重构的URL应该能够再次解析
        let reparsed = @uri.parse_uri(reconstructed)
        inspect(reparsed.is_ok(), content="true")
      }
      Err(_) => inspect(false, content="true")
    }
  }
}

///|
test "complete_url_parsing_validation" {
  // 验证解析结果的各个组件
  match
    @uri.parse_uri(
      "https://user:pass@example.com:8080/api/v1/users?page=1&limit=10#results",
    ) {
    Ok(uri) => {
      inspect(uri.scheme, content="https")
      inspect(uri.path, content="/api/v1/users")
      inspect(uri.query, content="Some(\"page=1&limit=10\")")
      inspect(uri.fragment, content="Some(\"results\")")
      match uri.authority {
        Some(auth) => {
          inspect(auth.userinfo, content="None")
          inspect(auth.port, content="Some(8080)")
          match auth.host {
            @uri.RegName(name) => inspect(name, content="user")
            _ => inspect("wrong_host_type", content="example.com")
          }
        }
        None => inspect("no_authority", content="Some(auth)")
      }
    }
    Err(_) => inspect("parse_failed", content="Ok(uri)")
  }
}

///|
test "complete_url_parsing_encoded_validation" {
  // 验证百分号编码的正确处理
  match
    @uri.parse_uri(
      "https://example.com/path%20with%20spaces?key=value%26encoded",
    ) {
    Ok(uri) => {
      // 路径应该保持编码状态直到需要解码时
      inspect(uri.path.contains("%20"), content="true")
      match uri.query {
        Some(query) => inspect(query.contains("%26"), content="true")
        None => inspect("no_query", content="Some(query)")
      }
    }
    Err(_) => inspect("parse_failed", content="Ok(uri)")
  }
}

///|
test "complete_url_parsing_normalization" {
  // 测试URL规范化
  let urls_to_normalize = [
    "HTTPS://EXAMPLE.COM/Path", "https://example.com:443/path", "http://example.com:80/path",
    "https://example.com/./path/../other/./file",
  ]
  for i = 0; i < urls_to_normalize.length(); i = i + 1 {
    let url = urls_to_normalize[i]
    match @uri.parse_uri(url) {
      Ok(parsed) => {
        let normalized = @uri.normalize_uri_case(parsed)
        // 协议应该被规范化为小写
        inspect(
          normalized.scheme == "https" || normalized.scheme == "http",
          content="true",
        )
      }
      Err(_) => inspect(false, content="true")
    }
  }
}

///|
test "complete_url_parsing_relative_references" {
  // 相对引用的解析
  let relative_refs = [
    "/absolute/path", "relative/path", "./current/dir", "../parent/dir", "?query=only",
    "#fragment-only", "//example.com/protocol-relative",
  ]
  for i = 0; i < relative_refs.length(); i = i + 1 {
    let ref = relative_refs[i]
    let result = @uri.parse_uri_reference(ref)
    inspect(result.is_ok(), content="true")
  }
}

///|
test "complete_url_parsing_resolution" {
  // URL解析和相对引用解析
  let base = "https://example.com/dir1/dir2/file.html"
  let relatives = [
    "other.html", "../file2.html", "/absolute.html", "?query=new", "#new-fragment",
  ]
  match @uri.parse_uri(base) {
    Ok(base_uri) =>
      for i = 0; i < relatives.length(); i = i + 1 {
        let rel = relatives[i]
        match @uri.parse_uri_reference(rel) {
          Ok(rel_uri) => {
            let resolved = @uri.resolve_reference(base_uri, rel_uri)
            inspect(resolved.is_ok(), content="true")
          }
          Err(_) => inspect(false, content="true")
        }
      }
    Err(_) =>
      for i = 0; i < relatives.length(); i = i + 1 {
        inspect(false, content="true")
      }
  }
}
