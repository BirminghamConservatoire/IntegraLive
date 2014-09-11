<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
                exclude-result-prefixes="exslt msxsl"
>
  <xsl:import href="lib.string.replace.xsl"/>
  <xsl:import href="integra.ixd.reify.xsl"/>
  <xsl:import href="integra.ixd.extract-modules.xsl"/>
  <xsl:import href="integra.ixd.embed-module-declarations.xsl"/>
  <xsl:import href="integra.module-list.resolve.xsl"/>

  <!-- render HTML5 content for specified IXD project -->
  <xsl:template name="render-ixd-content">
    <xsl:param name="project-name" />

    <xsl:variable name="project-path">
      <xsl:value-of select="'../data/'"/>
      <xsl:call-template name="replace">
        <xsl:with-param name="src" select="@project"/>
        <xsl:with-param name="old" select="' '"/>
        <xsl:with-param name="new" select="'%20'"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="module-list-path" select="concat($project-path,'.modules.xml')"/>

    <xsl:variable name="ixd-path" select="concat($project-path,'/integra_data/nodes.ixd')"/>
    <xsl:variable name="ixd" select="document($ixd-path)"/>

    <!-- retrieve an ixd-decorated module list based on content from the specified path -->
    <xsl:variable name="module-list">
      <xsl:call-template name="get-module-list-decorated-filtered">
        <xsl:with-param name="path" select="$module-list-path"/>
        <xsl:with-param name="ixd" select="$ixd"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="ixd-reified">
      <xsl:for-each select="exslt:node-set($ixd)/*">
        <xsl:call-template name="reify-any"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="ixd-module-hierarchy">
      <xsl:for-each select="exslt:node-set($ixd-reified)/*">
        <xsl:call-template name="extract-modules"/>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="ixd-reified-with-embedded-module-declarations">
      <xsl:for-each select="exslt:node-set($ixd-reified)/*">
        <xsl:call-template name="embed-module-declarations">
          <xsl:with-param name="modules" select="$module-list"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>

    <h2>
      <xsl:value-of select="$project-name"/>
    </h2>

    <h3>Structure <small>(original)</small></h3>
    <xsl:for-each select="exslt:node-set($ixd)">
      <xsl:apply-templates/>
    </xsl:for-each>

    <h3>Structure <small>(module hierarchy)</small></h3>
    <div class="ui-right">
      <label for="selAttributeDisplayMode">Attribute display mode:</label>
      <select id="selAttributeDisplayMode">
        <option>none</option>
        <option>generic</option>
        <option selected="selected">custom</option>
      </select>
    </div>
    <xsl:for-each select="exslt:node-set($ixd-module-hierarchy)">
      <xsl:apply-templates/>
    </xsl:for-each>

    <h3>Structure <small>(reified with embedded module declarations)</small></h3>
    <xsl:for-each select="exslt:node-set($ixd-reified-with-embedded-module-declarations)">
      <xsl:apply-templates/>
    </xsl:for-each>

    <xsl:variable name="link">
      <a href="data/{concat($project-name,'.modules.xml')}" target="_blank">
        <xsl:value-of select="concat($project-name,'.modules.xml')"/>
      </a>
    </xsl:variable>

    <h3>Modules <small>(from pre-extracted index <code><xsl:copy-of select="$link"/></code>)</small></h3>
    <xsl:for-each select="exslt:node-set($module-list)">
      <xsl:apply-templates/>
    </xsl:for-each>

  </xsl:template>

</xsl:stylesheet>