<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:str="http://xsltsl.org/string"
                xmlns:uri="http://xsltsl.org/uri"
                exclude-result-prefixes="str uri">

<!--
    ### THIS IS ALL STUFF THAT SHOULD REALLY BE INCORPORATED INTO XSLTSL ###
-->

<xsl:import href="xsltsl.xsl"/>

<xsl:template name="uri:sanitize-path">
  <xsl:param name="path" select="''"/>

  <xsl:variable name="clean-path">
    <xsl:choose>
      <xsl:when test="contains(normalize-space($path), ' ')">
        <xsl:call-template name="str:subst">
          <xsl:with-param name="text" select="normalize-space($path)"/>
          <xsl:with-param name="replace" select="' '"/>
          <xsl:with-param name="with" select="'%20'"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="normalize-space($path)"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:if test="starts-with($clean-path, '/')"><xsl:text>/</xsl:text></xsl:if>
  <xsl:value-of select="translate(normalize-space(translate($clean-path, '/', ' ')), ' ', '/')"/>
  <xsl:if test="substring($clean-path, string-length($clean-path), 1) = '/'"><xsl:text>/</xsl:text></xsl:if>

</xsl:template>

<xsl:template name="uri:make-relative-path">
  <xsl:param name="path" select="'/'"/>
  <xsl:param name="base" select="'/'"/>
  <xsl:param name="strict" select="false()"/>
  <xsl:param name="dotdot" select="0"/>

  <xsl:if test="not(starts-with($path, '/') and starts-with($base, '/'))">
    <xsl:message terminate="yes">uri:make-relative-path: both base and path must be absolute paths</xsl:message>
  </xsl:if>

  <xsl:choose>
    <xsl:when test="$dotdot = 0 and $strict and $path = $base">
      <xsl:value-of select="''"/>
    </xsl:when>
    <xsl:otherwise>
      <!-- give me up to and including the last slash -->
      <xsl:variable name="_b">
        <xsl:choose>
          <xsl:when test="substring($base, string-length($base), 1) = '/'">
            <xsl:value-of select="$base"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="str:substring-before-last">
              <xsl:with-param name="text" select="$base"/>
              <xsl:with-param name="chars" select="'/'"/>
            </xsl:call-template>
            <xsl:text>/</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- punt out the appropriate number of dotdots -->
      <xsl:call-template name="str:generate-string">
        <xsl:with-param name="text" select="'../'"/>
        <xsl:with-param name="count" select="$dotdot"/>
      </xsl:call-template>

      <xsl:choose>
        <!-- path is same as dirname of base -->
        <xsl:when test="$path != $base and $path = $_b and $dotdot = 0">
          <xsl:value-of select="'./'"/>
        </xsl:when>
        <!-- path begins with base -->
        <xsl:when test="starts-with($path, $_b)">
          <xsl:value-of select="substring-after($path, $_b)"/>
        </xsl:when>
        <!-- all other cases -->
        <xsl:otherwise>
          <xsl:call-template name="uri:make-relative-path">
            <xsl:with-param name="base">
              <xsl:call-template name="str:substring-before-last">
                <xsl:with-param name="text" select="substring($_b, 1, string-length($_b) - 1)"/>
                <xsl:with-param name="chars" select="'/'"/>
              </xsl:call-template>
              <xsl:text>/</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="path" select="$path"/>
            <xsl:with-param name="strict" select="$strict"/>
            <xsl:with-param name="dotdot" select="$dotdot + 1"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
    this is a temporary solution to deal with shortcomings in
    uri:resolve-uri
-->

