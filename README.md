# Standard-Compliant Transclusion Protocol

This is an attempt to systematize a method of
[transclusion](https://en.wikipedia.org/wiki/Transclusion) using only
declarative Web standards, namely
[(X)HTML5](https://www.w3.org/TR/html5/) and [XSLT
1.0](https://www.w3.org/TR/1999/REC-xslt-19991116).

Web browsers have implemented the XSLT 1.0 specification for nearly
two decades. This functionality continues to be supported, and is
perfectly adequate, if not _ideal_, for performing straightforward
markup manipulation tasks.

## Rationale

Transclusion is still a woefully underrepresented feature of the
World-Wide Web standards. Indeed there are many proprietary solutions
on both the server and the client side, but none that enable the
seamless welding of resources together, thus enabling their re-use.

While the now-defunct [XHTML2](https://www.w3.org/TR/xhtml2/) standard
featured transclusion everywhere, HTML5 is considerably more
apprehensive. Aside from a provisional `<iframe seamless>` which was
eventually removed, the specification is silent on the subject.

## Desiderata

For a transclusion reference, we want an element which is legal
anywhere under `<body>`, and already exhibits hypermedia semantics.
Here are the candidates:

### `<iframe>`

The most sensible initial choice, however `<iframe>` already _has_ a
meaning: make a new browser window inside a rectangle and put the
document in it. Make it a sandbox. Do not integrate the embedded
document into its caller; do not apply style rules. The proposed
`seamless` attribute, which was intended to do this, has vanished.
`<iframe>` is for banner ads.

### `<object>`

Also theoretically sensible, but sets off alarm bells for security
plugins. `<object>` is treated even more suspect than `<iframe>`
is. Moreover, the hypermedia reference attribute is `data`, which is
invisible to [RDFa](https://www.w3.org/TR/rdfa-core/).

### `<embed>`

The `<embed>` tag was deprecated in HTML 4.

### `<script>`

The current climate of HTML is very clement to `<script>`. It can go
pretty much anywhere and contain pretty much anything. If we give it
certain attributes, we can make a pretty unambiguous statement:

```html
<script type="application/xhtml+xml" src="transcluded.xhtml"/>
```

This declaration is effectively meaningless to an unadorned browser
context. If we want, we can include the `defer` attribute to further
signal the inertness of the declaration, though in practice it does
not seem to make much of a difference. The only side effect is that
the URI in the `src` attribute seems to get unconditionally
dereferenced, but this is fine considering we're planning on using it
anyway.

### General Pattern

Indeed, one could activate the transclusion process for any of these
elements, and others like `img`, as it is the `type` attribute that
signals that the referent in `src` is amenable to transclusion.

There is, for example, benefit in transcluding SVG images which are
connected via the `<img>` tag. When referenced this way, SVG content
is flattened and stripped of both its interactive content, as well as
callouts to external CSS resources. Invoking `<img
type="image/svg+xml" src="..."/>` would plop the image markup directly
into the host document and circuvment that behaviour.

## Transcluded Documents

The transcluded documents themselves are ordinary (X)HTML5 documents,
or potentially other XML (SVG, MathML, Atom) vocabularies. The default
behaviour (e.g. SVG, MathML) will be to drop the document directly
into the spot from which it was referred, replacing the referring
element.

In the case of HTML, however, we invariantly have to do surgery to the
transcluded document in order to obtain a valid result. Namely, in all
residual cases, we need to select the children of `<body>`. In so
doing, we have to consider the context into which these elements are
being transcluded. The content models of certain elements prohibit
certain descendants. In general we can leave this problem to the
implementor, but in many cases we will still need to derive whether
the containing element is _block_ or _inline_, and likewise the
transcluded content. At that point we can determine whether we should
wrap the transcluded content in a `<div>`, or in a `<span>`, which
would be sensible defaults.

### Tighter Integration

In the case that the transcluding element is the sole descendant of
another element, then wrapping the transcluded content in a `<div>` or
`<span>` will be redundant. Rather, the transcluded markup can be
placed directly under the transcluding element's parent.

```html
<article>
  <script type="application/xhtml+xml" src="/content"/>
</article>
```

This would replace the `<script>` with everything under the `<body>`
of the transcluded document, directly under `<article>` in the
transcluding document.

### Other Vagaries of HTML 5

The introduction of the various sectioning elements in HTML5, in
particular `<main>`, `<article>`, and `<section>`, has complicated the
transclusion task.

For instance, it would be inappropriate to transclude the part of a
document above `<main>`, especially if the referring document had a
`<main>` of its own (`<main>` cannot appear under another `<main>`,
and there can only be one `<main>` that is not `hidden`).

The presence of `<article>`, irrespective of the presence of `<main>`,
is intended to denote a discrete body of text.

### Heading levels

### Recursion

Without some form of guard or state mechanism, the presence of cycles
in the transclusion graph will be susceptible to infinite recursion.

The best state mechanism we can hope for in XSLT 1.0 is a
space-separated list of URIs. The idiom for matching elements is:

```xpath
contains(concat(' ', normalize-space($haystack), ' '), concat(' ', normalize-space($needle), ' '))
```

### Links, Fragments, and IDs

## Procedure

## Contributing

Bug reports and pull requests are welcome at
[the GitHub repository](https://github.com/doriantaylor/xslt-transclusion).

## Copyright & License

©2018 [Dorian Taylor](https://doriantaylor.com/)

This software is provided under
the [Apache License, 2.0](https://www.apache.org/licenses/LICENSE-2.0).

The file [xsltsl.xsl](blob/master/xsltsl.xsl) contains some (modified)
code from [XSLTSL](http://xsltsl.sourceforge.net/). Since it is a
derivative work, this code is licensed under the
[LGPL](https://www.gnu.org/copyleft/lesser.html), in compliance with
the original.
