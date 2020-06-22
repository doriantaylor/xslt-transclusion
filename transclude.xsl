<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:str="http://xsltsl.org/string"
    xmlns:uri="http://xsltsl.org/uri"
    xmlns:xc="https://makethingsmakesense.com/asset/transclude#"
    exclude-result-prefixes="html str uri rdf xlink xc">

<!-- 
     Make sure you import xsltsl/uri.xsl and xsltsl/string.xsl before
     importing this.
-->

<xsl:output method="xml" media-type="application/xhtml+xml" indent="yes"/>

<xsl:key name="xc:id" match="*[normalize-space(@id) != '']" use="normalize-space(@id)"/>
<xsl:key name="xc:blocks" match="/*[namespace-uri() != 'http://www.w3.org/1999/xhtml']|html:body|html:main[not(@hidden)]|html:article[not(ancestor::html:main[@hidden])]" use="''"/>
<xsl:key name="xc:references" match="html:*[@src][contains(translate(@type, 'XML',  'xml'), 'xml')]" use="''"/>
<xsl:key name="xc:main" match="html:main[not(@hidden)]" use="''"/>
<xsl:key name="xc:head-script" match="html:head/html:script" use="''"/>
<xsl:key name="xc:head-style"  match="html:head/html:style" use="''"/>
<xsl:key name="xc:head-link"   match="html:head/html:link" use="''"/>

<!-- these are cribbed from rdfa.xsl -->
<xsl:variable name="xc:RECORD-SEP" select="'&#xf11e;'"/>
<xsl:variable name="xc:UNIT-SEP"   select="'&#xf11f;'"/>

<xsl:variable name="xc:DEBUG" select="false()"/>

<!--
    these elements have block content models (or 'flow content' as it
    is now called): body article section nav aside header footer address
    blockquote li dt dd figure figcaption main div ins del caption td
    th form fieldset template
-->
<xc:elements>
  <xc:block name="body"/>
  <xc:block name="article"/>
  <xc:block name="section"/>
  <xc:block name="nav"/>
  <xc:block name="aside"/>
  <xc:block name="header"/>
  <xc:block name="footer"/>
  <xc:block name="address"/>
  <xc:block name="blockquote"/>
  <xc:block name="li"/>
  <xc:block name="dt"/>
  <xc:block name="dd"/>
  <xc:block name="figure"/>
  <xc:block name="figcaption"/>
  <xc:block name="main"/>
  <xc:block name="div"/>
  <xc:block name="caption"/>
  <xc:block name="td"/>
  <xc:block name="th"/>
  <xc:block name="form"/>
  <xc:block name="fieldset"/>
  <xc:block name="template"/>
</xc:elements>

<xsl:template match="*" mode="xc:get-base">
  <xsl:value-of select="normalize-space(ancestor-or-self::*[@xml:base][1]/@xml:base)"/>
</xsl:template>

<xsl:template match="html:*" mode="xc:get-base">
  <xsl:value-of select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
</xsl:template>

<xsl:template match="html:html">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite">
    <xsl:apply-templates select="." mode="xc:get-rewrites">
      <xsl:with-param name="base" select="$base"/>
    </xsl:apply-templates>
  </xsl:param>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="debug" select="$xc:DEBUG"/>

  <!--<xsl:message>root rewrites: <xsl:value-of select="$rewrite"/></xsl:message>-->

<html>
  <xsl:apply-templates select="@*" mode="xc:attribute">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
  </xsl:apply-templates>
  <xsl:apply-templates>
    <xsl:with-param name="base" select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</html>
</xsl:template>

