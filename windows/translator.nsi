#--------------------------------------------------------------------------
#
# translator.nsi --- This NSIS script is used to create a special version
#                    of the POPFile Windows installer. This test program does not
#                    install POPFile, it only installs a few files and allows
#                    buckets to be created - it is designed to provide a realistic
#                    testbed for the POPFile Installer/Uninstaller language files.
#
# Copyright (c) 2001-2003 John Graham-Cumming
#
#   This file is part of POPFile
#
#   POPFile is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   POPFile is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with POPFile; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#--------------------------------------------------------------------------
#
# This NSIS script can be compiled on a system which does NOT have Perl installed.
#
# To compile this script, the following additional POPFile CVS files are required:
#
#   engine\license
#   engine\otto.gif
#   engine\popfile.pl
#   engine\stopwords
#
#   engine\languages\English.msg
#   engine\languages\*.msg              (optional)
#
#   windows\CBP.nsh
#   windows\hdr-common.bmp
#   windows\ioA.ini
#   windows\ioB.ini
#   windows\ioC.ini
#   windows\pfi-library.nsh
#   windows\remove.ico
#   windows\special.bmp
#
#   windows\translator.change           (the 'release notes' text file for this test program)
#   windows\translator.htm              (a simple HTML file used to represent the POPFile UI)
#   windows\translator.nsi              (this file; included to show its relative position)
#
#   windows\languages\English-mui.nsh
#   windows\languages\English-pfi.nsh
#   windows\languages\*-mui.nsh         (optional - see the 'LANGUAGE SUPPORT' comment below)
#   windows\languages\*-pfi.nsh         (optional - see the 'LANGUAGE SUPPORT' comment below)
#
#   windows\POPFileIcon\popfile.ico
#
#   windows\UI\pfi_headerbmpr.exe
#
# This test program does NOT install POPFile or make any Outlook Express configuration changes.
#
# The only files unique to this test program are 'translator.change', 'translator.htm' and
# 'translator.nsi' - all of the other files are also used in the real POPFile installer.
#
#--------------------------------------------------------------------------

; As of 9 August 2003, the latest release of the NSIS compiler is 2.0b3. Since its release in
; March 2003, the compiler has been greatly improved. This script uses many of the improvements
; introduced since then. Although the NSIS compiler has been updated to 2.0b4 (CVS), the only
; way to obtain this version is to install the 2.0b3 release and then apply some CVS updates.
;
; There are two ways to apply these CVS updates:
;
; (a) use the 'NSIS Update' feature provided by the 'NSIS Menu', or
;
;(b) obtain a NSIS 'Nightly' CVS update and use it to upgrade the 2.0b3 installation.
;
; The 'NSIS Update' feature does not work reliably at the moment, due to SourceForge.net's
; current CVS server problems, so the quickest way to update NSIS to 2.0b4 (CVS) is by means
; of the snapshot which is a ZIP file created several times a day from data on the 'real' CVS
; servers (so it is NOT subject to the same problems as the 'NSIS Update' feature).
;
; This version of the script has been tested with NSIS 2.0b4 (CVS) after updating it by using
; the 11 August 2003 (19:44 GMT) version of the NSIS CVS snapshot.

#--------------------------------------------------------------------------
# LANGUAGE SUPPORT:
#
# The test program defaults to multi-language mode ('English' plus a number of other languages).
#
# If required, a command-line switch can be used to build an English-only version.
#
# Normal multi-language build command:  makensis.exe translator.nsi
# To build an English-only version:     makensis.exe  /DENGLISH_ONLY translator.nsi
#
#--------------------------------------------------------------------------
# Removing support for a particular language:
#
# To remove any of the additional languages, only TWO lines need to be commented-out:
#
# (a) comment-out the relevant '!insertmacro PFI_LANG_LOAD' line in the list of languages
#     in the 'Language Support for the installer and uninstaller' block of code
#
# (b) comment-out the relevant '!insertmacro UI_LANG_CONFIG' line in the list of languages
#     in the code which handles the 'UI Languages' component
#
# For example, to remove support for the 'Dutch' language, comment-out the line
#
#     !insertmacro PFI_LANG_LOAD "Dutch"
#
# in the list of languages supported by the installer, and comment-out the line
#
#     !insertmacro UI_LANG_CONFIG "DUTCH" "Nederlands"
#
# in the code which handles the 'UI Languages' component (Section "Languages").
#
#--------------------------------------------------------------------------
# Adding support for a particular language (it must be supported by NSIS):
#
# The number of languages which can be supported depends upon the availability of:
#
#     (1) an up-to-date main NSIS language file ({NSIS}\Contrib\Language files\*.nlf)
# and
#     (2) an up-to-date NSIS MUI Language file ({NSIS}\Contrib\Modern UI\Language files\*.nsh)
#
# To add support for a language which is already supported by the NSIS MUI package, two files
# are required:
#
#   <NSIS Language NAME>-mui.nsh  - holds customised versions of the standard MUI text strings
#                                   (eg removing the 'reboot' reference from the 'Welcome' page)
#
#   <NSIS Language NAME>-pfi.nsh  - holds strings used on the custom pages and elsewhere
#
# Once these files have been prepared and placed in the 'windows\languages' directory with the
# other *-mui.nsh and *-pfi.nsh files, add a new '!insertmacro PFI_LANG_LOAD' line to load these
# two new files and, if there is a suitable POPFile UI language file for the new language,
# add a suitable '!insertmacro UI_LANG_CONFIG' line in the section which handles the optional
# 'Languages' component to allow the installer to select the appropriate UI language.
#--------------------------------------------------------------------------
# NOTE:
# This source file is a modified version of the 'real thing' so some comments may refer to
# actions which are not applicable to this test program. For example, this test program
# does not shutdown an existing version of POPFile or install/startup a new version of POPFile.
#--------------------------------------------------------------------------

  ;--------------------------------------------------------------------------
  ; POPFile constants have been given names beginning with 'C_' (eg C_README)
  ;--------------------------------------------------------------------------

  !define MUI_PRODUCT       "PFI Testbed"

  !ifndef ENGLISH_ONLY
    !define MUI_VERSION     "0.6.0 (ML)"
  !else
    !define MUI_VERSION     "0.6.0 (English)"
  !endif

  !define C_README          "translator.change"
  !define C_RELEASE_NOTES   "${C_README}"

#--------------------------------------------------------------------------
# Delays (in milliseconds) used to simulate installation and uninstall activities
#--------------------------------------------------------------------------

  !define C_INST_PROG_UPGRADE_DELAY   2000
  !define C_INST_PROG_CORE_DELAY      2500
  !define C_INST_PROG_PERL_DELAY      2500
  !define C_INST_PROG_SHORT_DELAY     2500
  !define C_INST_PROG_SKINS_DELAY     2500
  !define C_INST_PROG_LANGS_DELAY     2500

  !define C_INST_RUN_BANNER_DELAY     2500

  !define C_UNINST_PROGRESS_1_DELAY   2500
  !define C_UNINST_PROGRESS_2_DELAY   2500
  !define C_UNINST_PROGRESS_3_DELAY   2500
  !define C_UNINST_PROGRESS_4_DELAY   2500
  !define C_UNINST_PROGRESS_5_DELAY   2500
  !define C_UNINST_PROGRESS_6_DELAY   2500

#------------------------------------------------
# Define PFI_VERBOSE to get more compiler output
#------------------------------------------------

; !define PFI_VERBOSE

#-----------------------------------------------------------------------------------------
# "Dummy" constants to avoid NSIS compiler warnings (used by macros in 'pfi-library.nsh')
#-----------------------------------------------------------------------------------------

  !define C_SHUTDOWN_LIMIT   10
  !define C_SHUTDOWN_DELAY   500
  !define C_STARTUP_LIMIT    10
  !define C_STARTUP_DELAY    500

#--------------------------------------------------------------------------
# Use the "Modern User Interface" and standard NSIS Section flag utilities
#--------------------------------------------------------------------------

  !include "MUI.nsh"
  !include "Sections.nsh"

#--------------------------------------------------------------------------
# Version Information settings (for the installer EXE and uninstaller EXE)
#--------------------------------------------------------------------------

  ; 'VIProductVersion' format is X.X.X.X where X is a number in range 0 to 65535
  ; representing the following values: Major.Minor.Release.Build

  VIProductVersion "0.6.0.0"

  VIAddVersionKey "ProductName" "POPFile Installer Language Testbed"
  VIAddVersionKey "Comments" "POPFile Homepage: http://popfile.sf.net"
  VIAddVersionKey "CompanyName" "POPFile Team"
  VIAddVersionKey "LegalCopyright" "� 2001-2003  John Graham-Cumming"
  VIAddVersionKey "FileDescription" "POPFile Installer Language Testbed"
  VIAddVersionKey "FileVersion" "${MUI_VERSION}"

  VIAddVersionKey "Build Date/Time" "${__DATE__} @ ${__TIME__}"
  VIAddVersionKey "Build Script" "${__FILE__}$\r$\n(${__TIMESTAMP__})"

  !ifndef ENGLISH_ONLY
    VIAddVersionKey "Build Type" "Multi-Language Testbed"
  !else
    VIAddVersionKey "Build Type" "English-Only Testbed"
  !endif

