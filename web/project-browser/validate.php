<?php
if($_SERVER['REQUEST_METHOD']=="GET")
{
  ?>
   <html>
      <head>
        <title>Integra Labs | Project Validator (prototype)</title>
        <!--
        <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css"/>
        -->
        <link rel="stylesheet" href="css/bootstrap.min.css"/>
        <link rel="stylesheet" href="css/default.css"/>
      </head>
    <body>
    <h2>Project Validator <small>(prototype)</small></h2>
    <form action="validate.php" method="post" enctype="multipart/form-data">
      <input type="file" name="file" id="file">
      <br/>
      <input type="submit" name="submit" value="Validate"/>
    </form>
  </body>
</html>
  <?php
}
else
{
  $f = $_FILES["file"];

  $name = $f["name"];
  $tmp = $f["tmp_name"];
  $type = $f["type"];
  $size = $f["size"];
  $error = $f["error"];

  $pathinfo = pathinfo($name);
  $filename = $pathinfo['filename'];
  $extension = $pathinfo['extension'];

  if($extension!="integra")
  {
    echo "Invalid extension ".$extension;
  }
  else if($type!="application/octet-stream")
  {
    echo "Invalid content ".$type;
  }
  else if ($error>0) {
    echo "Return code: ".$error;
  }
  else
  {
    // extract .integra file to relevant data folder
    if(!file_exists("data/".$filename))
    {
      $zip = new ZipArchive;
      $data = $zip->open($tmp);
      if ($data)
      {
        $zip->extractTo("data/".$filename);
        $zip->close();
      }
    }

    if(!file_exists("data/".$filename.".modules.xml"))
    {
      // generate module index
      $nl = "\r\n";
      $modules  = '<?xml version="1.0" encoding="UTF-8"?>'.$nl;
      $modules .= '<?xml-stylesheet type="text/xsl" href="../xsl/module-list.xsl"?>'.$nl;
      $modules .= '<IntegraModules>'.$nl;
      $modules .= '  <!-- default modules included with Integra Live -->'.$nl;
      $modules .= '  <collection src="Integra%20Live">'.$nl; 
      foreach(scandir("data/Integra Live/") as $module)
      {
        if($module=="." || $module=="..") continue;
        if(!is_dir("data/Integra Live/".$module)) continue;

        $iid_file = "data/Integra Live/".$module."/integra_module_data/interface_definition.iid";
        $iid = simplexml_load_file($iid_file);

        $modules .= '    <module';
        $modules .= ' name="'.$module.'"';
        $modules .= ' moduleGuid="'.$iid["moduleGuid"].'"';
        $modules .= ' originGuid="'.$iid["originGuid"].'"';
        $modules .= '/>'.$nl;
      }
      $modules .= '  </collection>'.$nl;
      $modules .= '  <!-- default modules included with project "'.$filename.'"" -->'.$nl;
      $modules .= '  <collection src="'.str_replace(' ','%20',$filename).'">'.$nl;

      foreach(scandir("data/".$filename."/integra_data/implementation/") as $module)
      {
        if($module=="." || $module=="..") continue;
        $root = "data/".$filename."/integra_data/implementation/";
        $pathinfo = pathinfo($module);
                                                                // we can skip:
        if(is_dir($root.$module)) continue;                     //  * directories
        if($pathinfo["extension"]!="module") continue;          //  * non-module files
        if(file_exists($root.$pathinfo["filename"])) continue;  //  * modules already unzipped

        $zip = new ZipArchive;
        $data = $zip->open($root.$module);
        if ($data)
        {
          $zip->extractTo($root.$pathinfo["filename"]);
          $zip->close();
        }
      }

      foreach(scandir("data/".$filename."/integra_data/implementation/") as $module)
      {
        if($module=="." || $module=="..") continue;
        $root = "data/".$filename."/integra_data/implementation/";

        if(!is_dir($root.$module)) continue;                             // skip files
        $iid_file = $root.$module."/integra_module_data/interface_definition.iid";
        $iid = simplexml_load_file($iid_file);

        $modules .= '    <module';
        $modules .= ' name="'.$module.'"';
        $modules .= ' moduleGuid="'.$iid["moduleGuid"].'"';
        $modules .= ' originGuid="'.$iid["originGuid"].'"';
        $modules .= '/>'.$nl;
      }
      $modules .= '  </collection>'.$nl;
      $modules .= '</IntegraModules>';

      file_put_contents("data/".$filename.".modules.xml", $modules);
    }

    $server_side = FALSE;

    if($server_side)
    {
      echo "Sorry, server-side validation is not yet supported";
      //$xml = simplexml_load_file("data/".$filename."/integra_data/nodes.ixd");
      //$xmlData = $xml->asXML();
      //$xslt = new xsltProcessor;
      //$xslt->importStyleSheet(DomDocument::load('xsl/default.xsl'));
      //print $xslt->transformToXML(DomDocument::loadXML($xmlData));
    } else {
      header('Content-Type: application/xml');
      echo '<?xml version="1.0" encoding="UTF-8"?>';
      echo '<?xml-stylesheet type="text/xsl" href="xsl/default.xsl"?>';
      echo '<root project="'.$filename.'"/>';
    }
  }  
}

?>