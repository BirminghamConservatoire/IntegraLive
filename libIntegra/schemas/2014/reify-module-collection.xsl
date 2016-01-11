<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" 
                xmlns               =   "http://www.integralive.org/schemas/2014/riid" 
                xmlns:xsd           =   "http://www.w3.org/2001/XMLSchema"
                xmlns:xsd-dummy     =    "dummy"
                xmlns:xsl           =   "http://www.w3.org/1999/XSL/Transform"
>
    <xsl:import href="reify-iid.xsl"/>
    <xsl:output method="xml" indent="yes"/>
    <xsl:namespace-alias stylesheet-prefix="xsd-dummy" result-prefix="xsd"/>

    <xsl:template match="IntegraModules">
        <xsl:message>
            <xsl:text>Collating IntegraModules IID endpoint constraints:</xsl:text>
        </xsl:message>

        <xsl:comment>
            <xsl:text>This is an auto-generated document, being the transformation output of the default modules list (specifically reify-module-collection.xsl applied to module-collection.xml), which represents the full set of IID module interface contracts as XSD attribute types, and defines minimal base types (for use as module instances in IXD node graphs).</xsl:text>
        </xsl:comment>

        <!-- NB: xsd-dummy is used to prevent validation errors when the parser forgets we're doing XSL and not actually XSD -->
        <xsd-dummy:schema targetNamespace="http://www.integralive.org/schemas/2014/riid"
                          xmlns:riid="http://www.integralive.org/schemas/2014/riid"
                          xmlns:rixd="http://www.integralive.org/schemas/2014/rixd/base"
                          attributeFormDefault="unqualified"
                          elementFormDefault="qualified"
        >
            <xsd:annotation>
                <xsd:documentation>XML Schema definitions for attribute groups within the reified Integra container format (RIXD).</xsd:documentation>
            </xsd:annotation>
            <xsd:import id="rixd" namespace="http://www.integralive.org/schemas/2014/rixd/base" schemaLocation="rixd.base.xsd"/>
            
            <xsl:text>&#xa;&#xa;</xsl:text>
            <xsl:comment>ATTRIBUTE GROUPS</xsl:comment> 
            <xsl:for-each select="collection/module">
                <xsl:apply-templates select="." mode="attributeGroup" />
            </xsl:for-each>
            
            <xsl:text>&#xa;&#xa;</xsl:text>
            <xsl:comment>CORE MODULE TYPES</xsl:comment>
            <xsl:for-each select="collection/module">
                <xsl:apply-templates select="." mode="coreComplexType" />
            </xsl:for-each>
            
            <xsl:text>&#xa;&#xa;</xsl:text>
            <xsl:comment>CORE MODULE GROUP</xsl:comment>
            <xsd:group name="coreModuleGroup">
                <xsd:choice>
                    <xsl:for-each select="collection/module">
                        <xsl:variable name="name">
                            <xsl:value-of select="translate(substring(@name,1,1),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')" />
                            <xsl:value-of select="substring(@name,2)" />
                        </xsl:variable>
                        <xsl:variable name="doc_name">
                            <xsl:value-of select="concat('../../../web/project-browser/data/Integra Live/',@name,'/integra_module_data/interface_definition.iid')"/>
                        </xsl:variable>
                        <xsl:if test="document($doc_name)/InterfaceDeclaration/InterfaceInfo/Tags/Tag='core'">
                            <xsd:element name="{@name}" type="{$name}"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsd:choice>
            </xsd:group>
            
            <xsl:text>&#xa;&#xa;</xsl:text>
            <xsl:comment>NON-CORE MODULE TYPES</xsl:comment>
            <xsl:for-each select="collection/module">
                <xsl:apply-templates select="." mode="nonCoreComplexType" />
            </xsl:for-each>
            
            <xsl:text>&#xa;&#xa;</xsl:text>
            <xsl:comment>NON-CORE MODULE GROUP</xsl:comment>
            <xsd:group name="nonCoreModuleGroup">
                <xsd:choice>
                    <xsl:for-each select="collection/module">
                        <xsl:variable name="name">
                            <xsl:value-of select="translate(substring(@name,1,1),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')" />
                            <xsl:value-of select="substring(@name,2)" />
                        </xsl:variable>
                        <xsl:variable name="doc_name">
                            <xsl:value-of select="concat('../../../web/project-browser/data/Integra Live/',@name,'/integra_module_data/interface_definition.iid')"/>
                        </xsl:variable>
                        <xsl:if test="not(document($doc_name)/InterfaceDeclaration/InterfaceInfo/Tags/Tag='core')">
                            <xsd:element name="{@name}" type="{$name}"/>
                        </xsl:if>
                    </xsl:for-each>
                </xsd:choice>
            </xsd:group>
        </xsd-dummy:schema>
        
    </xsl:template>

    <xsl:template match="module" mode="attributeGroup">
        <xsl:variable name="name">
            <xsl:value-of select="translate(substring(@name,1,1),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')" />
            <xsl:value-of select="substring(@name,2)" />
        </xsl:variable>
        <xsl:variable name="group_name">
            <xsl:value-of select="concat($name,'AttributeGroup')"/>
        </xsl:variable>
        <xsl:variable name="doc_name">
            <xsl:value-of select="concat('../../../web/project-browser/data/Integra Live/',@name,'/integra_module_data/interface_definition.iid')"/>
        </xsl:variable>
        <xsl:for-each select="document($doc_name)">
            <xsd:attributeGroup name="{$group_name}">
                <!-- generate interface documentation -->
                <xsl:apply-templates select="InterfaceDeclaration/InterfaceInfo" />
                <!-- generate interface implementation as list of supported attributes -->
                <xsl:apply-templates select="InterfaceDeclaration/EndpointInfo" />
            </xsd:attributeGroup>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="module" mode="coreComplexType">
        <xsl:variable name="name">
            <xsl:value-of select="translate(substring(@name,1,1),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')" />
            <xsl:value-of select="substring(@name,2)" />
        </xsl:variable>
        <xsl:variable name="group_name">
            <xsl:value-of select="concat($name,'AttributeGroup')"/>
        </xsl:variable>
        <xsl:variable name="doc_name">
            <xsl:value-of select="concat('../../../web/project-browser/data/Integra Live/',@name,'/integra_module_data/interface_definition.iid')"/>
        </xsl:variable>
        <xsl:for-each select="document($doc_name)[InterfaceDeclaration/InterfaceInfo/Tags/Tag='core']">
            <xsd:complexType name="{$name}">
                <xsl:apply-templates select="InterfaceDeclaration/InterfaceInfo" />
                <xsl:apply-templates select="InterfaceDeclaration/InterfaceInfo" mode="complexType" />
                <xsd:attributeGroup ref="rixd:baseAttributeGroup" />
                <xsd:attributeGroup ref="riid:{$group_name}" />
            </xsd:complexType>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="module" mode="nonCoreComplexType">
        <xsl:variable name="name">
            <xsl:value-of select="translate(substring(@name,1,1),'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')" />
            <xsl:value-of select="substring(@name,2)" />
        </xsl:variable>
        <xsl:variable name="group_name">
            <xsl:value-of select="concat($name,'AttributeGroup')"/>
        </xsl:variable>
        <xsl:variable name="doc_name">
            <xsl:value-of select="concat('../../../web/project-browser/data/Integra Live/',@name,'/integra_module_data/interface_definition.iid')"/>
        </xsl:variable>
        <xsl:for-each select="document($doc_name)[not(InterfaceDeclaration/InterfaceInfo/Tags/Tag='core')]">
            <xsd:complexType name="{$name}">
                <xsl:apply-templates select="InterfaceDeclaration/InterfaceInfo" />
                <xsl:apply-templates select="InterfaceDeclaration/InterfaceInfo" mode="complexType" />
                <xsd:attributeGroup ref="rixd:baseAttributeGroup" />
                <xsd:attributeGroup ref="riid:{$group_name}" />
            </xsd:complexType>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="InterfaceInfo" mode="complexType">
        <!-- in a few special cases, we expect an explicit hierarchy to be observed -->
        <xsl:choose>
            <!-- core module "player" -->
            <xsl:when test="../@originGuid='0f9203b8-e091-40f8-8968-4ee96185523f'">
                <xsd:sequence minOccurs="0" maxOccurs="unbounded">
                    <xsd:element name="Scene" type="scene" >
                        <xsd:annotation>
                            <xsd:documentation>A player node can contain an arbitrary number of scene nodes as children.</xsd:documentation>
                        </xsd:annotation>
                    </xsd:element>
                </xsd:sequence>
            </xsl:when>
            <!-- core module "envelope" -->
            <xsl:when test="../@originGuid='0b78bba4-bb49-46e4-868e-82777f92deae'">
                <xsd:sequence minOccurs="0" maxOccurs="unbounded">
                    <xsd:element name="ControlPoint" type="controlPoint">
                        <xsd:annotation>
                            <xsd:documentation>An envelope node can contain an arbitrary number of controlPoint nodes as children.</xsd:documentation>
                        </xsd:annotation>
                    </xsd:element>
                </xsd:sequence>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>