#----------------------------------------------------------------------------------------
# CBP Configuration Data (to override defaults, un-comment the lines below and modify them)
#----------------------------------------------------------------------------------------
#   ; Maximum number of buckets handled (in range 2 to 8)
#
#   !define CBP_MAX_BUCKETS 8
#
#   ; Default bucket selection (use "" if no buckets are to be pre-selected)
#
#   !define CBP_DEFAULT_LIST "inbox|spam|personal|work"
#
#   ; List of suggestions for bucket names (use "" if no suggestions are required)
#
#   !define CBP_SUGGESTION_LIST \
#   "admin|business|computers|family|financial|general|hobby|inbox|junk|list-admin|\
#   miscellaneous|not_spam|other|personal|recreation|school|security|shopping|spam|\
#   travel|work"
#----------------------------------------------------------------------------------------
# Make the CBP package available
#----------------------------------------------------------------------------------------

  !include CBP.nsh

#--------------------------------------------------------------------------
# Include private library functions and macro definitions
#--------------------------------------------------------------------------

  !include pfi-library.nsh

#--------------------------------------------------------------------------
# Define the Page order for the installer (and the uninstaller)
#--------------------------------------------------------------------------

  ; Installer Pages

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY
  Page custom SetOptionsPage "CheckPortOptions"
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro CBP_PAGE_SELECTBUCKETS
  Page custom SetOutlookExpressPage
  Page custom StartPOPFilePage "CheckLaunchOptions"
  !insertmacro MUI_PAGE_FINISH

  ; Uninstaller Pages

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

#--------------------------------------------------------------------------
# Configure the MUI pages
#--------------------------------------------------------------------------
  ;-----------------------------------------
  ; General Settings - License Page Settings
  ;-----------------------------------------

  ; Three styles of 'License Agreement' page are available:
  ; (1) New style with an 'I accept' checkbox below the license window
  ; (2) New style with 'I accept/I do not accept' radio buttons below the license window
  ; (3) Classic style with the 'Next' button replaced by an 'Agree' button
  ;     (to get the 'Classic' style, comment-out the CHECKBOX and the RADIOBUTTONS 'defines')

  !define MUI_LICENSEPAGE_CHECKBOX
#  !define MUI_LICENSEPAGE_RADIOBUTTONS

  ;-----------------------------------------
  ; General Settings - Finish Page Settings
  ;-----------------------------------------

  ; Offer to display the POPFile User Interface (The 'CheckRunStatus' function ensures this
  ; option is only offered if the installer has started POPFile running)

  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_FUNCTION "RunUI"

  ; Display the Release Notes for this version of POPFile

  !define MUI_FINISHPAGE_SHOWREADME
  !define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
  !define MUI_FINISHPAGE_SHOWREADME_FUNCTION "ShowReadMe"

  ; Debug aid: Allow log file checking (by clicking "Show Details" button on the "Install" page)

  !define MUI_FINISHPAGE_NOAUTOCLOSE

  ;-----------------------------------------
  ; General Settings - Other Settings
  ;-----------------------------------------

  ; Show a message box with a warning when the user closes the installation

  !define MUI_ABORTWARNING

  ;-----------------------------------------
  ; Interface Settings
  ;-----------------------------------------

  ; The 'hdr-common.bmp' logo is only 90 x 57 pixels, much smaller than the 150 x 57 pixel
  ; space provided by the default 'modern_headerbmpr.exe' UI, so we use a custom UI which
  ; leaves more room for the TITLE and SUBTITLE text.

  !define MUI_UI_HEADERBITMAP_RIGHT "UI\pfi_headerbmpr.exe"

  ; The "Special" bitmap appears on the "Welcome" and "Finish" pages,
  ; the "Header" bitmap appears on the other pages of the installer.

  !define MUI_SPECIALBITMAP "special.bmp"
  !define MUI_HEADERBITMAP "hdr-common.bmp"
  !define MUI_HEADERBITMAP_RIGHT

  ; The icon files for the installer and uninstaller must have the same structure. For example,
  ; if one icon file contains a 32x32 16-colour image and a 16x16 16-colour image then the other
  ; file cannot just contain a 32x32 16-colour image, it must also have a 16x16 16-colour image.

  !define MUI_ICON    "POPFileIcon\popfile.ico"
  !define MUI_UNICON  "remove.ico"

  ;-----------------------------------------
  ; Custom Functions added to MUI pages
  ;-----------------------------------------

  ; Use a custom '.onGUIInit' function to add language-specific texts to custom page INI files

  !define MUI_CUSTOMFUNCTION_GUIINIT PFIGUIInit

  ; Use a "leave" function to look for 'popfile.cfg' in the directory selected for this install

  !define MUI_CUSTOMFUNCTION_DIRECTORY_LEAVE "CheckExistingConfig"

  ; Use a "pre" function for the 'Finish' page to ensure installer only offers to display
  ; POPFile User Interface if user has chosen to start POPFile from the installer.

  !define MUI_CUSTOMFUNCTION_FINISH_PRE "CheckRunStatus"

#--------------------------------------------------------------------------
# User Registers (Global)
#--------------------------------------------------------------------------

  ; This script uses 'User Variables' (with names starting with 'G_') to hold GLOBAL data.

  Var   G_POP3        ; POP3 port (1-65535)
  Var   G_GUI         ; GUI port (1-65535)
  Var   G_STARTUP     ; automatic startup flag (1 = yes, 0 = no)
  Var   G_NOTEPAD     ; path to notepad.exe ("" = not found in search path)

  ; NSIS provides 20 general purpose user registers:
  ; (a) $R0 to $R9   are used as local registers
  ; (b) $0 to $9     are used as additional local registers

  ; Local registers referred to by 'defines' use names starting with 'L_' (eg L_LNE, L_OLDUI)
  ; and the scope of these 'defines' is limited to the "routine" where they are used.

  ; In earlier versions of the NSIS compiler, 'User Variables' did not exist, and the convention
  ; was to use $R0 to $R9 as 'local' registers and $0 to $9 as 'global' ones. This is why this
  ; script uses registers $R0 to $R9 in preference to registers $0 to $9.

  ; POPFile constants have been given names beginning with 'C_' (eg C_README)

#--------------------------------------------------------------------------
# Language Support for the installer and uninstaller
#--------------------------------------------------------------------------

  ;-----------------------------------------
  ; Language Settings for MUI pages
  ;-----------------------------------------

  ; Same "Language selection" dialog is used for the installer and the uninstaller
  ; so we override the standard "Installer Language" title to avoid confusion.

  !define MUI_TEXT_LANGDLL_WINDOWTITLE "Language Selection"

  ; Always show the language selection dialog, even if a language has been stored in the
  ; registry (the language stored in the registry will be selected as the default language)

  !define MUI_LANGDLL_ALWAYSSHOW

  ; Remember user's language selection and offer this as the default when re-installing
  ; (uninstaller also uses this setting to determine which language is to be used)

  !define MUI_LANGDLL_REGISTRY_ROOT "HKLM"
  !define MUI_LANGDLL_REGISTRY_KEY "SOFTWARE\${MUI_PRODUCT}"
  !define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"

  ;-----------------------------------------
  ; Select the languages to be supported by installer/uninstaller.
  ; Currently a subset of the languages supported by NSIS MUI 1.65 (using the NSIS names)
  ;-----------------------------------------

  ; At least one language must be specified for the installer (the default is "English")

  !insertmacro PFI_LANG_LOAD "English"

  ; Conditional compilation: if ENGLISH_ONLY is defined, support only 'English'

  !ifndef ENGLISH_ONLY

        ; Additional languages supported by the installer.

        ; To remove a language, comment-out the relevant '!insertmacro PFI_LANG_LOAD' line
        ; from this list. (To remove all of these languages, use /DENGLISH_ONLY on command-line)

        ; Entries will appear in the drop-down list of languages in the order given below
        ; (the order used here ensures that the list entries appear in alphabetic order).

        !insertmacro PFI_LANG_LOAD "Bulgarian"    ; 'New style' license msgs missing (27-Jun-03)
        !insertmacro PFI_LANG_LOAD "SimpChinese"
        !insertmacro PFI_LANG_LOAD "TradChinese"
        !insertmacro PFI_LANG_LOAD "Czech"
        !insertmacro PFI_LANG_LOAD "Danish"       ; 'New style' license msgs missing (27-Jun-03)
        !insertmacro PFI_LANG_LOAD "German"
        !insertmacro PFI_LANG_LOAD "Spanish"
        !insertmacro PFI_LANG_LOAD "French"
        !insertmacro PFI_LANG_LOAD "Japanese"
        !insertmacro PFI_LANG_LOAD "Korean"
        !insertmacro PFI_LANG_LOAD "Hungarian"
        !insertmacro PFI_LANG_LOAD "Dutch"
        !insertmacro PFI_LANG_LOAD "Polish"
        !insertmacro PFI_LANG_LOAD "Portuguese"
        !insertmacro PFI_LANG_LOAD "PortugueseBR"
        !insertmacro PFI_LANG_LOAD "Russian"
        !insertmacro PFI_LANG_LOAD "Slovak"
        !insertmacro PFI_LANG_LOAD "Finnish"      ; 'New style' license msgs missing (27-Jun-03)
        !insertmacro PFI_LANG_LOAD "Swedish"
        !insertmacro PFI_LANG_LOAD "Ukrainian"

  !endif

#--------------------------------------------------------------------------
# General settings
#--------------------------------------------------------------------------

  ; Specify NSIS output filename

  OutFile "pfi-testbed.exe"

  ; Ensure CRC checking cannot be turned off using the /NCRC command-line switch

  CRCcheck Force

#--------------------------------------------------------------------------
# Default Destination Folder
#--------------------------------------------------------------------------

  InstallDir "$PROGRAMFILES\${MUI_PRODUCT}"
  InstallDirRegKey HKLM "SOFTWARE\${MUI_PRODUCT}" InstallLocation

