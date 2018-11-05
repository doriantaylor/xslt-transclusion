<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:str="http://xsltsl.org/string"
                xmlns:uri="http://xsltsl.org/uri"
                exclude-result-prefixes="str uri">

<!--

This file is a derivative work of http://xsltsl.sourceforge.net/ , and
is therefore licensed under the LGPL: https://www.gnu.org/copyleft/lesser.html .

-->

<!--
    ### THIS IS ALL STUFF THAT COMES STRAIGHT FROM XSLTSL
-->

<xsl:template name="str:generate-string">
  <xsl:param name="text"/>
  <xsl:param name="count"/>  
  <xsl:choose>
    <xsl:when test="string-length($text) = 0 or $count &lt;= 0"/>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
      <xsl:call-template name="str:generate-string">
        <xsl:with-param name="text" select="$text"/>
        <xsl:with-param name="count" select="$count - 1"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="str:subst">
  <xsl:param name="text"/>
  <xsl:param name="replace"/>
  <xsl:param name="with"/>
  <xsl:param name="disable-output-escaping">no</xsl:param>
  <xsl:choose>
    <xsl:when test="string-length($replace) = 0 and $disable-output-escaping = 'yes'">
      <xsl:value-of select="$text" disable-output-escaping="yes"/>
    </xsl:when>
    <xsl:when test="string-length($replace) = 0">
      <xsl:value-of select="$text"/>
    </xsl:when>
    <xsl:when test="contains($text, $replace)">
      <xsl:variable name="before" select="substring-before($text, $replace)"/>
      <xsl:variable name="after" select="substring-after($text, $replace)"/>
      <xsl:choose>
        <xsl:when test="$disable-output-escaping = 'yes'">
          <xsl:value-of select="$before" disable-output-escaping="yes"/>
          <xsl:value-of select="$with" disable-output-escaping="yes"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$before"/>
          <xsl:value-of select="$with"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="str:subst">
        <xsl:with-param name="text" select="$after"/>
        <xsl:with-param name="replace" select="$replace"/>
        <xsl:with-param name="with" select="$with"/>
        <xsl:with-param name="disable-output-escaping" select="$disable-output-escaping"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="$disable-output-escaping = 'yes'">
      <xsl:value-of select="$text" disable-output-escaping="yes"/>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
  </xsl:choose>            
</xsl:template>

<xsl:template name="str:substring-before-last">
  <xsl:param name="text"/>
  <xsl:param name="chars"/>

  <xsl:choose>
    <xsl:when test="string-length($text) = 0"/>
    <xsl:when test="string-length($chars) = 0">
      <xsl:value-of select="$text"/>
    </xsl:when>
    <xsl:when test="contains($text, $chars)">
      <xsl:call-template name="str:substring-before-last-aux">
        <xsl:with-param name="text" select="$text"/>
        <xsl:with-param name="chars" select="$chars"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="str:substring-before-last-aux">
  <xsl:param name="text"/>
  <xsl:param name="chars"/>

  <xsl:choose>
    <xsl:when test="string-length($text) = 0"/>
    <xsl:when test="contains($text, $chars)">
      <xsl:variable name="after">
        <xsl:call-template name="str:substring-before-last-aux">
          <xsl:with-param name="text" select="substring-after($text, $chars)"/>
          <xsl:with-param name="chars" select="$chars"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:value-of select="substring-before($text, $chars)"/>
      <xsl:if test="string-length($after) &gt; 0">
        <xsl:value-of select="$chars"/>
        <xsl:copy-of select="$after"/>
      </xsl:if>
    </xsl:when>
    <xsl:otherwise/>
  </xsl:choose>
</xsl:template>

<xsl:template name="uri:get-uri-scheme">
  <xsl:param name="uri"/>
  <xsl:if test="contains($uri, ':')">
    <xsl:value-of select="substring-before($uri, ':')"/>
  </xsl:if>
</xsl:template>

