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

Transclusion is still a woefully underrepresented feature in
World-Wide Web standards. Indeed there are many proprietary solutions
on both the server and the client side, but none that enable the
seamless welding of resources together, thus enabling their re-use.

While the now-defunct [XHTML2](https://www.w3.org/TR/xhtml2/) standard
featured transclusion everywhere, HTML5 is considerably more
apprehensive. Aside from a provisional `<iframe seamless>` which was
eventually removed, the specification is silent on the subject.

## Targets

* Design patterns in XSLT 1.0 for performing reliable transclusions
  within the scope of a given website,
* XSLT 1.0 library encapsulating those patterns which can be encapsulated,
* Design patterns in (X)HTML5 conducive to straightforward,
  uncomplicated transclusion and content reuse.

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

```xml
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

In the case of HTML, however, we invariably have to do surgery to the
transcluded document in order to obtain a conforming result. Namely,
in all residual cases, we need to select the children of `<body>`. In
so doing, we have to consider the context into which these elements
are being transcluded. The content models of certain elements prohibit
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

```xml
<!-- in referring document -->
<article>
  <script type="application/xhtml+xml" src="/content"/>
</article>

<!-- in transcluded document -->
<body>
  <p>lol hi i got transcluded</p>
  <p>isn't life grand?</p>
</body>
```

This would replace the `<script>` with everything under the `<body>`
of the transcluded document, directly under `<article>` in the
transcluding document:

```xml
<article>
  <p>lol hi i got transcluded</p>
  <p>isn't life grand?</p>
</article>
```

To summarize:

* _Either_ the `<body>` (or `<main>`) of the transcluded document is
  replaced by a suitable element in the referring document,
  * (The replacement element _could_ be the parent of the special
    `<script>` element _if_ the latter had no siblings other than
    whitespace)
* _Or_ the transclusion content _is_ itself a single element.

### Single-Element Documents

When the `<body>` (or when present, `<main>`) of the transcluded HTML
document only possesses a single child element (and no non-whitespace
text nodes as children), and, assuming the parent of the transclusion
reference admits it, that single child element can directly replace
the transcluding element with no additional negotiation. Indeed, this
condition should supersede the behaviour described in the previous
section.

### Other Vagaries of HTML 5

The introduction of the various sectioning elements in HTML5, in
particular `<main>`, `<article>`, and `<section>`, has complicated the
transclusion task.

For instance, it would be inappropriate to transclude the part of a
document above `<main>`, especially if the referring document had a
`<main>` of its own (`<main>` cannot appear under another `<main>`,
and there can only be one `<main>` that is not `hidden`). Therefore,
when present, transclusion should begin beneath the first visible
`<main>` element in the transcluded document. This will also make it
easier for transcluded resources to do double duty as standalone
documents.

The presence of `<article>`, irrespective of the presence of `<main>`,
is intended to denote a discrete body of text. It is not clear at this
time what the best policy is for transcluding around `<article>` tags.

Finally, the `<section>` element provides a more elegant method than
the general-purpose `<div>` for constructing document hierarchies,
which can be given special consideration in the following section.

### Heading levels

A common pattern is to put an `<h?>` (where `?` is the number `1`
through `6`) as the first child of a `<section>` element, containing
the title of the section. (There was briefly a recursive `<h>` tag in
the spec, but it was removed). When transcluding `<section>` content,
it would be useful to automatically commute the `<title>` of the
transcluded document to an `<h?>` tag, notwithstanding there already
being one present as the first child of the element to be transcluded.

Whether we generate a heading or use an existing one, we will need to
recalculate the appropriate heading level for it, as well as all
_descendant_ `<h?>` tags. This heading level must be propagated
through subsequent templates until it stops at `6`, the smallest
heading size.

### Recursion

A cycle in the transclusion path is bound to produce an infinite
recursion. Cycles can be detected through the use of a state
mechanism. The parameter `$resource-path` is a space-separated list of
URIs handed down through the templates. The efficacy of this mechanism
depends on the `<base href="..."/>` element to exactly match the
Request-URI of the transcluded document, or at the very least, a URI
where the transcluded document can be accessed. It is up to the
implementor to make sure this condition remains satisfied.

> (Note that XSLT 1.0 has no mechanism for gleaning the Request-URI of
> the document it is currently processing. If the `<base>` URI of the
> transcluded document is different from the URI in the transcluding
> element, we can simply append it to the `$resource-path`. I was
> originally planning on using the path length of `$resource-path` to
> compute the heading level, but it seems now like it would be more
> prudent to separate these concerns.)

Template authors will have to manually propagate the `$resource-path`
parameter through their work. Moreover, resource authors will have to
take into account the potential for acyclical, yet unsustainably long
transclusion paths. Parametric resources (i.e., those which can vary
by URI query parameters) may also fall into this category.

### Links, Fragments, and IDs

Links to transcluded documents should be rewritten into fragments of
the topmost document. This will entail coming up with both a way to
prefetch the transcluded documents, and a method of generating
identifiers which match the
[NCName](https://www.w3.org/TR/xml-names/#NT-NCName) grammar _and_ are
guaranteed to be unique at the level of the site. (Browser
implementations have historically not permitted XSLT 1.0
requests—including subrequests—to cross origins; this may be different
now with [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).)

> See [`uuid-ncname`](https://www.rubydoc.info/gems/uuid-ncname) for a
> candidate. For now we will assume that all `id` attributes are
> unique across the entire site.

Transclusion references to URI fragments should select the element
bearing the `id` that matches the fragment (the content after the
`#`). This mode of operation should supersede all other behaviour
described above, unless there is no such `id`, in which case the
template should behave as normal (but perhaps signal a warning).

## Procedure

The following parameters must be present in every template:

* `$base`, which is the normalized content of `<base href="..."/>`.
* `$resource-path`, which is a space-separated list of URIs that gets
  added to with every transclusion, beginning with `$base`.
* `$rewrite`, another space-separated list of URIs similar to
  `$resource-path`, though collected all at once. Represents the set
  of (transcluded) URIs to be rewritten into fragment identifiers, and
  should therefore _not_ contain `$base`.
* `$main`, a flag indicating the current node in the result tree is
  beneath a `<main>` element.
* `$heading`, a non-negative integer, denoting the adjustment to the
  heading level.
  
Now for the main procedure:

* Set `$base` to `normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)`.
* Set `$resource-path` to the same value as `$base`.
* Set `$rewrite` to the list of all URIs to be transcluded.
* set `$main` to `boolean(ancestor-or-self::html:main)`.
* Set the initial heading (`$heading`) level to **0**.
* Traverse the document as normal, ensuring the aforementioned
  parameters are conveyed through each template:
  * If the processor encounters a `<section>`, increment `$heading`.
  * If the processor encounters an `<h1>` through `<h6>` element,
    extract the integer from the element name and increment it by
    `$heading` (clipping at **6**), then use the resulting number to
    generate a new heading element.
  * If the processor encounters an `<a>` or `<area>`, rewrite `href`.
  * If the processor encounters a `<script>` (or other designated
    element) with an `src` attribute and a `type` attribute containing
    the string `xml`, perform the transclusion process.

### Transclusion Process

In addition to the parameters already described, transclusion will also need:

* `$uri` which is the content of e.g. the `src` attribute of the
  appropriate `<script>` element, turned into an absolute URI.
* `$caller` which is the element in the referring document which
  contains the `src` attribute we followed.

> No-ops may optionally issue warnings. It would be useful to create a
> mechanism such that users of the library can override the no-op
> behaviour.

* Resolve the assumed-to-be relative URI in the `src` attribute.
* Separate the fragment if it exists.
* If the document (i.e. sans-fragment) URI is contained in
  `$resource-path`, treat this element as a no-op.
* Add the document URI to `$resource-path`.
* Dereference the document URI using `document()`.
* If the dereference fails to produce an element tree, this is a no-op
* Set `$base` to the content of `<base href="..."/>`.
* If the `$base` of the newly-dereferenced document is different from
  the document URI, check it against `$resource-path`, bailing out
  once again with a no-op if there is a match.
  * Otherwise, add the new `$base` to `$resource-path`.
* If `$uri` has a fragment, locate the element with the matching `id`.
  * If an element is found, continue as if this is a single-element document.
  * If no such element is found, continue as if `$uri` had no fragment.
* If the document has a `<main>` element, select it as our new root.
  * Otherwise, select `<body>`.
* We generate an enclosing element if and only if:
  * there are multiple child nodes under the new root **AND**
  * `$caller` has sibling nodes other than whitespace/comments/PIs **OR**
* Determine what the new enclosing element will be (or whether there
  will be one):
  * If the new root has multiple 
* If `$caller` has a parent element
* If `$caller`'s parent element is a `<section>`:
  * If there is no existing header element immediately under the root,
  generate an `<h?>` (1 + `$heading`) element and populate it with the
  contents of `<title>`.


**TODO**

### Rewriting `href`

**TODO**

* The first URI in `$resource-path` is always the topmost document.

## Contributing

Bug reports and pull requests are welcome at
[the GitHub repository](https://github.com/doriantaylor/xslt-transclusion).

## Copyright & License

©2018 [Dorian Taylor](https://doriantaylor.com/)

This software is provided under
the [Apache License, 2.0](https://www.apache.org/licenses/LICENSE-2.0).

The file [xsltsl.xsl](xsltsl.xsl) contains some (modified)
code from [XSLTSL](http://xsltsl.sourceforge.net/). Since it is a
derivative work, this code is licensed under the
[LGPL](https://www.gnu.org/copyleft/lesser.html), in compliance with
the original.
