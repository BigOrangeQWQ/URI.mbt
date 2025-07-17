/// Path parsing utilities
/// path = path-abempty / path-absolute / path-noscheme / path-rootless / path-empty

///| Validate a path segment: *pchar
fn is_valid_segment(s : String) -> Bool {
  is_valid_encoded_string(s, is_pchar)
}

///| Validate a non-zero segment: 1*pchar
fn is_valid_segment_nz(s : String) -> Bool {
  not(s.is_empty()) && is_valid_segment(s)
}

///| Validate a segment-nz-nc: 1*( unreserved / pct-encoded / sub-delims / "@" )
/// (non-zero-length segment without any colon ":")
fn is_valid_segment_nz_nc(s : String) -> Bool {
  not(s.is_empty()) && is_valid_encoded_string(s, is_segment_nz_nc_char)
}

///| Determine path type and validate
pub fn classify_and_validate_path(
  path : String
) -> URIResult[(PathType, String)] {
  if path.is_empty() {
    // path-empty
    Ok((Empty, path))
  } else if path.has_prefix("//") {
    // This would be authority, not a valid path by itself
    Err(InvalidPath("Path cannot start with '//' (use authority component)"))
  } else if path.has_prefix("/") {
    // path-absolute or path-abempty
    validate_path_absolute(path)
  } else {
    // path-noscheme or path-rootless
    validate_path_relative(path)
  }
}

///| Validate path-absolute: "/" [ segment-nz *( "/" segment ) ]
fn validate_path_absolute(path : String) -> URIResult[(PathType, String)] {
  if path == "/" {
    Ok((Absolute, path))
  } else {
    let segments = path.substring(start=1).split("/") // Remove leading '/'
    let segments_arr = segments.collect()

    // First segment must be non-zero if it exists
    if segments_arr.length() > 0 && not(segments_arr[0].to_string().is_empty()) {
      if not(is_valid_segment_nz(segments_arr[0].to_string())) {
        return Err(InvalidPath("Invalid first segment in absolute path"))
      }
    }

    // Remaining segments can be empty
    for i = 1; i < segments_arr.length(); i = i + 1 {
      if not(is_valid_segment(segments_arr[i].to_string())) {
        return Err(InvalidPath("Invalid segment in absolute path"))
      }
    }
    Ok((Absolute, path))
  }
}

///| Validate relative paths (path-noscheme or path-rootless)
fn validate_path_relative(path : String) -> URIResult[(PathType, String)] {
  let segments = path.split("/")
  let segments_arr = segments.collect()
  if segments_arr.length() == 0 {
    return Err(InvalidPath("Path cannot be empty here"))
  }

  // First segment determines if this is noscheme or rootless
  let first_segment = segments_arr[0].to_string()
  if not(is_valid_segment_nz(first_segment)) {
    return Err(InvalidPath("Invalid first segment in relative path"))
  }

  // Check if first segment contains colon (which would make it path-rootless)
  let has_colon = first_segment.contains(":")
  let path_type = if has_colon { Rootless } else { NoScheme }
  if path_type == NoScheme {
    // For path-noscheme, first segment must be segment-nz-nc
    if not(is_valid_segment_nz_nc(first_segment)) {
      return Err(
        InvalidPath("First segment in no-scheme path cannot contain colon"),
      )
    }
  }

  // Validate remaining segments
  for i = 1; i < segments_arr.length(); i = i + 1 {
    if not(is_valid_segment(segments_arr[i].to_string())) {
      return Err(InvalidPath("Invalid segment in relative path"))
    }
  }
  Ok((path_type, path))
}

///| Validate path-abempty: *( "/" segment )
pub fn validate_path_abempty(path : String) -> URIResult[String] {
  if path.is_empty() {
    Ok(path)
  } else if not(path.has_prefix("/")) {
    Err(InvalidPath("Path-abempty must start with '/' or be empty"))
  } else {
    let segments = path.substring(start=1).split("/") // Remove leading '/'
    let segments_arr = segments.collect()
    for i = 0; i < segments_arr.length(); i = i + 1 {
      if not(is_valid_segment(segments_arr[i].to_string())) {
        return Err(InvalidPath("Invalid segment in abempty path"))
      }
    }
    Ok(path)
  }
}

///| 简化的路径规范化函数
pub fn normalize_path(path : String) -> String {
  if path.is_empty() {
    return path
  }
  
  let is_absolute = path.has_prefix("/")
  let segments = (if is_absolute { path.substring(start=1) } else { path })
    .split("/")
    .map(fn(s) { s.to_string() })
    .collect()
  
  // 使用函数式编程风格处理段
  let normalized_segments : Array[String] = []
  
  for segment in segments {
    match segment {
      "." | "" if normalized_segments.length() == 0 && is_absolute => normalized_segments.push("")
      "." | "" => continue  // 跳过当前目录和空段
      ".." => {
        // 处理父目录
        let len = normalized_segments.length()
        if len > 0 && normalized_segments[len - 1] != ".." && normalized_segments[len - 1] != "" {
          ignore(normalized_segments.pop())
        } else if not(is_absolute) {
          normalized_segments.push("..")  // 相对路径保留 ".."
        }
        // 绝对路径中根级别的 ".." 被忽略
      }
      _ => normalized_segments.push(segment)
    }
  }
  
  let result = normalized_segments.join("/")
  if is_absolute && not(result.has_prefix("/")) { "/" + result } else { result }
}

///| 简化的路径连接函数
pub fn join_paths(base : String, path : String) -> String {
  match (base.is_empty(), path.is_empty(), path.has_prefix("/")) {
    (_, _, true) => path // 绝对路径替换基路径
    (true, _, _) => path // 空基路径
    (_, true, _) => base // 空路径
    _ => {
      let base_with_slash = if base.has_suffix("/") { base } else { base + "/" }
      normalize_path(base_with_slash + path)
    }
  }
}

///| 简化的路径分段函数
pub fn path_segments(path : String) -> Array[String] {
  match path {
    "" => []
    "/" => [""]
    _ => {
      let trimmed = if path.has_prefix("/") { path.substring(start=1) } else { path }
      trimmed.split("/").map(fn(s) { s.to_string() }).collect()
    }
  }
}