<!-- rewrites are basically the resource path fetched all at once -->
<xsl:template match="html:*" mode="xc:get-rewrites">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="references" select="key('xc:references', '')"/>
  <xsl:param name="result" select="''"/>
  <xsl:param name="debug" select="$xc:DEBUG"/>
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

    <!--<xsl:message>refs: <xsl:value-of select="count($references)"/></xsl:message>-->

    <xsl:variable name="resource">
      <xsl:choose>
        <xsl:when test="contains($src, '#')">
          <xsl:value-of select="substring-before($src, '#')"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$src"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- if the new uri is not present in the list then dereference it -->

    <!-- run this template recursively over the root of the
         dereferenced document and capture its output -->
    <xsl:variable name="new-result">
      <xsl:variable name="_">
        <xsl:if test="not(contains(concat(' ', $result, ' '), concat(' ', $resource, ' ')))">
        <xsl:apply-templates select="document($resource)/*" mode="xc:get-rewrites">
          <xsl:with-param name="result" select="concat($result, ' ', $resource)"/>
        </xsl:apply-templates>
        </xsl:if>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="normalize-space($_)">
          <xsl:value-of select="$_"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="normalize-space(concat($result, ' ', $resource))"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- now we move to the next reference in this document-->
    <!-- this is just an optimization to keep from recursing unnecessarily -->
    <xsl:choose>
      <xsl:when test="count($references) &gt; 1">
        <xsl:apply-templates select="." mode="xc:get-rewrites">
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="references" select="$references[position() &gt; 1]"/>
          <xsl:with-param name="result" select="$new-result"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$new-result"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$result"/>
  </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template match="html:head" mode="xc:get-head-scripts" name="xc:get-head-scripts">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite">
    <xsl:apply-templates select="." mode="xc:get-rewrites">
      <xsl:with-param name="base" select="$base"/>
    </xsl:apply-templates>
  </xsl:param>


  <xsl:variable name="r" select="normalize-space($rewrite)"/>
  <xsl:choose>
    <xsl:when test="$r = ''"/>
    <xsl:when test="contains($r, ' ')">
      <xsl:variable name="head" select="substring-before($r, ' ')"/>
      <xsl:apply-templates select="document($head)/html:html/html:head/html:script"/>
      <xsl:call-template name="xc:get-head-scripts">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite" select="substring-after($r, ' ')"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="document($r)/html:html/html:head/html:script"/>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template match="html:*" mode="xc:get-head-styles" name="xc:get-head-styles">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite">
    <xsl:apply-templates select="." mode="xc:get-rewrites">
      <xsl:with-param name="base" select="$base"/>
    </xsl:apply-templates>
  </xsl:param>


  <xsl:variable name="r" select="normalize-space($rewrite)"/>
  <xsl:choose>
    <xsl:when test="$r = ''"/>
    <xsl:when test="contains($r, ' ')">
      <xsl:variable name="head" select="substring-before($r, ' ')"/>
      <xsl:apply-templates select="document($head)/html:html/html:head/html:style"/>
      <xsl:call-template name="xc:get-head-styles">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite" select="substring-after($r, ' ')"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="document($r)/html:html/html:head/html:style"/>
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
  <xsl:param name="debug"   select="$xc:DEBUG"/>

  <xsl:variable name="src">
    <xsl:call-template name="uri:resolve-uri">
      <xsl:with-param name="uri" select="@src"/>
      <xsl:with-param name="base" select="$base"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:apply-templates select="." mode="xc:transclude-element">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
    <xsl:with-param name="src"           select="$src"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="html:*" mode="xc:transclude-element">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="src">
    <xsl:message terminate="yes">must include $src</xsl:message>
  </xsl:param>
  <xsl:param name="debug"   select="$xc:DEBUG"/>

  <xsl:variable name="document">
    <xsl:choose>
      <xsl:when test="contains($src, '#')">
        <xsl:value-of select="substring-before($src, '#')"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$src"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:if test="$debug">
    <xsl:message>processing script tag with transclude: <xsl:value-of select="$src"/> (<xsl:value-of select="$resource-path"/>)</xsl:message>
  </xsl:if>

  <xsl:choose>
    <xsl:when test="contains(concat(' ', $resource-path, ' '), concat(' ', $document, ' '))">
      <xsl:comment>xc:transclude-element: Cycle detected in transclusion path and halted (<xsl:value-of select="$document"/>).</xsl:comment>
      <xsl:call-template name="xc:html-no-op">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
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

  <xsl:variable name="fragment" select="substring-after($uri, '#')"/>
  <xsl:variable name="document">
    <xsl:choose>
      <xsl:when test="contains($uri, '#')">
        <xsl:value-of select="substring-before($uri, '#')"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$uri"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="parent" select="$caller/parent::*"/>

  <xsl:variable name="to-transclude" select="((key('xc:blocks', '')[self::*[namespace-uri() != 'http://www.w3.org/1999/xhtml']|self::html:body|self::html:main][last()])[1]|key('xc:id', $fragment))[last()]"/>

  <xsl:choose>
    <xsl:when test="count($parent/*) = 1">
      <!-- we unconditionally replace the parent node because it's been skipped -->
      <xsl:element name="{name($parent)}" namespace="{namespace-uri($parent)}">
        <xsl:apply-templates select="$parent/@*" mode="xc:attribute">
          <xsl:with-param name="base"          select="$base"/>
          <xsl:with-param name="resource-path" select="$resource-path"/>
          <xsl:with-param name="rewrite"       select="$rewrite"/>
        </xsl:apply-templates>

        <xsl:choose>
          <xsl:when test="$document != $base and contains(concat(' ', $resource-path, ' '), concat(' ', $base, ' '))">
            <xsl:comment>Cycle detected in transclusion path and halted (<xsl:value-of select="$document"/>).</xsl:comment>
            <xsl:element name="{name($caller)}" namespace="{namespace-uri($caller)}">
              <xsl:apply-templates select="$caller/@*" mode="xc:attribute">
                <xsl:with-param name="base"          select="$base"/>
                <xsl:with-param name="resource-path" select="$resource-path"/>
                <xsl:with-param name="rewrite"       select="$rewrite"/>
              </xsl:apply-templates>

              <xsl:apply-templates select="$caller/node()">
                <xsl:with-param name="base"          select="$base"/>
                <xsl:with-param name="resource-path" select="$resource-path"/>
                <xsl:with-param name="rewrite"       select="$rewrite"/>
                <xsl:with-param name="main"          select="$main"/>
                <xsl:with-param name="heading"       select="$heading"/>
              </xsl:apply-templates>
            </xsl:element>
          </xsl:when>
          <xsl:otherwise>
            <!-- rdfa attributes -->
            <xsl:if test="not($parent/@id) and $to-transclude/@id">
              <xsl:attribute name="id">
                <xsl:value-of select="$to-transclude/@id"/>
              </xsl:attribute>
            </xsl:if>

            <xsl:apply-templates select="$to-transclude" mode="xc:head-js">
              <xsl:with-param name="base"          select="$base"/>
              <xsl:with-param name="resource-path" select="$resource-path"/>
              <xsl:with-param name="rewrite"       select="$rewrite"/>
              <xsl:with-param name="main"          select="$main"/>
              <xsl:with-param name="heading"       select="$heading"/>
            </xsl:apply-templates>

            <xsl:variable name="title" select="/html:html/html:head/html:title[normalize-space(.) != '']"/>

            <xsl:if test="$title and (local-name($parent) = 'section' or local-name($parent) = 'article') and string(number($heading)) != 'NaN'">
              <xsl:text>