#--------------------------------------------------------------------------
# Reserve the files required by the installer (to improve performance)
#--------------------------------------------------------------------------

  ;Things that need to be extracted on startup (keep these lines before any File command!)
  ;Only useful for BZIP2 compression
  ;Use ReserveFile for your own Install Options ini files too!

  !insertmacro MUI_RESERVEFILE_LANGDLL
  !insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
  !insertmacro MUI_RESERVEFILE_WELCOMEFINISHPAGE
  ReserveFile "ioA.ini"
  ReserveFile "ioB.ini"
  ReserveFile "ioC.ini"
  ReserveFile "${C_RELEASE_NOTES}"

#--------------------------------------------------------------------------
# Installer Function: .onInit - installer starts by offering a choice of languages
#--------------------------------------------------------------------------

Function .onInit

  !define L_INPUT_FILE_HANDLE   $R9
  !define L_OUTPUT_FILE_HANDLE  $R8
  !define L_LINE                $R7

  Push ${L_INPUT_FILE_HANDLE}
  Push ${L_OUTPUT_FILE_HANDLE}
  Push ${L_LINE}

  ; Conditional compilation: if ENGLISH_ONLY is defined, support only 'English'

  !ifndef ENGLISH_ONLY
        !insertmacro MUI_LANGDLL_DISPLAY
  !endif

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioA.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioB.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioC.ini"

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "${C_RELEASE_NOTES}" "${C_README}"

  ; Ensure the release notes are in a format which the standard Windows NOTEPAD.EXE can use.
  ; When the "POPFile" section is processed, the converted release notes will be copied to the
  ; installation directory to ensure user has a copy which can be read by NOTEPAD.EXE later.

  FileOpen ${L_INPUT_FILE_HANDLE}  "$PLUGINSDIR\${C_README}" r
  FileOpen ${L_OUTPUT_FILE_HANDLE} "$PLUGINSDIR\${C_README}.txt" w
  ClearErrors

loop:
  FileRead ${L_INPUT_FILE_HANDLE} ${L_LINE}
  IfErrors close_files
  Push ${L_LINE}
  Call TrimNewlines
  Pop ${L_LINE}
  FileWrite ${L_OUTPUT_FILE_HANDLE} ${L_LINE}$\r$\n
  Goto loop

close_files:
  FileClose ${L_INPUT_FILE_HANDLE}
  FileClose ${L_OUTPUT_FILE_HANDLE}

  Pop ${L_LINE}
  Pop ${L_OUTPUT_FILE_HANDLE}
  Pop ${L_INPUT_FILE_HANDLE}

  !undef L_INPUT_FILE_HANDLE
  !undef L_OUTPUT_FILE_HANDLE
  !undef L_LINE
FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: PFIGUIInit
# (custom .onGUIInit function)
#
# Used to complete the initialisation of the installer.
# (this code was moved from '.onInit' in order to permit the custom pages
# to be set up to use the language selected by the user)
#--------------------------------------------------------------------------

Function PFIGUIInit

  SearchPath $G_NOTEPAD notepad.exe
  MessageBox MB_YESNO|MB_ICONQUESTION \
      "$(PFI_LANG_MBRELNOTES_1)\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBRELNOTES_2)" IDNO exit
  StrCmp $G_NOTEPAD "" use_file_association
  ExecWait 'notepad.exe "$PLUGINSDIR\${C_README}.txt"'
  GoTo exit

use_file_association:
  ExecShell "open" "$PLUGINSDIR\${C_README}.txt"

exit:

  ; Insert appropriate language strings into the custom page INI files
  ; (the CBP package creates its own INI file so there is no need for a CBP *Page_Init function)

  Call SetOptionsPage_Init
  Call SetOutlookExpressPage_Init
  Call StartPOPFilePage_Init

FunctionEnd

#--------------------------------------------------------------------------
# Installer Section: POPFile component
#--------------------------------------------------------------------------

Section "POPFile" SecPOPFile

  ; Make this section mandatory (i.e. it is always installed)

  SectionIn RO

  !define L_CFG   $R9   ; file handle

  Push ${L_CFG}

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_UPGRADE)"
  SetDetailsPrint listonly

  Sleep ${C_INST_PROG_UPGRADE_DELAY}

  ; If we are installing over a previous version, (try to) ensure that version is not running

  Call MakeItSafe

  ; Retrieve the POP3 and GUI ports from the ini and get whether we install the
  ; POPFile run in the Startup group

  !insertmacro MUI_INSTALLOPTIONS_READ $G_POP3    "ioA.ini" "Field 2" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $G_GUI     "ioA.ini" "Field 4" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $G_STARTUP "ioA.ini" "Field 5" "State"

  WriteRegStr HKLM "SOFTWARE\${MUI_PRODUCT}" InstallLocation $INSTDIR

  ; Install the POPFile Core files

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_CORE)"
  SetDetailsPrint listonly

  SetOutPath $INSTDIR

  File "..\engine\license"
  File "${C_RELEASE_NOTES}"
  CopyFiles /SILENT /FILESONLY "$PLUGINSDIR\${C_README}.txt" "$INSTDIR\${C_README}.txt"
  File "..\engine\popfile.pl"
  File "..\engine\otto.gif"
  File "translator.htm"

  IfFileExists "$INSTDIR\stopwords" 0 copy_stopwords
  MessageBox MB_YESNO|MB_ICONQUESTION \
      "POPFile 'stopwords' $(PFI_LANG_MBSTPWDS_1)\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBSTPWDS_2)\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBSTPWDS_3) 'stopwords.bak')\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBSTPWDS_4) 'stopwords.default')" IDNO copy_default_stopwords
  IfFileExists "$INSTDIR\stopwords.bak" 0 make_backup
  SetFileAttributes "$INSTDIR\stopwords.bak" NORMAL

make_backup:
  CopyFiles /SILENT /FILESONLY "$INSTDIR\stopwords" "$INSTDIR\stopwords.bak"

copy_stopwords:
  File "..\engine\stopwords"

copy_default_stopwords:
  File /oname=stopwords.default "..\engine\stopwords"
  FileOpen  ${L_CFG} $PLUGINSDIR\popfile.cfg a
  FileSeek  ${L_CFG} 0 END
  FileWrite ${L_CFG} "pop3_port $G_POP3$\r$\n"
  FileWrite ${L_CFG} "html_port $G_GUI$\r$\n"
  FileClose ${L_CFG}
  IfFileExists "$INSTDIR\popfile.cfg" 0 update_config
  SetFileAttributes "$INSTDIR\popfile.cfg" NORMAL
  IfFileExists "$INSTDIR\popfile.cfg.bak" 0 make_cfg_backup
  MessageBox MB_YESNO|MB_ICONQUESTION \
      "$(PFI_LANG_MBCFGBK_1) 'popfile.cfg' $(PFI_LANG_MBCFGBK_2) ('popfile.cfg.bak').\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBCFGBK_3)\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBCFGBK_4)" IDNO update_config
  SetFileAttributes "$INSTDIR\popfile.cfg.bak" NORMAL

make_cfg_backup:
  CopyFiles /SILENT /FILESONLY $INSTDIR\popfile.cfg $INSTDIR\popfile.cfg.bak

update_config:
  CopyFiles /SILENT /FILESONLY $PLUGINSDIR\popfile.cfg $INSTDIR\

  SetOutPath $INSTDIR\languages
  File "..\engine\languages\English.msg"

  Sleep ${C_INST_PROG_CORE_DELAY}

  ; Install the Minimal Perl files

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_PERL)"
  SetDetailsPrint listonly

  Sleep ${C_INST_PROG_PERL_DELAY}

  ; Create the uninstall program BEFORE creating the shortcut to it
  ; (this ensures that the correct "uninstall" icon appears in the START MENU shortcut)

  SetOutPath $INSTDIR
  Delete $INSTDIR\uninstall.exe
  WriteUninstaller $INSTDIR\uninstall.exe

  ; Create the START MENU entries

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_SHORT)"
  SetDetailsPrint listonly

  ; 'CreateShortCut' uses '$OUTDIR' as the working directory for the shortcut
  ; ('SetOutPath' is one way to change the value of $OUTDIR)

  SetOutPath "$SMPROGRAMS\${MUI_PRODUCT}"
  SetOutPath $INSTDIR
  CreateShortCut "$SMPROGRAMS\${MUI_PRODUCT}\Uninstall PFI Testbed.lnk" "$INSTDIR\uninstall.exe"

  Sleep ${C_INST_PROG_SHORT_DELAY}

  ; Create entry in the Control Panel's "Add/Remove Programs" list

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${MUI_PRODUCT}" \
              "DisplayName" "${MUI_PRODUCT} ${MUI_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${MUI_PRODUCT}" \
              "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${MUI_PRODUCT}" \
              "NoModify" "1"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${MUI_PRODUCT}" \
              "NoRepair" "1"

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_ENDSEC)"
  SetDetailsPrint listonly

  Pop ${L_CFG}

  !undef L_CFG

SectionEnd

#--------------------------------------------------------------------------
# Installer Section: (optional) Skins component
#--------------------------------------------------------------------------

Section "Skins" SecSkins

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_SKINS)"
  SetDetailsPrint listonly

  Sleep ${C_INST_PROG_SKINS_DELAY}

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_ENDSEC)"
  SetDetailsPrint listonly

SectionEnd

#--------------------------------------------------------------------------
# Installer Section: (optional) UI Languages component
#
# If this component is selected, the installer will attempt to preset the POPFile UI
# language to match the language used for the installation. The 'UI_LANG_CONFIG' macro
# defines the mapping between NSIS language name and POPFile UI language name.
# The POPFile UI language is only preset if the required UI language file exists.
# If no match is found or if the UI language file does not exist, the default UI language
# is used (it is left to POPFile to determine which language to use).
#
# By the time this section is executed, the function 'CheckExistingConfig' in conjunction with
# the processing performed in the "POPFile" section will have removed all UI language settings
# from 'popfile.cfg' so all we have to do is append the UI setting to the file. If we do not
# append anything, POPFile will choose the default language.
#--------------------------------------------------------------------------

