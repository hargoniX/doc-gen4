/-
Copyright (c) 2021 Henrik Böving. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Henrik Böving
-/
import DocGen4.ToHtmlFormat
import DocGen4.Output.Navbar

namespace DocGen4
namespace Output

open scoped DocGen4.Jsx

def baseHtml (title : String) (site : Html) : HtmlM Html := do
  <html lang="en">
    <head>
      <link rel="stylesheet" href={s!"{←getRoot}style.css"}/>
      <link rel="stylesheet" href={s!"{←getRoot}pygments.css"}/>
      <link rel="shortcut icon" href={s!"{←getRoot}favicon.ico"}/>
      <title>{title}</title>
      <meta charset="UTF-8"/>
      <meta name="viewport" content="width=device-width, initial-scale=1"/>
    </head>
    
    <body>

    <input id="nav_toggle" type="checkbox"/>

    <header>
      <h1><label «for»="nav_toggle"></label>Documentation</h1>
      <p «class»="header_filename break_within">{title}</p>
      -- TODO: Replace this form with our own search
      <form action="https://google.com/search" method="get" id="search_form">
        <input type="hidden" name="sitesearch" value="https://leanprover-community.github.io/mathlib_docs"/>
        <input type="text" name="q" autocomplete="off"/>
        <button>Google site search</button>
      </form>
    </header>

    <nav «class»="internal_nav"></nav>

    {site}
    
    {←navbar}

    -- Lean in JS in HTML in Lean...very meta
    <script>
      siteRoot = "{←getRoot}";
    </script>

    -- TODO Add more js stuff
    <script src={s!"{←getRoot}nav.js"}></script>
    </body>
  </html>

end Output
end DocGen4
