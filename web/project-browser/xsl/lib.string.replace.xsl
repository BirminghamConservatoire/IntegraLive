<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <xsl:template name="replace">
    <xsl:param name="src" />
    <xsl:param name="old" />
    <xsl:param name="new" />

    <xsl:variable name="pre" select="substring-before($src,$old)"/>
    <xsl:variable name="post" select="substring-after($src,$old)"/>

    <xsl:choose>
      <xsl:when test="$post">
        <xsl:value-of select="$pre"/>
        <xsl:value-of select="$new"/>
        <xsl:call-template name="replace">
          <xsl:with-param name="src" select="$post"/>
          <xsl:with-param name="old" select="$old"/>
          <xsl:with-param name="new" select="$new"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$src"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>