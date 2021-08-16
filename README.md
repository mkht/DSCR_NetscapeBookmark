DSCR_NetscapeBookmark
====

DSC Resource to create Netscape format bookmark file.

----
## Installation
You can install from [PowerShell Gallery](https://www.powershellgallery.com/packages/DSCR_NetscapeBookmark/).
```Powershell
Install-Module -Name DSCR_NetscapeBookmark
```

----
### Examples

#### Example configuration
```Powershell
Configuration Example1
{
    Import-DscResource -ModuleName DSCR_NetscapeBookmark
    
    NetscapeBookmarkFolder FolderSample
    {
        Ensure = 'Present'
        Path = 'C:\bookmark.html'   # Key property
        Title = 'Bookmark Folder'   # Key property
        AddDate = [datetime]'2021/8/1 12:00:00'
        ModifiedDate = [datetime]'2021/8/1 12:00:00'
        Attributes = @{'PERSONAL_TOOLBAR_FOLDER' = 'true'}
    }

    NetscapeBookmarkLink GoogleLink
    {
        Ensure = 'Present'
        Path = 'C:\bookmark.html'       # Key property
        Folder = 'Bookmark Folder'      # Key property
        Title = 'Google'                # Key property
        Url = 'https://www.google.com/' # Require property
        AddDate = [datetime]'2021/8/1 12:00:00'
        ModifiedDate = [datetime]'2021/8/1 12:00:00'
        IconData = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=='
    }
}
```

#### Output
```html
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!-- This is an automatically generated file.
     It will be read and overwritten.
     DO NOT EDIT! -->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
    <DT><H3 ADD_DATE="1627786800" LAST_MODIFIED="1627786800" PERSONAL_TOOLBAR_FOLDER="true">Bookmark Folder</H3>
    <DL><p>
        <DT><A HREF="https://www.google.com/" ADD_DATE="1627786800" LAST_MODIFIED="1627786800" ICON="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==">Google</A>
    </DL><p>
</DL><p>
```

----
## ChangeLog
### 1.0.0
 + First public release


----
## Libraries
This software uses below libraries.

+ [Dissimilis/BookmarksManager](https://github.com/Dissimilis/BookmarksManager)
    - Copyright (c) 2014 Marius Vitkevičius
      Licensed under the **MIT License**.  
      https://github.com/Dissimilis/BookmarksManager/blob/master/LICENSE
