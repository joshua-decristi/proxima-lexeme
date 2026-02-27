import gleam/http
import gleam/io
import proxima_lexeme
import wisp/simulate

pub fn get_home_page_test() {
  let request = simulate.browser_request(http.Get, "/")
  let response = proxima_lexeme.route(request, Nil)

  assert response.status == 200
  io.println("✅ Pass! | Home page returned 200")

  assert response.headers == [#("content-type", "text/html; charset=utf-8")]
  io.println("✅ Pass! | Home page returned html")
}
