<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:str="http://xsltsl.org/string"
    xmlns:uri="http://xsltsl.org/uri"
    exclude-result-prefixes="html str uri">

<!-- XXX just embed this eventually -->
<xsl:import href="xsltsl-extension.xsl"/>

<xsl:key name="id" match="*" use="normalize-space(@id)"/>
<xsl:key name="blocks" match="html:body|html:main[not(@hidden)]|html:article[not(ancestor::html:main[@hidden])]" use="''"/>
<xsl:key name="references" match="html:*[@src][contains(transform(@type, 'LMX',  'lmx'), 'xml')]" use="''"/>

<!-- this performs the transclusion -->

<xsl:template match="html:script[@src][contains(@type, 'xml')]">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="caller" select=".."/>
  <xsl:param name="heading" select="false()"/>

  <xsl:variable name="src">
    <xsl:call-template name="uri:resolve-uri">
      <xsl:with-param name="uri" select="@src"/>
      <xsl:with-param name="base" select="$base"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="resource">
    <xsl:choose>
      <xsl:when test="contains($src, '#')">
        <xsl:value-of select="substring-before($src, '#')"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$src"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="contains(concat(' ', $resource-path, ' '), concat(' ', $resource, ' '))">
      <xsl:comment>Transclusion cycle detected and halted.</xsl:comment>
      <xsl:call-template name="html-no-op">
        <xsl:with-param name="base" select="$base"/>
        <xsl:with-param name="resource-path" select="$resource-path"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:message><xsl:value-of select="$resource"/></xsl:message>
      <xsl:apply-templates select="document($resource)/*" mode="transclude">
        <xsl:with-param name="resource-path" select="concat($resource-path, ' ', $resource)"/>
        <xsl:with-param name="uri"    select="$src"/>
        <xsl:with-param name="caller" select="$caller"/>
      </xsl:apply-templates>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template match="html:*" mode="transclude">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path"/>
  <xsl:param name="uri" select="$base"/>
  <xsl:param name="caller" select="/.."/>

  <xsl:message>wat</xsl:message>

  <xsl:if test="normalize-space($resource-path) = ''">
    <xsl:message terminate="yes">Resource path must be explicitly defined in transclusions.</xsl:message>
  </xsl:if>

  <xsl:if test="not($caller)">
    <xsl:message terminate="yes">Transclude invoked without caller node</xsl:message>
  </xsl:if>

  <xsl:if test="key('blocks', '')[self::html:main]">
    <p>has main</p>
  </xsl:if>
</xsl:template>

<xsl:template match="*" mode="transclude">
  <xsl:message>huh</xsl:message>
  <xsl:apply-templates select=".">
    <xsl:with-param name="base" select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
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

<xsl:template match="html:section[not(self::html:script)][html:script[@src][contains(@type, 'xml')]][count(*) = 1][normalize-space(text()) = '']">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>

  <xsl:apply-templates select="html:script">
    <xsl:with-param name="base" select="$base"/>
    <xsl:with-param name="resource-path" select="$resource-path"/>
  </xsl:apply-templates>

</xsl:template>

<!-- fix h1 through h6 -->

<xsl:template match="html:h1|html:h2|html:h3|html:h4|html:h5|html:h6" name="heading">
  <xsl:param name="base" select="normalize-space((/html:html/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="level" select="string-length(normalize-space($resource-path)) - string-length(translate(normalize-space($resource-path), ' ', ''))"/>
  <xsl:variable name="rank" select="number(substring-after(local-name(), 'h'))"/>
  <xsl:variable name="element">
    <xsl:choose>
      <xsl:when test="($rank + $level) &lt;= 6">
        <xsl:value-of select="concat('h', $rank + $level)"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="'h6'"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:element name="{$element}">
    <xsl:for-each select="@*">
      <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>
    <xsl:apply-templates>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
    </xsl:apply-templates>
  </xsl:element>
</xsl:template>

<!-- catch-all template for propagating state variables -->

<xsl:template match="html:*" name="html-no-op">
  <xsl:param name="base" select="normalize-space((ancestor-or-self::html:html[html:head/html:base[@href]][1]/html:head/html:base[@href])[1]/@href)"/>
  <xsl:param name="resource-path" select="$base"/>
  <xsl:param name="element" select="name()"/>

  <xsl:element name="{$element}" namespace="{namespace-uri()}">
    <xsl:for-each select="@*">
      <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>
    <xsl:apply-templates>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
    </xsl:apply-templates>
  </xsl:element>
</xsl:template>

<!-- all non-html -->

<xsl:template match="*">
  <xsl:param name="base" select="normalize-space(ancestor-or-self::*[@xml:base][1]/@xml:base)"/>
  <xsl:param name="resource-path" select="$base"/>

  <xsl:element name="{name()}" namespace="{namespace-uri()}">
    <xsl:for-each select="@*">
      <xsl:attribute name="{name()}"><xsl:value-of select="."/></xsl:attribute>
    </xsl:for-each>
    <xsl:apply-templates>
      <xsl:with-param name="base" select="$base"/>
      <xsl:with-param name="resource-path" select="$resource-path"/>
    </xsl:apply-templates>
  </xsl:element>
</xsl:template>

</xsl:stylesheet>