Section "Languages" SecLangs

  !define L_CFG   $R9   ; file handle
  !define L_LANG  $R8   ; language to be used for POPFile UI

  Push ${L_CFG}
  Push ${L_LANG}

  StrCpy ${L_LANG} ""     ; assume default POPFile UI language will be used.

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_LANGS)"
  SetDetailsPrint listonly

  SetOutPath $INSTDIR\languages
  File "..\engine\languages\*.msg"

  ; Conditional compilation: if ENGLISH_ONLY is defined, installer supports only 'English'
  ; so there is no need to select a language for the POPFile UI

  !ifndef ENGLISH_ONLY

        ; UI_LANG_CONFIG parameters: "NSIS Language name"  "POPFile UI language name"

        !insertmacro UI_LANG_CONFIG "ENGLISH" "English"
        !insertmacro UI_LANG_CONFIG "BULGARIAN" "Bulgarian"
        !insertmacro UI_LANG_CONFIG "SIMPCHINESE" "Chinese-Simplified"
        !insertmacro UI_LANG_CONFIG "TRADCHINESE" "Chinese-Traditional"
        !insertmacro UI_LANG_CONFIG "CZECH" "Czech"
        !insertmacro UI_LANG_CONFIG "DANISH" "Dansk"
        !insertmacro UI_LANG_CONFIG "GERMAN" "Deutsch"
        !insertmacro UI_LANG_CONFIG "SPANISH" "Espa�ol"
        !insertmacro UI_LANG_CONFIG "FRENCH" "Francais"
        !insertmacro UI_LANG_CONFIG "JAPANESE" "Nihongo"
        !insertmacro UI_LANG_CONFIG "KOREAN" "Korean"
        !insertmacro UI_LANG_CONFIG "HUNGARIAN" "Hungarian"
        !insertmacro UI_LANG_CONFIG "DUTCH" "Nederlands"
        !insertmacro UI_LANG_CONFIG "POLISH" "Polish"
        !insertmacro UI_LANG_CONFIG "PORTUGUESE" "Portugu�s"
        !insertmacro UI_LANG_CONFIG "PORTUGUESEBR" "Portugu�s do Brasil"
        !insertmacro UI_LANG_CONFIG "RUSSIAN" "Russian"
        !insertmacro UI_LANG_CONFIG "SLOVAK" "Slovak"
        !insertmacro UI_LANG_CONFIG "FINNISH" "Suomi"
        !insertmacro UI_LANG_CONFIG "SWEDISH" "Svenska"
        !insertmacro UI_LANG_CONFIG "UKRAINIAN" "Ukrainian"

        ; at this point, no match was found so we use the default POPFile UI language
        ; (and leave it to POPFile to determine which language to use)

        goto lang_done

      lang_save:
        FileOpen  ${L_CFG} $INSTDIR\popfile.cfg a
        FileSeek  ${L_CFG} 0 END
        FileWrite ${L_CFG} "html_language ${L_LANG}$\r$\n"
        FileClose ${L_CFG}

      lang_done:
  !endif

  Sleep ${C_INST_PROG_LANGS_DELAY}

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_ENDSEC)"
  SetDetailsPrint listonly

  Pop ${L_LANG}
  Pop ${L_CFG}

  !undef L_CFG
  !undef L_LANG

SectionEnd

#--------------------------------------------------------------------------
# Component-selection page descriptions
#--------------------------------------------------------------------------

  !insertmacro MUI_FUNCTIONS_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecPOPFile} $(DESC_SecPOPFile)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecSkins}   $(DESC_SecSkins)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecLangs}   $(DESC_SecLangs)
  !insertmacro MUI_FUNCTIONS_DESCRIPTION_END

#--------------------------------------------------------------------------
# Installer Function: MakeItSafe
#
# If we are installing on top of a previous installation, we try to shut it down
# (to allow the files to be overwritten without requiring a reboot)
#--------------------------------------------------------------------------

Function MakeItSafe

  !define L_EXE      $R9
  !define L_NEW_GUI  $R8
  !define L_OLD_GUI  $R7

  Push ${L_EXE}
  Push ${L_NEW_GUI}
  Push ${L_OLD_GUI}

  StrCpy ${L_OLD_GUI} "8080"
  StrCpy ${L_NEW_GUI} "9090"

  DetailPrint "$(PFI_LANG_INST_LOG_1) ${L_OLD_GUI}"

  DetailPrint "$(PFI_LANG_INST_LOG_1) ${L_NEW_GUI}"

  ; Insert call to WaitUntilUnlocked to avoid NSIS compiler warnings

  StrCpy ${L_EXE} "$INSTDIR\wperl.exe"
  Push ${L_EXE}
  Call WaitUntilUnlocked

  Pop ${L_OLD_GUI}
  Pop ${L_NEW_GUI}
  Pop ${L_EXE}

  !undef L_EXE
  !undef L_NEW_GUI
  !undef L_OLD_GUI
FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: CheckExistingConfig
# (the "leave" function for the DIRECTORY selection page)
#
# This function is used to extract the POP3 and UI ports from the 'popfile.cfg'
# configuration file (if any) in the directory used for this installation.
#
# As it is possible that there are multiple entries for these parameters in the file,
# this function removes them all as it makes a new copy of the file. New port data
# entries will be added to this copy and the original updated (and backed up) when
# the "POPFile" section of the installer is executed.
#
# If the user has selected the optional 'Languages' component then this function also strips
# out the POPFile UI language setting to allow the installer to easily preset the UI language
# to match the language selected for use by the installer. (See the code which handles the
# 'Languages' component for further details).
#--------------------------------------------------------------------------

Function CheckExistingConfig

  !define L_CFG       $R9     ; handle for "popfile.cfg"
  !define L_CLEANCFG  $R8     ; handle for "clean" copy
  !define L_CMPRE     $R7     ; config param name
  !define L_LNE       $R6     ; a line from popfile.cfg
  !define L_OLDUI     $R5     ; used to hold old-style of GUI port
  !define L_STRIPLANG $R4

  Push ${L_CFG}
  Push ${L_CLEANCFG}
  Push ${L_CMPRE}
  Push ${L_LNE}
  Push ${L_OLDUI}
  Push ${L_STRIPLANG}

  ; If the 'Languages' component is being installed, installer is allowed to preset UI language

  !insertmacro SectionFlagIsSet ${SecLangs} 1 strip nostrip

strip:
  StrCpy ${L_STRIPLANG} "yes"
  Goto init_port_vars

nostrip:
  StrCpy ${L_STRIPLANG} ""

init_port_vars:
  StrCpy $G_POP3 ""
  StrCpy $G_GUI ""
  StrCpy ${L_OLDUI} ""

  ; See if we can get the current pop3 and gui port from an existing configuration.
  ; There may be more than one entry for these ports in the file - use the last one found
  ; (but give priority to any "html_port" entry).

  ClearErrors

  FileOpen  ${L_CFG} $INSTDIR\popfile.cfg r
  FileOpen  ${L_CLEANCFG} $PLUGINSDIR\popfile.cfg w

loop:
  FileRead   ${L_CFG} ${L_LNE}
  IfErrors done

  StrCpy ${L_CMPRE} ${L_LNE} 5
  StrCmp ${L_CMPRE} "port " got_port

  StrCpy ${L_CMPRE} ${L_LNE} 10
  StrCmp ${L_CMPRE} "pop3_port " got_pop3_port
  StrCmp ${L_CMPRE} "html_port " got_html_port

  StrCpy ${L_CMPRE} ${L_LNE} 8
  StrCmp ${L_CMPRE} "ui_port " got_ui_port

  StrCmp ${L_STRIPLANG} "" transfer

  ; do not transfer any UI language settings to the copy of popfile.cfg

  StrCpy ${L_CMPRE} ${L_LNE} 9
  StrCmp ${L_CMPRE} "language " loop
  StrCpy ${L_CMPRE} ${L_LNE} 14
  StrCmp ${L_CMPRE} "html_language " loop

transfer:
  FileWrite  ${L_CLEANCFG} ${L_LNE}
  Goto loop

got_port:
  StrCpy $G_POP3 ${L_LNE} 5 5
  Goto loop

got_pop3_port:
  StrCpy $G_POP3 ${L_LNE} 5 10
  Goto loop

got_ui_port:
  StrCpy ${L_OLDUI} ${L_LNE} 5 8
  Goto loop

got_html_port:
  StrCpy $G_GUI ${L_LNE} 5 10
  Goto loop

done:
  FileClose ${L_CFG}
  FileClose ${L_CLEANCFG}

  Push $G_POP3
  Call TrimNewlines
  Pop $G_POP3

  Push $G_GUI
  Call TrimNewlines
  Pop $G_GUI

  Push ${L_OLDUI}
  Call TrimNewlines
  Pop ${L_OLDUI}

  ; Save the UI port settings (from popfile.cfg) for later use by the 'MakeItSafe' function

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "UI Port" "NewStyle" "$G_GUI"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "UI Port" "OldStyle" "${L_OLDUI}"

  ; The 'port' and 'pop3_port' settings are treated as equals so we use the last entry found.
  ; If 'ui_port' and 'html_port' settings were found, we use the last 'html_port' we found.

  StrCmp $G_GUI "" 0 validity_checks
  StrCpy $G_GUI ${L_OLDUI}

