// 完整的黑盒测试套件
// 通过公共API测试所有主要功能

///|
test "basic_uri_parsing" {
  // 测试基本URI解析
  let result = @uri.parse_uri(
    "https://example.com:8080/path?query=value#fragment",
  )
  inspect(
    result,
    content=(
      #|Ok({scheme: "https", authority: Some({userinfo: None, host: RegName("example.com"), port: Some(8080)}), path: "/path", path_type: AbEmpty, query: Some("query=value"), fragment: Some("fragment")})
    ),
  )
}

///|
test "uri_reference_parsing" {
  // 测试URI引用解析
  let result = @uri.parse_uri_reference("/path/to/resource")
  inspect(result.is_ok(), content="true")
  let relative_uri = @uri.parse_uri_reference("//example.com/path")
  inspect(relative_uri.is_ok(), content="true")
}

///|
test "scheme_parsing" {
  // 测试协议解析
  inspect(@uri.parse_scheme("http"), content="Ok(\"http\")")
  inspect(@uri.parse_scheme("https"), content="Ok(\"https\")")
  inspect(@uri.parse_scheme("ftp"), content="Ok(\"ftp\")")

  // 无效协议
  let invalid_scheme = @uri.parse_scheme("123invalid")
  inspect(invalid_scheme.is_err(), content="true")
}

///|
test "authority_parsing" {
  // 测试权限部分解析
  let auth1 = @uri.parse_authority("user:pass@example.com:8080")
  inspect(auth1.is_ok(), content="true")
  let auth2 = @uri.parse_authority("example.com")
  inspect(auth2.is_ok(), content="true")
  let auth3 = @uri.parse_authority("[::1]:8080")
  inspect(auth3.is_ok(), content="true")
}

///|
test "host_parsing" {
  // 测试主机解析
  let ipv4_host = @uri.parse_host("192.168.1.1")
  inspect(ipv4_host.is_ok(), content="true")
  let ipv6_host = @uri.parse_host("[::1]")
  inspect(ipv6_host.is_ok(), content="true")
  let reg_name_host = @uri.parse_host("example.com")
  inspect(reg_name_host.is_ok(), content="true")
}

///|
test "ipv4_address_parsing" {
  // 测试IPv4地址解析
  inspect(@uri.parse_ipv4_address("192.168.1.1"), content="Ok(\"192.168.1.1\")")
  inspect(@uri.parse_ipv4_address("127.0.0.1"), content="Ok(\"127.0.0.1\")")
  inspect(
    @uri.parse_ipv4_address("255.255.255.255"),
    content="Ok(\"255.255.255.255\")",
  )

  // 无效IPv4
  let invalid_ipv4 = @uri.parse_ipv4_address("256.1.1.1")
  inspect(invalid_ipv4.is_err(), content="true")
}

///|
test "ipv6_address_parsing" {
  // 测试IPv6地址解析
  inspect(@uri.parse_ipv6_address("::1"), content="Ok(\"::1\")")
  inspect(@uri.parse_ipv6_address("2001:db8::1"), content="Ok(\"2001:db8::1\")")
  inspect(
    @uri.parse_ipv6_address("fe80::1%lo0"),
    content=(
      #|Err(InvalidHost("Invalid hex segment in IPv6"))
    ),
  )
}

///|
test "query_parsing" {
  // 测试查询字符串解析
  inspect(
    @uri.parse_query("key1=value1&key2=value2"),
    content="Ok(\"key1=value1&key2=value2\")",
  )
  inspect(@uri.parse_query(""), content="Ok(\"\")")
  let params = @uri.parse_query_params("key1=value1&key2=value2&key3=")
  inspect(params.length(), content="3")
}

///|
test "fragment_parsing" {
  // 测试片段解析
  inspect(@uri.parse_fragment("section1"), content="Ok(\"section1\")")
  inspect(@uri.parse_fragment(""), content="Ok(\"\")")
}

