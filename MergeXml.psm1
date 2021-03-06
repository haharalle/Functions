<#
    Script     : MergeXml
    Author     : Riwut Libinuko
    Blog       : http://blog.libinuko.com
    Copyright© 2011, Riwut Libinuko (IdeasFree - cakriwut@gmail.com). All Rights Reserved.    
#>

function Merge-XmlFile
{
<#
.SYNOPSIS
Merge source XML file to target XML file and update only modified element. 
		
.DESCRIPTION
The function takes Xml filepath and merge the content to Xml filepath output. It is usuful to merge any 
XML's like file, such as .proj, web.config, app.config.
In that case you will be able to package only the essential element, and this function will merge it 
automatically. The old Xml target file will be stored as a backup file.
    
.INPUTS
None. You can not pipe objects to Merge-XmlFile
	
.OUTPUTS
None. No output from Merge-XmlFile
		
.PARAMETER sourceXmlFile
MANDATORY parameter to specify the source Xml filename. 
	
.PARAMETER targetXmlFile
MANDATORY parameter to specify target Xml filename.
        	
.EXAMPLE
    PS>  Merge-XmlElement "additionalweb.config" "web.config"
			

	Description
	-----------
	Update web.config based on additionalweb.config content. The function will search and update according the the tag,
    attribute and element.
    When there is doubt in the Xml, you have to specify Select keyword to select specific key, or
    Remove keyword to remove specific key. For example appSettings section in the web.config, as follows
    
    Example: 
    additionalweb.config
    <configuration>
       <appSettings>
         <!--Select=add[@key='Keyword']-->
         <add key="Keyword" value="SharePoint,PowerShell" />
         <!--Remove=add[@key='OldKeyword']-->
         <add key="OldKeyword" value="SharePoint 2007" />
       </appSettings>
    </configuration>
    
    web.config
    <configuration>
       <appSettings>
         <add key="Keyword" value="SharePoint 2007,PowerShell" />         
         <add key="OldKeyword" value="SharePoint 2007" />
       </appSettings>
    </configuration>
    
    After the operation, web.config will become
    <configuration>
       <appSettings>
         <add key="Keyword" value="SharePoint,PowerShell" />                  
       </appSettings>
    </configuration>
    
		            
.LINK
    Author blog  : IdeasForFree  (http://blog.libinuko.com)
.LINK
    Author email : cakriwut@gmail.com
#>
   param ( 
        [Parameter(Mandatory=$true,Position=0)]            
        $sourceXmlFile, 
        [Parameter(Mandatory=$true,Position=1)]       
        $targetXmlfile 
  )
  
  if(!(test-path $sourceXmlFile))
  {
    write-host "Can not find source XML file. $sourceXmlFile."
  }
  if(!(test-path $targetXmlfile))
  {
    write-host "Can not find target XML file. $targetXmlFile."
  }
   
   $target = gi $targetXmlfile
   $backup = (join-path $target.Directory $target.BaseName) + "_" + (get-date).tostring("yyyy_MM_dd_hh_mm_ss") + ".bak"  
  
   $xmlSource = [xml](get-content $sourceXmlFile)  
   $xmlTarget = [xml](get-content $targetXmlfile)
   #save backup
   $xmlTarget.Save($backup)
   
   $SourceElement = $xmlSource.get_Documentelement()
   $TargetElement = $xmlTarget.get_DocumentElement() 
  
   Merge-XmlElement $SourceElement $TargetElement
   
   #save backup
   $xmlTarget.Save($targetXmlFile)
}

function Merge-XmlElement 
{ 
<#
.SYNOPSIS
Merge source XML element to target XML element and update only modified element. 
		
.DESCRIPTION
The function takes XmlElement input and merge the content to XmlElement output. It is usuful to merge any XML's like file, such as .proj, web.config, app.config.
In that case you will be able to package only the essential element, and this function will merge it automatically.
    
.INPUTS
None. You can not pipe objects to Merge-XmlElement
	
.OUTPUTS
None. No output from Merge-XmlElement
		
.PARAMETER sourceElement
MANDATORY parameter to specify the source Xml element. 
	
.PARAMETER targetElement
MANDATORY parameter to specify target Xml element.
        	
.EXAMPLE
    PS>  $xmlWebConfig = [xml](get-content "web.config")  
    PS>  $xmlUpdateWebConfig = [xml](get-content "additionalweb.config")
	PS>  $targetRoot = $xmlWebConfig.get_DocumentElement()
    PS>  $sourceRoot = $xmlUpdateWebConfig.get_DocumentElement()
    PS>  Merge-XmlElement $sourceRoot $targetRoot
			

	Description
	-----------
	Update web.config based on additionalweb.config content. The function will search and update according the the tag, attribute and element.
    When there is doubt in the Xml, for example appSettings section in the web.config, you have to specify Select keyword to select specific key, or
    Remove keyword to remove specific key.
    
    Example: 
    additionalweb.config
    <configuration>
       <appSettings>
         <!--Select=add[@key='Keyword']-->
         <add key="Keyword" value="SharePoint,PowerShell" />
         <!--Remove=add[@key='OldKeyword']-->
         <add key="OldKeyword" value="SharePoint 2007" />
       </appSettings>
    </configuration>
    
    web.config
    <configuration>
       <appSettings>
         <add key="Keyword" value="SharePoint 2007,PowerShell" />         
         <add key="OldKeyword" value="SharePoint 2007" />
       </appSettings>
    </configuration>
    
    After the operation, web.config will become
    <configuration>
       <appSettings>
         <add key="Keyword" value="SharePoint,PowerShell" />                  
       </appSettings>
    </configuration>
    
		            
.LINK
    Author blog  : IdeasForFree  (http://blog.libinuko.com)
.LINK
    Author email : cakriwut@gmail.com
#>
  param ( 
        [Parameter(Mandatory=$true,Position=0)]
        [System.Xml.XmlElement]                    
        $sourceElement,
        [Parameter(Mandatory=$true,Position=1)]
        [System.Xml.XmlElement]        
        $targetElement 
  )
    
  if ($sourceElement.get_Name() -ne $targetElement.get_Name()) 
  { 
    write-host "Source element name $($sourceElement.get_Name()) and target element name $($targetElement.get_Name()) do not match" 
    return
  } 
     
  if (-not $sourceElement.get_HasChildNodes()) { return } 
  
  $sourceChildren = $sourceElement.get_Childnodes() 
  $targetChildren = $targetElement.get_Childnodes()
  $prevChild = $null
  
  foreach ($sourceChild in $sourceChildren) 
  {     
     if ($sourceChild.get_Name() -eq "#comment") 
     { 
       $prevChild = $sourceChild       
       continue 
     }
              
     $matchingNode = $False 
     $targetChild = $Null 
     $select = $False
     $remove = $False
     
     foreach ($child in $targetChildren )
     {
        $targetChild = $child
        if(($select = ($prevChild -and $prevChild.Value.StartsWith("Select="))) `
            -or ($remove = ($prevChild -and $prevChild.Value.StartsWith("Remove=")))) { break; }        
                            
        if ($sourceChild.get_Name() -eq $targetChild.get_Name())
        {         
            OverrideAttribute $sourceChild $targetChild
            $matchingNode = $True
            break;       
         }       
     } #end foreach TargetChildren
                 
     if ($matchingNode -eq $False) 
     { 
        if($select)
        {            
           if(($selectedElement = $targetElement.SelectSingleNode($prevChild.Value.Trim().Remove(0,7))))
           {
              OverrideAttribute $sourceChild $selectedElement
           } else {
              AppendElement $sourceChild $targetElement
           }
         } elseif($remove)
         {
           if(($selectedElement = $targetElement.SelectSingleNode($prevChild.Value.Trim().Remove(0,7))))
           {
              write-host "Removing element " $selectedElement.OuterXml
              $selectedElement.RemoveAll()
           }
         } else 
         {
            AppendElement $sourceChild $targetElement
         }

      } else { 
         if($sourceChild.get_HasChildNodes()) {
            Merge-XmlElement $sourceChild $targetChild
             }
      }               
      $prevChild = $null
   } #end foreach SourceChildren
   
}

function OverrideAttribute
{
   param(
      $Source,
      $Target
   )
   
   foreach($SourceAttribute in $Source.get_Attributes())
   {
      if($SourceAttribute.get_Value() -ne $Target.GetAttribute($SourceAttribute.get_Name())) 
      {
          write-host "Override attribute " $SourceAttribute.get_Name() "," $Target.GetAttribute($SourceAttribute.get_Name()) "=>" $SourceAttribute.get_Value() 
      }
      $Target.SetAttribute($SourceAttribute.get_Name(),$SourceAttribute.get_Value())
   }
}

function AppendElement
{
   param (
       $Source,
       $Target
   )
   $NewElement = $Source.CloneNode($True)
   $Target.AppendChild($Target.get_OwnerDocument().ImportNode($NewElement,$True))
   $Target.Normalize()
}

