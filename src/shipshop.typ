#let __sequence_shake(it) = {
  // 1. Define the "trash" criteria
  let is_empty(el) = {
    if el == [] { return true }
    if type(el) == content {
      if el.func() == h or el.func() == v {
        if el.amount == 0pt or el.amount == 0fr { return true }
      }
    }
    return false
  }

  // 2. If it's not content (like a string or symbol), just return it
  if type(it) != content { return it }

  // 3. Handle Sequences
  if it.func() == [].func() {
    let children = it.children.map(__sequence_shake).filter(child => not is_empty(child))

    return children.join()
  }

  // 4. Handle Styled elements or containers
  if it.has("child") {
    let new_child = __sequence_shake(it.child)
    if is_empty(new_child) { return [] }

    // Create a copy and update the child
    let out = it
    out.child = new_child
    return out
  }

  return it
}

// --- Testing ---

#let test_content = [
  Hello
  #h(0pt)
  #v(0mm)
  #[]
  World
  #h(10pt)
  #[#h(0fr)]
]

#let __std_test_case_001 = [
  Original length: #test_content.children.len() \
  Shaken length: #__sequence_shake(test_content).children.len()

  #__sequence_shake(test_content)
]


#let __parse_color(input_color) = {
  let __color = black
  if input_color.clusters().at(0) == "#" {
    // Hex parser mode
    __color = rgb(input_color)
  } else {
    // Asume named color mode
    __color = eval(input_color)
  } // TODO: More modes
  return __color
}

#let __get-text(it) = {
  // Walk a sequence tree
  if type(it) == str {
    // If it's already a string, just return it
    return it
  } else if it.has("text") {
    // If it's a text element (e.g., [Hello])
    return it.text
  } else if it.has("children") {
    // If it's a sequence, walk the children
    return it.children.map(__get-text).join()
  } else if it.has("body") {
    // If it's a container (like a box, block, or bold)
    return __get-text(it.body)
  } else {
    // Fallback for elements without text (like images or spacing)
    return ""
  }
}



#let __parse_dimension(dimstr) = {
  return eval(dimstr.replace("px", "pt"))
}

#let __parse_quoted_list(input) = {
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



#let __expand-shorthand(dict, name) = {
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





#let __nodestyler(
  dom_task, // content or sequence, usually
  csskv, // kv of css properties
  tagname, // "div", "p", "h2"
  attrs, // dictionary of element attributes
  tagname_stack_current, // list of tag names of the current branch on tree
  treeish, // Recuesive DOM tree partial, from native parser
) = {
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

  // Expand border values
  if realkv.border != none {
    realkv.border-top = realkv.border
    realkv.border-bottom = realkv.border
    realkv.border-left = realkv.border
    realkv.border-right = realkv.border
  }
  for (itr, side) in ("top", "bottom", "left", "right").enumerate() {
    let __config = realkv.at("border-" + side)
    if __config != none {
      let __arr = __config.split(regex("\s+"))
      realkv.at("border-" + side + "-width") = (__arr.at(0))
      // TODO: solid/dashes
      realkv.at("border-" + side + "-color") = (__arr.at(2))
    }
  }

  /// Expands shorthand properties like padding or margin into
  /// individual directional keys in the dictionary.
  realkv = __expand-shorthand(realkv, "padding")
  realkv = __expand-shorthand(realkv, "margin")

  let pipe(value, ..functions) = {
    functions.pos().fold(value, (acc, f) => f(acc))
  }

  let steps = (
    // font-size
    it => {
      if type(it) == array {
        return it
      } else {
        let __dim = __parse_dimension(realkv.font-size)
        return if __dim != none {
          text(size: __dim, it)
        } else {
          it
        }
      }
    },
    // color
    it => {
      return if type(it) == array {
        it
      } else {
        text(fill: __parse_color(realkv.color), it)
      }
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
        let __fonts = __parse_quoted_list(realkv.font-family).map(fontname => {
          let __table = (
            serif: "Libertinus Serif",
            sans-serif: "Noto Sans",
            monospace: "DejaVu Sans Mono",
          )
          return __table.at(fontname, default: fontname)
        })
        return text(font: __fonts, it)
      }
    },
    // content box
    it => {
      let __width = auto
      if realkv.width != "initial" {
        __width = __parse_dimension(realkv.width)
      }
      let __height = auto
      if realkv.height != "initial" {
        __height = __parse_dimension(realkv.height)
      }
      return box(width: __width, height: __height, it)
    },
    // block padding box
    it => {
      if realkv.display == "block" {
        return box(
          inset: (
            top: __parse_dimension(realkv.padding-top),
            bottom: __parse_dimension(realkv.padding-bottom),
            left: __parse_dimension(realkv.padding-left),
            right: __parse_dimension(realkv.padding-right),
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
          top: __parse_dimension(realkv.border-top-width) / 2,
          bottom: __parse_dimension(realkv.border-bottom-width) / 2,
          left: __parse_dimension(realkv.border-left-width) / 2,
          right: __parse_dimension(realkv.border-right-width) / 2,
        )
        let __inset_all_zero = false // TODO: Calculate this bool value from __inset
        if __inset_all_zero { return it } else {
          return box(
            inset: __inset,
            fill: __parse_color(realkv.background-color),
            box(
              stroke: (
                top: __parse_dimension(realkv.border-top-width) + __parse_color(realkv.border-top-color),
                bottom: __parse_dimension(realkv.border-bottom-width) + __parse_color(realkv.border-bottom-color),
                left: __parse_dimension(realkv.border-left-width) + __parse_color(realkv.border-left-color),
                right: __parse_dimension(realkv.border-right-width) + __parse_color(realkv.border-right-color),
              ),
              inset: __inset,
              it,
            ),
          )
        }
      } else {
        return it
      }
    },
    // block margin box
    it => {
      if realkv.display == "block" {
        return box(
          inset: (
            top: __parse_dimension(realkv.margin-top),
            bottom: __parse_dimension(realkv.margin-bottom),
            left: __parse_dimension(realkv.margin-left),
            right: __parse_dimension(realkv.margin-right),
          ),
          it,
        )
      } else {
        // return it
        return {
          h(__parse_dimension(realkv.margin-left))
          it
          h(__parse_dimension(realkv.margin-right))
        }
      }
    },
    // Miscellaneous
    it => {
      set par(leading: __parse_dimension(realkv.line-height) - 1em)
      it
    },
    // ...
    it => { it },
  )
  let output = pipe(dom_task, ..steps)
  output
}







