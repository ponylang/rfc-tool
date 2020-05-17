use "peg"

primitive RFCParser
  fun apply(): Parser val =>
    recover
      let header = feature() * start() * pr() * issue()
      let content = R(0).many1().term(Content)
      (header * content).eof()
    end

  fun feature(): Parser val =>
    recover
      let name = alphanum().many1(L("-")).term(Feature)
      -L("- Feature Name: ") * name * -L("\n")
    end

  fun start(): Parser val =>
    recover
      let digits4 = digit() * digit() * digit() * digit()
      let digits2 = digit() * digit()
      let date = (digits4 * L("-") * digits2 * L("-") * digits2).term(Start)
      -L("- Start Date: ") * date * -L("\n")
    end

  fun pr(): Parser val =>
    recover -L("- RFC PR:") * (-L(" ") * pr_url()).opt() * -L("\n") end

  fun pr_url(): Parser val =>
    recover
      let url_base = "https://github.com/ponylang/rfcs/pull/"
      (L(url_base) * digits()).term(PR)
    end

  fun issue(): Parser val =>
    recover -L("- Pony Issue:") * (-L(" ") * issue_url()).opt() * -L("\n") end

  fun issue_url(): Parser val =>
    recover
      let url_base = "https://github.com/ponylang/ponyc/issues/"
      (L(url_base) * digits()).term(Issue)
    end

  fun alphanum(): Parser val =>
    recover (alpha() / digit()).many1() end

  fun alpha(): Parser val =>
    recover R('A', 'Z') / R('a', 'z') end

  fun digits(): Parser val =>
    recover digit().many1().term() end

  fun digit(): Parser val =>
    recover R('0', '9') end

primitive Feature is Label
  fun text(): String => "Feature"
primitive Start is Label
  fun text(): String => "Start"
primitive PR is Label
  fun text(): String => "PR"
primitive Issue is Label
  fun text(): String => "Issue"
primitive Content is Label
  fun text(): String => "Content"
