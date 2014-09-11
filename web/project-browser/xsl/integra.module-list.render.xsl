<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
                exclude-result-prefixes="exslt msxsl"
>
  <!-- override rendering of module-list content, as we're only interested in seeing details of the modules it references -->
  <xsl:template match="IntegraModules">
    <!-- add UI elements to support toggling display of modules that aren't referenced by the current IXD -->
  	<div class="ui-right">
	    <input id="cbToggleUnreferencedModules" type="checkbox" />
	    <label for="cbToggleUnreferencedModules">Show unreferenced modules</label>
	  </div>
    <!-- render all listed modules (as determined by other templates) in alphabetical order by name -->
  	<xsl:for-each select="collection/module">
	  	<xsl:sort select="@name"/>
      <xsl:apply-templates select="." />
  	</xsl:for-each>
  </xsl:template>

  <!-- override rendering of module-list module elements that have been decorated with an InterfaceDeclaration from the relevant IID -->
  <xsl:template match="IntegraModules/collection/module[InterfaceDeclaration]">

    <xsl:variable name="suffix">
      <xsl:value-of select="concat('-',@moduleGuid)"/>
    </xsl:variable>

    <xsl:variable name="name">
      <xsl:choose>
        <xsl:when test="contains(@name,$suffix)">
          <xsl:value-of select="substring-before(@name,$suffix)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <div>
      <!-- mark unreferenced modules with a noref class -->
      <xsl:attribute name="class">
        <xsl:value-of select="@status"/>
        <xsl:if test="@refs=0">
          <xsl:text> noref</xsl:text>
        </xsl:if>
      </xsl:attribute>
      <!-- render a section heading with the module name and reference count -->
      <h4>
        <xsl:value-of select="$name"/>
        <xsl:text> </xsl:text>
        <small>(<xsl:value-of select="@refs"/> reference<xsl:if test="not(@refs=1)">s</xsl:if>)</small>
      </h4>
      <!-- render module contents (as determined by other templates) -->
      <xsl:apply-templates select="*"/>
    </div>
  </xsl:template>

</xsl:stylesheet>