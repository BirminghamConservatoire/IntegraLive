<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
                xmlns="http://www.integralive.org/schemas/ixd/2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt"
                xmlns:ixd="http://www.integralive.org/schemas/ixd/2.0"
                exclude-result-prefixes="msxsl ixd"
>
  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>
  
  <xsl:template match="IntegraCollection">
    <root xmlns="http://www.integralive.org/schemas/ixd/2.0">
      <client>
        <xsl:apply-templates select="@*"/>
      </client>
      <xsl:apply-templates select="node()"/>
    </root>
  </xsl:template>

  <xsl:template match="object">
    <object>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="attribute"/>
      <xsl:apply-templates select="object"/>
    </object>
  </xsl:template>

  <xsl:template match="attribute">
    <attribute name="{@name}">
      <xsl:choose>
        <xsl:when test="@typeCode=1">
          <integer>
            <xsl:value-of select="text()"/>
          </integer>
        </xsl:when>
        <xsl:when test="@typeCode=2">
          <float>
            <xsl:value-of select="text()"/>
          </float>
        </xsl:when>
        <xsl:when test="@typeCode=3">
          <string>
            <xsl:value-of select="text()"/>
          </string>
        </xsl:when>
      </xsl:choose>
    </attribute>
  </xsl:template>

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