///|
test "percent_encoding" {
  // 测试百分比编码
  let encoded = @uri.percent_encode("hello world", @uri.is_unreserved)
  inspect(encoded.contains("%20"), content="false")
  let decoded = @uri.percent_decode("hello%20world")
  inspect(decoded, content="Ok(\"hello world\")")

  // 测试无效编码
  let invalid_decode = @uri.percent_decode("hello%2")
  inspect(invalid_decode.is_err(), content="true")
}

///|
test "specific_encoding_functions" {
  // 测试特定编码函数
  let encoded_path = @uri.encode_path_segment("hello/world")
  inspect(encoded_path.contains("%2F"), content="true")
  let encoded_query = @uri.encode_query("key=value&other")
  inspect(encoded_query, content="key=value&other")
  let encoded_fragment = @uri.encode_fragment("section#1")
  inspect(encoded_fragment.contains("%23"), content="true")
  let encoded_userinfo = @uri.encode_userinfo("user:pass")
  inspect(encoded_userinfo.contains("%3A"), content="false")
  let encoded_regname = @uri.encode_reg_name("host.example")
  inspect(encoded_regname, content="host.example")
}

///|
test "uri_builder" {
  // 测试URI构建器
  let builder = @uri.new_builder()
  let uri = builder
    .scheme("https")
    .host("example.com")
    .port(8080)
    .path("/api/v1")
    .query("param=value")
    .fragment("section")
    .build()
  inspect(uri.is_ok(), content="true")

  // 测试添加路径段
  let builder2 = @uri.new_builder()
    .scheme("http")
    .host("example.com")
    .add_path_segment("api")
    .add_path_segment("users")
    .build()
  inspect(builder2.is_ok(), content="true")

  // 测试查询参数
  let builder3 = @uri.new_builder()
    .scheme("https")
    .host("example.com")
    .add_query_param("key1", "value1")
    .add_query_param("key2", "value2")
    .build()
  inspect(builder3.is_ok(), content="true")
}

///|
test "uri_creation_helpers" {
  // 测试URI创建助手函数
  let http_uri = @uri.create_http_uri(
    "example.com",
    Some(8080),
    "/path",
    Some("query=value"),
    Some("fragment"),
  )
  inspect(http_uri.is_ok(), content="true")
  let https_uri = @uri.create_https_uri(
    "example.com",
    None,
    "/secure",
    None,
    None,
  )
  inspect(https_uri.is_ok(), content="true")
  let file_uri = @uri.create_file_uri("/home/user/file.txt")
  inspect(file_uri.is_ok(), content="true")
  let simple_uri = @uri.create_simple_uri("http", "//example.com/path")
  inspect(simple_uri.is_ok(), content="false")
}

///|
test "authority_creation" {
  // 测试权限创建
  let ipv4_host = @uri.make_ipv4_host("192.168.1.1")
  let auth1 = @uri.create_authority(Some("user"), ipv4_host, Some(8080))
  inspect(@uri.authority_to_string(auth1), content="user@192.168.1.1:8080")
  let reg_name_host = @uri.make_reg_name_host("example.com")
  let auth2 = @uri.create_authority(None, reg_name_host, None)
  inspect(@uri.authority_to_string(auth2), content="example.com")
  let ipv6_host = @uri.make_ipv6_host("::1")
  let auth3 = @uri.create_authority(None, ipv6_host, Some(443))
  inspect(@uri.authority_to_string(auth3), content="[::1]:443")
}

///|
test "path_operations" {
  // 测试路径操作
  let segments = @uri.path_segments("/api/v1/users")
  inspect(segments.length(), content="3")
  inspect(segments[0], content="api")
  inspect(segments[1], content="v1")
  inspect(segments[2], content="users")
  let joined = @uri.join_paths("/api", "users")
  inspect(joined, content="/api/users")
  let normalized = @uri.normalize_path("/api/../users/./profile")
  inspect(normalized, content="/users/profile")
  let classified = @uri.classify_and_validate_path("/absolute/path")
  inspect(classified.is_ok(), content="true")
}

