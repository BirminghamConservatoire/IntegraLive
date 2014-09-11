<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- templates to render XML as a collapsible tree structure -->
  <xsl:import href="lib.xml.render-nested-tree.xsl" />

  <!-- templates to render a Bootstrap HTML 5 page with head/body/script stubs -->
  <xsl:import href="lib.html.render-page.xsl" />

  <!-- template overrides to render head/body/script for display of IXD -->
  <xsl:import href="integra.ixd.render-details.xsl" />

  <!-- templates to render full module list, including IXD usage stats -->
  <xsl:import href="integra.module-list.render.xsl" />

  <!-- entry point -->
  <xsl:output method="html" />
  <xsl:template match="/">
	  <xsl:call-template name="render-page"/>
  </xsl:template>

  <!-- override default HTML5 page transform for rendering body content -->
  <xsl:template name="render-content">
    <xsl:if test="@project">
      <xsl:call-template name="render-ixd-content">
        <xsl:with-param name="project-name" select="@project"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="not(@project)">
        <p>Please use attribute 'project' to specify a project name - this should match one of the extracted projects contained in the 'data' sub-folder</p>
    </xsl:if>
  </xsl:template>


</xsl:stylesheet>