</xsl:text>
<xsl:element name="h{1 + $heading}" namespace="http://www.w3.org/1999/xhtml">
  <xsl:apply-templates select="/html:html/html:head/html:title/@*" mode="xc:attribute">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
  </xsl:apply-templates>
  <xsl:value-of select="normalize-space($title)"/>
</xsl:element>
<xsl:text>
</xsl:text>
            </xsl:if>

            <xsl:variable name="h">
              <xsl:choose>
                <xsl:when test="string(number($heading)) = 'NaN'">
                  <xsl:value-of select="0"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$heading"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <!-- this never needs a wrapper element; $parent suffices -->
            <xsl:apply-templates select="$to-transclude" mode="xc:transclude-shim">
              <xsl:with-param name="base"          select="$base"/>
              <xsl:with-param name="resource-path" select="$resource-path"/>
              <xsl:with-param name="rewrite"       select="$rewrite"/>
              <xsl:with-param name="main"          select="$main"/>
              <xsl:with-param name="heading"       select="number($h)"/>
              <xsl:with-param name="uri"           select="$uri"/>
              <xsl:with-param name="caller"        select="$caller"/>
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <!-- i dunno if this is smart or dumb-->

      <xsl:apply-templates select="$to-transclude" mode="xc:head-js">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>

      <!-- this might need a wrapper element if there are multiple nodes -->

      <xsl:apply-templates select="$to-transclude" mode="xc:transclude-shim">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
        <xsl:with-param name="uri"           select="$uri"/>
        <xsl:with-param name="caller"        select="$caller"/>
      </xsl:apply-templates>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template match="html:*" mode="xc:head-js">
  <xsl:param name="base"/>
  <xsl:param name="resource-path"/>
  <xsl:param name="rewrite"/>
  <xsl:param name="main"/>
  <xsl:param name="heading"/>

  <xsl:apply-templates select="ancestor-or-self::*[html:head]/html:head/html:script">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<!-- this exists so we can put logic in here -->

