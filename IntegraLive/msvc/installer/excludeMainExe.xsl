<?xml version="1.0" ?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wix="http://schemas.microsoft.com/wix/2006/wi">
  <!-- Copy all attributes and elements to the output. -->
  <xsl:template match="@*|*">
    <xsl:copy>
      <xsl:apply-templates select="@*" />
      <xsl:apply-templates select="*" />
    </xsl:copy>
  </xsl:template>
  <xsl:output method="xml" indent="yes" />

  <!-- Remove IntegraLive.exe -->
  <xsl:template match="wix:File[@Source='$(var.SourceDirectory)\gui\Integra Live.exe']" />
  <xsl:template match="wix:Component[@Id='Integra_Live.exe']" />
  <xsl:template match="wix:ComponentRef[@Id='Integra_Live.exe']" />
</xsl:stylesheet>

