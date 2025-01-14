/-
Copyright (c) 2021 Wojciech Nawrocki. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.

Authors: Wojciech Nawrocki, Sebastian Ullrich, Henrik Böving
-/
import Lean.Data.Json
import Lean.Parser

/-! This module defines:
- a representation of HTML trees
- together with a JSX-like DSL for writing them
- and widget support for visualizing any type as HTML. -/

namespace DocGen4

open Lean

inductive Html where
  -- TODO(WN): it's nameless for shorter JSON; re-add names when we have deriving strategies for From/ToJson
  -- element (tag : String) (flatten : Bool) (attrs : Array HtmlAttribute) (children : Array Html)
  | element : String → Bool → Array (String × String) → Array Html → Html
  | text : String → Html
  deriving Repr, BEq, Inhabited, FromJson, ToJson

instance : Coe String Html :=
  ⟨Html.text⟩

namespace Html

def attributesToString (attrs : Array (String × String)) :String :=
  attrs.foldl (λ acc (k, v) => acc ++ " " ++ k ++ "=\"" ++ v ++ "\"") ""

-- TODO: Termination proof
partial def toStringAux : Html → String
| element tag false attrs #[text s] => s!"<{tag}{attributesToString attrs}>{s}</{tag}>\n"
| element tag false attrs #[child] => s!"<{tag}{attributesToString attrs}>\n{child.toStringAux}</{tag}>\n"
| element tag false attrs children => s!"<{tag}{attributesToString attrs}>\n{children.foldl (· ++ toStringAux ·) ""}</{tag}>\n"
| element tag true attrs children => s!"<{tag}{attributesToString attrs}>{children.foldl (· ++ toStringAux ·) ""}</{tag}>"
| text s => s

def toString (html : Html) : String :=
  html.toStringAux.trimRight

instance : ToString Html :=
  ⟨toString⟩

end Html

namespace Jsx
open Parser PrettyPrinter

declare_syntax_cat jsxElement
declare_syntax_cat jsxChild

def jsxAttrVal : Parser := strLit <|> group ("{" >> termParser >> "}")
def jsxAttr : Parser := ident >> "=" >> jsxAttrVal

-- JSXTextCharacter : SourceCharacter but not one of {, <, > or }
def jsxText : Parser :=
  withAntiquot (mkAntiquot "jsxText" `jsxText) {
    fn := fun c s =>
      let startPos := s.pos
      let s := takeWhile1Fn (not ∘ "[{<>}]$".contains) "expected JSX text" c s
      mkNodeToken `jsxText startPos c s }

@[combinatorFormatter DocGen4.Jsx.jsxText] def jsxText.formatter : Formatter := pure ()
@[combinatorParenthesizer DocGen4.Jsx.jsxText] def jsxText.parenthesizer : Parenthesizer := pure ()

scoped syntax "<" ident jsxAttr* "/>" : jsxElement
scoped syntax "<" ident jsxAttr* ">" jsxChild* "</" ident ">" : jsxElement

scoped syntax jsxText      : jsxChild
scoped syntax "{" term "}" : jsxChild
scoped syntax "[" term "]" : jsxChild
scoped syntax jsxElement   : jsxChild

scoped syntax:max jsxElement : term

macro_rules
  | `(<$n $[$ns = $vs]* />) =>
    let ns := ns.map (quote <| toString ·.getId)
    let vs := vs.map fun
      | `(jsxAttrVal| $s:strLit) => s
      | `(jsxAttrVal| { $t:term }) => t
      | _ => unreachable!
    `(Html.element $(quote <| toString n.getId) false #[ $[($ns, $vs)],* ] #[])
  | `(<$n $[$ns = $vs]* >$cs*</$m>) =>
    if n.getId == m.getId then do
      let ns := ns.map (quote <| toString ·.getId)
      let vs := vs.map fun
        | `(jsxAttrVal| $s:strLit) => s
        | `(jsxAttrVal| { $t:term }) => t
        | _ => unreachable!
      let cs ← cs.mapM fun
        | `(jsxChild|$t:jsxText)    => `(#[Html.text $(quote t[0].getAtomVal!)])
        -- TODO(WN): elab as list of children if type is `t Html` where `Foldable t`
        | `(jsxChild|{$t})          => `(#[$t])
        | `(jsxChild|[$t])          => `($t)
        | `(jsxChild|$e:jsxElement) => `(#[$e:jsxElement])
        | _                         => unreachable!
      let tag := toString n.getId
      `(Html.element $(quote tag) false #[ $[($ns, $vs)],* ] (Array.foldl Array.append #[] #[ $[$cs],* ]))
    else Macro.throwError ("expected </" ++ toString n.getId ++ ">")

end Jsx

/-- A type which implements `ToHtmlFormat` will be visualized
as the resulting HTML in editors which support it. -/
class ToHtmlFormat (α : Type u) where
  formatHtml : α → Html

end DocGen4
