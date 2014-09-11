<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="comment()">
    <p class="comment">
      <xsl:value-of select="."/>
    </p>
  </xsl:template>

  <xsl:template match="processing-instruction()">
    <p class="processing-instruction">
      <xsl:copy/>
    </p>
  </xsl:template>

  <xsl:template match="node()">
    <p class="unknown">
      <xsl:copy />
    </p>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:variable name="text">
      <xsl:value-of select="."/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="normalize-space(.)=''">
      </xsl:when>
      <xsl:when test="string-length($text)&lt;10">
        <p class="text short">
          <xsl:copy/>
        </p>
      </xsl:when>
      <xsl:otherwise>
        <p class="text long">
          <xsl:copy/>
        </p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="prettify" match="*">
    <xsl:variable name="validity">
      <xsl:choose>
        <xsl:when test="@error">invalid error</xsl:when>
        <xsl:when test="descendant::*[@error]">invalid</xsl:when>
        <xsl:otherwise>valid</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fieldset class="element {local-name()} {$validity}">
      <legend>
        <xsl:value-of select="local-name()" />
      </legend>
      <xsl:if test="@*">
        <ul class="attributes">
          <xsl:apply-templates select="@*" />
        </ul>
      </xsl:if>
      <xsl:apply-templates select="node()" />
    </fieldset>
  </xsl:template>

  <xsl:template match="*[not(*|@*|text())]">
    <fieldset class="element empty {local-name()} valid">
      <xsl:value-of select="local-name()" />
    </fieldset>
  </xsl:template>

  <xsl:template match="@*">
    <li class="{local-name()}">
      <span class="key"><xsl:value-of select="local-name()" /></span>
      <span class="eq"> = </span>
      <span class="value"><xsl:value-of select="." /></span>
    </li>
  </xsl:template>

</xsl:stylesheet>