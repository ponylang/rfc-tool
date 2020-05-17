use "files"
use "peg"

actor Main
  let _env: Env

  new create(env: Env) =>
    _env = consume env

    let auth =
      try
        _env.root as AmbientAuth
      else
        err("environment does not have ambient authority")
        return
      end

    // TODO: cli
    let filepath =
      try
        _env.args(1)?
      else
        err("no path specified")
        return
      end

    let source =
      try
        Source(FilePath(auth, filepath)?)?
      else
        err("invalid file path: " + filepath)
        return
      end

    match recover val RFCParser().parse(source) end
    | (_, let ast: AST) =>
      _env.out.print(recover val Printer(ast) end)
    | (let offset: USize, let r: Parser val) =>
      let e = recover val SyntaxError(source, offset, r) end
      _env.out.writev(PegFormatError.console(e))
      err("unable to parse file: " + filepath)
    else
      err("unable to parse file: " + filepath)
    end

  fun err(message: String) =>
    _env.exitcode(1)
    _env.out.print("error: " + message)