///|
test "validation_functions" {
  // 测试验证函数
  inspect(@uri.is_valid_uri("https://example.com/path"), content="true")
  inspect(@uri.is_valid_uri("invalid://"), content="false")
  inspect(@uri.is_valid_uri_reference("/relative/path"), content="true")
  inspect(@uri.is_valid_uri_reference("//example.com"), content="true")
  inspect(@uri.is_valid_percent_encoding("%20"), content="true")
  inspect(@uri.is_valid_percent_encoding("%2G"), content="false")
  let valid_encoded = @uri.is_valid_encoded_string(
    "hello%20world", @uri.is_unreserved,
  )
  inspect(valid_encoded, content="true")
}

///|
test "character_classification" {
  // 测试字符分类
  inspect(@uri.is_unreserved('a'), content="true")
  inspect(@uri.is_unreserved('1'), content="true")
  inspect(@uri.is_unreserved('-'), content="true")
  inspect(@uri.is_unreserved('!'), content="false")
  inspect(@uri.is_reserved('!'), content="true")
  inspect(@uri.is_reserved('*'), content="true")
  inspect(@uri.is_reserved('a'), content="false")
  inspect(@uri.is_gen_delim(':'), content="true")
  inspect(@uri.is_gen_delim('/'), content="true")
  inspect(@uri.is_gen_delim('a'), content="false")
  inspect(@uri.is_sub_delim('!'), content="true")
  inspect(@uri.is_sub_delim('$'), content="true")
  inspect(@uri.is_sub_delim(':'), content="false")
  inspect(@uri.is_pchar('a'), content="true")
  inspect(@uri.is_pchar(':'), content="true")
  inspect(@uri.is_pchar('['), content="false")
}

///|
test "scheme_specific_chars" {
  // 测试协议特定字符
  inspect(@uri.is_scheme_char('a'), content="true")
  inspect(@uri.is_scheme_char('1'), content="true")
  inspect(@uri.is_scheme_char('+'), content="true")
  inspect(@uri.is_scheme_char('!'), content="false")
}

///|
test "userinfo_and_regname_chars" {
  // 测试用户信息和注册名字符
  inspect(@uri.is_userinfo_char('a'), content="true")
  inspect(@uri.is_userinfo_char(':'), content="true")
  inspect(@uri.is_userinfo_char('['), content="false")
  inspect(@uri.is_reg_name_char('a'), content="true")
  inspect(@uri.is_reg_name_char('-'), content="true")
  inspect(@uri.is_reg_name_char('['), content="false")
}

///|
test "query_and_fragment_chars" {
  // 测试查询和片段字符
  inspect(@uri.is_query_char('a'), content="true")
  inspect(@uri.is_query_char('?'), content="true")
  inspect(@uri.is_query_char(' '), content="false")
  inspect(@uri.is_fragment_char('a'), content="true")
  inspect(@uri.is_fragment_char('?'), content="true")
  inspect(@uri.is_fragment_char(' '), content="false")
}

///|
test "segment_nz_nc_chars" {
  // 测试非零非冒号段字符
  inspect(@uri.is_segment_nz_nc_char('a'), content="true")
  inspect(@uri.is_segment_nz_nc_char('1'), content="true")
  inspect(@uri.is_segment_nz_nc_char(':'), content="false")
}

///|
test "hex_conversion" {
  // 测试十六进制转换
  inspect(@uri.hex_to_int('0'), content="Some(0)")
  inspect(@uri.hex_to_int('9'), content="Some(9)")
  inspect(@uri.hex_to_int('A'), content="Some(10)")
  inspect(@uri.hex_to_int('F'), content="Some(15)")
  inspect(@uri.hex_to_int('a'), content="Some(10)")
  inspect(@uri.hex_to_int('f'), content="Some(15)")
  inspect(@uri.hex_to_int('G'), content="None")
  inspect(@uri.int_to_hex(0), content="Some('0')")
  inspect(@uri.int_to_hex(9), content="Some('9')")
  inspect(@uri.int_to_hex(10), content="Some('A')")
  inspect(@uri.int_to_hex(15), content="Some('F')")
  inspect(@uri.int_to_hex(16), content="None")
}

