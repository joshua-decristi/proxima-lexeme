import gleeunit

pub fn main() {
  gleeunit.main()
}

fn sum(first: Int, second: Int) {
  first + second
}

pub fn my_function_test() {
  assert sum(1, 2) == 3
}