validity_checks:

  ; check port values (config file may have no port data or invalid port data)

  StrCmp $G_POP3 $G_GUI 0 ports_differ

  ; Config file has no port data or same port used for POP3 and GUI
  ; (i.e. the data is not valid), so use POPFile defaults

  StrCpy $G_POP3 "110"
  StrCpy $G_GUI "8080"
  Goto ports_ok

ports_differ:
  StrCmp $G_POP3 "" default_pop3
  Push $G_POP3
  Call StrCheckDecimal
  Pop $G_POP3
  StrCmp $G_POP3 "" default_pop3
  IntCmp $G_POP3 1 pop3_ok default_pop3
  IntCmp $G_POP3 65535 pop3_ok pop3_ok

default_pop3:
  StrCpy $G_POP3 "110"
  StrCmp $G_POP3 $G_GUI 0 pop3_ok
  StrCpy $G_POP3 "111"

pop3_ok:
  StrCmp $G_GUI "" default_gui
  Push $G_GUI
  Call StrCheckDecimal
  Pop $G_GUI
  StrCmp $G_GUI "" default_gui
  IntCmp $G_GUI 1 ports_ok default_gui
  IntCmp $G_GUI 65535 ports_ok ports_ok

default_gui:
  StrCpy $G_GUI "8080"
  StrCmp $G_POP3 $G_GUI 0 ports_ok
  StrCpy $G_GUI "8081"

ports_ok:
  Pop ${L_STRIPLANG}
  Pop ${L_OLDUI}
  Pop ${L_LNE}
  Pop ${L_CMPRE}
  Pop ${L_CLEANCFG}
  Pop ${L_CFG}

  !undef L_CFG
  !undef L_CLEANCFG
  !undef L_CMPRE
  !undef L_LNE
  !undef L_OLDUI
  !undef L_STRIPLANG

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: SetOptionsPage_Init
#
# This function adds language texts to the INI file used by the "SetOptionsPage" function
# (to make the custom page use the language selected by the user for the installer)
#--------------------------------------------------------------------------

Function SetOptionsPage_Init

  !insertmacro PFI_IO_TEXT "ioA.ini" "1" "$(PFI_LANG_OPTIONS_IO_POP3)"
  !insertmacro PFI_IO_TEXT "ioA.ini" "3" "$(PFI_LANG_OPTIONS_IO_GUI)"
  !insertmacro PFI_IO_TEXT "ioA.ini" "5" "$(PFI_LANG_OPTIONS_IO_STARTUP)"
  !insertmacro PFI_IO_TEXT "ioA.ini" "6" "$(PFI_LANG_OPTIONS_IO_WARNING)"
  !insertmacro PFI_IO_TEXT "ioA.ini" "7" "$(PFI_LANG_OPTIONS_IO_MESSAGE)"

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: SetOptionsPage (generates a custom page)
#
# If this is an "upgrade" installation, the user is offered the chance to uninstall the old
# version before continuing with the upgrade. If an uninstall is selected, the 'uninstall.exe'
# from THIS installer is used instead of the one from the POPFile which is being upgraded. This
# is done to ensure that a special "upgrade" uninstall is performed instead of a "normal" one.
# The "upgrade" uninstall ensures that the corpus and some other files are not removed. After
# an "upgrade" uninstall, the "SHUTDOWN" warning message is removed from the custom page
# (POPFile is automatically shutdown during the "upgrade" uninstall).
#
# This function is used to configure the POP3 and UI ports, and
# whether or not POPFile should be started automatically when Windows starts.
#
# A "leave" function (CheckPortOptions) is used to validate the port
# selections made by the user.
#--------------------------------------------------------------------------

Function SetOptionsPage

  !define L_PORTLIST  $R9   ; combo box ports list
  !define L_RESULT    $R8

  Push ${L_PORTLIST}
  Push ${L_RESULT}

  ; Ensure custom page shows the "Shutdown" warning message box.

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "Settings" "NumFields" "7"

  IfFileExists "$INSTDIR\popfile.pl" 0 continue

  MessageBox MB_YESNO|MB_ICONEXCLAMATION \
      "$(PFI_LANG_OPTIONS_MBUNINST_1) '$INSTDIR'\
      $\r$\n$\r$\n\
      $(PFI_LANG_OPTIONS_MBUNINST_2)\
      $\r$\n$\r$\n\
      ($(PFI_LANG_OPTIONS_MBUNINST_3))" IDNO continue

  Banner::show /NOUNLOAD /set 76 "$(PFI_LANG_OPTIONS_BANNER_1)" "$(PFI_LANG_OPTIONS_BANNER_2)"
  WriteUninstaller $INSTDIR\uninstall.exe
  ExecWait '"$INSTDIR\uninstall.exe"  _?=$INSTDIR'
  IfFileExists "$INSTDIR\popfile.pl" skip_msg_delete

  ; No need to display the warning about shutting down POPFile as it has just been uninstalled

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "Settings" "NumFields" "5"

skip_msg_delete:
  Banner::destroy

continue:

  ; The function "CheckExistingConfig" loads $G_POP3 and $G_GUI with the settings found in
  ; a previously installed "popfile.cfg" file or if no such file is found, it loads the
  ; POPFile default values. Now we display these settings and allow the user to change them.

  ; The POP3 and GUI port numbers must be in the range 1 to 65535 inclusive, and they
  ; must be different. This function assumes that the values "CheckExistingConfig" has loaded
  ; into $G_POP3 and $G_GUI are valid.

  !insertmacro MUI_HEADER_TEXT "$(PFI_LANG_OPTIONS_TITLE)" "$(PFI_LANG_OPTIONS_SUBTITLE)"

  ; If the POP3 (or GUI) port determined by "CheckExistingConfig" is not present in the list of
  ; possible values for the POP3 (or GUI) combobox, add it to the end of the list.

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_PORTLIST} "ioA.ini" "Field 2" "ListItems"
  Push |${L_PORTLIST}|
  Push |$G_POP3|
  Call StrStr
  Pop ${L_RESULT}
  StrCmp ${L_RESULT} "" 0 POP3_is_in_list
  StrCpy ${L_PORTLIST} ${L_PORTLIST}|$G_POP3
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "Field 2" "ListItems" ${L_PORTLIST}

POP3_is_in_list:
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_PORTLIST} "ioA.ini" "Field 4" "ListItems"
  Push |${L_PORTLIST}|
  Push |$G_GUI|
  Call StrStr
  Pop ${L_RESULT}
  StrCmp ${L_RESULT} "" 0 GUI_is_in_list
  StrCpy ${L_PORTLIST} ${L_PORTLIST}|$G_GUI
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "Field 4" "ListItems" ${L_PORTLIST}

GUI_is_in_list:

  ; If the StartUp folder contains a link to start POPFile automatically
  ; then offer to keep this facility in place.

  IfFileExists "$SMSTARTUP\Run POPFile in background.lnk" 0 show_defaults
    !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "Field 5" "State" 1

show_defaults:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "Field 2" "State" $G_POP3
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "Field 4" "State" $G_GUI

  ; Now display the custom page and wait for the user to make their selections.
  ; The function "CheckPortOptions" will check the validity of the selections
  ; and refuse to proceed until suitable ports have been chosen.

  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "ioA.ini"

  ; Store validated data (for use when the "POPFile" section is processed)

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "Field 2" "State" $G_POP3
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "Field 4" "State" $G_GUI

  Pop ${L_RESULT}
  Pop ${L_PORTLIST}

  !undef L_PORTLIST
  !undef L_RESULT

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: CheckPortOptions
# (the "leave" function for the custom page created by "SetOptionsPage")
#
# This function is used to validate the POP3 and UI ports selected by the user.
# If the selections are not valid, user is asked to select alternative values.
#--------------------------------------------------------------------------

Function CheckPortOptions

  !define L_RESULT    $R9

  Push ${L_RESULT}

  !insertmacro MUI_INSTALLOPTIONS_READ $G_POP3 "ioA.ini" "Field 2" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $G_GUI "ioA.ini" "Field 4" "State"

  ; strip leading zeroes and spaces from user input

  Push $G_POP3
  Call StrStripLZS
  Pop $G_POP3
  Push $G_GUI
  Call StrStripLZS
  Pop $G_GUI

  StrCmp $G_POP3 $G_GUI ports_must_differ
  Push $G_POP3
  Call StrCheckDecimal
  Pop ${L_RESULT}
  StrCmp ${L_RESULT} "" bad_pop3
  IntCmp $G_POP3 1 pop3_ok bad_pop3
  IntCmp $G_POP3 65535 pop3_ok pop3_ok

bad_pop3:
  MessageBox MB_OK|MB_ICONEXCLAMATION \
      "$(PFI_LANG_OPTIONS_MBPOP3_1) $\"$G_POP3$\"'.\
      $\r$\n$\r$\n\
      $(PFI_LANG_OPTIONS_MBPOP3_2)\
      $\r$\n$\r$\n\
      $(PFI_LANG_OPTIONS_MBPOP3_3)"
  Goto bad_exit

pop3_ok:
  Push $G_GUI
  Call StrCheckDecimal
  Pop ${L_RESULT}
  StrCmp ${L_RESULT} "" bad_gui
  IntCmp $G_GUI 1 good_exit bad_gui
  IntCmp $G_GUI 65535 good_exit good_exit

bad_gui:
  MessageBox MB_OK|MB_ICONEXCLAMATION \
      "$(PFI_LANG_OPTIONS_MBGUI_1) $\"$G_GUI$\".\
      $\r$\n$\r$\n\
      $(PFI_LANG_OPTIONS_MBGUI_2)\
      $\r$\n$\r$\n\
      $(PFI_LANG_OPTIONS_MBGUI_3)"
  Goto bad_exit

