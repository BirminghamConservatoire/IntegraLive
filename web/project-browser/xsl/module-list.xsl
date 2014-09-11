<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:import href="integra.module-list.resolve.xsl" />

  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:strip-space elements="*"/>

  <!-- entry point -->
  <xsl:template match="/">
    <IntegraModules>
  	  <xsl:apply-templates select="//module"/>
    </IntegraModules>
  </xsl:template>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="module">
    <xsl:call-template name="get-module"/>
  </xsl:template>

</xsl:stylesheet>