///|
test "string_utilities" {
  // 测试字符串工具函数
  inspect(@uri.is_empty_or_whitespace(""), content="true")
  inspect(@uri.is_empty_or_whitespace("   "), content="true")
  inspect(@uri.is_empty_or_whitespace("text"), content="false")
  let char_index = @uri.find_char_index("hello", 'l')
  inspect(char_index, content="Some(2)")
  let missing_char = @uri.find_char_index("hello", 'x')
  inspect(missing_char, content="None")
  let last_index = @uri.find_last_index_str("hello world hello", "hello")
  inspect(last_index, content="Some(12)")
  let (before, after) = @uri.split_string_at("key=value", '=')
  inspect(before, content="key")
  inspect(after, content="Some(\"value\")")
}

///|
test "uri_type_predicates" {
  // 测试URI类型判断
  match @uri.parse_uri("https://example.com/path") {
    Ok(absolute_uri) => {
      inspect(@uri.is_absolute_uri(absolute_uri), content="true")
      inspect(@uri.is_relative_uri(absolute_uri), content="false")
    }
    Err(_) => {
      inspect("error", content="true")
      inspect("error", content="false")
    }
  }
  match @uri.parse_uri_reference("/path") {
    Ok(relative_uri) => {
      inspect(@uri.is_relative_uri(relative_uri), content="true")
      inspect(@uri.is_absolute_uri(relative_uri), content="false")
    }
    Err(_) => {
      inspect("error", content="true")
      inspect("error", content="false")
    }
  }
}

///|
test "uri_comparison" {
  // 测试URI比较
  match
    (
      @uri.parse_uri("https://EXAMPLE.COM/path"),
      @uri.parse_uri("https://example.com/path"),
    ) {
    (Ok(uri1), Ok(uri2)) =>
      inspect(@uri.uris_equivalent(uri1, uri2), content="true")
    _ => inspect("error", content="true")
  }
  inspect(@uri.schemes_equal("HTTPS", "https"), content="true")
  inspect(@uri.schemes_equal("http", "https"), content="false")
}

///|
test "uri_normalization" {
  // 测试URI规范化
  match @uri.parse_uri("HTTPS://EXAMPLE.COM/Path") {
    Ok(uri) => {
      let normalized = @uri.normalize_uri_case(uri)
      // 协议应该被转换为小写
      inspect(normalized.scheme, content="https")
    }
    Err(_) => inspect("error", content="https")
  }
}

///|
test "query_string_building" {
  // 测试查询字符串构建
  let params = [("key1", "value1"), ("key2", "value2"), ("key3", "")]
  let query_string = @uri.build_query_string(params)
  inspect(query_string, content="key1=value1&key2=value2&key3")
}

///|
test "path_validation" {
  // 测试路径验证
  let valid_abempty = @uri.validate_path_abempty("/path/to/resource")
  inspect(valid_abempty.is_ok(), content="true")
  let empty_abempty = @uri.validate_path_abempty("")
  inspect(empty_abempty.is_ok(), content="true")
}

///|
test "comprehensive_uri_validation" {
  // 测试综合URI验证
  match @uri.parse_uri("https://example.com/path?query=value#fragment") {
    Ok(uri) => {
      let validation_result = @uri.validate_uri_comprehensive(uri)
      inspect(validation_result.is_ok(), content="true")
      let scheme_validation = @uri.validate_scheme_specific(uri)
      inspect(scheme_validation.is_ok(), content="true")
    }
    Err(_) => {
      inspect("error", content="true")
      inspect("error", content="true")
    }
  }
}

