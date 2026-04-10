









#let __nodestyler(dom_task, csskv, tagname, tagname_stack_current) = {
  let parse_dimension(dimstr) = {
    return eval(dimstr.replace("px", "pt"))
  }

  let parse_quoted_list(input) = {
    let pattern = regex("'([^']*)'|(\d+)")
    input
      .matches(pattern)
      .map(m => {
        // If it's a quoted match, the captured group is at index 1
        // If it's a raw number, the captured group is at index 2
        if m.captures.at(0) != none {
          m.captures.at(0)
        } else {
          m.captures.at(1)
        }
      })
  }

  let default_kv = (
    display: if ("span", "strong", "em", "code").contains(tagname) { "inline" } else { "block" },
    padding-top: "0pt",
    padding-bottom: "0pt",
    padding-left: "0pt",
    padding-right: "0pt",
    margin-top: "0pt",
    margin-bottom: "0pt",
    margin-left: "0pt",
    margin-right: "0pt",
    border-top-width: "0pt",
    border-bottom-width: "0pt",
    border-left-width: "0pt",
    border-right-width: "0pt",
    border-top-color: "black",
    border-bottom-color: "black",
    border-left-color: "black",
    border-right-color: "black",
    border-top: none,
    border-bottom: none,
    border-left: none,
    border-right: none,
    width: "initial",
    height: "initial",
    border: none,
    padding: none,
    margin: none,
    font-size: "1em",
    color: "black",
    line-height: "1.65em",
    background-color: "none",
    text-decoration: "none",
    text-align: "left",
    __dummy__font-family: "'TeX Gyre Heros', sans-serif",
    font-family: if ("pre", "code").contains(tagname) {
      "'JetBrains Mono NL', 'Source Code Pro', 'Noto Sans Mono', 'Ubuntu Mono', 'Inconsolata', monospace"
    } else {
      "'TeX Gyre Heros', sans-serif"
    },
  )
  let realkv = default_kv + csskv
  // repr(realkv)

  // Expand border values
  if realkv.border != none {
    realkv.border-top = realkv.border
    realkv.border-bottom = realkv.border
    realkv.border-left = realkv.border
    realkv.border-right = realkv.border
  }
  // ("top","bottom","left","right").map(side => {
  //   let __config = realkv.at("border-" + side)
  //   if __config != none {
  //     let __arr = parse_quoted_list(__config)
  //     realkv.at("border-" + side + "-width") = parse_dimension(__arr.at(0))
  //     // TODO: solid/dashes
  //     realkv.at("border-" + side + "-color") = parse_dimension(__arr.at(2))
  //   }
  // }).join()
  for (itr, side) in ("top", "bottom", "left", "right").enumerate() {
    // let side = ("top", "bottom", "left", "right").at(itr)
    // let side = (itr)
    let __config = realkv.at("border-" + side)
    if __config != none {
      let __arr = __config.split(regex("\s+"))
      // repr(__config)
      // repr(__arr)
      realkv.at("border-" + side + "-width") = (__arr.at(0))
      // TODO: solid/dashes
      realkv.at("border-" + side + "-color") = (__arr.at(2))
    }
  }

  /// Expands shorthand properties like padding or margin into
  /// individual directional keys in the dictionary.
  let expand-shorthand(dict, name) = {
    if name not in dict or dict.at(name) == none { return dict }

    let val = dict.at(name)
    let dims = if val.contains(" ") { val.split(regex("\s+")) } else { (val,) }

    // CSS Box Model Shorthand Logic:
    // 1 value:  [all]
    // 2 values: [top/bottom, left/right]
    // 3 values: [top, left/right, bottom]
    // 4 values: [top, right, bottom, left]
    let resolved = if dims.len() == 1 {
      (top: dims.at(0), right: dims.at(0), bottom: dims.at(0), left: dims.at(0))
    } else if dims.len() == 2 {
      (top: dims.at(0), right: dims.at(1), bottom: dims.at(0), left: dims.at(1))
    } else if dims.len() == 3 {
      (top: dims.at(0), right: dims.at(1), bottom: dims.at(2), left: dims.at(1))
    } else if dims.len() == 4 {
      (top: dims.at(0), right: dims.at(1), bottom: dims.at(2), left: dims.at(3))
    } else {
      (:)
    }

    // Merge the expanded values back into the dictionary
    for (dir, amount) in resolved {
      dict.insert(name + "-" + dir, amount)
    }

    // Optionally remove the shorthand key to clean up
    let _ = dict.remove(name)
    return dict
  }

  // Usage:
  realkv = expand-shorthand(realkv, "padding")
  realkv = expand-shorthand(realkv, "margin")

  let pipe(value, ..functions) = {
    functions.pos().fold(value, (acc, f) => f(acc))
  }
  // dom_task
  let steps = (
    // font-size
    it => {
      let __dim = parse_dimension(realkv.font-size)
      if __dim != none {
        text(size: __dim, it)
      } else {
        it
      }
    },
    // color
    it => {
      let __color = black
      if realkv.color.clusters().at(0) == "#" {
        // Hex parser mode
        __color = rgb(realkv.color)
      } else {
        // Asume named color mode
        __color = eval(realkv.color)
      } // TODO: More modes
      text(fill: __color, it)
    },
    // text-decoration
    it => {
      if realkv.text-decoration == "underline" {
        underline(it)
      } else {
        it
      }
    },
    // text-align
    it => {
      if realkv.text-align == "justify" {
        return {
          set par(justify: true)
          it
        }
      } else if realkv.text-align == "left" {
        return {
          set align(left)
          it
        }
      } else if realkv.text-align == "right" {
        return {
          set align(right)
          it
        }
      } else {
        it
      }
    },
    // font-family
    it => {
      if realkv.font-family == default_kv.__dummy__font-family {
        return it
      } else {
        let __fonts = parse_quoted_list(realkv.font-family)
        return text(font: __fonts, it)
      }
    },
    // content box
    it => {
      let __width = auto
      if realkv.width != "initial" {
        __width = parse_dimension(realkv.width)
      }
      let __height = auto
      if realkv.height != "initial" {
        __height = parse_dimension(realkv.height)
      }
      return box(width: __width, height: __height, it)
    },
    // block padding box
    it => {
      if realkv.display == "block" {
        return box(
          inset: (
            top: parse_dimension(realkv.padding-top),
            bottom: parse_dimension(realkv.padding-bottom),
            left: parse_dimension(realkv.padding-left),
            right: parse_dimension(realkv.padding-right),
          ),
          it,
        )
      } else {
        return it
      }
    },
    // block border box
    it => {
      if realkv.display == "block" or true {
        let __inset = (
          top: parse_dimension(realkv.border-top-width) / 2,
          bottom: parse_dimension(realkv.border-bottom-width) / 2,
          left: parse_dimension(realkv.border-left-width) / 2,
          right: parse_dimension(realkv.border-right-width) / 2,
        )
        return box(
          inset: __inset,
          fill: eval(realkv.background-color),
          box(
            stroke: (
              top: parse_dimension(realkv.border-top-width) + eval(realkv.border-top-color),
              bottom: parse_dimension(realkv.border-bottom-width) + eval(realkv.border-bottom-color),
              left: parse_dimension(realkv.border-left-width) + eval(realkv.border-left-color),
              right: parse_dimension(realkv.border-right-width) + eval(realkv.border-right-color),
            ),
            inset: __inset,
            it,
          ),
        )
      } else {
        return it
      }
    },
    // block margin box
    it => {
      if realkv.display == "block" {
        return box(
          inset: (
            top: parse_dimension(realkv.margin-top),
            bottom: parse_dimension(realkv.margin-bottom),
            left: parse_dimension(realkv.margin-left),
            right: parse_dimension(realkv.margin-right),
          ),
          it,
        )
      } else {
        // return it
        return {
          h(parse_dimension(realkv.margin-left))
          it
          h(parse_dimension(realkv.margin-right))
        }
      }
    },
    // Miscellaneous
    it => {
      set par(leading: parse_dimension(realkv.line-height) - 1em)
      it
    },
    // ...
    it => { it },
  )
  let output = pipe(dom_task, ..steps)
  output
}








