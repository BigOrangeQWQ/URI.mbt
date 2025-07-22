/// URI component parsing (scheme, query, fragment)

///| 简化的 scheme 解析: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
pub fn parse_scheme(s : String) -> URIResult[String] {
  if s.is_empty() {
    return Err(InvalidScheme("Scheme cannot be empty"))
  }
  let chars = s.to_array()

  // 第一个字符必须是字母
  if not(is_alpha(chars[0])) {
    return Err(InvalidScheme("Scheme must start with a letter"))
  }

  // 使用更简洁的验证逻辑
  for char in chars {
    if not(is_scheme_char(char)) {
      return Err(InvalidScheme("Invalid characters in scheme"))
    }
  }
  Ok(s.to_lower()) // scheme 对大小写不敏感，规范化为小写
}

///| Parse query: *( pchar / "/" / "?" )
pub fn parse_query(s : String) -> URIResult[String] {
  if is_valid_encoded_string(s, is_query_char) {
    Ok(s)
  } else {
    Err(InvalidQuery("Invalid characters in query"))
  }
}

///| Parse fragment: *( pchar / "/" / "?" )
pub fn parse_fragment(s : String) -> URIResult[String] {
  if is_valid_encoded_string(s, is_fragment_char) {
    Ok(s)
  } else {
    Err(InvalidFragment("Invalid characters in fragment"))
  }
}

///| 简化的查询字符串解析为键值对
pub fn parse_query_params(query : String) -> Array[(String, String)] {
  if query.is_empty() {
    return []
  }
  query
  .split("&")
  .map(fn(pair) { pair.to_string() })
  .collect()
  .map(fn(pair_str) {
    match pair_str.find("=") {
      Some(pos) => {
        let key = pair_str.substring(start=0, end=pos)
        let value = pair_str.substring(start=pos + 1)
        // 解码百分号编码的值
        match (percent_decode(key), percent_decode(value)) {
          (Ok(decoded_key), Ok(decoded_value)) => (decoded_key, decoded_value)
          _ => (key, value) // 解码失败时保持原值
        }
      }
      None =>
        // 没有值的键
        match percent_decode(pair_str) {
          Ok(decoded_key) => (decoded_key, "")
          Err(_) => (pair_str, "")
        }
    }
  })
}

///| 简化的查询字符串构建
pub fn build_query_string(params : Array[(String, String)]) -> String {
  if params.is_empty() {
    return ""
  }
  params
  .map(fn(pair) {
    let (key, value) = pair
    let encoded_key = encode_query(key)
    if value.is_empty() {
      encoded_key
    } else {
      encoded_key + "=" + encode_query(value)
    }
  })
  .join("&")
}

///| 简化的 URI 组件验证
pub fn validate_uri_components(
  scheme : String,
  authority : Authority?,
  path : String,
  query : String?,
  fragment : String?,
) -> URIResult[Unit] {
  // 验证 scheme
  match parse_scheme(scheme) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }

  // 验证查询（如果存在）
  match query {
    Some(q) =>
      match parse_query(q) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
    None => ()
  }

  // 验证片段（如果存在）
  match fragment {
    Some(f) =>
      match parse_fragment(f) {
        Ok(_) => ()
        Err(e) => return Err(e)
      }
    None => ()
  }

  // 根据是否有权威组件验证路径
  match authority {
    Some(_) =>
      match validate_path_abempty(path) {
        Ok(_) => Ok(())
        Err(e) => Err(e)
      }
    None =>
      match classify_and_validate_path(path) {
        Ok(_) => Ok(())
        Err(e) => Err(e)
      }
  }
}

///| Case-insensitive scheme comparison
pub fn schemes_equal(scheme1 : String, scheme2 : String) -> Bool {
  scheme1.to_lower() == scheme2.to_lower()
}

///| Normalize URI component case (schemes and host names are case-insensitive)
pub fn normalize_uri_case(uri : URI) -> URI {
  let normalized_authority = match uri.authority {
    Some(auth) => {
      let normalized_host = match auth.host {
        HostType::RegName(name) => HostType::RegName(name.to_lower())
        other => other
      }
      Some({ ..auth, host: normalized_host })
    }
    None => None
  }
  { ..uri, scheme: uri.scheme.to_lower(), authority: normalized_authority }
}
