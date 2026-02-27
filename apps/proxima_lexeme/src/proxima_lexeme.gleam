import gleam/erlang/process

import mist
import routes/router
import wisp
import wisp/wisp_mist

pub fn route(request, context) {
  case wisp.path_segments(request) {
    [] -> router.route(request, context)
    _ -> wisp.not_found()
  }
}

pub fn main() {
  wisp.configure_logger()

  let context = Nil
  let secret_key_base = ""

  let assert Ok(_) =
    route(_, context)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