#let html-render(input_str, debug: false) = {
  let __parse-css-kv(css_piece) = {
    let pairs = (:)
    // Split by semicolon to get individual "key: value" strings
    for rule in css_piece.split(";") {
      let trimmed = rule.trim()
      // Skip empty strings (common at the end of a CSS block)
      if trimmed.len() > 0 {
        let parts = trimmed.split(":")
        if parts.len() >= 2 {
          let key = parts.at(0).trim()
          // Join the rest back together in case the value contains a colon (like a URL)
          let value = parts.slice(1).join(":").trim()
          pairs.insert(key, value)
        }
      }
    }
    return pairs
  }


  let html_str = "<magicwrapperroot style=\"\">" + input_str + "</magicwrapperroot>"
  // BEGIN PREPROCESSOR -------------------------------------------------
  html_str = html_str
    .replace(regex(">\n\s*"), ">")
    .replace(regex(">\s*\n"), ">")
    .replace(regex("<br>"), "<br/>")
    .replace(regex("<hr>"), "<hr/>")
    // .replace(regex("\n\s+"), " ")
  // END PREPROCESSOR -------------------------------------------------
  let ast_tree = xml(bytes(html_str))
  if debug { text(repr(ast_tree)) }
  let walk_tree(treeish, tagname_stack_context) = {
    let get-text(it) = {
      // Walk a sequence tree
      if type(it) == str {
        // If it's already a string, just return it
        return it
      } else if it.has("text") {
        // If it's a text element (e.g., [Hello])
        return it.text
      } else if it.has("children") {
        // If it's a sequence, walk the children
        return it.children.map(get-text).join()
      } else if it.has("body") {
        // If it's a container (like a box, block, or bold)
        return get-text(it.body)
      } else {
        // Fallback for elements without text (like images or spacing)
        return ""
      }
    }
    let containers_table = (
      "h1": it => heading(level: 1, it),
      "h2": it => heading(level: 2, it),
      "h3": it => heading(level: 3, it),
      "h4": it => heading(level: 4, it),
      "h5": it => heading(level: 5, it),
      "h6": it => heading(level: 6, it),
      "p": it => par(it),
      "span": it => it,
      "strong": it => strong(it),
      "em": it => emph(it),
      "code": it => it,
      "div": it => block(breakable: true, it),
      "br": it => linebreak(),
      "hr": it => block(width: 100%, height: 0.5pt, fill: black),
    )
    let container_func = containers_table.at(treeish.tag, default: it => it)
    let tagname_stack_current = (..tagname_stack_context, treeish.tag)
    let process_child(child) = {
      if type(child) == str {
        return child.replace("\n", " ").replace(regex("\s+"), " ")
      } else {
        return {
          walk_tree(child, tagname_stack_current)
        }
      }
    }
    container_func({
      let attrs_style = treeish.attrs.at("style", default: none)
      let dom_task = treeish.children.filter(it => it != "\n " and it != "\n").map(process_child).join()
      if attrs_style == none {
        dom_task
      } else {
        let parsed_style_dict = __parse-css-kv(attrs_style)
        __nodestyler(dom_task, parsed_style_dict, treeish.tag, tagname_stack_current)
      }
    })
  }
  walk_tree(ast_tree.at(0), ())
  if debug {
    pagebreak()
    repr(walk_tree(ast_tree.at(0), ()))
  }
}