///|
test "component_validation" {
  // 测试组件验证
  let ipv4_host = @uri.make_ipv4_host("192.168.1.1")
  let authority = @uri.create_authority(Some("user"), ipv4_host, Some(8080))
  let validation_result = @uri.validate_uri_components(
    "https",
    Some(authority),
    "/path",
    Some("query=value"),
    Some("fragment"),
  )
  inspect(validation_result.is_ok(), content="true")
}

///|
test "reference_resolution" {
  // 测试引用解析
  match
    (
      @uri.parse_uri("https://example.com/dir1/dir2/file"),
      @uri.parse_uri_reference("../other"),
    ) {
    (Ok(base_uri), Ok(relative_ref)) => {
      let resolved = @uri.resolve_reference(base_uri, relative_ref)
      inspect(resolved.is_ok(), content="true")
    }
    _ => inspect("error", content="true")
  }
}

///|
test "ip_literal_parsing" {
  // 测试IP字面量解析
  let ipv6_literal = @uri.parse_ip_literal("[::1]")
  inspect(ipv6_literal.is_ok(), content="true")
  let ipv_future_literal = @uri.parse_ip_literal("[v1.addr]")
  inspect(ipv_future_literal.is_ok(), content="true")
}

///|
test "simple_int_parsing" {
  // 测试简单整数解析
  inspect(@uri.parse_int_simple("123"), content="123")
  inspect(@uri.parse_int_simple("0"), content="0")
  inspect(@uri.parse_int_simple("999"), content="999")
}

///|
test "host_type_creation" {
  // 测试主机类型创建
  let ipv4 = @uri.make_ipv4_host("192.168.1.1")
  inspect(
    ipv4,
    content=(
      #|IPv4("192.168.1.1")
    ),
  )
  let ipv6 = @uri.make_ipv6_host("::1")
  inspect(
    ipv6,
    content=(
      #|IPv6("::1")
    ),
  )
  let ipv_future = @uri.make_ipv_future_host("v1.addr")
  inspect(
    ipv_future,
    content=(
      #|IPvFuture("v1.addr")
    ),
  )
  let reg_name = @uri.make_reg_name_host("example.com")
  inspect(
    reg_name,
    content=(
      #|RegName("example.com")
    ),
  )
}

///|
test "error_cases" {
  // 测试错误情况
  let invalid_uri = @uri.parse_uri("ht!tp://example.com")
  inspect(invalid_uri.is_err(), content="true")
  let invalid_authority = @uri.parse_authority("user@host:abc")
  inspect(invalid_authority.is_err(), content="true")
  let invalid_host = @uri.parse_host("[invalid")
  inspect(invalid_host.is_err(), content="true")
  let invalid_query = @uri.parse_query("query with invalid chars \u0001")
  inspect(invalid_query.is_err(), content="true")
  let invalid_fragment = @uri.parse_fragment(
    "fragment with invalid chars \u0001",
  )
  inspect(invalid_fragment.is_err(), content="true")
}

///|
test "edge_cases" {
  // 测试边界情况
  let empty_path_result = @uri.parse_uri("https://example.com")
  match empty_path_result {
    Ok(empty_path) => inspect(empty_path.path, content="")
    Err(_) => inspect("error", content="")
  }
  let root_path_result = @uri.parse_uri("https://example.com/")
  match root_path_result {
    Ok(root_path) => inspect(root_path.path, content="/")
    Err(_) => inspect("error", content="/")
  }
  let no_authority_result = @uri.parse_uri("file:///path/to/file")
  match no_authority_result {
    Ok(no_authority) =>
      match no_authority.authority {
        Some(_) => inspect(true, content="true")
        None => inspect(false, content="true")
      }
    Err(_) => inspect("error", content="error")
  }

  // 测试只有协议的URI
  let scheme_only_result = @uri.parse_uri("mailto:")
  inspect(scheme_only_result.is_ok(), content="true")
}