<xsl:template name="uri:resolve-uri">
  <xsl:param name="uri"/>
  <xsl:param name="reference" select="$uri"/>
  <xsl:param name="base"/>
  <xsl:param name="document" select="$base"/>
  <xsl:param name="uri:DEBUG" select="false()"/>

  <xsl:if test="$uri:DEBUG">
    <xsl:message>Resolving <xsl:value-of select="$reference"/></xsl:message>
  </xsl:if>

  <xsl:variable name="reference-scheme">
    <xsl:call-template name="uri:get-uri-scheme">
      <xsl:with-param name="uri" select="$reference"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="reference-authority">
    <xsl:call-template name="uri:get-uri-authority">
      <xsl:with-param name="uri" select="$reference"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="reference-path">
    <xsl:call-template name="uri:get-uri-path">
      <xsl:with-param name="uri" select="$reference"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="has-query" select="contains($reference, '?')"/>
  <xsl:variable name="reference-query">
    <xsl:call-template name="uri:get-uri-query">
      <xsl:with-param name="uri" select="$reference"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="has-fragment" select="contains($reference, '#')"/>
  <xsl:variable name="reference-fragment" select="substring-after($reference, '#')"/>

  <xsl:choose>
    <xsl:when test="string-length($reference-scheme)">
      <xsl:value-of select="$reference"/>
    </xsl:when>
    <xsl:when test="starts-with($reference, '?')">
      <xsl:choose>
        <xsl:when test="contains($document, '?')">
          <xsl:value-of select="substring-before($document, '?')"/>
        </xsl:when>
        <xsl:when test="contains($document, '#')">
          <xsl:value-of select="substring-before($document, '#')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$document"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="$reference"/>
    </xsl:when>
    <xsl:when test="not(string-length($reference-scheme)) and
                    not(string-length($reference-authority)) and
                    not(string-length($reference-path)) and not($has-query)">
      <xsl:choose>
        <xsl:when test="contains($document, '#')">
          <xsl:value-of select="substring-before($document, '#')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$document"/>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="$has-fragment">
        <xsl:value-of select="concat('#', $reference-fragment)"/>
      </xsl:if>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="base-scheme">
        <xsl:call-template name="uri:get-uri-scheme">
          <xsl:with-param name="uri" select="$base"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="base-authority">
        <xsl:call-template name="uri:get-uri-authority">
          <xsl:with-param name="uri" select="$base"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="base-path">
        <xsl:call-template name="uri:get-uri-path">
          <xsl:with-param name="uri" select="$base"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="base-query">
        <xsl:call-template name="uri:get-uri-query">
          <xsl:with-param name="uri" select="$base"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="base-fragment" select="substring-after($base, '#')"/>

      <xsl:variable name="result-authority">
        <xsl:choose>
          <xsl:when test="string-length($reference-authority)">
            <xsl:value-of select="$reference-authority"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$base-authority"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:variable name="result-path">
        <xsl:choose>
          <!-- don't normalize absolute paths -->
          <xsl:when test="starts-with($reference-path, '/')">
            <xsl:value-of select="$reference-path" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="uri:normalize-path">
              <xsl:with-param name="path">
                <xsl:if test="string-length($reference-authority) = 0 and substring($reference-path, 1, 1) != '/'">
                  <xsl:call-template name="uri:get-path-without-file">
                    <xsl:with-param name="path-with-file" select="$base-path"/>
                  </xsl:call-template>
                  <xsl:value-of select="'/'"/>
                </xsl:if>
                <xsl:value-of select="$reference-path"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:value-of select="concat($base-scheme, '://', $result-authority, $result-path)"/>

      <xsl:if test="$has-query">
        <xsl:value-of select="concat('?', $reference-query)"/>
      </xsl:if>

      <xsl:if test="$has-fragment">
        <xsl:value-of select="concat('#', $reference-fragment)"/>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template name="uri:make-absolute-uri">
  <xsl:param name="uri"/>
  <xsl:param name="base"/>
  <xsl:param name="document" select="$base"/>

  <!-- resolve-uri removes empty query and fragment -->
  <xsl:variable name="has-query" select="contains($uri, '?')"/>
  <xsl:variable name="has-fragment" select="contains($uri, '#')"/>

  <!-- call the original resolver -->
  <xsl:variable name="out">
    <xsl:call-template name="uri:resolve-uri">
      <xsl:with-param name="reference" select="normalize-space($uri)"/>
      <xsl:with-param name="base" select="normalize-space($base)"/>
      <xsl:with-param name="document" select="$document"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:value-of select="$out"/>
  <xsl:if test="$has-query and not(contains($out, '?'))">
    <xsl:text>?</xsl:text>
  </xsl:if>
  <xsl:if test="$has-fragment and not(contains($out, '#'))">
    <xsl:text>#</xsl:text>
  </xsl:if>
  
</xsl:template>

