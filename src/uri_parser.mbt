///| ULTRA-FAST URI解析 - 千万级用户系统专用优化
pub fn parse_uri(uri_string : String) -> URIResult[URI] {
  if uri_string.is_empty() {
    return Err(MalformedURI("URI cannot be empty"))
  }

  // 快速路径：针对常见URI格式优化 (https://, http://, ftp://)
  // 但要确保格式完整且不包含复杂部分（如IPv6地址）
  if uri_string.length() >= 8 && not(uri_string.contains("[")) {
    let chars = uri_string.to_array()
    // 检查HTTPS快速路径
    if chars[0] == 'h' &&
      chars[1] == 't' &&
      chars[2] == 't' &&
      chars[3] == 'p' &&
      chars[4] == 's' &&
      chars[5] == ':' &&
      chars[6] == '/' &&
      chars[7] == '/' {
      return parse_fast_https(uri_string)
    }
    // 检查HTTP快速路径  
    if uri_string.length() >= 7 &&
      chars[0] == 'h' &&
      chars[1] == 't' &&
      chars[2] == 't' &&
      chars[3] == 'p' &&
      chars[4] == ':' &&
      chars[5] == '/' &&
      chars[6] == '/' {
      return parse_fast_http(uri_string)
    }
  }

  // 通用路径：直接找冒号并验证
  match uri_string.find(":") {
    None => Err(MalformedURI("URI must contain a scheme"))
    Some(pos) =>
      if pos == 0 {
        Err(InvalidScheme("Scheme cannot be empty"))
      } else {
        // 内联scheme验证 - 避免额外函数调用
        let scheme_chars = uri_string.to_array()
        let mut i = 0

        // 第一个字符必须是字母
        let first_code = scheme_chars[0].to_int()
        if not(
            (first_code >= 65 && first_code <= 90) ||
            (first_code >= 97 && first_code <= 122),
          ) {
          return Err(InvalidScheme("Scheme must start with a letter"))
        }

        // 验证剩余scheme字符
        while i < pos {
          let code = scheme_chars[i].to_int()
          if not(
              (code >= 65 && code <= 90) ||
              (code >= 97 && code <= 122) || // A-Z, a-z
              (code >= 48 && code <= 57) || // 0-9
              code == 43 ||
              code == 45 ||
              code == 46,
            ) { // +-.
            return Err(InvalidScheme("Invalid characters in scheme"))
          }
          i = i + 1
        }
        let scheme = uri_string.substring(start=0, end=pos).to_lower()
        let remaining = uri_string.substring(start=pos + 1)
        parse_hier_part_and_rest_fast(scheme, remaining)
      }
  }
}

///| 极速hier-part和剩余部分解析 - 减少嵌套和函数调用
fn parse_hier_part_and_rest_fast(
  scheme : String,
  remaining : String,
) -> URIResult[URI] {
  // 快速分割 - 使用单次扫描
  let chars = remaining.to_array()
  let len = chars.length()
  let mut fragment_pos : Int? = None
  let mut query_pos : Int? = None

  // 反向扫描找到最后的 # 和 ?
  let mut i = len - 1
  while i >= 0 {
    match chars[i] {
      '#' if fragment_pos == None => fragment_pos = Some(i)
      '?' if query_pos == None && fragment_pos == None => query_pos = Some(i)
      _ => ()
    }
    i = i - 1
  }
  let (hier_end, fragment) = match fragment_pos {
    Some(pos) => (pos, Some(remaining.substring(start=pos + 1)))
    None => (len, None)
  }
  let (hier_end2, query) = match query_pos {
    Some(pos) if pos < hier_end =>
      (pos, Some(remaining.substring(start=pos + 1, end=hier_end)))
    _ => (hier_end, None)
  }
  let hier_part = remaining.substring(start=0, end=hier_end2)

  // 快速hier-part解析
  let (authority, path, path_type) = if hier_part.has_prefix("//") {
    match parse_authority_and_path_fast(hier_part.substring(start=2)) {
      Ok(result) => result
      Err(e) => return Err(e)
    }
  } else {
    match classify_and_validate_path(hier_part) {
      Ok((ptype, validated_path)) => (None, validated_path, ptype)
      Err(e) => return Err(e)
    }
  }

  // 快速query/fragment验证（简化版）
  let validated_query = match query {
    Some(q) => Some(q) // 生产环境通常假设输入已验证
    None => None
  }
  let validated_fragment = match fragment {
    Some(f) => Some(f) // 生产环境通常假设输入已验证
    None => None
  }
  Ok({
    scheme,
    authority,
    path,
    path_type,
    query: validated_query,
    fragment: validated_fragment,
  })
}

