import routes/home_page
import wisp

pub fn route(request, context) {
  case wisp.path_segments(request) {
    [] -> home_page.get_home_page(request, context)
    _ -> wisp.not_found()
  }
}
