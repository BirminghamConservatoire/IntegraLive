<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <xsl:template name="join">
    <xsl:param name="src" />
    <xsl:param name="sep" />

    <xsl:value-of select="$src[1]"/>
    <xsl:if test="count($src)>1">
      <xsl:value-of select="$sep"/>
      <xsl:call-template name="join">
        <xsl:with-param name="src" select="$src[position()>1]"/>
        <xsl:with-param name="sep" select="$sep"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>