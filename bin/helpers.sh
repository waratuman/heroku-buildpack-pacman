indent() {
  case $(uname -s) in
    Darwin*) sed 's/^/       /';;
    *) sed -u 's/^/       /';;
  esac
}