<xsl:template name="uri:make-relative-uri">
  <xsl:param name="uri" select="''"/>
  <xsl:param name="base" select="''"/>
  <xsl:param name="strict" select="false()"/>
  <xsl:param name="uri:DEBUG" select="false()"/>

  <xsl:variable name="abs-base" select="normalize-space($base)"/>
  <xsl:variable name="abs-uri">
    <xsl:call-template name="uri:resolve-uri">
      <xsl:with-param name="reference" select="normalize-space($uri)"/>
      <xsl:with-param name="base" select="$abs-base"/>
    </xsl:call-template>
  </xsl:variable>

  <!--<xsl:message>wtf yo <xsl:value-of select="$uri"/><xsl:text> </xsl:text><xsl:value-of select="$abs-uri"/></xsl:message>-->

  <xsl:choose>
    <!-- early exit for exact match -->
    <xsl:when test="$strict and $abs-uri = $abs-base"><xsl:value-of select="''"/></xsl:when>
    <xsl:otherwise>
      <!-- now match authority -->
      <xsl:variable name="uri-scheme">
        <xsl:call-template name="uri:get-uri-scheme">
          <xsl:with-param name="uri" select="$abs-uri"/>
        </xsl:call-template>
      </xsl:variable>
      
      <xsl:variable name="uri-authority">
        <xsl:call-template name="uri:get-uri-authority">
          <xsl:with-param name="uri" select="$abs-uri"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="scheme-authority" select="concat($uri-scheme, '://', $uri-authority, '/')"/>

      <xsl:choose>
        <xsl:when test="starts-with($abs-base, $scheme-authority)">
          <xsl:variable name="base-path">
            <xsl:call-template name="uri:get-uri-path">
              <xsl:with-param name="uri" select="$abs-base"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="uri-path">
            <xsl:call-template name="uri:get-uri-path">
              <xsl:with-param name="uri" select="$abs-uri"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="uri-has-query" select="contains($abs-uri, '?')"/>
          <xsl:variable name="uri-query">
            <xsl:call-template name="uri:get-uri-query">
              <xsl:with-param name="uri" select="$abs-uri"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="uri-has-fragment" select="contains($abs-uri, '#')"/>
          <xsl:variable name="uri-fragment">
            <xsl:call-template name="uri:get-uri-fragment">
              <xsl:with-param name="uri" select="$abs-uri"/>
            </xsl:call-template>
          </xsl:variable>

          <!-- path will either be empty or relative -->
          <xsl:variable name="result-path">
            <xsl:call-template name="uri:make-relative-path">
              <xsl:with-param name="base" select="$base-path"/>
              <xsl:with-param name="path" select="$uri-path"/>
              <xsl:with-param name="strict" select="$strict"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:value-of select="$result-path"/>

          <xsl:if test="$uri-has-query">
            <xsl:variable name="base-has-query" select="contains($abs-base, '?')"/>
            <xsl:variable name="base-query">
              <xsl:call-template name="uri:get-uri-query">
                <xsl:with-param name="uri" select="$abs-base"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:if test="not($strict and $result-path = '' and $base-has-query and $base-query = $uri-query)">
              <xsl:value-of select="concat('?', $uri-query)"/>
            </xsl:if>
          </xsl:if>

          <xsl:if test="$uri-has-fragment">
            <!--<xsl:message>has fragment yo</xsl:message>-->
            <xsl:variable name="base-has-fragment" select="contains($abs-base, '#')"/>
            <xsl:variable name="base-fragment">
              <xsl:call-template name="uri:get-uri-fragment">
                <xsl:with-param name="uri" select="$abs-base"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:if test="not($strict and $result-path = '' and $base-has-fragment and $base-fragment = $uri-fragment)">
              <xsl:value-of select="concat('#', $uri-fragment)"/>
            </xsl:if>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$abs-uri"/></xsl:otherwise>
      </xsl:choose>

    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template name="uri:local-part">
  <xsl:param name="uri"/>
  <xsl:param name="base"/>

  <xsl:variable name="base-authority">
    <xsl:call-template name="uri:get-uri-authority">
      <xsl:with-param name="uri" select="$base"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="uri-authority">
    <xsl:call-template name="uri:get-uri-authority">
      <xsl:with-param name="uri" select="$uri"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$base-authority = $uri-authority">
      <xsl:value-of select="substring-after($uri, $uri-authority)"/>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$uri"/></xsl:otherwise>
  </xsl:choose>

</xsl:template>

<!-- deduplicate tokens -->

