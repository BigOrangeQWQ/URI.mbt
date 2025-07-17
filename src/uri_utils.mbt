/// 完全基于标准库的简化工具函数

/// 查找字符在字符串中的位置（使用标准库）
pub fn find_char_index(s : String, c : Char) -> Int? {
  s.find(c.to_string())
}

/// 查找子字符串最后出现的位置（使用标准库）
pub fn find_last_index_str(s : String, substr : String) -> Int? {
  s.rev_find(substr)
}

/// 简化的整数解析（数字字符串转整数）
pub fn parse_int_simple(s : String) -> Int {
  // 使用简化的循环逻辑
  let mut result = 0
  for c in s {
    if is_digit(c) {
      result = result * 10 + (c.to_int() - '0'.to_int())
    }
  }
  result
}

/// 字符串分割（使用标准库 find 方法）
pub fn split_string_at(s : String, delimiter : Char) -> (String, String?) {
  match s.find(delimiter.to_string()) {
    Some(pos) => (s.substring(start=0, end=pos), Some(s.substring(start=pos + 1)))
    None => (s, None)
  }
}

/// 检查字符串是否为空或只包含空白字符
pub fn is_empty_or_whitespace(s : String) -> Bool {
  if s.is_empty() {
    true
  } else {
    // 检查所有字符是否都是空白字符
    let mut all_whitespace = true
    for c in s {
      if c != ' ' && c != '\t' && c != '\n' && c != '\r' {
        all_whitespace = false
        break
      }
    }
    all_whitespace
  }
}