<xsl:template match="*" mode="xc:transclude-shim">
  <xsl:param name="base"/>
  <xsl:param name="resource-path"/>
  <xsl:param name="rewrite"/>
  <xsl:param name="main"/>
  <xsl:param name="heading"/>
  <xsl:param name="uri"/>
  <xsl:param name="caller"/>

  <xsl:apply-templates select="." mode="xc:maybe-wrap">
    <xsl:with-param name="base"          select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
    <xsl:with-param name="uri"           select="$uri"/>
    <xsl:with-param name="caller"        select="$caller"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="*" mode="xc:maybe-wrap">
  <xsl:param name="base"/>
  <xsl:param name="resource-path"/>
  <xsl:param name="rewrite"/>
  <xsl:param name="main"/>
  <xsl:param name="heading"/>
  <xsl:param name="uri"/>
  <xsl:param name="caller"/>

  <xsl:variable name="fragment" select="substring-after($uri, '#')"/>
  <xsl:variable name="parent" select="$caller/parent::*"/>

  <xsl:choose>
    <xsl:when test="$fragment != '' and @id = $fragment">
      <!-- this node -->
      <xsl:apply-templates select=".">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:when test="count($parent/*) = 1 and count($parent/text()[normalize-space(.) != '']) = 0">
      <!-- singular caller node -->
      <xsl:apply-templates select="*|text()">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:when test="count(*) = 1 and count(text()[normalize-space(.) != '']) = 0">
      <!-- singular child node -->
      <xsl:apply-templates select="*[1]">
        <xsl:with-param name="base"          select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
        <xsl:with-param name="rewrite"       select="$rewrite"/>
        <xsl:with-param name="main"          select="$main"/>
        <xsl:with-param name="heading"       select="$heading"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <!-- wrap either div or span -->
      <xsl:variable name="element">
        <xsl:choose>
          <xsl:when test="document('')/xsl:stylesheet/xc:elements/xc:block[@name = local-name($parent)]">div</xsl:when>
          <xsl:otherwise>span</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:element name="{$element}" namespace="http://www.w3.org/1999/xhtml">
        <xsl:apply-templates select="*|text()">
          <xsl:with-param name="base"          select="$base"/>
          <xsl:with-param name="resource-path" select="$resource-path"/>
          <xsl:with-param name="rewrite"       select="$rewrite"/>
          <xsl:with-param name="main"          select="$main"/>
          <xsl:with-param name="heading"       select="$heading"/>
        </xsl:apply-templates>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="*" mode="xc:transclude">
  <xsl:param name="base" select="normalize-space(ancestor-or-self::*[@xml:base][1]/@xml:base)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite"       select="''"/>
  <xsl:param name="main"          select="false()"/>
  <xsl:param name="heading"       select="0"/>

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
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>

  <xsl:apply-templates select="html:script">
    <xsl:with-param name="base" select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
    <xsl:with-param name="rewrite"       select="$rewrite"/>
    <xsl:with-param name="main"          select="$main"/>
    <xsl:with-param name="heading"       select="$heading"/>
  </xsl:apply-templates>
</xsl:template>

<!--
    special case for sections, where we want the title to drop in as
    a heading.
-->

<xsl:template match="html:section[html:script[@src][contains(translate(@type, 'XML', 'xml'), 'xml')]][count(*) = 1][normalize-space(text()) = '']">
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
    <xsl:apply-templates select="@*" mode="xc:attribute">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>

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
    <xsl:apply-templates select="@*" mode="xc:attribute">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>

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
    <xsl:apply-templates select="@*" mode="xc:attribute">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>

    <xsl:apply-templates>
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading + 1"/>
    </xsl:apply-templates>
  </xsl:element>
</xsl:template>

<!-- fix links -->

<!-- local-base and global-base -->

<xsl:template match="html:*" mode="xc:local-base">
<xsl:value-of select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
</xsl:template>

<xsl:template match="html:*" mode="xc:global-base">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path">
    <xsl:message terminate="yes">xc:global-base requires $resource-path</xsl:message>
  </xsl:param>

  <xsl:variable name="_" select="normalize-space($resource-path)"/>

  <xsl:choose>
    <xsl:when test="$_ = ''"><xsl:value-of select="$base"/></xsl:when>
    <xsl:when test="contains($_, ' ')">
      <xsl:value-of select="substring-before($_, ' ')"/>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$_"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- catch-all template for propagating state variables -->

