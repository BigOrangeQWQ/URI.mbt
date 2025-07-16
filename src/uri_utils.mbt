/// Common utility functions for URI processing

///| Find first occurrence of character in string
pub fn find_char_index(s : String, c : Char) -> Int? {
  s.find(c.to_string())
}

///| Find last occurrence of substring in string 
pub fn find_last_index_str(s : String, substr : String) -> Int? {
  s.rev_find(substr)
}

///| Simple integer parsing (without error handling for internal use)
pub fn parse_int_simple(s : String) -> Int {
  let chars = s.to_array() 
  let mut result = 0
  for char in chars {
    let digit_value = char.to_int() - 48 // '0' = 48
    result = result * 10 + digit_value
  }
  result
}