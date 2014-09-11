<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
                exclude-result-prefixes="exslt msxsl"
>
  <xsl:import href="lib.string.join.xsl"/>

  <xsl:template name="flatten">
    <xsl:copy>
      <xsl:for-each select="*[name()='Tags']">
        <xsl:attribute name="{name()}">
          <xsl:call-template name="join">
           <xsl:with-param name="src" select="*"/>
           <xsl:with-param name="sep" select="'|'"/>
          </xsl:call-template>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:for-each select="*[not(* or name()='Tags')]">
        <xsl:attribute name="{name()}">
          <xsl:value-of select="text()"/>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:for-each select="@*">
        <xsl:copy-of select="."/>
      </xsl:for-each>
      <xsl:for-each select="*[*]">
        <xsl:copy-of select="."/>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="InterfaceDeclaration/EndpointInfo/Endpoint">
    <xsl:variable name="local">
      <xsl:call-template name="flatten"/>
    </xsl:variable>
    <xsl:for-each select="exslt:node-set($local)/*">
      <xsl:apply-templates />
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="InterfaceDeclaration/*">
    <xsl:variable name="local">
      <xsl:call-template name="flatten"/>
    </xsl:variable>
    <xsl:for-each select="exslt:node-set($local)/*">
      <xsl:apply-templates />
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>