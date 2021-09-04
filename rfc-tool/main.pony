use "cli"
use "files"
use "format"
use peg = "peg"

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

    try
      match CommandParser(cli()?).parse(_env.args, _env.vars)
      | let c: Command => run(auth, c)
      | let h: CommandHelp => _env.out.print(h.help_string())
      | let e: SyntaxError =>
        _env.out.print(e.string())
        _env.exitcode(1)
      end
    else
      err("invalid command spec")
      please_report()
    end

  fun run(auth: AmbientAuth, cmd: Command) =>
    let filepath = cmd.arg("RFC file").string()
    match cmd.fullname()
    | "rfc-tool/version" => _env.out.print("rfc-tool " + Version())
    | "rfc-tool/verify" =>
      try
        make_rfc(parse_file(auth, filepath)?)?
        _env.out.print(filepath + " is a valid RFC")
      else
        return
      end
    | "rfc-tool/complete" =>
      let rfc = try make_rfc(parse_file(auth, filepath)?)? else return end
      let validate =
        {(p: peg.Parser val, src: String)(self: Main box = this): String ? =>
          try
            let ast =
              self.parse(recover p.eof() end, peg.Source.from_string(src))?
            (ast.extract() as peg.Token).string()
          else
            self.err("invalid argument: " + src)
            error
          end
        }
      try
        rfc.tracking =
          ( validate(RFCParser.pr_url(), cmd.arg("RFC PR").string())?
          , validate(RFCParser.issue_url(), cmd.arg("RFC issue").string())? )
      else
        return
      end

      if cmd.option("edit").bool() then
        File(FilePath(auth, filepath))
          .> set_length(0)
          .> write(rfc.string())
          .> flush()
          .> dispose()
      else
        _env.out.print(rfc.string())
      end
    else
      err("unknown command: " + cmd.fullname())
      please_report()
    end

  fun parse_file(auth: AmbientAuth, filepath: String): peg.AST ? =>
    let source = peg.Source(FilePath(auth, filepath))?
    try return parse(RFCParser(), source)?
    else
      err("unable to parse file: " + filepath)
      error
    end

  fun parse(p: peg.Parser val, src: peg.Source): peg.AST ? =>
    match recover val p.parse(src) end
    | (_, let ast: peg.AST) => return ast
    | (_, let t: peg.Token) => return peg.AST .> push(t)
    | (let offset: USize, let r: peg.Parser val) =>
      let e = recover val peg.SyntaxError(src, offset, r) end
      _env.out.writev(peg.PegFormatError.console(e))
    end
    error

  fun make_rfc(ast: peg.AST): RFC ? =>
    let token =
      {(ast: peg.AST, i: USize): peg.Token ? => ast.children(i)? as peg.Token }
    let start = token(ast, 1)?.string().split("-")
    RFC(
      token(ast, 0)?.string(),
      (start(0)?.u16()?, start(1)?.u8()?, start(2)?.u8()?),
      try (token(ast, 2)?.string(), token(ast, 3)?.string()) end,
      token(ast, 4)?.string())

  fun cli(): CommandSpec ? =>
    CommandSpec.parent(
      "rfc-tool",
      "",
      [],
      [ CommandSpec.leaf("version", "Show the version and exit")?
        CommandSpec.leaf(
          "verify",
          "Verify that an RFC is valid",
          [],
          [ ArgSpec.string("RFC file")
          ])?
        CommandSpec.leaf(
          "complete",
          "Complete an RFC with tracking information.",
          [ OptionSpec.bool("edit", "Modify the RFC file", 'e', false)
          ],
          [ ArgSpec.string("RFC file")
            ArgSpec.string("RFC PR")
            ArgSpec.string("RFC issue")
          ])?
      ])?
      .> add_help("help", "Print this message and exit")?

  fun please_report() =>
    _env.out.print(
      "This is an internal error. " +
      "Please open an issue at https://github.com/ponylang/rfc-tool")

  fun err(message: String) =>
    _env.exitcode(1)
    _env.out.print("error: " + message)

class RFC
  let feature: String
  let start: (U16, U8, U8)
  var tracking: ((String, String) | None)
  let content: String

  new create(
    feature': String,
    start': (U16, U8, U8),
    tracking': ((String, String) | None),
    content': String)
  =>
    feature = feature'
    start = start'
    tracking = tracking'
    content = content'

  fun string(): String iso^ =>
    let fmt_u8 =
      {(n: U8): String => Format.int[U8](n where width = 2, fill = '0') }
    "\n".join(
      [ "- Feature Name: " + feature
        "- Start Date: " +
          "-".join([start._1; fmt_u8(start._2); fmt_u8(start._3)].values())
        "- RFC PR:" +
          try " " + (tracking as (String, String))._1 else "" end
        "- Pony Issue:" +
          try " " + (tracking as (String, String))._2 else "" end
        content
      ].values())