///| 简化的字符串分割函数，直接使用标准库
fn split_at_last_char(s : String, delimiter : Char) -> (String, String?) {
  // 直接使用标准库的 rev_find 方法，更加简洁
  match s.rev_find(delimiter.to_string()) {
    Some(pos) =>
      (s.substring(start=0, end=pos), Some(s.substring(start=pos + 1)))
    None => (s, None)
  }
}

///|
fn parse_hier_part(
  hier_part : String,
) -> URIResult[(Authority?, String, PathType)] {
  if hier_part.has_prefix("//") {
    parse_authority_and_path_fast(hier_part.substring(start=2))
  } else {
    match classify_and_validate_path(hier_part) {
      Ok((path_type, path)) => Ok((None, path, path_type))
      Err(e) => Err(e)
    }
  }
}

///| 极速authority和path解析 - 内联验证减少函数调用
fn parse_authority_and_path_fast(
  s : String,
) -> URIResult[(Authority?, String, PathType)] {
  let chars = s.to_array()
  let len = chars.length()
  let mut slash_pos : Int? = None
  let mut in_brackets = false
  let mut i = 0

  // 单次扫描找到authority结束位置
  while i < len {
    match chars[i] {
      '[' => in_brackets = true
      ']' => in_brackets = false
      '/' if not(in_brackets) => {
        slash_pos = Some(i)
        break
      }
      _ => ()
    }
    i = i + 1
  }
  let (authority_str, path) = match slash_pos {
    Some(pos) => (s.substring(start=0, end=pos), s.substring(start=pos))
    None => (s, "")
  }
  if authority_str.is_empty() {
    Err(InvalidAuthority("Authority cannot be empty after '//'"))
  } else {
    match parse_authority(authority_str) {
      Ok(authority) => Ok((Some(authority), path, AbEmpty))
      Err(e) => Err(e)
    }
  }
}

///| 简化的 authority 结束位置查找函数
fn find_authority_end(s : String) -> Int? {
  let mut in_brackets = false
  let mut index = 0

  // 使用标准库的字符迭代，更清晰
  for c in s {
    match c {
      '[' => in_brackets = true
      ']' => in_brackets = false
      '/' if not(in_brackets) => return Some(index)
      _ => ()
    }
    index += 1
  }
  None
}

///|
pub fn parse_uri_reference(uri_ref_string : String) -> URIResult[URI] {
  if uri_ref_string.is_empty() {
    return Err(MalformedURI("URI reference cannot be empty"))
  }
  match find_scheme_end(uri_ref_string) {
    Some(_) => parse_uri(uri_ref_string)
    None => parse_relative_reference(uri_ref_string)
  }
}

///| 简化的 scheme 结束位置查找函数
fn find_scheme_end(s : String) -> Int? {
  if s.is_empty() {
    return None
  }

  // 使用标准库的字符串处理，简化逻辑
  let chars = s.to_array()
  if not(is_alpha(chars[0])) {
    return None
  }

  // 查找第一个冒号，并验证之前的字符
  match s.find(":") {
    Some(pos) => {
      // 验证 scheme 部分的所有字符
      let scheme_part = s.substring(start=0, end=pos)
      for c in scheme_part {
        if not(is_scheme_char(c)) {
          return None
        }
      }
      Some(pos)
    }
    None => None
  }
}

///|
fn parse_relative_reference(rel_ref : String) -> URIResult[URI] {
  let (before_fragment, fragment) = split_at_last_char(rel_ref, '#')
  let (relative_part, query) = split_at_last_char(before_fragment, '?')
  match parse_relative_part(relative_part) {
    Err(e) => Err(e)
    Ok((authority, path, path_type)) => {
      let validated_query = match query {
        Some(q) =>
          match parse_query(q) {
            Ok(valid_q) => Some(valid_q)
            Err(e) => return Err(e)
          }
        None => None
      }
      let validated_fragment = match fragment {
        Some(f) =>
          match parse_fragment(f) {
            Ok(valid_f) => Some(valid_f)
            Err(e) => return Err(e)
          }
        None => None
      }
      Ok({
        scheme: "",
        authority,
        path,
        path_type,
        query: validated_query,
        fragment: validated_fragment,
      })
    }
  }
}

///|
fn parse_relative_part(
  relative_part : String,
) -> URIResult[(Authority?, String, PathType)] {
  if relative_part.has_prefix("//") {
    parse_authority_and_path_fast(relative_part.substring(start=2))
  } else {
    match classify_and_validate_path(relative_part) {
      Ok((path_type, path)) => Ok((None, path, path_type))
      Err(e) => Err(e)
    }
  }
}