<xsl:template name="uri:get-uri-authority">
  <xsl:param name="uri"/>
  <xsl:variable name="a">
    <xsl:choose>
      <xsl:when test="contains($uri, ':')">
        <xsl:if test="substring(substring-after($uri, ':'), 1, 2) = '//'">
          <xsl:value-of select="substring(substring-after($uri, ':'), 3)"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="substring($uri, 1, 2) = '//'">
          <xsl:value-of select="substring($uri, 3)"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="contains($a, '/')">
      <xsl:value-of select="substring-before($a, '/')" />
    </xsl:when>
    <xsl:when test="contains($a, '?')">
      <xsl:value-of select="substring-before($a, '?')" />
    </xsl:when>
    <xsl:when test="contains($a, '#')">
      <xsl:value-of select="substring-before($a, '#')" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$a" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="uri:get-uri-path">
  <xsl:param name="uri"/>
  <xsl:variable name="p">
    <xsl:choose>
      <xsl:when test="contains($uri, '//')">
        <xsl:if test="contains(substring-after($uri, '//'), '/')">
          <xsl:value-of select="concat('/', substring-after(substring-after($uri, '//'), '/'))"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains($uri, ':')">
            <xsl:value-of select="substring-after($uri, ':')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$uri"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="contains($p, '?')">
      <xsl:value-of select="substring-before($p, '?')" />
    </xsl:when>
    <xsl:when test="contains($p, '#')">
      <xsl:value-of select="substring-before($p, '#')" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$p" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="uri:get-uri-query">
  <xsl:param name="uri"/>
  <xsl:variable name="q" select="substring-after($uri, '?')"/>
  <xsl:choose>
    <xsl:when test="contains($q, '#')">
      <xsl:value-of select="substring-before($q, '#')"/>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$q"/></xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="uri:get-uri-fragment">
  <xsl:param name="uri"/>
  <xsl:value-of select="substring-after($uri, '#')"/>
</xsl:template>

<xsl:template name="uri:get-path-without-file">
  <xsl:param name="path-with-file" />
  <xsl:param name="path-without-file" />

  <xsl:choose>
    <xsl:when test="contains($path-with-file, '/')">
      <xsl:call-template name="uri:get-path-without-file">
        <xsl:with-param name="path-with-file" select="substring-after($path-with-file, '/')" />
        <xsl:with-param name="path-without-file">
          <xsl:choose>
            <xsl:when test="$path-without-file">
              <xsl:value-of select="concat($path-without-file, '/', substring-before($path-with-file, '/'))" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="substring-before($path-with-file, '/')" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$path-without-file" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="uri:normalize-path">
  <xsl:param name="path"/>
  <xsl:param name="result" select="''"/>

  <xsl:choose>
    <xsl:when test="string-length($path)">
      <xsl:choose>
        <xsl:when test="$path = '/'">
          <xsl:value-of select="concat($result, '/')"/>
        </xsl:when>
        <xsl:when test="$path = '.'">
          <xsl:value-of select="concat($result, '/')"/>
        </xsl:when>
        <xsl:when test="$path = '..'">
          <xsl:call-template name="uri:get-path-without-file">
            <xsl:with-param name="path-with-file" select="$result"/>
          </xsl:call-template>
          <xsl:value-of select="'/'"/>
        </xsl:when>
        <xsl:when test="contains($path, '/')">
          <!-- the current segment -->
          <xsl:variable name="s" select="substring-before($path, '/')"/>
          <!-- the remaining path -->
          <xsl:variable name="p">
            <xsl:choose>
              <xsl:when test="substring-after($path, '/') = ''">
                <xsl:value-of select="'/'"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="substring-after($path, '/')"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="$s = ''">
              <xsl:call-template name="uri:normalize-path">
                <xsl:with-param name="path" select="$p"/>
                <xsl:with-param name="result" select="$result"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$s = '.'">
              <xsl:call-template name="uri:normalize-path">
                <xsl:with-param name="path" select="$p"/>
                <xsl:with-param name="result" select="$result"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$s = '..'">
              <xsl:choose>
                <xsl:when test="string-length($result) and (substring($result, string-length($result) - 2) != '/..')">
                  <xsl:call-template name="uri:normalize-path">
                    <xsl:with-param name="path" select="$p"/>
                    <xsl:with-param name="result">
                      <xsl:call-template name="uri:get-path-without-file">
                        <xsl:with-param name="path-with-file" select="$result"/>
                      </xsl:call-template>
                    </xsl:with-param>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:call-template name="uri:normalize-path">
                    <xsl:with-param name="path" select="$p"/>
                    <xsl:with-param name="result" select="concat($result, '/..')"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="uri:normalize-path">
                <xsl:with-param name="path" select="$p"/>
                <xsl:with-param name="result" select="concat($result, '/', $s)"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($result, '/', $path)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$result"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


</xsl:stylesheet>
