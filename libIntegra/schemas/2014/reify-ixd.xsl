<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt"
                xmlns:rixd="http://www.integralive.org/schemas/2014/rixd"
                xmlns:core="http://www.integralive.org/schemas/2014/rixd/core"
                xmlns:native="http://www.integralive.org/schemas/2014/rixd/native"
                xmlns:deprecated="http://www.integralive.org/schemas/2014/rixd/deprecated"
                xmlns:user="http://www.integralive.org/schemas/2014/rixd/user"
                exclude-result-prefixes="msxsl"
>
    <xsl:output method="xml" indent="yes"/>

    <xsl:template match="IntegraCollection">
        <xsl:message>
            <xsl:text>Reifying IntegraCollection IXD node graph:</xsl:text>
        </xsl:message>
        <rixd:ReifiedIntegraCollection>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates select="object"/>
        </rixd:ReifiedIntegraCollection>
    </xsl:template>

    <xsl:template match="object">

        <!-- evaluate reified module name based on originId and nesting level -->
        <xsl:variable name="name">
            <xsl:choose>
                <!-- core modules : ImplementedInLibIntegra = true -->
                <xsl:when test="@originId='b6f7421a-888a-47d7-b266-76a0b6c2b86b'">core:AudioIn</xsl:when>
                <xsl:when test="@originId='171ccd25-cdb0-4003-96d8-ee0d9a0ada37'">core:AudioOut</xsl:when>
                <xsl:when test="@originId='8b1826a1-1a76-d13a-0488-e84b06c97f7f'">core:AudioSettings</xsl:when>
                <xsl:when test="@originId='5dfd7aa5-eed1-4666-9d19-844a5a9912c9'">core:Connection</xsl:when>
                <xsl:when test="@originId='892b7437-a3dc-4a1f-863d-17b4ba973ef1'">
                    <!-- detect the nesting level of the current node -->
                    <xsl:variable name="level">
                        <xsl:value-of select="count(ancestor::*)"/>
                    </xsl:variable>
                    <!-- count how many player nodes there are in the document -->
                    <xsl:variable name="players">
                        <xsl:value-of select="count(//*[@originId='0f9203b8-e091-40f8-8968-4ee96185523f'])"/>
                    </xsl:variable>
                    <!-- note that this logic allows for (currently) illegal depths of container nesting; if there 
                         is a problem in the original document structure, we leave it for the XSD to flag it up 
                         since there may be other issues that premature termination of the transform would obscure
                    -->
                    <xsl:choose>
                        <!-- if no player nodes exist, assume the root element is a block -->
                        <xsl:when test="$players=0">
                            <xsl:choose>
                                <xsl:when test="$level=1">core:BlockContainer</xsl:when>
                                <xsl:otherwise>core:Container</xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <!-- otherwise, assume it's a project -->
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="$level=1">core:ProjectContainer</xsl:when>
                                <xsl:when test="$level=2">core:TrackContainer</xsl:when>
                                <xsl:when test="$level=3">core:BlockContainer</xsl:when>
                                <xsl:otherwise>core:Container</xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="@originId='158ae85a-a9a3-44b2-872e-f920f4543b81'">core:ControlPoint</xsl:when>
                <xsl:when test="@originId='0b78bba4-bb49-46e4-868e-82777f92deae'">core:Envelope</xsl:when>
                <xsl:when test="@originId='0f4bc0a6-9152-ee2f-9ec4-ef9f747d7278'">core:MidiControlInput</xsl:when>
                <xsl:when test="@originId='c264ee51-efc6-29d8-a00b-ac34af2c9c61'">core:MidiRawInput</xsl:when>
                <xsl:when test="@originId='f9cc2c13-7d97-a78d-5048-c7751c8d58d8'">core:MidiSettings</xsl:when>
                <xsl:when test="@originId='0f9203b8-e091-40f8-8968-4ee96185523f'">core:Player</xsl:when>
                <xsl:when test="@originId='bf519e13-c924-4198-bb1a-a1c66b64ac5d'">core:Scaler</xsl:when>
                <xsl:when test="@originId='360a956f-ad89-4e81-a3c6-30ba53e32acc'">core:Scene</xsl:when>
                <xsl:when test="@originId='122fadb9-215e-4bd3-9e11-2ed792ea90b0'">core:Script</xsl:when>
                <xsl:when test="@originId='4ba358bd-1ae9-45da-9876-16a0701f0433'">core:StereoAudioIn</xsl:when>
                <xsl:when test="@originId='2809b248-8194-4269-a168-d9f811d137b7'">core:StereoAudioOut</xsl:when>

                <!-- other native (bundled) modules : ImplementedInLibIntegra = false -->
                <xsl:when test="@originId='99afbf9a-b6b2-443b-8996-1f484e56a606'">native:AddSynth</xsl:when>
		        <xsl:when test="@originId='7335d47d-b1e8-4489-9d6f-f0826cb1bd53'">native:BandPass</xsl:when>
		        <xsl:when test="@originId='ceefdb94-538f-6a01-c0fa-94145d60ccb5'">native:BrightnessAnalyser</xsl:when>
		        <xsl:when test="@originId='3ca6b04e-e68a-42ee-8a14-a59ed33b25b7'">native:Delay</xsl:when>
		        <xsl:when test="@originId='e53d2202-3580-43e0-831d-cd6477df9b16'">native:Distortion</xsl:when>
		        <xsl:when test="@originId='0b78bba4-bb49-46e4-868e-82777f92deae'">native:Envelope</xsl:when>
		        <xsl:when test="@originId='b8e6c4db-6a13-4d5b-8620-7aa8b41e0fbb'">native:EnvelopeFollower</xsl:when>
		        <xsl:when test="@originId='89161bba-da46-4943-a8aa-5c0af9e30781'">native:Flanger</xsl:when>
		        <xsl:when test="@originId='bdcb3977-6070-48af-a45b-d257a6ee2a7a'">native:Flute</xsl:when>
		        <xsl:when test="@originId='08d70538-eab0-4398-b747-ac7e7862ebc9'">native:FourByOneMixer</xsl:when>
		        <xsl:when test="@originId='69742e40-47ad-16fb-ace9-40312dbfb042'">native:Gate</xsl:when>
		        <xsl:when test="@originId='10c3b8ed-75e4-4fc7-8276-27893f022c89'">native:GranularDelay</xsl:when>
		        <xsl:when test="@originId='c6240acc-d050-7ce0-e922-70c64d7f1c56'">native:HarmonicFilter</xsl:when>
		        <xsl:when test="@originId='7c6b0a4a-609d-48fc-b292-5f0093d9f16b'">native:HighPass</xsl:when>
		        <xsl:when test="@originId='f0018b50-848e-416f-848b-8d7dc60ca746'">native:Limiter</xsl:when>
		        <xsl:when test="@originId='c23b5bdc-bc9f-48ca-9b1b-3077d186ce9f'">native:LowPass</xsl:when>
		        <xsl:when test="@originId='babd6d17-9791-4c29-9406-939d96253598'">native:MaterialSimulator</xsl:when>
		        <xsl:when test="@originId='f481d6e7-a0c4-c26c-ee48-f9b6986b31db'">native:MidiCCoutTest</xsl:when>
		        <xsl:when test="@originId='a8f04784-fef2-4ed2-068b-be6c011014ad'">native:MidiStuffTest</xsl:when>
		        <xsl:when test="@originId='a445bbaf-78a7-12db-4dc1-f77bc6f5c532'">native:MultiBandCompressor</xsl:when>
		        <xsl:when test="@originId='a794df90-642a-c8ec-9e18-ec8bd167d6f2'">native:Noisiness</xsl:when>
		        <xsl:when test="@originId='9c5e229c-cfa0-4a9e-99fb-61a8abf3e4d9'">native:Notch</xsl:when>
		        <xsl:when test="@originId='be7f9e0c-4792-4a54-4cef-9ed77b7c35c9'">native:OctoSoundfiler</xsl:when>
		        <xsl:when test="@originId='8cd76d4e-0b1d-4a40-baca-c2011ec84466'">native:OnsetDetector</xsl:when>
		        <xsl:when test="@originId='a12d00ba-279b-56ae-8726-8d6aef14bb6e'">native:PartialAnalyser</xsl:when>
		        <xsl:when test="@originId='bcfb0c97-0476-e9ab-917b-14ad8cba79c3'">native:PerceptualLoudness</xsl:when>
		        <xsl:when test="@originId='fa991702-961d-4a82-bbf7-48606afba694'">native:PercussiveOnsetDetector</xsl:when>
		        <xsl:when test="@originId='a13d6b16-b844-4a13-9ebe-2c97934cc832'">native:Phaser</xsl:when>
		        <xsl:when test="@originId='2fdbe31b-a5ca-493b-b6b8-c91d36aae2ec'">native:PhaseVocoder</xsl:when>
		        <xsl:when test="@originId='9e83ef7a-3b33-4a39-a9db-03bf9b0855bf'">native:PianoReverbMSP</xsl:when>
		        <xsl:when test="@originId='b9138603-194b-4706-beec-7fbc21b1a415'">native:PianoReverbStrings</xsl:when>
		        <xsl:when test="@originId='7fb1ab41-f23f-4ff7-9ac6-4de994769be9'">native:PingPongDelay</xsl:when>
		        <xsl:when test="@originId='ce0380dc-af98-4175-bb09-90c0764f43f4'">native:PitchDetector</xsl:when>
		        <xsl:when test="@originId='9ef1c7b1-87cd-4e43-a623-ab5488b18a71'">native:PitchShifter</xsl:when>
		        <xsl:when test="@originId='b6c4edc9-8ed1-45e8-81e3-8f59aaa29b63'">native:PluckedString</xsl:when>
		        <xsl:when test="@originId='10200818-f2a1-4db8-8976-96d84342d084'">native:QuadAudioIn</xsl:when>
		        <xsl:when test="@originId='e9c394be-2d57-4711-8291-9753a9448a10'">native:QuadAudioOut</xsl:when>
		        <xsl:when test="@originId='ed18e1e1-153d-4a19-87f3-2cfae56bd4b0'">native:QuadAutoPanner</xsl:when>
		        <xsl:when test="@originId='cab5db87-3f8b-441c-9e29-ea83d5c6d728'">native:QuadGranularSynthesizer</xsl:when>
		        <xsl:when test="@originId='9f43aa8c-ad4b-44f9-a5d1-d8e476aecb96'">native:QuadPanner</xsl:when>
		        <xsl:when test="@originId='5c65f5e9-be98-53e7-a083-82a57592cc3c'">native:QuadSoundFiler</xsl:when>
		        <xsl:when test="@originId='618d3bc7-6360-4246-b425-ed4f6c3aa57a'">native:QuadXYPanner</xsl:when>
		        <xsl:when test="@originId='641599c0-5157-45e4-8be0-9ded155112fb'">native:ResonantBandPass</xsl:when>
		        <xsl:when test="@originId='9467b6ca-05a2-4c88-a830-502025c00fd5'">native:ResonantLowPass</xsl:when>
		        <xsl:when test="@originId='eb5dd331-0516-453d-81a0-25f254d5a58c'">native:Reverb</xsl:when>
		        <xsl:when test="@originId='b4cabc6b-5c06-498b-a3df-643f93fe225f'">native:RingModulator</xsl:when>
		        <xsl:when test="@originId='0d9bae67-a1d3-41d5-9dfd-6bd4971bc5b4'">native:Soundfiler</xsl:when>
		        <xsl:when test="@originId='ec65b788-e410-8c58-106b-954bbd0e1e85'">native:SPAT</xsl:when>
		        <xsl:when test="@originId='da7a7720-c428-4cbc-a09e-c16ec0456ffe'">native:SpectralDelay</xsl:when>
		        <xsl:when test="@originId='8e27c8d8-ed63-48c4-9dcd-f87e418e0e2d'">native:SpectralFreeze</xsl:when>
		        <xsl:when test="@originId='2e25b243-6c60-4632-b66f-a7dff1e4bb45'">native:SpectralVocoder</xsl:when>
		        <xsl:when test="@originId='717de99c-b259-a910-33aa-f7907fdb6840'">native:StereoChorus</xsl:when>
		        <xsl:when test="@originId='f5597948-2cf4-4c46-a139-51163ad362c8'">native:StereoConvolution</xsl:when>
		        <xsl:when test="@originId='60c751c3-dbdb-485c-99d5-8b464796d6b9'">native:StereoGranularSynthesizer</xsl:when>
		        <xsl:when test="@originId='7367e797-b7c5-485c-bd4b-e983ad31a850'">native:StereoPanner</xsl:when>
		        <xsl:when test="@originId='78a8ceb5-59dd-4712-9603-2db189ce17ca'">native:StereoReverb</xsl:when>
		        <xsl:when test="@originId='3a92cb19-50dc-45cb-a48a-7c071bc31e12'">native:StereoReverbTwo</xsl:when>
		        <xsl:when test="@originId='fa3f8bc6-b9d8-be0f-5173-9190d252be63'">native:StereoSoundfiler</xsl:when>
		        <xsl:when test="@originId='cca29950-bfef-41d4-843f-1290ca2b412b'">native:SubSynth</xsl:when>
		        <xsl:when test="@originId='6da5f172-d615-4014-8309-1035f0c3aade'">native:TapDelay</xsl:when>
		        <xsl:when test="@originId='994e450c-cd7a-549a-3464-c90db70acb50'">native:TempoDetector</xsl:when>
		        <xsl:when test="@originId='c12680da-12c4-44c7-9b9b-5c24c322e812'">native:TestSource</xsl:when>
		        <xsl:when test="@originId='aea84321-cf05-4288-9957-1d2c4fe41798'">native:VibratoChorus</xsl:when>
                
                <!-- deprecated module origins, as found listed in id2guid.csv and in some IXD samples -->
                <xsl:when test="@originId='cb718748-f1ac-44fe-abbc-a997bcf06fe4'">deprecated:Midi</xsl:when>
                <xsl:when test="@originId='0e699345-6d14-4c89-a9ff-dec4f8a21a6f'">deprecated:Unknown</xsl:when>
                <xsl:when test="@originId='191858dd-61d0-4fe3-9946-9c3c00842174'">deprecated:Unknown</xsl:when>
                <xsl:when test="@originId='28584ef7-5652-4857-ac6a-767bcf647bfe'">deprecated:Unknown</xsl:when>
                <xsl:when test="@originId='2ab5d844-551e-4447-9436-854d8986a58a'">deprecated:Unknown</xsl:when>
                <xsl:when test="@originId='4146310b-c814-440c-a0b1-c3017a4df1e4'">deprecated:Unknown</xsl:when>
                <xsl:when test="@originId='4f183815-2645-460c-954c-720ab7cf4dee'">deprecated:Unknown</xsl:when>
                <xsl:when test="@originId='706263e4-4655-4f94-b960-17e72975559d'">deprecated:Unknown</xsl:when>
                <xsl:when test="@originId='7eb44525-a4a1-4a52-bb46-23300a826b58'">deprecated:Unknown</xsl:when>
                <xsl:when test="@originId='98ead0ea-7fe7-42c6-8f87-e8a178cfd83b'">deprecated:Unknown</xsl:when>
                <xsl:when test="@originId='9aee9d2c-87e7-4ee0-9a4d-36e11732ba37'">deprecated:Unknown</xsl:when>
                <xsl:when test="@originId='a7498f8b-afc3-4f2f-9b09-54437078f15b'">deprecated:Unknown</xsl:when>
                <xsl:when test="@originId='c42d4daf-c4db-417a-b3f8-64529ea0af16'">deprecated:Unknown</xsl:when>

                <!-- unknown modules -->
                <xsl:otherwise>user:Unknown</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- generate an indented message to indicate that this node is being parsed -->
        <xsl:message>
            <xsl:variable name="padding" xml:space="preserve"><xsl:for-each select="ancestor::*">  </xsl:for-each></xsl:variable>
            <xsl:value-of select="concat($padding,'o parsed node &quot;',@name,'&quot; (',$name,')')"/>
        </xsl:message>

        <!-- transformation output -->
        <xsl:element name="{$name}">
            <!-- render 'name' attribute first (for readability) -->
            <xsl:copy-of select="@name"/>
            <xsl:choose>
                <xsl:when test="contains($name,':Unknown')">
                    <!-- render all other attributes (including originId/moduleId for ease of debugging) -->
                    <xsl:copy-of select="@*[not(name()='name')]"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- output all other attributes, with the following exceptions:
                           * originId - since this is implicit in the node name
                           * moduleId - as we're not currently performing any implementation-specific validation checks
                      -->
                    <xsl:copy-of select="@*[not(name()='name' or name()='originId' or name()='moduleId')]"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- render any "attribute" elements next, as they will appear as attributes in the transformed document, so must precede any rendered elements -->
            <xsl:apply-templates select="attribute[not(@name='userData' or @name='info')]"/>
            <!-- finally, render any "object" child elements -->
            <xsl:apply-templates select="object"/>
        </xsl:element>

    </xsl:template>
    
    <xsl:template match="attribute">
        <!-- render the IXD "attribute" element as an XML attribute, whose name is taken from the source element's @name attribute, and its value from the source element's content -->
        <xsl:attribute name="{@name}">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

</xsl:stylesheet>
