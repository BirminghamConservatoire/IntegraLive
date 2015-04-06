<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" 
                xmlns               =   "http://www.integralive.org/schemas/2014/riid" 
                xmlns:xsd           =   "http://www.w3.org/2001/XMLSchema"
                xmlns:xsl           =   "http://www.w3.org/1999/XSL/Transform"
                xmlns:rixd          =   "http://www.integralive.org/schemas/2014/rixd"
>
    <xsl:output method="xml" indent="yes"/>

    <xsl:template match="InterfaceInfo">
        <xsl:variable name="doc">
            <xsl:value-of select="Description"/>
            <xsl:if test="string-length(Description)>0 and not(substring(Description, string-length(Description))='.')">
                <xsl:text>.</xsl:text>
            </xsl:if>
            <xsl:text>&#xa;&#xa;[Tags:</xsl:text>
            <xsl:call-template name="join">
                <xsl:with-param name="src" select="Tags/Tag"/>
                <xsl:with-param name="sep" select="'|'"/>
            </xsl:call-template>
            <xsl:text>]</xsl:text>
        </xsl:variable>
        <xsl:if test="string-length(Description)>0 and count(Tags/Tag)>0">
            <xsd:annotation>
                <xsd:documentation>
                    <xsl:value-of select="$doc"/>
                </xsd:documentation>
            </xsd:annotation>
        </xsl:if>
    </xsl:template>

    <xsl:template match="EndpointInfo">
        <xsl:for-each select="Endpoint[ControlInfo/StateInfo/IsSavedToFile='true']">
            <xsd:attribute name="{Name}">
                <xsl:if test="ControlInfo/StateInfo/Default='None'">
                    <xsl:attribute name="use">required</xsl:attribute>
                </xsl:if>
                <xsl:if test="Description and not(Description='') and not(Description='None')">
                <xsd:annotation>
                    <xsd:documentation>
                        <xsl:value-of select="Description"/>
                    </xsd:documentation>
                </xsd:annotation>
                </xsl:if>
                <xsd:simpleType>
                    <xsd:restriction base="{concat('xsd:',ControlInfo/StateInfo/StateType)}">
                        <xsl:for-each select="ControlInfo/StateInfo[not(StateType='string')]/Constraint/Range/Minimum">
                            <xsd:minInclusive value="{.}"/>
                        </xsl:for-each>
                        <xsl:for-each select="ControlInfo/StateInfo[not(StateType='string')]/Constraint/Range/Maximum">
                            <xsd:maxInclusive value="{.}"/>
                        </xsl:for-each>
                        <xsl:for-each select="ControlInfo/StateInfo/Constraint/AllowedStates/State">
                            <xsd:enumeration value="{.}"/>
                        </xsl:for-each>
                    </xsd:restriction>
                </xsd:simpleType>
            </xsd:attribute>
            <!--
            <Endpoint>
                <Name>mute</Name>
                <Label>Mute</Label>
                <Description>
                    Mute the output of the module.

                    This will cause the module to become silent, but the module will remain active.
                </Description>
                <Type>control</Type>
                <ControlInfo>
                    <ControlType>state</ControlType>
                    <StateInfo>
                        <StateType>integer</StateType>
                        <IsSavedToFile>true</IsSavedToFile>
                        <IsInputFile>false</IsInputFile>
                        <Constraint>
                            <Range>
                                <Minimum>0</Minimum>
                                <Maximum>1</Maximum>
                            </Range>
                        </Constraint>
                        <Default>0</Default>
                    </StateInfo>
                    <CanBeSource>true</CanBeSource>
                    <CanBeTarget>true</CanBeTarget>
                    <IsSentToHost>true</IsSentToHost>
                </ControlInfo>
            </Endpoint>
            -->
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="WidgetInfo"/>

    <xsl:template match="ImplementationInfo" />

    <xsl:template name="join">
        <xsl:param name="src" />
        <xsl:param name="sep" />

        <xsl:value-of select="$src[1]"/>
        <xsl:if test="count($src)>1">
            <xsl:value-of select="$sep"/>
            <xsl:call-template name="join">
                <xsl:with-param name="src" select="$src[position()>1]"/>
                <xsl:with-param name="sep" select="$sep"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>
