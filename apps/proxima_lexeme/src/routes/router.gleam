import wisp

pub fn route(request, _context) {
  let base_html =
    "
    <html>
      <head>
      </head>
      <body style=\"background: #222\">
        <h1 style=\"color:white\">TEST!</h1>
      </body>
    </html>
    "

  case request {
    _ -> wisp.html_response(base_html, 200)
  }
}
