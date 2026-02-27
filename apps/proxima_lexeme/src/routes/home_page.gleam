import gleam/http
import wisp

pub fn get_home_page(request, _context) {
  use <- wisp.require_method(request, http.Get)

  wisp.ok()
  |> wisp.html_body("<h1>First Lexeme</h1>")
}
