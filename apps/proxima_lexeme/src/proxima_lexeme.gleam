import gleam/erlang/process

import mist
import routes/router
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let context = Nil
  let secret_key_base = ""

  let assert Ok(_) =
    router.route(_, context)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
