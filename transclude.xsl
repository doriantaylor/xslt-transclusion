<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:str="http://xsltsl.org/string"
    xmlns:uri="http://xsltsl.org/uri"
    xmlns:xc="https://makethingsmakesense.com/asset/transclude#"
    exclude-result-prefixes="html str uri xc">

<!-- XXX just embed this eventually -->
<xsl:import href="xsltsl-extension.xsl"/>

<xsl:output method="xml" media-type="application/xhtml+xml" indent="yes"/>

<xsl:key name="xc:id" match="*[normalize-space(@id) != '']" use="normalize-space(@id)"/>
<xsl:key name="xc:blocks" match="html:body|html:main[not(@hidden)]|html:article[not(ancestor::html:main[@hidden])]" use="''"/>
<xsl:key name="xc:references" match="html:*[@src][contains(translate(@type, 'XML',  'xml'), 'xml')]" use="''"/>

<!-- these are cribbed from rdfa.xsl -->
<xsl:variable name="xc:RECORD-SEP" select="'&#xf11e;'"/>
<xsl:variable name="xc:UNIT-SEP"   select="'&#xf11f;'"/>

<xsl:template match="html:*" mode="xc:get-rewrites">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="references" select="key('xc:references', '')"/>
  <xsl:param name="result" select="''"/>
  <!-- note the only way to do this in one template is to go depth first -->
  <xsl:choose>
    <xsl:when test="count($references)">
    <!-- resolve the uri of the first reference -->
    <xsl:variable name="src">
      <xsl:call-template name="uri:resolve-uri">
        <xsl:with-param name="uri" select="$references[1]/@src"/>
        <xsl:with-param name="base" select="$base"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- if the new uri is not present in the list then dereference it -->


    <!-- run this template recursively over the root of the
         dereferenced document and capture its output -->
    <xsl:variable name="new-result">
      <xsl:apply-templates select="document($src)/*" mode="xc:get-rewrites">
        <xsl:with-param name="result" select="concat($result, ' ', $src)"/>
      </xsl:apply-templates>
    </xsl:variable>

    <!-- now we move to the next reference in this document-->
    <!-- this is just an optimization to keep from recursing unnecessarily -->
    <xsl:if test="count($references) &gt; 1">
      <xsl:apply-templates select="." mode="xc:get-rewrites">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="references" select="$references[position() &gt; 1]"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$result"/>
  </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<!-- this performs the transclusion -->

<xsl:template match="html:script[@src][contains(translate(@type, 'XML', 'xml'), 'xml')]">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:variable name="src">
    <xsl:call-template name="uri:resolve-uri">
      <xsl:with-param name="uri" select="@src"/>
      <xsl:with-param name="base" select="$base"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="document">
    <xsl:choose>
      <xsl:when test="contains($src, '#')">
        <xsl:value-of select="substring-before($src, '#')"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$src"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="contains(concat(' ', $resource-path, ' '), concat(' ', $document, ' '))">
      <xsl:comment>Cycle detected in transclusion path and halted.</xsl:comment>
      <xsl:call-template name="xc:html-no-op">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message><xsl:value-of select="$document"/></xsl:message>
      <xsl:apply-templates select="document($document)/*" mode="xc:transclude">
        <xsl:with-param name="resource-path" select="concat($resource-path, ' ', $document)"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
        <xsl:with-param name="uri"    select="$src"/>
        <xsl:with-param name="caller" select="."/>
      </xsl:apply-templates>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template match="html:*" mode="xc:transclude">
  <!-- $base is a variable, not a param, to prevent accidental contamination -->
  <xsl:param name="resource-path"/>
  <xsl:param name="rewrite"       select="''"/>
  <xsl:param name="main"          select="false()"/>
  <xsl:param name="heading"       select="0"/>
  <xsl:param name="uri" select="''"/>
  <xsl:param name="caller" select="/.."/>

  <xsl:variable name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>


  <xsl:if test="normalize-space($uri) = ''">
    <xsl:message terminate="yes">URI must be explicitly defined in transclusions.</xsl:message>
  </xsl:if>

  <xsl:if test="normalize-space($resource-path) = ''">
    <xsl:message terminate="yes">Resource path must be explicitly defined in transclusions.</xsl:message>
  </xsl:if>

  <xsl:if test="not($caller)">
    <xsl:message terminate="yes">Transclude invoked without caller node</xsl:message>
  </xsl:if>

  <xsl:variable name="parent" select="$caller/parent::*"/>
  <xsl:variable name="solo"   select="count($parent/*) = 1"/>
  <xsl:variable name="fragment" select="substring-after($uri, '#')"/>

  <xsl:message><xsl:value-of select="key('xc:id', $fragment)"/></xsl:message>



  <xsl:variable name="to-transclude" select="((key('xc:blocks', '')[self::html:body|self::html:main][last()])[1]|key('xc:id', $fragment))[last()]"/>

  <xsl:choose>
    <xsl:when test="count($parent/*) = 1">
      <!-- we unconditionally replace the parent node because it's been skipped -->
      <xsl:element name="{name($parent)}" namespace="{namespace-uri($parent)}">
        <xsl:for-each select="@*">
          <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
        </xsl:for-each>

        <xsl:variable name="title" select="/html:html/html:head/html:title[normalize-space(.) != '']"/>

        <xsl:if test="$parent[self::html:section] and $title">
          <xsl:element name="h{1 + $heading}" namespace="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates select="$title/node()"/>
          </xsl:element>
        </xsl:if>

        <!-- this does not need a wrapper element -->
        <xsl:apply-templates select="$to-transclude/*|$to-transclude/text()[normalize-space(.) != '']">
          <xsl:with-param name="base"          select="$base"/>
          <xsl:with-param name="resource-path" select="$resource-path"/>
          <xsl:with-param name="rewrite"       select="$rewrite"/>
          <xsl:with-param name="main"          select="$main"/>
          <xsl:with-param name="heading"       select="$heading"/>
        </xsl:apply-templates>
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>

      <!-- this might need a wrapper element if there are multiple nodes -->

      <xsl:apply-templates select="$to-transclude/*|$to-transclude/text()[normalize-space(.) != '']">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template match="*" mode="xc:transclude">
  <xsl:param name="base" select="normalize-space(ancestor-or-self::*[@xml:base][1]/@xml:base)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite"       select="''"/>
  <xsl:param name="main"          select="false()"/>
  <xsl:param name="heading"       select="0"/>

  <xsl:message>huh</xsl:message>

  <xsl:apply-templates select=".">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<!--
    match any html element that contains a single script src as an
    only child.
