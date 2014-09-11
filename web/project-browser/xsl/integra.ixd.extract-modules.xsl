<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
                exclude-result-prefixes="exslt msxsl"
>
  <xsl:import href="lib.string.replace.xsl"/>

  <xsl:template name="extract-modules">
    <xsl:choose>
      <xsl:when test="name()='module'">
        <xsl:element name="{@name}">
          <xsl:for-each select="endpoints/*">
            <xsl:attribute name="{name()}">
              <xsl:value-of select="(int|float|string)/text()"/>
            </xsl:attribute>
          </xsl:for-each>
          <xsl:for-each select="modules/module">
            <xsl:call-template name="extract-modules"/>
          </xsl:for-each>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="module">
          <xsl:call-template name="extract-modules"/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>