<xsl:template name="str:unique-tokens">
  <xsl:param name="string"/>
  <xsl:param name="cache"/>

  <xsl:variable name="_norm" select="normalize-space($string)"/>

  <xsl:choose>
    <xsl:when test="$_norm  = ''"><xsl:value-of select="$cache"/></xsl:when>
    <xsl:when test="contains($_norm, ' ')">
      <xsl:variable name="first" select="substring-before($_norm, ' ')"/>
      <xsl:variable name="rest"  select="substring-after($_norm, ' ')"/>

      <xsl:variable name="cache-out">
        <xsl:choose>
        <xsl:when test="contains(concat(' ', $rest, ' '), concat(' ', $first, ' '))">
          <xsl:value-of select="$cache"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($cache, $first, ' ')"/>
        </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:choose>
        <xsl:when test="contains($rest, ' ')">
          <xsl:call-template name="str:unique-tokens">
            <xsl:with-param name="string" select="$rest"/>
            <xsl:with-param name="cache"  select="$cache-out"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="contains(concat(' ', $cache-out, ' '), concat(' ' , $rest, ' '))">
          <xsl:value-of select="$cache-out"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($cache-out, $rest, ' ')"/>
        </xsl:otherwise>
      </xsl:choose>

    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat($cache, $_norm)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

  <!--
      per https://www.w3.org/International/questions/qa-controls
      control codes are illegal in XML 1.0, even when escaped, which
      is too bad. in particular unit separator, record separator etc
      would be useful for dealing with literals.

      what we can do to compensate is use codepoints from the unicode
      private use area: map whitespace and separators to a set of
      codepoints.

      of course this will have the same weakness, namely that content
      may contain delimiters and then gum up the works, although
      potentially more likely with private-use unicode characters than
      control characters (e.g. custom emoji).

      nevertheless, the basic strategy here is to take the same octets
      we're interested in and plunk them somewhere in one of the
      private use areas (U+E000-U+F8FF etc), like so:

      0x1c -> &#xe01c; - file separator
      0x1d -> &#xe01d; - group separator
      0x1e -> &#xe01e; - record separator
      0x1f -> &#xe01f; - unit separator

      we will also need to do the same for whitespace characters, as
      literals can contain whitespace:

      0x09 -> &#xe009; - tab
      0x0a -> &#xe00a; - newline
      0x0d -> &#xe00d; - carriage return
      0x20 -> &#xe020; - space

      if we do this, we can do things like:

      1) encode the whitespace characters into their PUP counterparts
         with translate()
      2) translate() a particular delimiter into spaces and run
         normalize-space() to prune out empty records
      3) translate() the delimiter back to its original counterpart
      4) translate() whitespace chars back to their originals too

      NOTE actually we're using the range U+F100
  -->

<xsl:template name="str:unique-strings">
  <xsl:param name="string" select="''"/>
  <xsl:param name="delimiter" select="$rdfa:RECORD-SEP"/>

  <xsl:choose>
    <xsl:when test="contains($string, $delimiter)">
      <xsl:variable name="in" select="translate($string, '&#x09;&#x0a;&#x0d;&#x20;', '&#xf109;&#xf10a;&#xf10d;&#xf120;')"/>
      <xsl:variable name="out">
        <xsl:variable name="_">
          <xsl:call-template name="str:unique-tokens">
            <xsl:with-param name="string" select="translate($in, $delimiter, ' ')"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="translate(normalize-space($_), ' ', $delimiter)"/>
      </xsl:variable>

      <xsl:value-of select="translate($out, '&#xf109;&#xf10a;&#xf10d;&#xf120;',  '&#x09;&#x0a;&#x0d;&#x20;')"/>
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="$string"/></xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template name="str:token-intersection">
  <xsl:param name="left"  select="''"/>
  <xsl:param name="right" select="''"/>
  <xsl:param name="init"  select="true()"/>

  <xsl:variable name="_l" select="normalize-space($left)"/>
  <xsl:variable name="_r" select="normalize-space($right)"/>

  <!--<xsl:message>wtftoken <xsl:value-of select="string-length($_r)"/></xsl:message>-->


  <xsl:if test="string-length($_l) and string-length($_r)">
    <xsl:variable name="lfirst">
      <xsl:choose>
        <xsl:when test="contains($_l, ' ')">
          <xsl:value-of select="substring-before($_l, ' ')"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$_l"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:if test="contains(concat(' ', $_r, ' '), concat(' ', $lfirst, ' '))">
      <!--<xsl:message><xsl:value-of select="$lfirst"/> in <xsl:value-of select="$_r"/></xsl:message>-->
      <xsl:value-of select="$lfirst"/>
    </xsl:if>

    <xsl:variable name="lrest" select="substring-after($_l, ' ')"/>

    <xsl:if test="string-length($lrest)">
      <xsl:text> </xsl:text>
      <xsl:call-template name="str:token-intersection">
        <xsl:with-param name="left"  select="$lrest"/>
        <xsl:with-param name="right" select="$_r"/>
        <xsl:with-param name="init"  select="false()"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