-->

<xsl:template match="html:*[not(self::html:script)][html:script[@src][contains(@type, 'xml')]][count(*) = 1][normalize-space(text()) = '']">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>


</xsl:template>

<!--
    special case for sections, where we want the title to drop in as
    a heading.
-->

<xsl:template match="html:section[not(self::html:script)][html:script[@src][contains(translate(@type, 'XML', 'xml'), 'xml')]][count(*) = 1][normalize-space(text()) = '']">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:apply-templates select="html:script">
    <xsl:with-param name="base" select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading + 1"/>
  </xsl:apply-templates>

</xsl:template>

<!-- special case for main element -->

<xsl:template match="html:main">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:if test="$main">
    <xsl:comment>we already have a main element</xsl:comment>
  </xsl:if>

  <main>
    <xsl:for-each select="@*">
      <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>
    <xsl:apply-templates>
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="true()"/>
      <xsl:with-param name="heading"       select="$heading"/>
    </xsl:apply-templates>
  </main>
</xsl:template>

<!-- special case for section element -->

<xsl:template match="html:section">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <section>
    <xsl:for-each select="@*">
      <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>
    <xsl:apply-templates>
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading + 1"/>
    </xsl:apply-templates>
  </section>
</xsl:template>

<!-- fix h1 through h6 -->

<xsl:template match="html:h1|html:h2|html:h3|html:h4|html:h5|html:h6" name="xc:heading">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:variable name="rank" select="number(substring-after(local-name(), 'h'))"/>

  <!-- okay this is clever -->
  <xsl:variable name="initial" select="number(not(not(ancestor::html:main))) * count(ancestor::html:section[ancestor::html:main]) + number(not(ancestor::html:main)) * count(ancestor::html:section)"/>

  <xsl:variable name="element">
    <xsl:variable name="_" select="$rank - $initial + $heading"/>
    <xsl:choose>
      <xsl:when test="$_ &lt; 1">h1</xsl:when>
      <xsl:when test="$_ &gt; 6">h6</xsl:when>
      <xsl:otherwise><xsl:value-of select="concat('h', $_)"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:element name="{$element}">
    <xsl:for-each select="@*">
      <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>
    <xsl:apply-templates>
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading + 1"/>
    </xsl:apply-templates>
  </xsl:element>
</xsl:template>

<!-- catch-all template for propagating state variables -->

<xsl:template match="html:*" name="xc:html-no-op">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="element" select="name()"/>

  <xsl:element name="{$element}">
    <xsl:for-each select="@*">
      <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>
    <xsl:apply-templates>
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading"/>
    </xsl:apply-templates>
  </xsl:element>
</xsl:template>

<!-- all non-html -->

<xsl:template match="*">
  <xsl:param name="base" select="normalize-space(ancestor-or-self::*[@xml:base][1]/@xml:base)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite"       select="''"/>
  <xsl:param name="main"          select="false()"/>
  <xsl:param name="heading"       select="0"/>

  <xsl:element name="{name()}" namespace="{namespace-uri()}">
    <xsl:for-each select="@*">
      <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>
    <xsl:apply-templates>
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading"/>
    </xsl:apply-templates>
  </xsl:element>
</xsl:template>

</xsl:stylesheet>