ports_must_differ:
  MessageBox MB_OK|MB_ICONEXCLAMATION \
      "$(PFI_LANG_OPTIONS_MBDIFF_1)\
      $\r$\n$\r$\n\
      $(PFI_LANG_OPTIONS_MBDIFF_2)"

bad_exit:

  ; Stay with the custom page created by "SetOptionsPage"

  Pop ${L_RESULT}
  Abort

good_exit:

  ; Allow next page in the installation sequence to be shown

  Pop ${L_RESULT}

  !undef L_RESULT

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: SetOutlookExpressPage_Init
#
# This function adds language texts to the INI file used by the "SetOutlookExpressPage" function
# (to make the custom page use the language selected by the user for the installer)
#--------------------------------------------------------------------------

Function SetOutlookExpressPage_Init

  !insertmacro PFI_IO_TEXT "ioB.ini" "1" "$(PFI_LANG_OECFG_IO_INTRO)"
  !insertmacro PFI_IO_TEXT "ioB.ini" "2" "$(PFI_LANG_OECFG_IO_CHECKBOX)"
  !insertmacro PFI_IO_TEXT "ioB.ini" "3" "$(PFI_LANG_OECFG_IO_EMAIL)"
  !insertmacro PFI_IO_TEXT "ioB.ini" "4" "$(PFI_LANG_OECFG_IO_SERVER)"
  !insertmacro PFI_IO_TEXT "ioB.ini" "5" "$(PFI_LANG_OECFG_IO_USERNAME)"
  !insertmacro PFI_IO_TEXT "ioB.ini" "6" "$(PFI_LANG_OECFG_IO_RESTORE)"

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: SetOutlookExpressPage (generates a custom page)
#
# This function is used to reconfigure Outlook Express accounts
#--------------------------------------------------------------------------

Function SetOutlookExpressPage

  ; More than one "identity" can be created in OE. Each of these identities is
  ; given a GUID and these GUIDs are stored in HKEY_CURRENT_USER\Identities.

  ; Each identity can have several email accounts and the details for these
  ; accounts are grouped according to the GUID which "owns" the accounts.

  ; We step through every identity defined in HKEY_CURRENT_USER\Identities and
  ; for each one found check its OE email account data.

  ; When OE is installed, it (usually) creates an initial identity which stores its
  ; email account data in a fixed registry location. If an identity with an "Identity Ordinal"
  ; value of 1 is found, we need to look for its OE email account data in
  ;
  ;     HKEY_CURRENT_USER\Software\Microsoft\Internet Account Manager\Accounts
  ;
  ; otherwise we look in the GUID's entry in HKEY_CURRENT_USER\Identities, using the path
  ;
  ;     HKEY_CURRENT_USER\Identities\{GUID}\Software\Microsoft\Internet Account Manager\Accounts

  ; All of the OE account data for an identity appears "under" the path defined
  ; above, e.g. if an identity has several accounts, the account data is stored like this:
  ;    HKEY_CURRENT_USER\...\Internet Account Manager\Accounts\00000001
  ;    HKEY_CURRENT_USER\...\Internet Account Manager\Accounts\00000002
  ;    etc

  !define L_ACCOUNT     $R9   ; path to the data for the current OE account (less the HKCU part)
  !define L_ACCT_INDEX  $R8   ; used to loop through OE accounts for the current OE Identity
  !define L_CFG         $R7   ; file handle
  !define L_GUID        $R6   ; GUID of the current entry in HKCU\Identities list
  !define L_GUID_INDEX  $R5   ; used to loop through the list of OE Identities
  !define L_IDENTITY    $R4   ; plain text form of OE Identity name
  !define L_OEDATA      $R3   ; some data (it varies) for current OE account
  !define L_OEPATH      $R2   ; holds part of the path used to access OE account data
  !define L_ORDINALS    $R1   ; "Identity Ordinals" flag (1 = found, 0 = not found)
  !define L_SEPARATOR   $R0   ; char used to separate the pop3 server from the username
  !define L_TEMP        $9

  Push ${L_ACCOUNT}
  Push ${L_ACCT_INDEX}
  Push ${L_CFG}
  Push ${L_GUID}
  Push ${L_GUID_INDEX}
  Push ${L_IDENTITY}
  Push ${L_OEDATA}
  Push ${L_OEPATH}
  Push ${L_ORDINALS}
  Push ${L_SEPARATOR}
  Push ${L_TEMP}

  ; Determine the separator character to be used when configuring an email account for POPFile

  Call GetSeparator
  Pop ${L_SEPARATOR}

  StrCpy ${L_GUID_INDEX} 0

  ; Get the next identity from the registry

get_guid:
  EnumRegKey ${L_GUID} HKCU "Identities" ${L_GUID_INDEX}
  StrCmp ${L_GUID} "" finished_oe_config

  ; Check if this is the GUID for the first "Main Identity" created by OE as the account data
  ; for that identity is stored separately from the account data for the other OE identities.
  ; If no "Identity Ordinal" value found, use the first "Main Identity" created by OE.

  StrCpy ${L_ORDINALS} "1"

  ReadRegDWORD ${L_TEMP} HKCU "Identities\${L_GUID}" "Identity Ordinal"
  IntCmp ${L_TEMP} 1 firstOrdinal noOrdinals otherOrdinal

firstOrdinal:
  StrCpy ${L_OEPATH} ""
  goto check_accounts

noOrdinals:
  StrCpy ${L_ORDINALS} "0"
  StrCpy ${L_OEPATH} ""
  goto check_accounts

otherOrdinal:
  StrCpy ${L_OEPATH} "Identities\${L_GUID}\"

check_accounts:

  ; Now check all of the accounts for the current OE Identity

  StrCpy ${L_ACCT_INDEX} 0

next_acct:
  EnumRegKey ${L_ACCOUNT} \
             HKCU "${L_OEPATH}Software\Microsoft\Internet Account Manager\Accounts" \
             ${L_ACCT_INDEX}
  StrCmp ${L_ACCOUNT} "" finished_this_guid
  StrCpy ${L_ACCOUNT} \
        "${L_OEPATH}Software\Microsoft\Internet Account Manager\Accounts\${L_ACCOUNT}"

  ; Now extract the POP3 Server data, if this does not exist then this account is
  ; not configured for mail so move on. If the data is "127.0.0.1" assume the account has
  ; already been configured for use with POPFile.

  ReadRegStr ${L_OEDATA} HKCU ${L_ACCOUNT} "POP3 Server"
  StrCmp ${L_OEDATA} "" try_next_account
  StrCmp ${L_OEDATA} "127.0.0.1" try_next_account

  ; If 'POP3 Server' data contains the separator character, we cannot configure this account

  Push ${L_OEDATA}
  Push ${L_SEPARATOR}
  Call StrStr
  Pop ${L_TEMP}
  StrCmp ${L_TEMP} "" 0 try_next_account

  !insertmacro MUI_HEADER_TEXT "$(PFI_LANG_OECFG_TITLE)" "$(PFI_LANG_OECFG_SUBTITLE)"

  ; Ensure the 'configure this account' check box is NOT ticked

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field 2" "State" "0"

  ; Prepare to display the 'POP3 Server' data

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field 8" "Text" ${L_OEDATA}

  ReadRegStr ${L_OEDATA} HKCU ${L_ACCOUNT} "SMTP Email Address"
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field 7" "Text" ${L_OEDATA}

  ReadRegStr ${L_OEDATA} HKCU ${L_ACCOUNT} "POP3 User Name"

  ; If 'POP3 User Name' data contains the separator character, we cannot configure this account

  Push ${L_OEDATA}
  Push ${L_SEPARATOR}
  Call StrStr
  Pop ${L_TEMP}
  StrCmp ${L_TEMP} "" 0 try_next_account

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field 9" "Text" ${L_OEDATA}

  ; Find the Username used by OE for this identity and the OE Account Name
  ; (so we can unambiguously report which email account we are offering to reconfigure).

  ReadRegStr ${L_IDENTITY} HKCU "Identities\${L_GUID}\" "Username"
  StrCpy ${L_IDENTITY} $\"${L_IDENTITY}$\"
  ReadRegStr ${L_OEDATA} HKCU ${L_ACCOUNT} "Account Name"
  StrCpy ${L_OEDATA} $\"${L_OEDATA}$\"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioB.ini" "Field 10" "Text" \
      "${L_OEDATA} $(PFI_LANG_OECFG_IO_LINK_1) ${L_IDENTITY} $(PFI_LANG_OECFG_IO_LINK_2)"

  ; Display the OE account data and offer to configure this account to work with POPFile

  !insertmacro MUI_INSTALLOPTIONS_DISPLAY_RETURN "ioB.ini"
  Pop ${L_TEMP}

  StrCmp ${L_TEMP} "cancel" finished_this_guid
  StrCmp ${L_TEMP} "back" finished_this_guid

  ; Has the user ticked the 'configure this account' check box ?

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "Field 2" "State"
  StrCmp ${L_TEMP} "1" change_oe try_next_account

change_oe:
  ReadRegStr ${L_OEDATA} HKCU ${L_ACCOUNT} "POP3 User Name"
  ReadRegStr ${L_TEMP} HKCU ${L_ACCOUNT} "POP3 Server"

  ; To be able to restore the registry to previous settings when we uninstall we
  ; write a special file called popfile.reg.dummy containing the registry settings
  ; prior to modification in the form of lines consisting of
  ;
  ; the\key
  ; thesubkey
  ; the\value

  FileOpen  ${L_CFG} $INSTDIR\popfile.reg.dummy a
  FileSeek  ${L_CFG} 0 END
  FileWrite ${L_CFG} "${L_ACCOUNT}$\n"
  FileWrite ${L_CFG} "POP3 User Name$\n"
  FileWrite ${L_CFG} "${L_OEDATA}$\n"
  FileWrite ${L_CFG} "${L_ACCOUNT}$\n"
  FileWrite ${L_CFG} "POP3 Server$\n"
  FileWrite ${L_CFG} "${L_TEMP}$\n"
  FileClose ${L_CFG}

  ; The testbed does NOT change the Outlook Express settings