<xsl:template match="html:*" mode="xc:html-no-op" name="xc:html-no-op">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="''"/>
  <xsl:param name="main"    select="false()"/>
  <xsl:param name="heading" select="0"/>
  <xsl:param name="element" select="name()"/>

  <xsl:element name="{$element}">
    <xsl:apply-templates select="@*" mode="xc:attribute">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>
    <xsl:apply-templates>
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
      <xsl:with-param name="main"          select="$main"/>
      <xsl:with-param name="heading"       select="$heading"/>
    </xsl:apply-templates>
  </xsl:element>
</xsl:template>

<xsl:template match="@xml:*" mode="xc:attribute">
  <!-- MSIE/MSXSL hates the explicit XML namespace and fails all over  -->
  <xsl:attribute name="xml:{local-name()}">
    <xsl:value-of select="."/>
  </xsl:attribute>
</xsl:template>

<xsl:template match="@*[namespace-uri()]" mode="xc:attribute">
  <!--<xsl:message>found <xsl:value-of select="name()"/>, ns <xsl:value-of select="namespace-uri()"/></xsl:message>-->
  <xsl:attribute name="{name()}" namespace="{namespace-uri()}">
    <xsl:value-of select="."/>
  </xsl:attribute>
</xsl:template>

<xsl:template match="@*[not(namespace-uri())]" mode="xc:attribute">
  <!--<xsl:message>found <xsl:value-of select="name()"/></xsl:message>-->
  <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
</xsl:template>

<xsl:template match="@href[not(parent::html:base)]|@src|@data|@action|@longdesc|@xlink:href|@rdf:about|@rdf:resource" mode="xc:attribute" priority="2">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite" select="$resource-path"/>

  <!--<xsl:message>rewrite: <xsl:value-of select="$rewrite"/></xsl:message>-->

  <xsl:variable name="origin">
    <xsl:choose>
      <xsl:when test="contains(normalize-space($resource-path), ' ')">
        <xsl:value-of select="substring-before(normalize-space($resource-path), ' ')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="normalize-space($resource-path)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="origin-authority">
    <xsl:call-template name="uri:get-uri-authority">
      <xsl:with-param name="uri" select="$origin"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="uri">
    <xsl:call-template name="uri:resolve-uri">
      <xsl:with-param name="uri" select="normalize-space(.)"/>
      <xsl:with-param name="base" select="$base"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="href-authority">
    <xsl:call-template name="uri:get-uri-authority">
      <xsl:with-param name="uri" select="$uri"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="has-fragment" select="contains($uri, '#')"/>
  <xsl:variable name="fragment" select="substring-after($uri, '#')"/>
  <xsl:variable name="document">
    <xsl:choose>
      <xsl:when test="$has-fragment">
        <xsl:value-of select="substring-before($uri, '#')"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$uri"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="rewritten" select="contains(concat(' ', $rewrite, ' '), concat(' ', $document, ' '))"/>

  <xsl:variable name="href-fragment">
    <xsl:choose>
      <xsl:when test="$origin-authority = $href-authority and not($has-fragment) and $rewritten">
        <xsl:variable name="d" select="document($uri)"/>
        <xsl:value-of select="normalize-space(($d/html:html/html:body[1]/@id|$d/*/@id)[1])"/>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <xsl:attribute name="{name()}" namespace="{namespace-uri()}">
    <xsl:variable name="match" select="contains(concat(' ', $rewrite, ' '), concat(' ', $document, ' '))"/>
    <xsl:choose>
      <xsl:when test="$has-fragment and $match">
        <xsl:value-of select="concat($origin, '#', $fragment)"/>
      </xsl:when>
      <xsl:when test="$href-fragment and $match">
        <xsl:value-of select="concat($origin, '#', $href-fragment)"/>
      </xsl:when>
      <xsl:when test="$match"><xsl:value-of select="$origin"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$uri"/></xsl:otherwise>
    </xsl:choose>
  </xsl:attribute>

</xsl:template>

<!-- all non-html -->

<xsl:template match="*">
  <xsl:param name="base" select="normalize-space(ancestor-or-self::*[@xml:base][1]/@xml:base)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="rewrite"       select="''"/>
  <xsl:param name="main"          select="false()"/>
  <xsl:param name="heading"       select="0"/>

  <xsl:element name="{name()}" namespace="{namespace-uri()}">
    <xsl:apply-templates select="@*" mode="xc:attribute">
      <xsl:with-param name="base"          select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
      <xsl:with-param name="rewrite"       select="$rewrite"/>
    </xsl:apply-templates>

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
