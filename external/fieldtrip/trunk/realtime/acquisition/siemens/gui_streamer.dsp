# Microsoft Developer Studio Project File - Name="gui_streamer" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=gui_streamer - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "gui_streamer.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "gui_streamer.mak" CFG="gui_streamer - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "gui_streamer - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "gui_streamer - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "gui_streamer - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD BASE RSC /l 0x809 /d "NDEBUG"
# ADD RSC /l 0x809 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386

!ELSEIF  "$(CFG)" == "gui_streamer - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /GZ /c
# ADD BASE RSC /l 0x809 /d "_DEBUG"
# ADD RSC /l 0x809 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept

!ENDIF 

# Begin Target

# Name "gui_streamer - Win32 Release"
# Name "gui_streamer - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\Brain3dWindow.cc
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\FolderWatcher.cc
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\gui_buffer_client.cc
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\gui_streamer.cc
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\nifti2matlab.c
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\nii_to_buffer.cc
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\opengl_client.cc
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\pixeldata_to_remote_buffer.cc
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\PixelDataGrabber.cc
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\sap2matlab.c
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\sap2nifti.c
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\save_as_nifti.c
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\siemensap.c
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\testFolderWatcher.cc
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\unixtime.c
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\Brain3dWindow.h
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\FolderWatcher.h
# End Source File
# Begin Source File

SOURCE=..\realtime\buffer\cpp\FtBuffer.h
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\nifti1.h
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\PixelDataGrabber.h
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\siemensap.h
# End Source File
# Begin Source File

SOURCE=..\realtime\buffer\cpp\SimpleStorage.h
# End Source File
# Begin Source File

SOURCE=..\realtime\acquisition\siemens\unixtime.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# End Group
# End Target
# End Project