try_next_account:
  IntOp ${L_ACCT_INDEX} ${L_ACCT_INDEX} + 1
  goto next_acct

finished_this_guid:

  ; If no "Identity Ordinal" values were found then exit otherwise move on to the next identity

  StrCmp ${L_ORDINALS} "0" finished_oe_config

  IntOp ${L_GUID_INDEX} ${L_GUID_INDEX} + 1
  goto get_guid

finished_oe_config:

  Pop ${L_TEMP}
  Pop ${L_SEPARATOR}
  Pop ${L_ORDINALS}
  Pop ${L_OEPATH}
  Pop ${L_OEDATA}
  Pop ${L_IDENTITY}
  Pop ${L_GUID_INDEX}
  Pop ${L_GUID}
  Pop ${L_CFG}
  Pop ${L_ACCT_INDEX}
  Pop ${L_ACCOUNT}

  !undef L_ACCOUNT
  !undef L_ACCT_INDEX
  !undef L_CFG
  !undef L_GUID
  !undef L_GUID_INDEX
  !undef L_IDENTITY
  !undef L_OEDATA
  !undef L_OEPATH
  !undef L_ORDINALS
  !undef L_SEPARATOR
  !undef L_TEMP

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: StartPOPFilePage_Init (adds language texts to custom page INI file)
#
# This function adds language texts to the INI file used by the "StartPOPFilePage" function
# (to make the custom page use the language selected by the user for the installer)
#--------------------------------------------------------------------------

Function StartPOPFilePage_Init

  !insertmacro PFI_IO_TEXT "ioC.ini" "1" "$(PFI_LANG_LAUNCH_IO_INTRO)"
  !insertmacro PFI_IO_TEXT "ioC.ini" "2" "$(PFI_LANG_LAUNCH_IO_NO)"
  !insertmacro PFI_IO_TEXT "ioC.ini" "3" "$(PFI_LANG_LAUNCH_IO_DOSBOX)"
  !insertmacro PFI_IO_TEXT "ioC.ini" "4" "$(PFI_LANG_LAUNCH_IO_BCKGRND)"

  !insertmacro PFI_IO_TEXT "ioC.ini" "6" "$(PFI_LANG_LAUNCH_IO_NOTE_1)"
  !insertmacro PFI_IO_TEXT "ioC.ini" "7" "$(PFI_LANG_LAUNCH_IO_NOTE_2)"
  !insertmacro PFI_IO_TEXT "ioC.ini" "8" "$(PFI_LANG_LAUNCH_IO_NOTE_3)"

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: StartPOPFilePage (generates a custom page)
#
# This function offers to start the newly installed POPFile.
#
# A "leave" function (CheckLaunchOptions) is used to act upon the selection made by the user.
#--------------------------------------------------------------------------

Function StartPOPFilePage

  !insertmacro MUI_HEADER_TEXT "$(PFI_LANG_LAUNCH_TITLE)" "$(PFI_LANG_LAUNCH_SUBTITLE)"

  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "ioC.ini"

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: CheckLaunchOptions
# (the "leave" function for the custom page created by "StartPOPFilePage")
#
# This function is used to action the "start POPFile" option selected by the user.
# The user is allowed to return to this page and change their selection, so the
# previous state is stored in the INI file used for this custom page.
#--------------------------------------------------------------------------

Function CheckLaunchOptions

  !define L_RESULT      $R9
  !define L_TEMP        $R8

  Push ${L_RESULT}
  Push ${L_TEMP}

  ; Field 2 = 'Do not run POPFile' radio button

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Field 2" "State"
  StrCmp ${L_TEMP} "0" run_popfile

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Run Status" "LastAction"
  StrCmp ${L_TEMP} "" exit_without_banner
  StrCmp ${L_TEMP} "no" exit_without_banner
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Run Status" "LastAction" "no"

  ; User has changed their mind: Shutdown the newly installed version of POPFile

  Sleep 250 ; milliseconds
  goto exit_without_banner

run_popfile:

  ; Field 4 = 'Run POPFile in background' radio button

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Field 4" "State"
  StrCmp ${L_TEMP} "1" run_in_background

  ; Run POPFile in a DOS box

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Run Status" "LastAction"
  StrCmp ${L_TEMP} "DOS-box" exit_without_banner
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Run Status" "LastAction" "DOS-box"

  Banner::show /NOUNLOAD /set 76 "$(PFI_LANG_LAUNCH_BANNER_1)" "$(PFI_LANG_LAUNCH_BANNER_2)"

  ; Before starting the newly installed POPFile, ensure that no other version of POPFile
  ; is running on the same UI port as the newly installed version.

  Sleep ${C_INST_RUN_BANNER_DELAY}
  goto wait_for_popfile

run_in_background:

  ; Run POPFile without a DOS box

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Run Status" "LastAction"
  StrCmp ${L_TEMP} "background" exit_without_banner
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Run Status" "LastAction" "background"

  Banner::show /NOUNLOAD /set 76 "$(PFI_LANG_LAUNCH_BANNER_1)" "$(PFI_LANG_LAUNCH_BANNER_2)"

  ; Before starting the newly installed POPFile, ensure that no other version of POPFile
  ; is running on the same UI port as the newly installed version.

  Sleep ${C_INST_RUN_BANNER_DELAY}

wait_for_popfile:

  ; Wait until POPFile is ready to display the UI (may take a second or so)

  StrCpy ${L_TEMP} 5   ; Timeout limit to avoid an infinite loop

check_if_ready:
  Sleep 250   ; milliseconds
  IntOp ${L_TEMP} ${L_TEMP} - 1
  IntCmp ${L_TEMP} 0 remove_banner remove_banner check_if_ready

remove_banner:
  Banner::destroy

exit_without_banner:

  Pop ${L_TEMP}
  Pop ${L_RESULT}

  !undef L_RESULT
  !undef L_TEMP

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: CheckRunStatus
# (the "pre" function for the 'Finish' page)
#
# The 'Finish' page contains two CheckBoxes: one to control whether or not the installer
# starts the POPFile User Interface and one to control whether or not the 'ReadMe' file is
# displayed. The User Interface only works when POPFile is running, so we must ensure its
# CheckBox can only be ticked if the installer has started POPFile.
#--------------------------------------------------------------------------

Function CheckRunStatus

  !define L_TEMP        $R9

  Push ${L_TEMP}

  ; Field 4 is the 'Run' CheckBox on the 'Finish' page

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 4" "Flags" ""

  ; Get the status of the 'Do not run POPFile' radio button on the previous page of installer

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Field 2" "State"
  StrCmp ${L_TEMP} "0" selection_ok

  ; User has not started POPFile so we cannot offer to display the POPFile User Interface

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 4" "State" "0"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 4" "Flags" "DISABLED"

selection_ok:
  Pop ${L_TEMP}

  !undef L_TEMP

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: RunUI
# (the "Run" function for the 'Finish' page)
#--------------------------------------------------------------------------

Function RunUI

  ExecShell "open" "$INSTDIR\translator.htm"

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: ShowReadMe
# (the "ReadMe" function for the 'Finish' page)
#--------------------------------------------------------------------------

Function ShowReadMe

  StrCmp $G_NOTEPAD "" use_file_association
  Exec 'notepad.exe "$INSTDIR\${C_README}.txt"'
  goto exit

use_file_association:
  ExecShell "open" "$INSTDIR\${C_README}.txt"

exit:
FunctionEnd

#--------------------------------------------------------------------------
# Initialise the uninstaller
#--------------------------------------------------------------------------

Function un.onInit

  ; Retrieve the language used when this version was installed, and use it for the uninstaller

  !insertmacro MUI_UNGETLANGUAGE

FunctionEnd

#--------------------------------------------------------------------------
# Uninstaller Section
#
# There are two types of uninstall:
#
# (1) normal uninstall, performed when user wishes to completely remove POPFile from the system
#
# (2) an uninstall performed as part of an upgrade installation. In this case some files are
#     preserved (eg the existing corpus).
#--------------------------------------------------------------------------

Section "Uninstall"

  !define L_CFG         $R9   ; used as file handle
  !define L_LNE         $R8   ; a line from popfile.cfg
  !define L_REG_KEY     $R7   ; L_REG_* registers are used to  restore Outlook Express settings
  !define L_REG_SUBKEY  $R6
  !define L_REG_VALUE   $R5
  !define L_TEMP        $R4
  !define L_UPGRADE     $R3   ; "yes" if this is an upgrade, "no" if we are just uninstalling
  !define L_CORPUS      $R2   ; holds full path to the POPFile corpus data
  !define L_SUBCORPUS   $R1   ; "yes" if corpus is in a subfolder of $INSTDIR, otherwise "no"
  !define L_OLDUI       $R0   ; holds old-style UI port (if previous POPFile is an old version)
  !define L_HISTORY     $9    ; holds full path to the message history data
  !define L_SUBHISTORY  $8    ; "yes" if history data in subfolder of $INSTDIR, otherwise "no"
  !define L_EXE         $7    ; full path of the EXE to be monitored

  ; When a normal uninstall is performed, the uninstaller is copied to a uniquely named
  ; temporary file and it is that temporary file which is executed (this is how the uninstaller
  ; removes itself). If we are performing an uninstall as part of an upgrade installation then
  ; no temporary file is created, we execute the 'real' file ($INSTDIR\uninstall.exe) instead.

  StrCpy ${L_UPGRADE} "no"

  Push $CMDLINE
  Push "$INSTDIR\uninstall.exe"
  Call un.StrStr
  Pop ${L_TEMP}
  StrCmp ${L_TEMP} "" confirmation
  StrCpy ${L_UPGRADE} "yes"