// This comment line is line # 314
#let html-render(input_str, debug: false) = {
  let __parse_css_kv(css_piece) = {
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
  // END PREPROCESSOR -------------------------------------------------


  let ast_tree = xml(bytes(html_str))
  let walk_tree(treeish, tagname_stack_context, dict_vars_context) = {
    let dict_vars_current = dict_vars_context + (:)


    if treeish.tag == "table" {
      dict_vars_current.is_table = true
      dict_vars_current.table_cols = treeish.children.at(0).children.at(0).children.len()
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
      "pre": it => block(breakable: true, it),
      "div": it => block(breakable: true, it),
      "br": it => linebreak(),
      "hr": it => block(width: 100%, height: 0.5pt, fill: black),
      "table": it => table(
        columns: dict_vars_current.table_cols * (auto + 1fr,),
        inset: 5pt,
        align: left,
        // it is likely ((cell, cell), (cell, cell)), flatten it to (cell, cell, cell, cell)
        ..if type(it) == array { it.flatten() } else { it } // error: cannot spread content. Why? (Line 453)
      ),
      "thead": it => it,
      "tbody": it => it,
      "tr": it => it,
      "th": it => table.cell(fill: gray.lighten(100%), strong(it)),
      "td": it => table.cell(it),
    )
    let container_func = containers_table.at(treeish.tag, default: it => it)

    let impls_table = (
      "pre": it => raw(block: true, lang: treeish.attrs.at("lang", default: none), __get-text(it)),
      "code": it => raw(block: false, lang: treeish.attrs.at("lang", default: none), __get-text(it)),
    )
    let impl_func = impls_table.at(treeish.tag, default: it => it)

    let tagname_stack_current = (..tagname_stack_context, treeish.tag)


    let process_child(child) = {
      if type(child) == str {
        // Only collapse whitespace if we are NOT inside a 'pre' tag
        if not tagname_stack_current.contains("pre") {
          return child
            .replace("\n", " ")
            .replace(regex("\s+"), " ")
            .replace(regex("/th>[\n\s]*<"), "/th><")
            .replace(regex("/td>[\n\s]*<"), "/td><")
        }
        return child
      } else {
        return walk_tree(child, tagname_stack_current, dict_vars_current)
      }
    }


    // If it's a table-related container, don't join into a string;
    // keep as an array to allow the 'table' tag to spread them.
    let is_table_component = ("table", "thead", "tbody", "tr").contains(treeish.tag)
    let processed_children = treeish.children.filter(it => it != "\n " and it != "\n").map(process_child)
    if not is_table_component {
      processed_children = __sequence_shake(processed_children)
    }

    let dom_task = if is_table_component {
      processed_children
    } else {
      impl_func(processed_children.join(""))
    }

    let attrs_style = treeish.attrs.at("style", default: none)

    // ... inside walk_tree ...

    // 1. Identify the style
    let parsed_style_dict = if attrs_style != none { __parse_css_kv(attrs_style) } else { none }

    // 2. Resolve the task
    // Only apply __nodestyler if it's NOT a table component that needs to remain an array
    let final_task = if is_table_component {
      dom_task
    } else if parsed_style_dict == none {
      dom_task
    } else {
      __nodestyler(dom_task, parsed_style_dict, treeish.tag, treeish.attrs, tagname_stack_current, treeish)
    }

    // 3. Call the container function
    // If the tag is 'table', we handle the array spreading safely
    if treeish.tag == "table" {
      return table(
        columns: dict_vars_current.table_cols * (auto,),
        inset: 5pt,
        align: left,
        ..final_task.flatten() // Now guaranteed to be an array
      )
    }

    return container_func(final_task)
  }
  set par(spacing: 0mm)
  (walk_tree(ast_tree.at(0), (), (:)))
  if debug {
    pagebreak()
    raw(repr(ast_tree))
    pagebreak()
    raw(repr(walk_tree(ast_tree.at(0), (), (:))))
  }
}