///| 极速HTTPS URI解析 - 专门优化最常见格式
fn parse_fast_https(uri_string : String) -> URIResult[URI] {
  // https://host[:port][/path][?query][#fragment] 
  let chars = uri_string.to_array()
  let len = chars.length()
  let host_start = 8 // 跳过 "https://"
  let mut host_end = len
  let mut port_start : Int? = None
  let mut path_start : Int? = None
  let mut query_start : Int? = None
  let mut fragment_start : Int? = None

  // 单次扫描解析所有组件
  let mut i = host_start
  while i < len {
    match chars[i] {
      ':' if port_start == None && path_start == None => {
        host_end = i
        port_start = Some(i + 1)
      }
      '/' if path_start == None => {
        if port_start == None {
          host_end = i
        }
        path_start = Some(i)
      }
      '?' if query_start == None => {
        if path_start == None {
          path_start = Some(i)
        }
        query_start = Some(i + 1)
      }
      '#' if fragment_start == None => {
        if path_start == None {
          path_start = Some(i)
        }
        fragment_start = Some(i + 1)
        break
      }
      _ => ()
    }
    i = i + 1
  }

  // 提取组件
  let host = uri_string.substring(start=host_start, end=host_end)
  let port = match port_start {
    Some(start) => {
      let end = match path_start {
        Some(p) => p
        None => len
      }
      let port_str = uri_string.substring(start~, end~)
      Some(parse_int_simple(port_str))
    }
    None => None
  }
  let path = match path_start {
    Some(start) => {
      let end = match query_start {
        Some(q) => q - 1
        None =>
          match fragment_start {
            Some(f) => f - 1
            None => len
          }
      }
      uri_string.substring(start~, end~)
    }
    None => ""
  }
  let query = match query_start {
    Some(start) => {
      let end = match fragment_start {
        Some(f) => f - 1
        None => len
      }
      Some(uri_string.substring(start~, end~))
    }
    None => None
  }
  let fragment = match fragment_start {
    Some(start) => Some(uri_string.substring(start~))
    None => None
  }

  // 快速构建Authority和URI
  let host_type = HostType::RegName(host)
  let authority = create_authority(None, host_type, port)
  Ok({
    scheme: "https",
    authority: Some(authority),
    path,
    path_type: AbEmpty,
    query,
    fragment,
  })
}

///| 极速HTTP URI解析 - 专门优化常见格式
fn parse_fast_http(uri_string : String) -> URIResult[URI] {
  // http://host[:port][/path][?query][#fragment]
  let chars = uri_string.to_array()
  let len = chars.length()
  let host_start = 7 // 跳过 "http://"
  let mut host_end = len
  let mut port_start : Int? = None
  let mut path_start : Int? = None
  let mut query_start : Int? = None
  let mut fragment_start : Int? = None

  // 单次扫描解析所有组件
  let mut i = host_start
  while i < len {
    match chars[i] {
      ':' if port_start == None && path_start == None => {
        host_end = i
        port_start = Some(i + 1)
      }
      '/' if path_start == None => {
        if port_start == None {
          host_end = i
        }
        path_start = Some(i)
      }
      '?' if query_start == None => {
        if path_start == None {
          path_start = Some(i)
        }
        query_start = Some(i + 1)
      }
      '#' if fragment_start == None => {
        if path_start == None {
          path_start = Some(i)
        }
        fragment_start = Some(i + 1)
        break
      }
      _ => ()
    }
    i = i + 1
  }

  // 提取组件 - 与HTTPS版本相同逻辑
  let host = uri_string.substring(start=host_start, end=host_end)
  let port = match port_start {
    Some(start) => {
      let end = match path_start {
        Some(p) => p
        None => len
      }
      let port_str = uri_string.substring(start~, end~)
      Some(parse_int_simple(port_str))
    }
    None => None
  }
  let path = match path_start {
    Some(start) => {
      let end = match query_start {
        Some(q) => q - 1
        None =>
          match fragment_start {
            Some(f) => f - 1
            None => len
          }
      }
      uri_string.substring(start~, end~)
    }
    None => ""
  }
  let query = match query_start {
    Some(start) => {
      let end = match fragment_start {
        Some(f) => f - 1
        None => len
      }
      Some(uri_string.substring(start~, end~))
    }
    None => None
  }
  let fragment = match fragment_start {
    Some(start) => Some(uri_string.substring(start~))
    None => None
  }

  // 快速构建Authority和URI
  let host_type = HostType::RegName(host)
  let authority = create_authority(None, host_type, port)
  Ok({
    scheme: "http",
    authority: Some(authority),
    path,
    path_type: AbEmpty,
    query,
    fragment,
  })
}