confirmation:
  IfFileExists $INSTDIR\popfile.pl skip_confirmation
    MessageBox MB_YESNO|MB_ICONSTOP|MB_DEFBUTTON2 \
        "$(un.PFI_LANG_MBNOTFOUND_1) '$INSTDIR'.\
        $\r$\n$\r$\n\
        $(un.PFI_LANG_MBNOTFOUND_2)" IDYES skip_confirmation
    Abort "$(un.PFI_LANG_ABORT_1)"

skip_confirmation:

  StrCpy ${L_SUBCORPUS} "yes"

  Push $INSTDIR
  Call un.GetCorpusPath
  Pop ${L_CORPUS}
  Push ${L_CORPUS}
  Push $INSTDIR
  Call un.StrStr
  Pop ${L_TEMP}
  StrCmp ${L_TEMP} "" 0 check_msg_folder
  StrCpy ${L_SUBCORPUS} "no"

check_msg_folder:
  StrCpy ${L_SUBHISTORY} "yes"

  Push $INSTDIR
  Call un.GetHistoryPath
  Pop ${L_HISTORY}
  Push ${L_HISTORY}
  Push $INSTDIR
  Call un.StrStr
  Pop ${L_TEMP}
  StrCmp ${L_TEMP} "" 0 check_if_running
  StrCpy ${L_SUBHISTORY} "no"

check_if_running:

  ; Insert call to un.WaitUntilUnlocked to avoid NSIS compiler warnings

  StrCpy ${L_EXE} "$INSTDIR\wperl.exe"
  Push ${L_EXE}
  Call un.WaitUntilUnlocked

  SetDetailsPrint textonly
  DetailPrint "$(un.PFI_LANG_PROGRESS_1)"
  SetDetailsPrint listonly

  StrCpy $G_GUI ""
  StrCpy ${L_OLDUI} ""

  ClearErrors
  FileOpen ${L_CFG} $INSTDIR\popfile.cfg r

loop:
  FileRead ${L_CFG} ${L_LNE}
  IfErrors ui_port_done

  StrCpy ${L_TEMP} ${L_LNE} 10
  StrCmp ${L_TEMP} "html_port " got_html_port

  StrCpy ${L_TEMP} ${L_LNE} 8
  StrCmp ${L_TEMP} "ui_port " got_ui_port
  Goto loop

got_html_port:
  StrCpy $G_GUI ${L_LNE} 5 10
  Goto loop

got_ui_port:
  StrCpy ${L_OLDUI} ${L_LNE} 5 8
  Goto loop

ui_port_done:
  FileClose ${L_CFG}

  StrCmp $G_GUI "" use_other_port
  Push $G_GUI
  Call un.TrimNewlines
  Call un.StrCheckDecimal
  Pop $G_GUI
  StrCmp $G_GUI "" use_other_port
  DetailPrint "$(un.PFI_LANG_LOG_1) $G_GUI"
  Sleep 250 ; milliseconds
  Goto remove_shortcuts

use_other_port:
  Push ${L_OLDUI}
  Call un.TrimNewlines
  Call un.StrCheckDecimal
  Pop ${L_OLDUI}
  StrCmp ${L_OLDUI} "" remove_shortcuts
  DetailPrint "$(un.PFI_LANG_LOG_1) ${L_OLDUI}"
  Sleep 250 ; milliseconds

remove_shortcuts:

  Sleep ${C_UNINST_PROGRESS_1_DELAY}

  SetDetailsPrint textonly
  DetailPrint "$(un.PFI_LANG_PROGRESS_2)"
  SetDetailsPrint listonly

  Delete "$SMPROGRAMS\${MUI_PRODUCT}\*.lnk"
  RMDir "$SMPROGRAMS\${MUI_PRODUCT}"

  Sleep ${C_UNINST_PROGRESS_2_DELAY}

  SetDetailsPrint textonly
  DetailPrint "$(un.PFI_LANG_PROGRESS_3)"
  SetDetailsPrint listonly

  Sleep ${C_UNINST_PROGRESS_3_DELAY}

  ; popfile.pl deleted to indicate an uninstall has occurred (file is checked during 'upgrade')

  Delete $INSTDIR\popfile.pl
  Delete $INSTDIR\popfile.cfg.bak

  ; For "upgrade" uninstalls, we leave most files in $INSTDIR
  ; and do not restore Outlook Express settings

  StrCmp ${L_UPGRADE} "yes" no_reg_file

  ; Note: 'translator.htm' is not deleted here
  ; (this ensures the message box showing the 'un.PFI_LANG_MBREMDIR_1' string appears later on)

  Delete $INSTDIR\*.pl
  Delete $INSTDIR\*.gif
  Delete $INSTDIR\*.exe
  Delete $INSTDIR\*.change
  Delete $INSTDIR\*.change.txt
  Delete $INSTDIR\license
  Delete $INSTDIR\popfile.cfg

  IfFileExists "$INSTDIR\popfile.reg.dummy" 0 no_reg_file

  SetDetailsPrint textonly
  DetailPrint "$(un.PFI_LANG_PROGRESS_4)"
  SetDetailsPrint listonly

  ; Read the registry settings found in popfile.reg.dummy and restore them
  ; it there are any.   All are assumed to be in HKCU

  ClearErrors
  FileOpen ${L_CFG} $INSTDIR\popfile.reg.dummy r
  IfErrors skip_registry_restore
  Sleep ${C_UNINST_PROGRESS_4_DELAY}

  DetailPrint "$(un.PFI_LANG_LOG_2): popfile.reg.dummy"

restore_loop:
  FileRead ${L_CFG} ${L_REG_KEY}
  Push ${L_REG_KEY}
  Call un.TrimNewlines
  Pop ${L_REG_KEY}
  IfErrors skip_registry_restore
  FileRead ${L_CFG} ${L_REG_SUBKEY}
  Push ${L_REG_SUBKEY}
  Call un.TrimNewlines
  Pop ${L_REG_SUBKEY}
  IfErrors skip_registry_restore
  FileRead ${L_CFG} ${L_REG_VALUE}
  Push ${L_REG_VALUE}
  Call un.TrimNewlines
  Pop ${L_REG_VALUE}
  IfErrors skip_registry_restore

  ; Testbed does NOT restore Outlook Express settings (it never changed them during 'install')

  DetailPrint "$(un.PFI_LANG_LOG_3) ${L_REG_SUBKEY}: ${L_REG_VALUE}"
  goto restore_loop

skip_registry_restore:
  FileClose ${L_CFG}
  DetailPrint "$(un.PFI_LANG_LOG_4): popfile.reg.dummy"
  Delete $INSTDIR\popfile.reg.dummy

no_reg_file:
  SetDetailsPrint textonly
  DetailPrint "$(un.PFI_LANG_PROGRESS_5)"
  SetDetailsPrint listonly

  Sleep ${C_UNINST_PROGRESS_5_DELAY}

  Delete $INSTDIR\languages\*.msg
  RMDir $INSTDIR\languages

  StrCmp ${L_UPGRADE} "yes" skip_corpus
  RMDir /r "$INSTDIR\corpus"

skip_corpus:
  Delete $INSTDIR\stopwords
  Delete $INSTDIR\stopwords.bak
  Delete $INSTDIR\stopwords.default

  StrCmp ${L_UPGRADE} "yes" remove_perl
  RMDir /r "$INSTDIR\messages"

remove_perl:
  SetDetailsPrint textonly
  DetailPrint "$(un.PFI_LANG_PROGRESS_6)"
  SetDetailsPrint listonly

  Sleep ${C_UNINST_PROGRESS_6_DELAY}

  StrCmp ${L_UPGRADE} "yes" Removed

  Delete "$INSTDIR\Uninstall.exe"

  RMDir $INSTDIR

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${MUI_PRODUCT}"
  DeleteRegKey HKLM "SOFTWARE\${MUI_PRODUCT}"

  ; if $INSTDIR was removed, skip these next ones

  IfFileExists $INSTDIR 0 Removed
    MessageBox MB_YESNO|MB_ICONQUESTION "$(un.PFI_LANG_MBREMDIR_1)" IDNO Removed
    DetailPrint "$(un.PFI_LANG_LOG_5)"
    Delete $INSTDIR\*.* ; this would be skipped if the user hits no
    RMDir /r $INSTDIR
    IfFileExists $INSTDIR 0 Removed
      DetailPrint "$(un.PFI_LANG_LOG_6)"
      MessageBox MB_OK|MB_ICONEXCLAMATION \
          "$(un.PFI_LANG_MBREMERR_1): $INSTDIR $(un.PFI_LANG_MBREMERR_2)"
Removed:

  SetDetailsPrint both

  !undef L_CFG
  !undef L_LNE
  !undef L_REG_KEY
  !undef L_REG_SUBKEY
  !undef L_REG_VALUE
  !undef L_TEMP
  !undef L_UPGRADE
  !undef L_CORPUS
  !undef L_SUBCORPUS
  !undef L_OLDUI
  !undef L_HISTORY
  !undef L_SUBHISTORY
  !undef L_EXE
SectionEnd

#--------------------------------------------------------------------------
# End of 'translator.nsi'
#--------------------------------------------------------------------------