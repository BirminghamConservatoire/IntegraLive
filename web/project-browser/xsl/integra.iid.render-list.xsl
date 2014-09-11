<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
                exclude-result-prefixes="exslt msxsl"
>

  <xsl:template match="IntegraModules">
    <div class="ui-right">
      <input id="cbToggleUnreferencedModules" type="checkbox" />
      <label for="cbToggleUnreferencedModules">
        Show unreferenced modules
      </label>
    </div>
    <fieldset>
      <table>
        <thead>
          <tr>
            <th>name</th>
            <th>originGuid</th>
            <th>source</th>
            <th>refs</th>
          </tr>
        </thead>
        <tbody>
        	<xsl:for-each select="collection/module">
				  	<xsl:sort select="@name"/>
	          <xsl:apply-templates select="." />
        	</xsl:for-each>
        </tbody>
      </table>
    </fieldset>
  </xsl:template>

  <xsl:template match="IntegraModules/collection/module">
	  <xsl:variable name="path">
	  	<xsl:call-template name="get-module-path"/>
	  </xsl:variable>
	  <xsl:variable name="src" select="concat($path,'/integra_module_data/interface_definition.iid')" />
  	<xsl:variable name="row-class">
  		<xsl:choose>
		  	<xsl:when test="@refs=0">noref</xsl:when>
		  	<xsl:otherwise></xsl:otherwise>
  		</xsl:choose>
  	</xsl:variable>
    <tr class="{$row-class}">
      <th>
        <xsl:value-of select="@name"/>
      </th>
      <td>
        <xsl:value-of select="@originGuid"/>
      </td>
      <td>
        <xsl:value-of select="../@src"/>
      </td>
      <td>
        <xsl:value-of select="@refs"/>
      </td>
    </tr>
    <tr class="{$row-class}">
    	<td colspan="5" class="detail">
			  <xsl:value-of select="$src"/>
    	</td>
    </tr>
    <!--
    <tr class="{$row-class}">
    	<td colspan="4" class="detail">
        <xsl:apply-templates select="document($src)/*" />
	    </td>
	  </tr>
		-->
  </xsl:template>

  <xsl:template name="get-module-path">
  	<xsl:choose>
  		<xsl:when test="../@src='Integra%20Live'">
 				<xsl:value-of select="concat('../data/',../@src,'/',@name)" />
		 	</xsl:when>
		 	<xsl:otherwise>
 				<xsl:value-of select="concat('../data/',../@src,'/integra_data/implementation/',@name)" />
		 	</xsl:otherwise>
  	</xsl:choose>
	</xsl:template>

</xsl:stylesheet>