#--------------------------------------------------------------------------
#
# adduser.nsi --- This is the NSIS script used to create the 'Add POPFile User' wizard
#                 which makes it easy to add a new POPFile user. If a multi-user install
#                 is performed, this wizard is installed in the main POPFile installation
#                 folder for use when a new user tries to run POPFile for the first time.
#
# Copyright (c) 2001-2004 John Graham-Cumming
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

; This version of the script has been tested with the "NSIS 2" compiler (final),
; released 7 February 2004, with no patches applied.
;
; Expect 3 compiler warnings, all related to standard NSIS language files which are out-of-date.

#--------------------------------------------------------------------------
# Compile-time command-line switches (used by 'makensis.exe')
#--------------------------------------------------------------------------
#
# /DENGLISH_MODE
#
# To build an 'Add POPFile User' wizard that only displays English messages (so there is no
# need to ensure all of the non-English *-pfi.nsh files are up-to-date), supply the command-line
# switch /DENGLISH_MODE when compiling this script. This switch only affects the language used
# by the wizard, it does not affect which files get installed.
#
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
# LANGUAGE SUPPORT:
#
# The wizard defaults to multi-language mode ('English' plus a number of other languages).
#
# If required, the command-line switch /DENGLISH_MODE can be used to build an English-only
# version.
#--------------------------------------------------------------------------
# Removing support for a particular language:
#
# To remove any of the additional languages, only TWO lines need to be commented-out:
#
# (a) comment-out the relevant '!insertmacro PFI_LANG_LOAD' line in the list of languages
#     in the 'Language Support for the installer and uninstaller' block of code
#
# (b) comment-out the relevant '!insertmacro UI_LANG_CONFIG' line in the list of languages
#     in the code which preselects the UI language
#
# For example, to remove support for the 'Dutch' language, comment-out the line
#
#     !insertmacro PFI_LANG_LOAD "Dutch"
#
# in the list of languages supported by the wizard, and comment-out the line
#
#     !insertmacro UI_LANG_CONFIG "DUTCH" "Nederlands"
#
# in the code which preselects the UI language (Section "Languages").
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
# To add support for a language which is already supported by the NSIS MUI package, an extra
# file is required:
#
# <NSIS Language NAME>-pfi.nsh  -  holds customised versions of the standard MUI text strings
#                                  plus strings used on the custom pages and elsewhere
#
# Once this file has been prepared and placed in the 'windows\languages' directory with the
# other *-pfi.nsh files, add a new '!insertmacro PFI_LANG_LOAD' line to load this new file
# and, if there is a suitable POPFile UI language file for the new language, add a suitable
# '!insertmacro UI_LANG_CONFIG' line in the section which handles the optional 'Languages'
# component to allow the wizard to select the appropriate UI language.
#--------------------------------------------------------------------------

  ;------------------------------------------------
  ; Define PFI_VERBOSE to get more compiler output
  ;------------------------------------------------

## !define PFI_VERBOSE

  ;--------------------------------------------------------------------------
  ; POPFile constants have been given names beginning with 'C_' (eg C_README)
  ;--------------------------------------------------------------------------

  ; This build is for use with the POPFile installer

  !define C_PFI_PRODUCT  "POPFile"

  Name                   "POPFile User"

  !define C_PFI_VERSION  "0.1.0"

  ; Mention the wizard's version number in the titles of the installer & uninstaller windows

  Caption                "Add POPFile User v${C_PFI_VERSION}"
  UninstallCaption       "Remove POPFile User v${C_PFI_VERSION}"

  ;----------------------------------------------------------------------
  ; Default location for POPFile User Data files (popfile.cfg and others)
  ;
  ; Detection of the 'current user' path for $APPDATA requires Internet Explorer 4 and above.
  ; Detection of the 'all users' path for $APPDATA requires Internet Explorer 5 and above.
  ;
  ; NOTE: Windows 95 systems with Internet Explorer 4 installed also need to have
  ;       Active Desktop installed, otherwise $APPDATA will not be available. For
  ;       these cases, an alternative constant is used to define the default location.
  ;----------------------------------------------------------------------

  !define C_STD_DEFAULT_USERDATA  "$APPDATA\POPFile"
  !define C_ALT_DEFAULT_USERDATA  "$WINDIR\Application Data\POPFile"

  ;--------------------------------------------------------------------------------
  ; Constants for the timeout loop used after issuing a POPFile 'shutdown' request
  ;--------------------------------------------------------------------------------

  ; Timeout loop counter start value (counts down to 0)

  !define C_SHUTDOWN_LIMIT    20

  ; Delay (in milliseconds) used inside the timeout loop

  !define C_SHUTDOWN_DELAY    1000

  ;-------------------------------------------------------------------------------
  ; Constants for the timeout loop used after issuing a POPFile 'startup' request
  ;-------------------------------------------------------------------------------

  ; Timeout loop counter start value (counts down to 0)

  !define C_STARTUP_LIMIT    20

  ; Delay (in milliseconds) used inside the timeout loop

  !define C_STARTUP_DELAY    1000

  ;-------------------------------------------------------------------------------
  ; Constant used to avoid problems with Banner.dll
  ;
  ; (some versions of the DLL do not like being 'destroyed' immediately)
  ;-------------------------------------------------------------------------------

  ; Minimum time for the banner to be shown (in milliseconds)

  !define C_MIN_BANNER_DISPLAY_TIME    250

#--------------------------------------------------------------------------
# User Registers (Global)
#--------------------------------------------------------------------------

  ; This script uses 'User Variables' (with names starting with 'G_') to hold GLOBAL data.

  Var G_ROOTDIR            ; full path to the folder used for the POPFile program files
  Var G_USERDIR            ; full path to the folder containing the 'popfile.cfg' file
  Var G_MPBINDIR           ; full path to the folder used for the minimal Perl EXE and DLL files
  Var G_MPLIBDIR           ; full path to the folder used for the rest of the minimal Perl files

  Var G_POP3               ; POP3 port (1-65535)
  Var G_GUI                ; GUI port (1-65535)
  Var G_STARTUP            ; automatic startup flag (1 = yes, 0 = no)

  Var G_OOECONFIG_HANDLE   ; to access list of all Outlook/Outlook Express accounts found
  Var G_OOECHANGES_HANDLE  ; to access list of Outlook/Outlook Express configuration changes
  Var G_OOELIST_INDEX      ; to access the list of up to 6 Outlook/Outlook Express accounts
  Var G_OOELIST_CBOX       ; to access one of the 6 checkbox fields on the configuration page
  Var G_SEPARATOR          ; character used to separate the POP3 server from the username

  Var G_HWND               ; HWND of the dialog we are going to modify
  Var G_DLGITEM            ; HWND of the field we are going to modify on that dialog
  Var G_FONT               ; the font we use to modify that field

  Var G_WINUSERNAME        ; current Windows user login name
  Var G_WINUSERTYPE        ; user group ('Admin', 'Power', 'User', 'Guest' or 'Unknown')

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
# Use the "Modern User Interface"
#--------------------------------------------------------------------------

  !include "MUI.nsh"

#--------------------------------------------------------------------------
# Version Information settings (for the installer EXE and uninstaller EXE)
#--------------------------------------------------------------------------

  ; 'VIProductVersion' format is X.X.X.X where X is a number in range 0 to 65535
  ; representing the following values: Major.Minor.Release.Build

  VIProductVersion "${C_PFI_VERSION}.0"

  VIAddVersionKey "ProductName" "POPFile User wizard"
  VIAddVersionKey "Comments" "POPFile Homepage: http://popfile.sf.net"
  VIAddVersionKey "CompanyName" "The POPFile Project"
  VIAddVersionKey "LegalCopyright" "� 2004  John Graham-Cumming"
  VIAddVersionKey "FileDescription" "Add/Remove POPFile User wizard"
  VIAddVersionKey "FileVersion" "${C_PFI_VERSION}"

  !ifndef ENGLISH_MODE
    VIAddVersionKey "Build" "Multi-Language"
  !else
    VIAddVersionKey "Build" "English-Mode"
  !endif

  VIAddVersionKey "Build Date/Time" "${__DATE__} @ ${__TIME__}"
  VIAddVersionKey "Build Script" "${__FILE__}$\r$\n(${__TIMESTAMP__})"

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
  !define CBP_DEFAULT_LIST "spam|personal|work|other"
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

  ; Avoid compiler warnings by disabling the functions and definitions we do not use

  !define ADDUSER "active"

  !include pfi-library.nsh
  !include WriteEnvStr.nsh

#--------------------------------------------------------------------------
# Configure the MUI pages
#--------------------------------------------------------------------------

  ;----------------------------------------------------------------
  ; Interface Settings - General Interface Settings
  ;----------------------------------------------------------------

  ; The icon files for the installer and uninstaller must have the same structure. For example,
  ; if one icon file contains a 32x32 16-colour image and a 16x16 16-colour image then the other
  ; file cannot just contain a 32x32 16-colour image, it must also have a 16x16 16-colour image.
  ; The order of the images in each icon file must also be the same.

  !define MUI_ICON    "POPFileIcon\popfile.ico"
  !define MUI_UNICON  "remove.ico"

  ; The "Header" bitmap appears on all pages of the installer (except Welcome & Finish pages)
  ; and on all pages of the uninstaller.

  !define MUI_HEADERIMAGE
  !define MUI_HEADERIMAGE_BITMAP "hdr-common.bmp"
  !define MUI_HEADERIMAGE_RIGHT

  ;----------------------------------------------------------------
  ;  Interface Settings - Interface Resource Settings
  ;----------------------------------------------------------------

  ; The banner provided by the default 'modern.exe' UI does not provide much room for the
  ; two lines of text, e.g. the German version is truncated, so we use a custom UI which
  ; provides slightly wider text areas. Each area is still limited to a single line of text.

  !define MUI_UI "UI\pfi_modern.exe"

  ; The 'hdr-common.bmp' logo is only 90 x 57 pixels, much smaller than the 150 x 57 pixel
  ; space provided by the default 'modern_headerbmpr.exe' UI, so we use a custom UI which
  ; leaves more room for the TITLE and SUBTITLE text.

  !define MUI_UI_HEADERIMAGE_RIGHT "UI\pfi_headerbmpr.exe"

  ;----------------------------------------------------------------
  ;  Interface Settings - Welcome/Finish Page Interface Settings
  ;----------------------------------------------------------------

  ; The "Special" bitmap appears on the "Welcome" and "Finish" pages

  !define MUI_WELCOMEFINISHPAGE_BITMAP "special.bmp"

  ;----------------------------------------------------------------
  ;  Interface Settings - Installer Finish Page Interface Settings
  ;----------------------------------------------------------------

  ; Debug aid: Hide the installation log but let user display it (using "Show details" button)

##  !define MUI_FINISHPAGE_NOAUTOCLOSE

  ;----------------------------------------------------------------
  ;  Interface Settings - Abort Warning Settings
  ;----------------------------------------------------------------

  ; Show a message box with a warning when the user closes the installation

  !define MUI_ABORTWARNING

  ;----------------------------------------------------------------
  ; Customize MUI - General Custom Function
  ;----------------------------------------------------------------

  ; Use a custom '.onGUIInit' function to add language-specific texts to custom page INI files

  !define MUI_CUSTOMFUNCTION_GUIINIT PFIGUIInit

  ; Use a custom 'un.onGUIInit' function to allow language-specific texts in the username check

  !define MUI_CUSTOMFUNCTION_UNGUIINIT un.PFIGUIInit

  ;----------------------------------------------------------------
  ; Language Settings for MUI pages
  ;----------------------------------------------------------------

  ; Same "Language selection" dialog is used for the installer and the uninstaller
  ; so we override the standard "Installer Language" title to avoid confusion.

  !define MUI_LANGDLL_WINDOWTITLE "Add/Remove POPFile User"

  ; Always show the language selection dialog, even if a language has been stored in the
  ; registry (the language stored in the registry will be selected as the default language)
  ; This makes it easy to recover from a previous 'bad' choice of language for the installer

  !define MUI_LANGDLL_ALWAYSSHOW

  ; Remember user's language selection and offer this as the default when re-installing
  ; (uninstaller also uses this setting to determine which language is to be used)

  !define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
  !define MUI_LANGDLL_REGISTRY_KEY "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI"
  !define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"

#--------------------------------------------------------------------------
# Define the Page order for the installer (and the uninstaller)
#--------------------------------------------------------------------------

  ;---------------------------------------------------
  ; Installer Page - Welcome
  ;---------------------------------------------------

  !define MUI_WELCOMEPAGE_TEXT "$(PFI_LANG_ADDUSER_INFO_TEXT)"

  ; Use a "leave" function to look for an existing 'popfile.cfg' and decide upon a suitable
  ; default value for the user data folder (this default value is used when displaying the
  ; DIRECTORY page used to select 'User Data' location). For this build, we do not attempt to
  ; relocate the user data when upgrading a POPFile installation.

  !define MUI_PAGE_CUSTOMFUNCTION_LEAVE "CheckExistingConfig"

  !insertmacro MUI_PAGE_WELCOME

  ;---------------------------------------------------
  ; Installer Page - Select user data Directory
  ;---------------------------------------------------

  ; This page is used to select the folder for the POPFile USER DATA files

  !define MUI_DIRECTORYPAGE_VARIABLE          $G_USERDIR

  !define MUI_PAGE_HEADER_TEXT                "$(PFI_LANG_USERDIR_TITLE)"
  !define MUI_PAGE_HEADER_SUBTEXT             "$(PFI_LANG_USERDIR_SUBTITLE)"
  !define MUI_DIRECTORYPAGE_TEXT_TOP          "$(PFI_LANG_USERDIR_TEXT_TOP)"
  !define MUI_DIRECTORYPAGE_TEXT_DESTINATION  "$(PFI_LANG_USERDIR_TEXT_DESTN)"

  !insertmacro MUI_PAGE_DIRECTORY

  ;---------------------------------------------------
  ; Installer Page - POP3 and UI Port Options
  ;---------------------------------------------------

  Page custom SetOptionsPage "CheckPortOptions"

  ;---------------------------------------------------
  ; Installer Page - Install files
  ;---------------------------------------------------

  !define MUI_PAGE_HEADER_TEXT                "$(PFI_LANG_ADDUSER_TITLE)"
  !define MUI_PAGE_HEADER_SUBTEXT             "$(PFI_LANG_ADDUSER_SUBTITLE)"

  !insertmacro MUI_PAGE_INSTFILES

  ;---------------------------------------------------
  ; Installer Page - Create Buckets (if necessary)
  ;---------------------------------------------------

  !insertmacro CBP_PAGE_SELECTBUCKETS

  ;---------------------------------------------------
  ; Installer Page - Email Client Configuration
  ;---------------------------------------------------

  Page custom SetEmailClientPage

  ;---------------------------------------------------
  ; Installer Page - Configure Outlook Express accounts
  ;---------------------------------------------------

  Page custom SetOutlookExpressPage "CheckOutlookExpressRequests"

  ;---------------------------------------------------
  ; Installer Page - Configure Outlook accounts
  ;---------------------------------------------------

  Page custom SetOutlookPage "CheckOutlookRequests"

  ;---------------------------------------------------
  ; Installer Page - Configure Eudora personalities
  ;---------------------------------------------------

  Page custom SetEudoraPage

  ;---------------------------------------------------
  ; Installer Page - Choose POPFile launch mode
  ;---------------------------------------------------

  Page custom StartPOPFilePage "CheckLaunchOptions"

  ;---------------------------------------------------
  ; Installer Page - Finish (may offer to start UI)
  ;---------------------------------------------------

  !define MUI_FINISHPAGE_TEXT         "$(PFI_LANG_ADDUSER_FINISH_INFO)"

  ; Use a "pre" function for the 'Finish' page to ensure installer only offers to display
  ; POPFile User Interface if user has chosen to start POPFile from the installer.

  !define MUI_PAGE_CUSTOMFUNCTION_PRE "CheckRunStatus"

  ; Offer to display the POPFile User Interface (The 'CheckRunStatus' function ensures this
  ; option is only offered if the installer has started POPFile running)

  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_TEXT     "$(PFI_LANG_FINISH_RUN_TEXT)"
  !define MUI_FINISHPAGE_RUN_FUNCTION "RunUI"

  !insertmacro MUI_PAGE_FINISH

  ;---------------------------------------------------
  ; Uninstaller Page - Confirmation Page
  ;---------------------------------------------------

  !define MUI_PAGE_HEADER_TEXT                "$(PFI_LANG_REMUSER_TITLE)"
  !define MUI_PAGE_HEADER_SUBTEXT             "$(PFI_LANG_REMUSER_SUBTITLE)"
  !define MUI_UNCONFIRMPAGE_TEXT_TOP          "$(PFI_LANG_REMUSER_TEXT_TOP)"

  !insertmacro MUI_UNPAGE_CONFIRM

  ;---------------------------------------------------
  ; Uninstaller Page - Uninstall POPFile
  ;---------------------------------------------------

  !define MUI_PAGE_HEADER_TEXT                "$(PFI_LANG_REMOVING_TITLE)"
  !define MUI_PAGE_HEADER_SUBTEXT             "$(PFI_LANG_REMOVING_SUBTITLE)"

  !insertmacro MUI_UNPAGE_INSTFILES

#--------------------------------------------------------------------------
# Language Support for the installer and uninstaller
#--------------------------------------------------------------------------

  ;-----------------------------------------
  ; Select the languages to be supported by installer/uninstaller.
  ; Currently a subset of the languages supported by NSIS MUI 1.70 (using the NSIS names)
  ;-----------------------------------------

  ; At least one language must be specified for the installer (the default is "English")

  !insertmacro PFI_LANG_LOAD "English"

  ; Conditional compilation: if ENGLISH_MODE is defined, support only 'English'

  !ifndef ENGLISH_MODE

        ; Additional languages supported by the installer.

        ; To remove a language, comment-out the relevant '!insertmacro PFI_LANG_LOAD' line
        ; from this list. (To remove all of these languages, use /DENGLISH_MODE on command-line)

        ; Entries will appear in the drop-down list of languages in the order given below
        ; (the order used here ensures that the list entries appear in alphabetic order).

        !insertmacro PFI_LANG_LOAD "Bulgarian"
        !insertmacro PFI_LANG_LOAD "SimpChinese"
        !insertmacro PFI_LANG_LOAD "TradChinese"
        !insertmacro PFI_LANG_LOAD "Czech"
        !insertmacro PFI_LANG_LOAD "Danish"
        !insertmacro PFI_LANG_LOAD "German"
        !insertmacro PFI_LANG_LOAD "Spanish"
        !insertmacro PFI_LANG_LOAD "French"
        !insertmacro PFI_LANG_LOAD "Greek"
        !insertmacro PFI_LANG_LOAD "Italian"
        !insertmacro PFI_LANG_LOAD "Japanese"
        !insertmacro PFI_LANG_LOAD "Korean"
        !insertmacro PFI_LANG_LOAD "Hungarian"
        !insertmacro PFI_LANG_LOAD "Dutch"
        !insertmacro PFI_LANG_LOAD "Norwegian"
        !insertmacro PFI_LANG_LOAD "Polish"
        !insertmacro PFI_LANG_LOAD "Portuguese"
        !insertmacro PFI_LANG_LOAD "PortugueseBR"
        !insertmacro PFI_LANG_LOAD "Russian"
        !insertmacro PFI_LANG_LOAD "Slovak"
        !insertmacro PFI_LANG_LOAD "Finnish"
        !insertmacro PFI_LANG_LOAD "Swedish"
        !insertmacro PFI_LANG_LOAD "Turkish"
        !insertmacro PFI_LANG_LOAD "Ukrainian"

  !endif

#--------------------------------------------------------------------------
# General settings
#--------------------------------------------------------------------------

  ; Specify NSIS output filename

  OutFile "adduser.exe"

  ; Ensure CRC checking cannot be turned off using the /NCRC command-line switch

  CRCcheck Force

#--------------------------------------------------------------------------
# Default Destination Folder
#--------------------------------------------------------------------------

  InstallDir "${C_STD_DEFAULT_USERDATA}"

#--------------------------------------------------------------------------
# Reserve the files required by the installer (to improve performance)
#--------------------------------------------------------------------------

  ; Things that need to be extracted on startup (keep these lines before any File command!)
  ; Only useful when solid compression is used (by default, solid compression is enabled
  ; for BZIP2 and LZMA compression)

  !insertmacro MUI_RESERVEFILE_LANGDLL
  !insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
  ReserveFile "ioA.ini"
  ReserveFile "ioB.ini"
  ReserveFile "ioC.ini"
  ReserveFile "ioD.ini"
  ReserveFile "ioE.ini"
  ReserveFile "ioF.ini"
  ReserveFile "ioG.ini"

#--------------------------------------------------------------------------
# Installer Function: .onInit - installer starts by offering a choice of languages
#--------------------------------------------------------------------------

Function .onInit

  ; Conditional compilation: if ENGLISH_MODE is defined, support only 'English'

  !ifndef ENGLISH_MODE
        !insertmacro MUI_LANGDLL_DISPLAY
  !endif

  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioA.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioB.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioC.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioD.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioE.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioF.ini"
  !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioG.ini"

  ; The 'UserInfo' plugin may return an error if run on a Win9x system but since Win9x systems
  ; do not support different account types, we treat this error as if user has 'Admin' rights.

	ClearErrors
	UserInfo::GetName
	IfErrors 0 got_name

  ; Assume Win9x system, so user has 'Admin' rights (To do: look for username in Registry?)
  ; (UserInfo works on Win98SE so perhaps it is only Win95 that fails ?)

  StrCpy $G_WINUSERNAME "UnknownUser"
  StrCpy $G_WINUSERTYPE "Admin"
  Goto exit

got_name:
	Pop $G_WINUSERNAME
  StrCmp $G_WINUSERNAME "" 0 get_usertype
  StrCpy $G_WINUSERNAME "UnknownUser"

get_usertype:
  UserInfo::GetAccountType
	Pop $G_WINUSERTYPE
  StrCmp $G_WINUSERTYPE "Admin" exit
  StrCmp $G_WINUSERTYPE "Power" exit
  StrCmp $G_WINUSERTYPE "User" exit
  StrCmp $G_WINUSERTYPE "Guest" exit
  StrCpy $G_WINUSERTYPE "Unknown"

exit:
FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: PFIGUIInit
# (custom .onGUIInit function)
#
# Used to complete the initialization of the installer.
# This code was moved from '.onInit' in order to permit the use of language-specific strings
# (the selected language is not available inside the '.onInit' function)
#--------------------------------------------------------------------------

Function PFIGUIInit

  !define L_RESERVED            $1    ; used in the system.dll call

  Push ${L_RESERVED}

  ReadRegStr ${L_RESERVED} HKLM "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "InstallPath"
  StrCmp ${L_RESERVED} "" 0 continue
  MessageBox MB_OK|MB_ICONSTOP "Error: Cannot find compatible version of POPFile !"
  Abort

continue:

  ; Ensure only one copy of this installer is running

  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "OnlyOnePFI_mutex") i .r1 ?e'
  Pop ${L_RESERVED}
  StrCmp ${L_RESERVED} 0 mutex_ok
  MessageBox MB_OK|MB_ICONEXCLAMATION "$(PFI_LANG_INSTALLER_MUTEX)"
  Abort

mutex_ok:
  ReadRegStr $G_ROOTDIR HKLM "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "InstallPath"

  ; Insert appropriate language strings into the custom page INI files
  ; (the CBP package creates its own INI file so there is no need for a CBP *Page_Init function)

  Call SetOptionsPage_Init
  Call SetEmailClientPage_Init
  Call SetOutlookOutlookExpressPage_Init
  Call SetEudoraPage_Init
  Call StartPOPFilePage_Init

  Pop ${L_RESERVED}

  !undef L_RESERVED

FunctionEnd

#--------------------------------------------------------------------------
# Installer Section: POPFile component
#--------------------------------------------------------------------------

Section "POPFile" SecPOPFile

  ; Make this section mandatory (i.e. it is always installed)

  SectionIn RO

  !define L_CFG           $R9   ; file handle
  !define L_POPFILE_ROOT  $R8
  !define L_POPFILE_USER  $R7
  !define L_TEMP          $R6
  !define L_TEMP_2        $R5
  !define L_TEMP_3        $R4
  !define L_TEMP_4        $R3
  !define L_TEMP_5        $R2

  !define L_RESERVED      $0    ; used in system.dll calls
  Push ${L_RESERVED}

  Push ${L_CFG}
  Push ${L_POPFILE_ROOT}
  Push ${L_POPFILE_USER}
  Push ${L_TEMP}
  Push ${L_TEMP_2}
  Push ${L_TEMP_3}
  Push ${L_TEMP_4}
  Push ${L_TEMP_5}

  ; For this build, each user is expected to have separate user data folders. The installer uses
  ; the $G_USERDIR variable to hold the full path to this folder. By default each folder will
  ; contain popfile.cfg, stopwords, stopwords.default, popfile.db, the messages folder, etc.
  ; If an existing flat file or BerkeleyDB corpus has been converted to the new SQL database
  ; format, a backup copy of the old corpus will be saved in the $G_USERDIR\backup folder.
  ; If we are upgrading a prior version  of POPFile, the user data is found in $INSTDIR
  ; so we set $G_USERDIR to $INSTDIR when suggesting a location for the user data.

  ; For increased flexibility, four global user variables are used in addition to $INSTDIR
  ; (this makes it easier to change the folder structure used by the installer).

  StrCpy $G_MPBINDIR  "$G_ROOTDIR"
  StrCpy $G_MPLIBDIR  "$G_ROOTDIR\lib"

  ; The fourth global variable ($G_USERDIR) is initialized by the 'CheckExistingConfig' function
  ; and may be changed by the user via the second DIRECTORY page.

  ; Retrieve the POP3 and GUI ports from the ini and get whether we install the
  ; POPFile run in the Startup group

  !insertmacro MUI_INSTALLOPTIONS_READ $G_POP3    "ioA.ini" "Field 2" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $G_GUI     "ioA.ini" "Field 4" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $G_STARTUP "ioA.ini" "Field 5" "State"

  ReadRegStr ${L_TEMP_2} HKLM "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "POPFile Major Version"
  ReadRegStr ${L_TEMP_3} HKLM "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "POPFile Minor Version"
  ReadRegStr ${L_TEMP_4} HKLM "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "POPFile Revision"
  ReadRegStr ${L_TEMP_5} HKLM "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "POPFile RevStatus"

  WriteRegStr HKCU "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "POPFile Major Version" "${L_TEMP_2}"
  WriteRegStr HKCU "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "POPFile Minor Version" "${L_TEMP_3}"
  WriteRegStr HKCU "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "POPFile Revision" "${L_TEMP_4}"
  WriteRegStr HKCU "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "POPFile RevStatus" "${L_TEMP_5}"
  WriteRegStr HKCU "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "Author" "adduser.exe"

  ReadRegStr ${L_TEMP} HKLM "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "InstallPath"
  Push ${L_TEMP}
  Call StrLower
  Pop ${L_TEMP}
  WriteRegStr HKCU "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "RootDir_LFN" "${L_TEMP}"
  GetFullPathName /SHORT ${L_TEMP_2} ${L_TEMP}
  Push ${L_TEMP_2}
  Call StrLower
  Pop ${L_TEMP_2}
  WriteRegStr HKCU "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "RootDir_SFN" "${L_TEMP_2}"

  IfFileExists "$G_USERDIR\*.*" userdir_exists
  ClearErrors
  CreateDirectory $G_USERDIR
  IfErrors 0 userdir_exists
  MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST "Error: Unable to create folder for user data\
      $\r$\n$\r$\n\
      ($G_USERDIR)"

userdir_exists:
  WriteINIStr "$G_USERDIR\install.ini" "Settings" "Owner" "$G_WINUSERNAME"
  WriteINIStr "$G_USERDIR\install.ini" "Settings" "Class" "$G_WINUSERTYPE"
  WriteINIStr "$G_USERDIR\install.ini" "Settings" "LastU" "adduser.exe"

  WriteRegStr HKCU "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "UserDataPath" "$G_USERDIR"
  Push $G_USERDIR
  Call StrLower
  Pop ${L_TEMP}
  WriteRegStr HKCU "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "UserDir_LFN" "${L_TEMP}"
  GetFullPathName /SHORT ${L_TEMP_2} $G_USERDIR
  Push ${L_TEMP_2}
  Call StrLower
  Pop ${L_TEMP_2}
  WriteRegStr HKCU "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "UserDir_SFN" "${L_TEMP_2}"

  ; Now ensure the POPFILE_ROOT and POPFILE_USER environment variables have the correct data

  ; On non-Win9x systems we create entries in the registry to do this. On Win9x we could use
  ; AUTOEXEC.BAT to do something similar but that would require a reboot to action the changes
  ; required when one user logs off and another logs on, so we don't bother.

  ; On all systems we update these two environment variables NOW (i.e for this process)
  ; so we can start POPFile from the installer.

  ReadRegStr ${L_POPFILE_ROOT} HKCU "Software\POPFile Project\${C_PFI_PRODUCT}\MRI" "RootDir_SFN"
  ReadEnvStr ${L_TEMP} "POPFILE_ROOT"
  StrCmp ${L_POPFILE_ROOT} ${L_TEMP} root_set_ok
  Call IsNT
  Pop ${L_RESERVED}
  StrCmp ${L_RESERVED} 0 set_root_now
  WriteRegStr HKCU "Environment" "POPFILE_ROOT" ${L_POPFILE_ROOT}
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

set_root_now:
  System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("POPFILE_ROOT", "${L_POPFILE_ROOT}").r0'
  StrCmp ${L_RESERVED} 0 0 root_set_ok
  MessageBox MB_OK|MB_ICONSTOP "$(PFI_LANG_CONVERT_ENVNOTSET) (POPFILE_ROOT)"

root_set_ok:
  ReadRegStr ${L_POPFILE_USER} HKCU "Software\POPFile Project\${C_PFI_PRODUCT}\MRI" "UserDir_SFN"
  ReadEnvStr ${L_TEMP} "POPFILE_USER"
  StrCmp ${L_POPFILE_USER} ${L_TEMP} continue
  Call IsNT
  Pop ${L_RESERVED}
  StrCmp ${L_RESERVED} 0 set_user_now
  WriteRegStr HKCU "Environment" "POPFILE_USER" ${L_POPFILE_USER}
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

set_user_now:
  System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("POPFILE_USER", "${L_POPFILE_USER}").r0'
  StrCmp ${L_RESERVED} 0 0 continue
  MessageBox MB_OK|MB_ICONSTOP "$(PFI_LANG_CONVERT_ENVNOTSET) (POPFILE_USER)"

continue:
  SetOutPath $G_USERDIR

  ; Create a shortcut to make it easier to run the SQLite utility

  CreateShortCut "$G_USERDIR\Run SQLite utility.lnk" \
                 "$G_ROOTDIR\sqlite.exe" "popfile.db"

  IfFileExists "$G_USERDIR\stopwords" 0 copy_stopwords
  MessageBox MB_YESNO|MB_ICONQUESTION \
      "POPFile 'stopwords' $(PFI_LANG_MBSTPWDS_1)\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBSTPWDS_2)\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBSTPWDS_3) 'stopwords.bak')\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBSTPWDS_4) 'stopwords.default')" IDNO copy_default_stopwords
  IfFileExists "$G_USERDIR\stopwords.bak" 0 make_backup
  SetFileAttributes "$G_USERDIR\stopwords.bak" NORMAL

make_backup:
  CopyFiles /SILENT /FILESONLY "$G_USERDIR\stopwords" "$G_USERDIR\stopwords.bak"

copy_stopwords:
  File "..\engine\stopwords"

copy_default_stopwords:
  File /oname=stopwords.default "..\engine\stopwords"
  FileOpen  ${L_CFG} $PLUGINSDIR\popfile.cfg a
  FileSeek  ${L_CFG} 0 END
  FileWrite ${L_CFG} "pop3_port $G_POP3$\r$\n"
  FileWrite ${L_CFG} "html_port $G_GUI$\r$\n"
  FileClose ${L_CFG}
  IfFileExists "$G_USERDIR\popfile.cfg" 0 update_config
  SetFileAttributes "$G_USERDIR\popfile.cfg" NORMAL
  IfFileExists "$G_USERDIR\popfile.cfg.bak" 0 make_cfg_backup
  MessageBox MB_YESNO|MB_ICONQUESTION \
      "$(PFI_LANG_MBCFGBK_1) 'popfile.cfg' $(PFI_LANG_MBCFGBK_2) ('popfile.cfg.bak').\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBCFGBK_3)\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBCFGBK_4)" IDNO update_config
  SetFileAttributes "$G_USERDIR\popfile.cfg.bak" NORMAL

make_cfg_backup:
  CopyFiles /SILENT /FILESONLY $G_USERDIR\popfile.cfg $G_USERDIR\popfile.cfg.bak

update_config:
  CopyFiles /SILENT /FILESONLY $PLUGINSDIR\popfile.cfg $G_USERDIR\

  ; Create the uninstall program BEFORE creating the shortcut to it
  ; (this ensures that the correct "uninstall" icon appears in the START MENU shortcut)

  ; NOTE: The main POPFile installer uses 'uninstall.exe' so we have to use a different name
  ; in case user has selected the main POPFile directory for the user data

  SetOutPath $G_USERDIR
  Delete $G_USERDIR\uninstalluser.exe
  WriteUninstaller $G_USERDIR\uninstalluser.exe

  ; Create entry in the Control Panel's "Add/Remove Programs" list

  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${C_PFI_PRODUCT}_Data" \
              "DisplayName" "${C_PFI_PRODUCT} ($G_WINUSERNAME)"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${C_PFI_PRODUCT}_Data" \
              "UninstallString" "$G_USERDIR\uninstalluser.exe"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${C_PFI_PRODUCT}_Data" \
              "NoModify" "1"
  WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${C_PFI_PRODUCT}_Data" \
              "NoRepair" "1"

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_ENDSEC)"
  SetDetailsPrint listonly

  Pop ${L_TEMP_5}
  Pop ${L_TEMP_4}
  Pop ${L_TEMP_3}
  Pop ${L_TEMP_2}
  Pop ${L_TEMP}
  Pop ${L_POPFILE_USER}
  Pop ${L_POPFILE_ROOT}
  Pop ${L_CFG}

  Pop ${L_RESERVED}
  !undef L_RESERVED

  !undef L_CFG
  !undef L_POPFILE_ROOT
  !undef L_POPFILE_USER
  !undef L_TEMP
  !undef L_TEMP_2
  !undef L_TEMP_3
  !undef L_TEMP_4
  !undef L_TEMP_5

SectionEnd

#--------------------------------------------------------------------------
# Installer Section: Flat File or BerkeleyDB Corpus Backup component (always 'installed')
#
# If we are performing an upgrade of a 'flat file' or 'BerkeleyDB' version of POPFile, we make
# a backup of the old corpus structure. Note that if a backup already exists, we do nothing.
#
# The backup is created in the '$INSTDIR\backup' folder. Information on the backup is stored
# in the 'backup.ini' file to assist in restoring the old corpus. A copy of 'popfile.cfg'
# is also placed in the backup folder.
#
# If corpus conversion is required, create a list of bucket files to be monitored during the
# conversion process (it can take several minutes to convert large corpus files)
#--------------------------------------------------------------------------

Section "-NonSQLCorpusBackup" SecBackup

  !define L_CFG_HANDLE    $R9     ; handle for "popfile.cfg"
  !define L_BUCKET_COUNT  $R8     ; used to update the list of bucket filenames
  !define L_BUCKET_NAME   $R7     ; name of a bucket folder
  !define L_CORPUS_PATH   $R6     ; full path to the corpus
  !define L_CORPUS_SIZE   $R5     ; total number of bytes in all the table/table.db files found
  !define L_FOLDER_COUNT  $R4     ; used to update the list of bucket folder paths
  !define L_TEMP          $R3

  Push ${L_CFG_HANDLE}
  Push ${L_BUCKET_COUNT}
  Push ${L_BUCKET_NAME}
  Push ${L_CORPUS_PATH}
  Push ${L_CORPUS_SIZE}
  Push ${L_FOLDER_COUNT}
  Push ${L_TEMP}

  IfFileExists "$G_USERDIR\popfile.cfg" 0 exit
  IfFileExists "$G_USERDIR\backup\nonsql\*.*" exit

  ; Save installation-specific data for use by the 'Monitor Corpus Conversion' utility

  WriteINIStr "$PLUGINSDIR\corpus.ini" "Settings" "PERLDIR" "$G_MPBINDIR"
  WriteINIStr "$PLUGINSDIR\corpus.ini" "Settings" "ROOTDIR" "$G_ROOTDIR"
  WriteINIStr "$PLUGINSDIR\corpus.ini" "Settings" "USERDIR" "$G_USERDIR"
  WriteINIStr "$PLUGINSDIR\corpus.ini" "Settings" "KReboot"  "no"

  ; Use data in 'popfile.cfg' to generate the full path to the corpus folder

  Push $G_USERDIR
  Call GetCorpusPath
  Pop ${L_CORPUS_PATH}

  StrCpy ${L_FOLDER_COUNT} 0
  WriteINIStr "$PLUGINSDIR\corpus.ini" "FolderList" "MaxNum" ${L_FOLDER_COUNT}

  StrCpy ${L_BUCKET_COUNT} 0
  WriteINIStr "$PLUGINSDIR\corpus.ini" "BucketList" "FileCount" ${L_BUCKET_COUNT}

  FindFirst ${L_CFG_HANDLE} ${L_BUCKET_NAME} ${L_CORPUS_PATH}\*.*

  ; If the "corpus" directory does not exist then "${L_CFG_HANDLE}" will be empty

  StrCmp ${L_CFG_HANDLE} "" nothing_to_backup

  StrCpy ${L_CORPUS_SIZE} 0

  FindNext ${L_CFG_HANDLE} ${L_BUCKET_NAME}
  StrCmp ${L_BUCKET_NAME} ".." corpus_check
  StrCmp ${L_BUCKET_NAME} "" check_bucket_count got_bucket_name

  ; Now search through the corpus folder, looking for buckets

corpus_check:
  FindNext ${L_CFG_HANDLE} ${L_BUCKET_NAME}
  StrCmp ${L_BUCKET_NAME} "" check_bucket_count

got_bucket_name:

  IfFileExists "${L_CORPUS_PATH}\${L_BUCKET_NAME}\*.*" 0 corpus_check

  ; Have found a folder, so we make a note to make it easier to remove the folder after
  ; corpus conversion has been completed (folder will only be removed if it is empty)

  IntOp ${L_FOLDER_COUNT} ${L_FOLDER_COUNT} + 1
  WriteINIStr "$PLUGINSDIR\corpus.ini" "FolderList" "MaxNum" ${L_FOLDER_COUNT}
  WriteINIStr "$PLUGINSDIR\corpus.ini" "FolderList" \
              "Path-${L_FOLDER_COUNT}" "${L_CORPUS_PATH}\${L_BUCKET_NAME}"

  ; Assume what we've found is a bucket folder, now check if it contains
  ; a BerkeleyDB file or a flat-file corpus file. We make a list of all the
  ; buckets we find so we can later monitor the progress of the conversion process.
  ; If we find both types of corpus file in a particular bucket, we add both to the list.

  IfFileExists "${L_CORPUS_PATH}\${L_BUCKET_NAME}\table.db" bdb_bucket
  IfFileExists "${L_CORPUS_PATH}\${L_BUCKET_NAME}\table" flat_bucket
  Goto corpus_check

bdb_bucket:
  IntOp ${L_BUCKET_COUNT} ${L_BUCKET_COUNT} + 1
  WriteINIStr "$PLUGINSDIR\corpus.ini" "BucketList" "FileCount" ${L_BUCKET_COUNT}
  WriteINIStr "$PLUGINSDIR\corpus.ini" "Bucket-${L_BUCKET_COUNT}" "File_Name" \
                                       "${L_CORPUS_PATH}\${L_BUCKET_NAME}\table.db"
  Push "${L_CORPUS_PATH}\${L_BUCKET_NAME}\table.db"
  Call GetFileSize
  Pop ${L_TEMP}
  IntOp ${L_CORPUS_SIZE} ${L_CORPUS_SIZE} + ${L_TEMP}
  WriteINIStr "$PLUGINSDIR\corpus.ini" "Bucket-${L_BUCKET_COUNT}" "File_Size" "${L_TEMP}"
  WriteINIStr "$PLUGINSDIR\corpus.ini" "Bucket-${L_BUCKET_COUNT}" "Stop_Time" "0"
  WriteINIStr "$PLUGINSDIR\corpus.ini" "Bucket-${L_BUCKET_COUNT}" "ElapsTime" "0"

  IfFileExists "${L_CORPUS_PATH}\${L_BUCKET_NAME}\table" 0 corpus_check

flat_bucket:
  IntOp ${L_BUCKET_COUNT} ${L_BUCKET_COUNT} + 1
  WriteINIStr "$PLUGINSDIR\corpus.ini" "BucketList" "FileCount" ${L_BUCKET_COUNT}
  WriteINIStr "$PLUGINSDIR\corpus.ini" "Bucket-${L_BUCKET_COUNT}" "File_Name" \
                                       "${L_CORPUS_PATH}\${L_BUCKET_NAME}\table"
  Push "${L_CORPUS_PATH}\${L_BUCKET_NAME}\table"
  Call GetFileSize
  Pop ${L_TEMP}
  IntCmp ${L_TEMP} 3 valid_size 0 valid_size

  ; Very early versions of POPFile used an empty 'table' file to represent an empty bucket
  ; so we replace these files with an updated flat file version of an empty bucket to avoid
  ; problems when this flat file corpus is converted to the new SQL database format

  FileOpen ${L_TEMP} "${L_CORPUS_PATH}\${L_BUCKET_NAME}\table" w
  FileWrite ${L_TEMP} "__CORPUS__ __VERSION__ 1$\r$\n"
  FileClose ${L_TEMP}
  StrCpy ${L_TEMP} 26

valid_size:
  IntOp ${L_CORPUS_SIZE} ${L_CORPUS_SIZE} + ${L_TEMP}
  WriteINIStr "$PLUGINSDIR\corpus.ini" "Bucket-${L_BUCKET_COUNT}" "File_Size" "${L_TEMP}"
  WriteINIStr "$PLUGINSDIR\corpus.ini" "Bucket-${L_BUCKET_COUNT}" "Stop_Time" "0"
  WriteINIStr "$PLUGINSDIR\corpus.ini" "Bucket-${L_BUCKET_COUNT}" "ElapsTime" "0"
  Goto corpus_check

check_bucket_count:
  WriteINIStr "$PLUGINSDIR\corpus.ini" "BucketList" "TotalSize" ${L_CORPUS_SIZE}
  FlushINI "$PLUGINSDIR\corpus.ini"
  StrCmp ${L_BUCKET_COUNT} 0 nothing_to_backup

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_CORPUS)"
  SetDetailsPrint listonly

  CreateDirectory "$G_USERDIR\backup\nonsql"
  CopyFiles "$G_USERDIR\popfile.cfg" "$G_USERDIR\backup\popfile.cfg"
  WriteINIStr "$G_USERDIR\backup\backup.ini" "NonSQLCorpus" "CorpusPath" "${L_CORPUS_PATH}"

  StrCpy ${L_TEMP} ${L_CORPUS_PATH}
  Push ${L_TEMP}
  Call GetParent
  Pop ${L_TEMP}
  WriteINIStr "$G_USERDIR\backup\backup.ini" "NonSQLCorpus" "ParentPath" "${L_TEMP}"
  StrLen ${L_TEMP} ${L_TEMP}
  IntOp ${L_TEMP} ${L_TEMP} + 1
  StrCpy ${L_TEMP} ${L_CORPUS_PATH} "" ${L_TEMP}
  WriteINIStr "$G_USERDIR\backup\backup.ini" "NonSQLCorpus" "BackupPath" "$G_USERDIR\backup\nonsql"

  ClearErrors
  CopyFiles /SILENT "${L_CORPUS_PATH}" "$G_USERDIR\backup\nonsql\"
  IfErrors 0 continue
  DetailPrint "Error detected when making corpus backup"
  MessageBox MB_OK|MB_ICONEXCLAMATION "$(PFI_LANG_MBCORPUS_1)"

continue:
  WriteINIStr "$G_USERDIR\backup\backup.ini" "NonSQLCorpus" "Corpus" "${L_TEMP}"
  WriteINIStr "$G_USERDIR\backup\backup.ini" "NonSQLCorpus" "Status" "new"

  File "/oname=$PLUGINSDIR\monitorcc.exe" "monitorcc.exe"

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_ENDSEC)"
  SetDetailsPrint listonly

nothing_to_backup:
  FindClose ${L_CFG_HANDLE}

exit:
  Pop ${L_TEMP}
  Pop ${L_FOLDER_COUNT}
  Pop ${L_CORPUS_SIZE}
  Pop ${L_CORPUS_PATH}
  Pop ${L_BUCKET_NAME}
  Pop ${L_BUCKET_COUNT}
  Pop ${L_CFG_HANDLE}

  !undef L_CFG_HANDLE
  !undef L_BUCKET_COUNT
  !undef L_BUCKET_NAME
  !undef L_CORPUS_PATH
  !undef L_CORPUS_SIZE
  !undef L_FOLDER_COUNT
  !undef L_TEMP

SectionEnd

#--------------------------------------------------------------------------
# Installer Section: UI Languages component
#
# The installer will attempt to preset the POPFile UI
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

Section "-Languages" SecLangs

  !define L_CFG   $R9   ; file handle
  !define L_LANG  $R8   ; language to be used for POPFile UI

  Push ${L_CFG}
  Push ${L_LANG}

  StrCpy ${L_LANG} ""     ; assume default POPFile UI language will be used.

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_LANGS)"
  SetDetailsPrint listonly

  ; There are several special cases: some UI languages are not yet supported by the
  ; installer, so if we are upgrading a system which was using one of these UI languages,
  ; we re-select it, provided the UI language file still exists.

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_LANG} "ioC.ini" "Inherited" "html_language"
  StrCmp ${L_LANG} "?" 0 use_inherited_lang
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_LANG} "ioC.ini" "Inherited" "language"
  StrCmp ${L_LANG} "?" use_installer_lang

use_inherited_lang:
  StrCmp ${L_LANG} "English-UK" special_case
  StrCmp ${L_LANG} "Hebrew"  0 use_installer_lang

special_case:
  IfFileExists "$G_ROOTDIR\languages\${L_LANG}.msg" lang_save

use_installer_lang:

  ; Conditional compilation: if ENGLISH_MODE is defined, installer supports only 'English'
  ; so we use whatever UI language was defined in the existing 'popfile.cfg' file (if none
  ; found then we let POPFile use the default UI language)

  !ifndef ENGLISH_MODE

        ; UI_LANG_CONFIG parameters: "NSIS Language name"  "POPFile UI language name"

        !insertmacro UI_LANG_CONFIG "ENGLISH" "English"
        !insertmacro UI_LANG_CONFIG "BULGARIAN" "Bulgarian"
        !insertmacro UI_LANG_CONFIG "SIMPCHINESE" "Chinese-Simplified"
        !insertmacro UI_LANG_CONFIG "TRADCHINESE" "Chinese-Traditional"
        !insertmacro UI_LANG_CONFIG "CZECH" "Czech"
        !insertmacro UI_LANG_CONFIG "DANISH" "Dansk"
        !insertmacro UI_LANG_CONFIG "GERMAN" "Deutsch"
        !insertmacro UI_LANG_CONFIG "SPANISH" "Espanol"
        !insertmacro UI_LANG_CONFIG "FRENCH" "Francais"
        !insertmacro UI_LANG_CONFIG "GREEK" "Hellenic"
        !insertmacro UI_LANG_CONFIG "ITALIAN" "Italiano"
        !insertmacro UI_LANG_CONFIG "JAPANESE" "Nihongo"
        !insertmacro UI_LANG_CONFIG "KOREAN" "Korean"
        !insertmacro UI_LANG_CONFIG "HUNGARIAN" "Hungarian"
        !insertmacro UI_LANG_CONFIG "DUTCH" "Nederlands"
        !insertmacro UI_LANG_CONFIG "NORWEGIAN" "Norsk"
        !insertmacro UI_LANG_CONFIG "POLISH" "Polish"
        !insertmacro UI_LANG_CONFIG "PORTUGUESE" "Portugues"
        !insertmacro UI_LANG_CONFIG "PORTUGUESEBR" "Portugues do Brasil"
        !insertmacro UI_LANG_CONFIG "RUSSIAN" "Russian"
        !insertmacro UI_LANG_CONFIG "SLOVAK" "Slovak"
        !insertmacro UI_LANG_CONFIG "FINNISH" "Suomi"
        !insertmacro UI_LANG_CONFIG "SWEDISH" "Svenska"
        !insertmacro UI_LANG_CONFIG "TURKISH" "Turkce"
        !insertmacro UI_LANG_CONFIG "UKRAINIAN" "Ukrainian"

        ; at this point, no match was found so we use the default POPFile UI language
        ; (and leave it to POPFile to determine which language to use)
  !endif

  goto lang_done

lang_save:
  FileOpen  ${L_CFG} $G_USERDIR\popfile.cfg a
  FileSeek  ${L_CFG} 0 END
  FileWrite ${L_CFG} "html_language ${L_LANG}$\r$\n"
  FileClose ${L_CFG}

lang_done:
  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_INST_PROG_ENDSEC)"
  SetDetailsPrint listonly

  Pop ${L_LANG}
  Pop ${L_CFG}

  !undef L_CFG
  !undef L_LANG

SectionEnd

#--------------------------------------------------------------------------
# Installer Function: CheckExistingConfig
# (the "leave" function for the WELCOME page)
#
# This function is used to extract the POP3 and UI ports from the 'popfile.cfg'
# configuration file (if a copy is found when the wizard starts up).
#
# As it is possible that there are multiple entries for these parameters in the file,
# this function removes them all as it makes a new copy of the file. New port data
# entries will be added to this copy and the original updated (and backed up) when
# the "POPFile" section of the installer is executed.
#
# If the user has selected the optional 'Languages' component then this function also strips
# out the POPFile UI language setting to allow the installer to easily preset the UI language
# to match the language selected for use by the installer. (See the code which handles the
# 'Languages' component for further details). A copy of any settings found is kept in 'ioC.ini'
# for later use in the 'Languages' section.
#
# This function also ensures that only one copy of the tray icon & console settings is present,
# and saves (in 'ioC.ini') any values found for use when the user is offered the chance to start
# POPFile from the installer. If no setting is found, we save '?' in 'ioC.ini'. These settings
# are used by the 'StartPOPFilePage' and 'CheckLaunchOptions' functions.
#--------------------------------------------------------------------------

Function CheckExistingConfig

  !define L_CFG       $R9     ; handle for "popfile.cfg"
  !define L_CLEANCFG  $R8     ; handle for "clean" copy
  !define L_CMPRE     $R7     ; config param name
  !define L_LNE       $R6     ; a line from popfile.cfg
  !define L_OLDUI     $R5     ; used to hold old-style of GUI port
  !define L_TRAYICON  $R4     ; a config parameter used by popfile.exe
  !define L_CONSOLE   $R3     ; a config parameter used by popfile.exe
  !define L_LANG_NEW  $R2     ; new style UI lang parameter
  !define L_LANG_OLD  $R1     ; old style UI lang parameter

  ; Only one register pushed for now, in case we bail out via an Abort

  Push ${L_CFG}

  ; This function initialises the $G_USERDIR global user variable for use elsewhere in wizard

  ; Warn the user if we are about to upgrade an existing installation
  ; and allow user to select a different directory if they wish

  ; Starting with the 0.21.0 release, user-specific data is stored in the registry

  ReadRegStr $G_USERDIR HKCU "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "UserDataPath"
  StrCmp $G_USERDIR "" look_elsewhere
  IfFileExists "$G_USERDIR\popfile.cfg" warning

look_elsewhere:

  ; All versions prior to 0.21.0 stored popfile.pl and popfile.cfg in the same folder

  StrCpy $G_USERDIR $G_ROOTDIR

  IfFileExists "$G_USERDIR\popfile.cfg" warning

  ; Check if we are installing over a version which uses an early version of the new structure

  StrCpy $G_USERDIR "$INSTDIR\user"
  IfFileExists "$G_USERDIR\popfile.cfg" warning

  ;----------------------------------------------------------------------
  ; Default location for POPFile User Data files (popfile.cfg and others)
  ;
  ; Windows 95 systems with Internet Explorer 4 installed also need to have
  ; Active Desktop installed, otherwise $APPDATA will not be available.
  ;----------------------------------------------------------------------

  StrCmp $APPDATA "" 0 appdata_valid
  StrCpy $G_USERDIR "${C_ALT_DEFAULT_USERDATA}\$G_WINUSERNAME"
  Goto check_default_locn

appdata_valid:
  StrCpy $G_USERDIR "${C_STD_DEFAULT_USERDATA}"
  Push $G_USERDIR
  Push $G_WINUSERNAME
  Call StrStr
  Pop ${L_CFG}
  StrCmp ${L_CFG} "" 0 check_default_locn
  StrCpy $G_USERDIR "$G_USERDIR\$G_WINUSERNAME"

check_default_locn:
  IfFileExists "$G_USERDIR\popfile.cfg" warning
  Goto continue

warning:
  MessageBox MB_YESNO|MB_ICONQUESTION "$(PFI_LANG_DIRSELECT_MBWARN_1)\
      $\r$\n$\r$\n\
      $G_USERDIR\
      $\r$\n$\r$\n$\r$\n\
      $(PFI_LANG_DIRSELECT_MBWARN_2)" IDYES continue

  ; We are returning to the DIRECTORY page, so there is only one register to restore

  Pop ${L_CFG}
  Abort

continue:
  Push ${L_CLEANCFG}
  Push ${L_CMPRE}
  Push ${L_LNE}
  Push ${L_OLDUI}
  Push ${L_TRAYICON}
  Push ${L_CONSOLE}
  Push ${L_LANG_NEW}
  Push ${L_LANG_OLD}

  StrCpy $G_POP3 ""
  StrCpy $G_GUI ""
  StrCpy ${L_OLDUI} ""

  StrCpy ${L_TRAYICON} ""
  StrCpy ${L_CONSOLE} ""

  StrCpy ${L_LANG_NEW} ""
  StrCpy ${L_LANG_OLD} ""

  ; See if we can get the current pop3 and gui port from an existing configuration.
  ; There may be more than one entry for these ports in the file - use the last one found
  ; (but give priority to any "html_port" entry).

  ClearErrors

  FileOpen  ${L_CFG} $G_USERDIR\popfile.cfg r
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

  StrCpy ${L_CMPRE} ${L_LNE} 17
  StrCmp ${L_CMPRE} "windows_trayicon " got_trayicon
  StrCpy ${L_CMPRE} ${L_LNE} 16
  StrCmp ${L_CMPRE} "windows_console " got_console

  ; do not transfer any UI language settings to the copy of popfile.cfg

  StrCpy ${L_CMPRE} ${L_LNE} 9
  StrCmp ${L_CMPRE} "language " got_lang_old
  StrCpy ${L_CMPRE} ${L_LNE} 14
  StrCmp ${L_CMPRE} "html_language " got_lang_new

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

got_trayicon:
  StrCpy ${L_TRAYICON} ${L_LNE} 1 17
  Goto loop

got_console:
  StrCpy ${L_CONSOLE} ${L_LNE} 1 16
  Goto loop

got_lang_new:
  StrCpy ${L_LANG_NEW} ${L_LNE} "" 14
  Goto loop

got_lang_old:
  StrCpy ${L_LANG_OLD} ${L_LNE} "" 9
  Goto loop

done:
  FileClose ${L_CFG}

  ; Before closing the clean copy of 'popfile.cfg' we add the most recent settings for the
  ; system tray icon and console mode, if valid values were found. If no valid values were
  ; found, we add nothing to the clean copy. A record of our findings is stored in 'ioC.ini'
  ; for use by 'StartPOPFilePage' and 'CheckLaunchOptions'.

  StrCmp ${L_CONSOLE} "0" found_console
  StrCmp ${L_CONSOLE} "1" found_console
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Inherited" "Console" "?"
  Goto check_trayicon

found_console:
  FileWrite ${L_CLEANCFG} "windows_console ${L_CONSOLE}$\r$\n"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Inherited" "Console" "${L_CONSOLE}"

check_trayicon:
  StrCmp ${L_TRAYICON} "0" found_trayicon
  StrCmp ${L_TRAYICON} "1" found_trayicon
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Inherited" "TrayIcon" "?"
  Goto close_cleancopy

found_trayicon:
  FileWrite ${L_CLEANCFG} "windows_trayicon ${L_TRAYICON}$\r$\n"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Inherited" "TrayIcon" "${L_TRAYICON}"

close_cleancopy:
  FileClose ${L_CLEANCFG}

  ; We save the UI language settings for later use when the 'Languages' section is processed
  ; (if no settings were found, we save '?'). If 'Languages' component is not selected, these
  ; saved settings will not be used (any existing settings were copied to the new 'popfile.cfg')

  Push ${L_LANG_NEW}
  Call TrimNewlines
  Pop ${L_LANG_NEW}
  StrCmp ${L_LANG_NEW} "" 0 check_lang_old
  StrCpy ${L_LANG_NEW} "?"

check_lang_old:
  Push ${L_LANG_OLD}
  Call TrimNewlines
  Pop ${L_LANG_OLD}
  StrCmp ${L_LANG_OLD} "" 0 save_langs
  StrCpy ${L_LANG_OLD} "?"

save_langs:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Inherited" "html_language" "${L_LANG_NEW}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Inherited" "language" "${L_LANG_OLD}"

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
  Pop ${L_LANG_OLD}
  Pop ${L_LANG_NEW}
  Pop ${L_CONSOLE}
  Pop ${L_TRAYICON}
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
  !undef L_TRAYICON
  !undef L_CONSOLE
  !undef L_LANG_NEW
  !undef L_LANG_OLD

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: SetOptionsPage_Init
#
# This function adds language texts to the INI file used by the "SetOptionsPage" function
# (to make the custom page use the language selected by the user for the installer)
#--------------------------------------------------------------------------

Function SetOptionsPage_Init

  ; Ensure custom page matches the selected language (left-to-right or right-to-left order)

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioA.ini" "Settings" "RTL" "$(^RTL)"

  !insertmacro PFI_IO_TEXT "ioA.ini" "1" "$(PFI_LANG_OPTIONS_IO_POP3)"
  !insertmacro PFI_IO_TEXT "ioA.ini" "3" "$(PFI_LANG_OPTIONS_IO_GUI)"
  !insertmacro PFI_IO_TEXT "ioA.ini" "5" "$(PFI_LANG_OPTIONS_IO_STARTUP)"
  !insertmacro PFI_IO_TEXT "ioA.ini" "6" "$(PFI_LANG_OPTIONS_IO_WARNING)"
  !insertmacro PFI_IO_TEXT "ioA.ini" "7" "$(PFI_LANG_OPTIONS_IO_MESSAGE)"

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: SetOptionsPage (generates a custom page)
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

  !insertmacro MUI_INSTALLOPTIONS_INITDIALOG "ioA.ini"
  Pop $G_HWND                 ; HWND of dialog we want to modify

  ; In 'GetDlgItem', use (1200 + Field number - 1) to refer to the field to be changed

  GetDlgItem $G_DLGITEM $G_HWND 1204            ; Field 5 = 'Run POPFile at startup' checkbox
  CreateFont $G_FONT "MS Shell Dlg" 10 700      ; use larger & bolder version of the font in use
  SendMessage $G_DLGITEM ${WM_SETFONT} $G_FONT 0

  !insertmacro MUI_INSTALLOPTIONS_SHOW

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
# Installer Function: SetEmailClientPage_Init
#
# This function adds language texts to the INI file used by "SetEmailClientPage" function
# (to make the custom page use the language selected by the user for the installer)
#--------------------------------------------------------------------------

Function SetEmailClientPage_Init

  ; Ensure custom page matches the selected language (left-to-right or right-to-left order)

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioF.ini" "Settings" "RTL" "$(^RTL)"

  ; We use the 'Back' button as an easy way to skip all the email client reconfiguration pages
  ; (but we still check if there are any old-style uninstall data files to be converted)

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioF.ini" \
              "Settings" "BackButtonText" "$(PFI_LANG_MAILCFG_IO_SKIPALL)"

  !insertmacro PFI_IO_TEXT "ioF.ini" "1" "$(PFI_LANG_MAILCFG_IO_TEXT_1)"
  !insertmacro PFI_IO_TEXT "ioF.ini" "3" "$(PFI_LANG_MAILCFG_IO_TEXT_2)"

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: SetEmailClientPage (generates a custom page)
#
# This function is used to introduce the reconfiguration of email clients
#--------------------------------------------------------------------------

Function SetEmailClientPage

  !define L_CLIENT_INDEX    $R9
  !define L_CLIENT_LIST     $R8
  !define L_CLIENT_NAME     $R7
  !define L_CLIENT_TYPE     $R6   ; used to indicate if client can be reconfigured by installer
  !define L_SEPARATOR       $R5
  !define L_TEMP            $R4

  Push ${L_CLIENT_INDEX}
  Push ${L_CLIENT_LIST}
  Push ${L_CLIENT_NAME}
  Push ${L_CLIENT_TYPE}
  Push ${L_SEPARATOR}
  Push ${L_TEMP}

  ; On older systems with several email clients, the email client scan can take a few seconds
  ; during which time the user may be tempted to click the 'Next' button. Display a banner to
  ; reassure the user (and hope they do NOT click any buttons)

  Banner::show /NOUNLOAD /set 76 "$(PFI_LANG_OPTIONS_BANNER_1)" "$(PFI_LANG_OPTIONS_BANNER_2)"

  !insertmacro MUI_HEADER_TEXT "$(PFI_LANG_MAILCFG_TITLE)" "$(PFI_LANG_MAILCFG_SUBTITLE)"

  StrCpy ${L_CLIENT_INDEX} 0
  StrCpy ${L_CLIENT_LIST} ""
  StrCpy ${L_SEPARATOR} ""

read_next_name:
  EnumRegKey ${L_CLIENT_NAME} HKLM "Software\Clients\Mail" ${L_CLIENT_INDEX}
  StrCmp ${L_CLIENT_NAME} "" display_results
  StrCmp ${L_CLIENT_NAME} "Hotmail" incrm_index
  Push "|Microsoft Outlook|Outlook Express|Eudora|"
  Push "|${L_CLIENT_NAME}|"
  Call StrStr
  Pop ${L_CLIENT_TYPE}
  StrCmp ${L_CLIENT_TYPE} "" add_to_list
  StrCpy ${L_CLIENT_TYPE} " (*)"

  ReadRegStr ${L_TEMP} HKLM "Software\Clients\Mail\${L_CLIENT_NAME}\shell\open\command" ""
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioF.ini" "ClientEXE" "${L_CLIENT_NAME}" "${L_TEMP}"

add_to_list:
  StrCpy ${L_CLIENT_LIST} "${L_CLIENT_LIST}${L_SEPARATOR}${L_CLIENT_NAME}${L_CLIENT_TYPE}"
  StrCpy ${L_SEPARATOR} "\r\n"

incrm_index:
  IntOp ${L_CLIENT_INDEX} ${L_CLIENT_INDEX} + 1
  Goto read_next_name

display_results:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioF.ini" "Field 2" "State" "${L_CLIENT_LIST}"

  Sleep ${C_MIN_BANNER_DISPLAY_TIME}
  Banner::destroy

  !insertmacro MUI_INSTALLOPTIONS_DISPLAY_RETURN "ioF.ini"
  Pop ${L_TEMP}
  StrCmp ${L_TEMP} "back" 0 exit
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioF.ini" "ClientEXE" "ConfigStatus" "SkipAll"

  !insertmacro MUI_INSTALLOPTIONS_WRITE   "ioF.ini" "Settings" "NumFields" "1"
  !insertmacro MUI_INSTALLOPTIONS_WRITE   "ioF.ini" "Settings" "BackEnabled" "0"
  !insertmacro PFI_IO_TEXT "ioF.ini" "1" "$(PFI_LANG_MAILCFG_IO_CANCEL)"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "ioF.ini"

exit:
  Pop ${L_TEMP}
  Pop ${L_SEPARATOR}
  Pop ${L_CLIENT_TYPE}
  Pop ${L_CLIENT_NAME}
  Pop ${L_CLIENT_LIST}
  Pop ${L_CLIENT_INDEX}

  !undef L_CLIENT_INDEX
  !undef L_CLIENT_LIST
  !undef L_CLIENT_NAME
  !undef L_CLIENT_TYPE
  !undef L_SEPARATOR
  !undef L_TEMP

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: SetOutlookOutlookExpressPage_Init
#
# This function adds language texts to the INI file used by "SetOutlookExpressPage" function
# and by the "SetOutlookPage" function (to make the custom page use the language selected by
# the user for the installer)
#--------------------------------------------------------------------------

Function SetOutlookOutlookExpressPage_Init

  ; Ensure custom page matches the selected language (left-to-right or right-to-left order)

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioB.ini" "Settings" "RTL" "$(^RTL)"

  ; We use the 'Back' button as an easy way to skip the 'Outlook Express' or 'Outlook'
  ; reconfiguration (but we still check if there are any old-style uninstall data files
  ; to be converted)

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioB.ini" \
              "Settings" "BackButtonText" "$(PFI_LANG_MAILCFG_IO_SKIPONE)"

  !insertmacro PFI_IO_TEXT "ioB.ini" "1" "$(PFI_LANG_OOECFG_IO_BOXHDR)"
  !insertmacro PFI_IO_TEXT "ioB.ini" "3" "$(PFI_LANG_OOECFG_IO_FOOTNOTE)"
  !insertmacro PFI_IO_TEXT "ioB.ini" "4" "$(PFI_LANG_OOECFG_IO_ACCOUNTHDR)"
  !insertmacro PFI_IO_TEXT "ioB.ini" "5" "$(PFI_LANG_OOECFG_IO_EMAILHDR)"
  !insertmacro PFI_IO_TEXT "ioB.ini" "6" "$(PFI_LANG_OOECFG_IO_SERVERHDR)"
  !insertmacro PFI_IO_TEXT "ioB.ini" "7" "$(PFI_LANG_OOECFG_IO_USRNAMEHDR)"

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
  !define L_PORT        $R0   ; POP3 Port used for an OE Account
  !define L_STATUS      $9    ; keeps track of the status of the account we are checking
  !define L_TEMP        $8

  !define L_POP3SERVER    $7
  !define L_EMAILADDRESS  $6
  !define L_USERNAME      $5

  Push ${L_ACCOUNT}
  Push ${L_ACCT_INDEX}
  Push ${L_CFG}
  Push ${L_GUID}
  Push ${L_GUID_INDEX}
  Push ${L_IDENTITY}
  Push ${L_OEDATA}
  Push ${L_OEPATH}
  Push ${L_ORDINALS}
  Push ${L_PORT}
  Push ${L_STATUS}
  Push ${L_TEMP}

  Push ${L_POP3SERVER}
  Push ${L_EMAILADDRESS}
  Push ${L_USERNAME}

  !insertmacro MUI_HEADER_TEXT "$(PFI_LANG_EXPCFG_TITLE)" "$(PFI_LANG_EXPCFG_SUBTITLE)"

  ; Create timestamp used for all Outlook Express configuration activities
  ; and convert old-style 'undo' data to the new INI-file format

  Call GetDateTimeStamp
  Pop ${L_TEMP}
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "DateTime" "OutlookExpress" "${L_TEMP}"
  IfFileExists "$G_USERDIR\popfile.reg" 0 check_oe_config_enabled
  Push "popfile.reg"
  Call ConvertOOERegData

check_oe_config_enabled:

  ; Check if user decided to skip all email client configuration

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioF.ini" "ClientEXE" "ConfigStatus"
    StrCmp ${L_STATUS} "SkipAll" exit

  ; If Outlook Express is running, ask the user to shut it down now
  ; (user is allowed to ignore our request)

check_again:
  FindWindow ${L_STATUS} "Outlook Express Browser Class"
  IsWindow ${L_STATUS} 0 open_logfiles

  MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP|MB_DEFBUTTON2 "$(PFI_LANG_MBCLIENT_EXP)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_1)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_2)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_3)"\
             IDRETRY check_again IDIGNORE open_logfiles

abort_oe_config:

  ; Either 'Abort' has been selected so we do not offer to reconfigure any Outlook Express
  ; accounts or 'Cancel' has been selected during the Outlook Express configuration process
  ; so we stop now

  !insertmacro MUI_INSTALLOPTIONS_WRITE   "ioB.ini" "Settings" "NumFields" "1"
  !insertmacro MUI_INSTALLOPTIONS_WRITE   "ioB.ini" "Settings" "BackEnabled" "0"
  !insertmacro PFI_IO_TEXT "ioB.ini" "1" "$(PFI_LANG_EXPCFG_IO_CANCELLED)"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "ioB.ini"
  StrCmp $G_OOECONFIG_HANDLE "" exit
  FileWrite $G_OOECONFIG_HANDLE "$\r$\n\
      $(PFI_LANG_EXPCFG_IO_CANCELLED)\
      $\r$\n"
  Goto finished_oe_config

open_logfiles:
  !insertmacro MUI_INSTALLOPTIONS_WRITE   "ioB.ini" "Settings" "BackEnabled" "1"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "DateTime" "OutlookExpress"

  FileOpen  $G_OOECONFIG_HANDLE "$G_USERDIR\expconfig.txt" w
  FileWrite $G_OOECONFIG_HANDLE "[$G_WINUSERNAME] $(PFI_LANG_EXPCFG_LOG_BEFORE) (${L_TEMP})\
      $\r$\n$\r$\n"
  !insertmacro OOECONFIG_BEFORE_LOG  "$(PFI_LANG_EXPCFG_LOG_IDENTITY)"  20
  !insertmacro OOECONFIG_BEFORE_LOG  "$(PFI_LANG_OOECFG_LOG_ACCOUNT)"   20
  !insertmacro OOECONFIG_BEFORE_LOG  "$(PFI_LANG_OOECFG_LOG_EMAIL)"     30
  !insertmacro OOECONFIG_BEFORE_LOG  "$(PFI_LANG_OOECFG_LOG_SERVER)"    20
  !insertmacro OOECONFIG_BEFORE_LOG  "$(PFI_LANG_OOECFG_LOG_USER)"      20
  FileWrite $G_OOECONFIG_HANDLE "$(PFI_LANG_OOECFG_LOG_PORT)\
      $\r$\n$\r$\n"

  FileOpen  $G_OOECHANGES_HANDLE "$G_USERDIR\expchanges.txt" a
  FileSeek  $G_OOECHANGES_HANDLE 0 END
  FileWrite $G_OOECHANGES_HANDLE "[$G_WINUSERNAME] $(PFI_LANG_ExpCFG_LOG_AFTER) (${L_TEMP})\
      $\r$\n$\r$\n"
  !insertmacro OOECONFIG_CHANGES_LOG  "$(PFI_LANG_EXPCFG_LOG_IDENTITY)"   20
  !insertmacro OOECONFIG_CHANGES_LOG  "$(PFI_LANG_OOECFG_LOG_ACCOUNT)"    20
  !insertmacro OOECONFIG_CHANGES_LOG  "$(PFI_LANG_OOECFG_LOG_NEWSERVER)"  17
  !insertmacro OOECONFIG_CHANGES_LOG  "$(PFI_LANG_OOECFG_LOG_NEWUSER)"    40
  FileWrite $G_OOECHANGES_HANDLE "$(PFI_LANG_OOECFG_LOG_NEWPORT)\
      $\r$\n$\r$\n"

  ; Determine the separator character to be used when configuring an email account for POPFile

  Call GetSeparator
  Pop $G_SEPARATOR

  ; Start with an empty list of accounts and reset the list "pointers"

  Call ResetOutlookOutlookExpressAccountList

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

  ; Reset the text string used to keep track of the status of the email account we are checking

  StrCpy ${L_STATUS} ""

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

  ; Have found an email account so we add a new entry to the list (which can hold 6 accounts)

  IntOp $G_OOELIST_INDEX $G_OOELIST_INDEX + 1    ; used to access the [Account] data in ioB.ini
  IntOp $G_OOELIST_CBOX $G_OOELIST_CBOX + 1      ; field number for relevant checkbox

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Settings" "NumFields" "$G_OOELIST_CBOX"

  StrCmp ${L_OEDATA} "127.0.0.1" 0 check_pop3_server
  StrCpy ${L_STATUS} "bad IP"
  Goto check_pop3_username

check_pop3_server:

  ; If 'POP3 Server' data contains the separator character, we cannot configure this account

  Push ${L_OEDATA}
  Push $G_SEPARATOR
  Call StrStr
  Pop ${L_TEMP}
  StrCmp ${L_TEMP} "" check_pop3_username
  StrCpy ${L_STATUS} "bad servername"

check_pop3_username:

  ; Prepare to display the 'POP3 Server' data

  StrCpy ${L_POP3SERVER} ${L_OEDATA}

  ReadRegStr ${L_OEDATA} HKCU ${L_ACCOUNT} "SMTP Email Address"

  StrCpy ${L_EMAILADDRESS} ${L_OEDATA}

  ReadRegDWORD ${L_PORT} HKCU ${L_ACCOUNT} "POP3 Port"
  StrCmp ${L_PORT} "" 0 port_ok
  StrCpy ${L_PORT} "110"

port_ok:
  ReadRegStr ${L_OEDATA} HKCU ${L_ACCOUNT} "POP3 User Name"
  StrCpy ${L_USERNAME} ${L_OEDATA}
  StrCmp ${L_USERNAME} "" bad_username

  ; If 'POP3 User Name' data contains the separator character, we cannot configure this account

  Push ${L_OEDATA}
  Push $G_SEPARATOR
  Call StrStr
  Pop ${L_TEMP}
  StrCmp ${L_TEMP} "" configurable
  StrCmp ${L_STATUS} "" 0 configurable

bad_username:
  StrCpy ${L_STATUS} "bad username"
  Goto continue

configurable:
  StrCmp ${L_STATUS} "" 0 continue
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field $G_OOELIST_CBOX" "Flags" ""

continue:

  ; Find the Username used by OE for this identity and the OE Account Name
  ; (so we can unambiguously report which email account we are offering to reconfigure).

  ReadRegStr ${L_IDENTITY} HKCU "Identities\${L_GUID}\" "Username"
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field 1" "Text" "'${L_IDENTITY}' $(PFI_LANG_OOECFG_IO_BOXHDR)"
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Identity" "Username" "${L_IDENTITY}"

  ReadRegStr ${L_OEDATA} HKCU ${L_ACCOUNT} "Account Name"

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioB.ini" "Field 8" "State"
  StrCpy ${L_TEMP} ""
  StrCmp ${L_STATUS} "" no_padding
  StrCpy ${L_TEMP} "\r\n\r\n"

no_padding:
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Field 8" "State" "${L_STATUS}${L_TEMP}${L_OEDATA}"

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioB.ini" "Field 9" "State"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Field 9" "State" "${L_STATUS}${L_TEMP}${L_EMAILADDRESS}"

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioB.ini" "Field 10" "State"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Field 10" "State" "${L_STATUS}${L_TEMP}${L_POP3SERVER}"

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioB.ini" "Field 11" "State"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Field 11" "State" "${L_STATUS}${L_TEMP}${L_USERNAME}"

  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "AccountName" "${L_OEDATA}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "EmailAddress" "${L_EMAILADDRESS}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "POP3server" "${L_POP3SERVER}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "POP3username" "${L_USERNAME}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "POP3port" "${L_PORT}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "RegistryKey" "${L_ACCOUNT}"

  !insertmacro OOECONFIG_BEFORE_LOG  "${L_IDENTITY}"     20
  !insertmacro OOECONFIG_BEFORE_LOG  "${L_OEDATA}"       20
  !insertmacro OOECONFIG_BEFORE_LOG  "${L_EMAILADDRESS}" 30
  !insertmacro OOECONFIG_BEFORE_LOG  "${L_POP3SERVER}"   20
  !insertmacro OOECONFIG_BEFORE_LOG  "${L_USERNAME}"     20
  FileWrite $G_OOECONFIG_HANDLE "${L_PORT}\
      $\r$\n"

  IntCmp $G_OOELIST_INDEX 6 display_list try_next_account try_next_account

display_list:

  ; Display the OE account data with checkboxes enabled for those accounts we can configure

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Identity" "PageStatus" "new"

  !insertmacro MUI_INSTALLOPTIONS_INITDIALOG "ioB.ini"
  Pop $G_HWND                 ; HWND of dialog we want to modify

  ; In 'GetDlgItem', use (1200 + Field number - 1) to refer to the field to be changed

  GetDlgItem $G_DLGITEM $G_HWND 1200             ; Field 1 = IDENTITY label (above the box)
  CreateFont $G_FONT "MS Shell Dlg" 8 700        ; use a 'bolder' version of the font in use
  SendMessage $G_DLGITEM ${WM_SETFONT} $G_FONT 0

  !insertmacro MUI_INSTALLOPTIONS_SHOW_RETURN
  Pop ${L_TEMP}

  StrCmp ${L_TEMP} "back" abort_oe_config
  StrCmp ${L_TEMP} "cancel" finished_this_guid

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "Identity" "PageStatus"
  StrCmp ${L_TEMP} "updated" display_list
  StrCmp ${L_TEMP} "leftover_ticks" display_list

  Call ResetOutlookOutlookExpressAccountList

try_next_account:
  IntOp ${L_ACCT_INDEX} ${L_ACCT_INDEX} + 1
  goto next_acct

finished_this_guid:
  IntCmp $G_OOELIST_INDEX 0 continue_guid continue_guid

display_list_again:
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Identity" "PageStatus" "new"

  !insertmacro MUI_INSTALLOPTIONS_INITDIALOG "ioB.ini"
  Pop $G_HWND                 ; HWND of dialog we want to modify

  ; In 'GetDlgItem', use (1200 + Field number - 1) to refer to the field to be changed

  GetDlgItem $G_DLGITEM $G_HWND 1200             ; Field 1 = IDENTITY label (above the box)
  CreateFont $G_FONT "MS Shell Dlg" 8 700        ; use a 'bolder' version of the font in use
  SendMessage $G_DLGITEM ${WM_SETFONT} $G_FONT 0

  !insertmacro MUI_INSTALLOPTIONS_SHOW_RETURN
  Pop ${L_TEMP}

  StrCmp ${L_TEMP} "back" abort_oe_config
  StrCmp ${L_TEMP} "cancel" finished_this_guid

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "Identity" "PageStatus"
  StrCmp ${L_TEMP} "updated" display_list_again
  StrCmp ${L_TEMP} "leftover_ticks" display_list_again

  Call ResetOutlookOutlookExpressAccountList

continue_guid:

  ; If no "Identity Ordinal" values were found then exit otherwise move on to the next identity

  StrCmp ${L_ORDINALS} "0" finished_oe_config

  IntOp ${L_GUID_INDEX} ${L_GUID_INDEX} + 1
  goto get_guid

finished_oe_config:
  FileWrite $G_OOECONFIG_HANDLE "$\r$\n\
      $(PFI_LANG_OOECFG_LOG_END)\
      $\r$\n$\r$\n"
  FileClose $G_OOECONFIG_HANDLE

  FileWrite $G_OOECHANGES_HANDLE "$\r$\n\
      $(PFI_LANG_OOECFG_LOG_END)\
      $\r$\n$\r$\n"
  FileClose $G_OOECHANGES_HANDLE

exit:
  Pop ${L_USERNAME}
  Pop ${L_EMAILADDRESS}
  Pop ${L_POP3SERVER}

  Pop ${L_TEMP}
  Pop ${L_STATUS}
  Pop ${L_PORT}
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
  !undef L_PORT
  !undef L_STATUS
  !undef L_TEMP

  !undef L_POP3SERVER
  !undef L_EMAILADDRESS
  !undef L_USERNAME

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: ConvertOOERegData
#
# This function uses an old-style 'popfile.reg' (or 'outlook.reg') file to build a new
# 'pfi-outexpress.ini' (or 'pfi-outlook.ini') file. The old-style filename is passed via stack.
# After new file has been built, old one is renamed (up to 3 versions are kept).
#--------------------------------------------------------------------------

Function ConvertOOERegData

  !define L_CFG         $R9
  !define L_PREV_KEY    $R8
  !define L_REG_FILE    $R7
  !define L_REG_KEY     $R6
  !define L_REG_SUBKEY  $R5
  !define L_REG_VALUE   $R4
  !define L_TEMP        $R3
  !define L_UNDO        $R2
  !define L_UNDOFILE    $R1

  Exch ${L_REG_FILE}
  Push ${L_CFG}
  Push ${L_PREV_KEY}
  Push ${L_REG_KEY}
  Push ${L_REG_SUBKEY}
  Push ${L_REG_VALUE}
  Push ${L_TEMP}
  Push ${L_UNDO}
  Push ${L_UNDOFILE}

  Banner::show /NOUNLOAD /set 76 "$(PFI_LANG_OPTIONS_BANNER_1)" "$(PFI_LANG_OPTIONS_BANNER_2)"

  ; Original 'popfile.reg' format (2 values per entry, each using 3 lines) imported as 'IniV=1':
  ;
  ;                 "Registry key", "POP3 User Name", "original data",
  ;                 "Registry key", "POP3 Server", "original data"
  ;
  ; Revised 'popfile.reg' format (3 values per entry, each using 3 lines) imported as 'IniV=2':
  ;
  ;                 "Registry key", "POP3 User Name", "original data",
  ;                 "Registry key", "POP3 Server", "original data",
  ;                 "Registry key", "POP3 Port", "original data"
  ;
  ; Original 'outlook.reg' format (3 values per entry, each using 3 lines) imported as 'IniV=2':
  ;
  ;                 "Registry key", "POP3 User Name", "original data",
  ;                 "Registry key", "POP3 Server", "original data",
  ;                 "Registry key", "POP3 Port", "original data"

  StrCpy ${L_PREV_KEY} ""

  StrCmp ${L_REG_FILE} "popfile.reg" outlook_express
  StrCpy ${L_UNDOFILE} "pfi-outlook.ini"
  Goto read_old_file

outlook_express:
  StrCpy ${L_UNDOFILE} "pfi-outexpress.ini"

read_old_file:
  FileOpen  ${L_CFG} "$G_USERDIR\${L_REG_FILE}" r

next_entry:
  FileRead ${L_CFG} ${L_REG_KEY}
  StrCmp ${L_REG_KEY} "" end_of_file
  Push ${L_REG_KEY}
  Call TrimNewlines
  Pop ${L_REG_KEY}
  StrCmp ${L_REG_KEY} "" next_entry

  FileRead ${L_CFG} ${L_REG_SUBKEY}
  Push ${L_REG_SUBKEY}
  Call TrimNewlines
  Pop ${L_REG_SUBKEY}
  StrCmp ${L_REG_SUBKEY} "" next_entry

  FileRead ${L_CFG} ${L_REG_VALUE}
  Push ${L_REG_VALUE}
  Call TrimNewlines
  Pop ${L_REG_VALUE}
  StrCmp ${L_REG_VALUE} "" next_entry

  StrCmp ${L_REG_KEY} ${L_PREV_KEY} add_to_current
  StrCpy ${L_PREV_KEY} ${L_REG_KEY}

  ; New entry detected, so we create a new 'undo' entry for it

  ReadINIStr  ${L_UNDO} "$G_USERDIR\${L_UNDOFILE}" "History" "ListSize"
  StrCmp ${L_UNDO} "" 0 update_list_size
  StrCpy ${L_UNDO} 1
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "History" "ListSize" "1"
  Goto add_entry

update_list_size:
  IntOp ${L_UNDO} ${L_UNDO} + 1
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "History" "ListSize" "${L_UNDO}"

add_entry:
  StrCmp ${L_REG_FILE} "popfile.reg" outlook_express_stamp
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "DateTime" "Outlook"
  Goto save_entry

outlook_express_stamp:
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "DateTime" "OutlookExpress"

save_entry:
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "History" "Undo-${L_UNDO}" "Imported on ${L_TEMP}"
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "History" "IniV-${L_UNDO}" "1"

  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_UNDO}" "Restored" "No"
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_UNDO}" "RegistryKey" "${L_REG_KEY}"

add_to_current:
  StrCmp ${L_REG_SUBKEY} "POP3 User Name" 0 not_username
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_UNDO}" "POP3UserName" "${L_REG_VALUE}"
  Goto next_entry

not_username:
  StrCmp ${L_REG_SUBKEY} "POP3 Server" 0 not_server
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_UNDO}" "POP3Server" "${L_REG_VALUE}"
  Goto next_entry

not_server:
  StrCmp ${L_REG_SUBKEY} "POP3 Server" 0 next_entry
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_UNDO}" "POP3Port" "${L_REG_VALUE}"
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "History" "IniV-${L_UNDO}" "2"
  Goto next_entry

end_of_file:
  FileClose ${L_CFG}

  IfFileExists "$G_USERDIR\${L_REG_FILE}.bk1" 0 the_first
  IfFileExists "$G_USERDIR\${L_REG_FILE}.bk2" 0 the_second
  IfFileExists "$G_USERDIR\${L_REG_FILE}.bk3" 0 the_third
  Delete "$G_USERDIR\${L_REG_FILE}.bk3"

the_third:
  Rename "$G_USERDIR\${L_REG_FILE}.bk2" "$G_USERDIR\${L_REG_FILE}.bk3"

the_second:
  Rename "$G_USERDIR\${L_REG_FILE}.bk1" "$G_USERDIR\${L_REG_FILE}.bk2"

the_first:
  Rename "$G_USERDIR\${L_REG_FILE}" "$G_USERDIR\${L_REG_FILE}.bk1"

  Sleep ${C_MIN_BANNER_DISPLAY_TIME}
  Banner::destroy

  Pop ${L_UNDOFILE}
  Pop ${L_UNDO}
  Pop ${L_TEMP}
  Pop ${L_REG_VALUE}
  Pop ${L_REG_SUBKEY}
  Pop ${L_REG_KEY}
  Pop ${L_PREV_KEY}
  Pop ${L_CFG}
  Pop ${L_REG_FILE}

  !undef L_CFG
  !undef L_PREV_KEY
  !undef L_REG_FILE
  !undef L_REG_KEY
  !undef L_REG_SUBKEY
  !undef L_REG_VALUE
  !undef L_TEMP
  !undef L_UNDO
  !undef L_UNDOFILE

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: ResetOutlookOutlookExpressAccountList
#
# This function is used to empty the list used to display up to 6 accounts for a given identity
#--------------------------------------------------------------------------

Function ResetOutlookOutlookExpressAccountList

  !define L_CBOX_INDEX   $R9
  !define L_TEXT_INDEX   $R8

  Push ${L_CBOX_INDEX}
  Push ${L_TEXT_INDEX}

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Settings" "NumFields" "11"

  StrCpy $G_OOELIST_INDEX     0    ; values 1 to 6 used to access the list
  StrCpy $G_OOELIST_CBOX     11    ; first entry uses field 12

  StrCpy ${L_CBOX_INDEX} 12

next_row:
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field ${L_CBOX_INDEX}" "State" "0"
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field ${L_CBOX_INDEX}" "Flags" "DISABLED"

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field 8" "State" ""
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field 9" "State" ""
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field 10" "State" ""
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field 11" "State" ""

  IntOp ${L_CBOX_INDEX} ${L_CBOX_INDEX} + 1
  IntCmp ${L_CBOX_INDEX} 17 next_row next_row

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Identity" "Username" ""

  StrCpy ${L_TEXT_INDEX} 1

next_account:
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Account ${L_TEXT_INDEX}" "AccountName" ""
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Account ${L_TEXT_INDEX}" "EMailAddress" ""
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Account ${L_TEXT_INDEX}" "POP3server" ""
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Account ${L_TEXT_INDEX}" "POP3username" ""
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Account ${L_TEXT_INDEX}" "POP3port" ""
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Account ${L_TEXT_INDEX}" "RegistryKey" ""
  IntOp ${L_TEXT_INDEX} ${L_TEXT_INDEX} + 1
  IntCmp ${L_TEXT_INDEX} 6 next_account next_account

  Pop ${L_TEXT_INDEX}
  Pop ${L_CBOX_INDEX}

  !undef L_CBOX_INDEX
  !undef L_TEXT_INDEX

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: CheckOutlookExpressRequests
#
# This function is used to confirm any Outlook Express account reconfiguration requests
#--------------------------------------------------------------------------

Function CheckOutlookExpressRequests

  !define L_CBOX_INDEX   $R9
  !define L_CBOX_STATE   $R8
  !define L_DATA_INDEX   $R7
  !define L_REGKEY       $R6
  !define L_TEMP         $R5
  !define L_TEXT_ENTRY   $R4
  !define L_IDENTITY     $R3
  !define L_UNDO         $R2

  !define L_ACCOUNTNAME   $9
  !define L_EMAILADDRESS  $8
  !define L_POP3SERVER    $7
  !define L_POP3USERNAME  $6
  !define L_POP3PORT      $5

  Push ${L_CBOX_INDEX}
  Push ${L_CBOX_STATE}
  Push ${L_DATA_INDEX}
  Push ${L_REGKEY}
  Push ${L_TEMP}
  Push ${L_TEXT_ENTRY}
  Push ${L_IDENTITY}
  Push ${L_UNDO}

  Push ${L_ACCOUNTNAME}
  Push ${L_EMAILADDRESS}
  Push ${L_POP3SERVER}
  Push ${L_POP3USERNAME}
  Push ${L_POP3PORT}

  ; If user has cancelled the reconfiguration, there is nothing to do here

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "Settings" "NumFields"
  StrCmp ${L_TEMP} "1" exit

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_IDENTITY} "ioB.ini" "Identity" "Username"

  StrCpy ${L_CBOX_INDEX} 12
  StrCpy ${L_DATA_INDEX} 1

next_row:
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_CBOX_STATE} "ioB.ini" "Field ${L_CBOX_INDEX}" "Flags"
  StrCmp ${L_CBOX_STATE} "DISABLED" continue

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_CBOX_STATE} "ioB.ini" "Field ${L_CBOX_INDEX}" "State"
  StrCmp ${L_CBOX_STATE} "0" continue

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_ACCOUNTNAME}  "ioB.ini" "Account ${L_DATA_INDEX}" "AccountName"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_EMAILADDRESS} "ioB.ini" "Account ${L_DATA_INDEX}" "EMailAddress"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_POP3SERVER}   "ioB.ini" "Account ${L_DATA_INDEX}" "POP3server"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_POP3USERNAME} "ioB.ini" "Account ${L_DATA_INDEX}" "POP3username"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_POP3PORT}     "ioB.ini" "Account ${L_DATA_INDEX}" "POP3port"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_REGKEY}       "ioB.ini" "Account ${L_DATA_INDEX}" "RegistryKey"

  MessageBox MB_YESNO \
      "$(PFI_LANG_EXPCFG_MBIDENTITY) ${L_IDENTITY}\
      $\r$\n$\r$\n\
      $(PFI_LANG_EXPCFG_MBACCOUNT) ${L_ACCOUNTNAME}\
      $\r$\n$\r$\n\
      $(PFI_LANG_OOECFG_MBEMAIL) ${L_EMAILADDRESS}\
      $\r$\n$\r$\n\
      $(PFI_LANG_OOECFG_MBSERVER) 127.0.0.1 \
                                   ($(PFI_LANG_OOECFG_MBOLDVALUE) '${L_POP3SERVER}')\
      $\r$\n$\r$\n\
      $(PFI_LANG_OOECFG_MBUSERNAME) ${L_POP3SERVER}$G_SEPARATOR${L_POP3USERNAME} \
                                     ($(PFI_LANG_OOECFG_MBOLDVALUE) '${L_POP3USERNAME}')\
      $\r$\n$\r$\n\
      $(PFI_LANG_OOECFG_MBOEPORT) $G_POP3 \
                                   ($(PFI_LANG_OOECFG_MBOLDVALUE) '${L_POP3PORT}')\
      $\r$\n$\r$\n$\r$\n\
      $(PFI_LANG_OOECFG_MBQUESTION)\
      " IDNO ignore_tick

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Identity" "PageStatus" "updated"
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field ${L_CBOX_INDEX}" "Flags" "DISABLED"

  ReadINIStr  ${L_UNDO} "$G_USERDIR\pfi-outexpress.ini" "History" "ListSize"
  StrCmp ${L_UNDO} "" 0 update_list_size
  StrCpy ${L_UNDO} 1
  WriteINIStr "$G_USERDIR\pfi-outexpress.ini" "History" "ListSize" "1"
  Goto add_entry

update_list_size:
  IntOp ${L_UNDO} ${L_UNDO} + 1
  WriteINIStr "$G_USERDIR\pfi-outexpress.ini" "History" "ListSize" "${L_UNDO}"

add_entry:
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "DateTime" "OutlookExpress"
  WriteINIStr "$G_USERDIR\pfi-outexpress.ini" "History" "Undo-${L_UNDO}" "Created on ${L_TEMP}"
  WriteINIStr "$G_USERDIR\pfi-outexpress.ini" "History" "User-${L_UNDO}" "$G_WINUSERNAME"
  WriteINIStr "$G_USERDIR\pfi-outexpress.ini" "History" "Type-${L_UNDO}" "$G_WINUSERTYPE"
  WriteINIStr "$G_USERDIR\pfi-outexpress.ini" "History" "IniV-${L_UNDO}" "3"

  WriteINIStr "$G_USERDIR\pfi-outexpress.ini" "Undo-${L_UNDO}" "Restored" "No"
  WriteINIStr "$G_USERDIR\pfi-outexpress.ini" "Undo-${L_UNDO}" "RegistryKey" "${L_REGKEY}"
  WriteINIStr "$G_USERDIR\pfi-outexpress.ini" "Undo-${L_UNDO}" "POP3UserName" "${L_POP3USERNAME}"
  WriteINIStr "$G_USERDIR\pfi-outexpress.ini" "Undo-${L_UNDO}" "POP3Server" "${L_POP3SERVER}"
  WriteINIStr "$G_USERDIR\pfi-outexpress.ini" "Undo-${L_UNDO}" "POP3Port" "${L_POP3PORT}"

  ; Reconfigure the Outlook Express account

  WriteRegStr HKCU ${L_REGKEY} "POP3 User Name" "${L_POP3SERVER}$G_SEPARATOR${L_POP3USERNAME}"
  WriteRegStr HKCU ${L_REGKEY} "POP3 Server" "127.0.0.1"
  WriteRegDWORD HKCU ${L_REGKEY} "POP3 Port" $G_POP3

  !insertmacro OOECONFIG_CHANGES_LOG  "${L_IDENTITY}"    20
  !insertmacro OOECONFIG_CHANGES_LOG  "${L_ACCOUNTNAME}" 20
  !insertmacro OOECONFIG_CHANGES_LOG  "127.0.0.1"        17
  !insertmacro OOECONFIG_CHANGES_LOG  "${L_POP3SERVER}$G_SEPARATOR${L_POP3USERNAME}"  40
  FileWrite $G_OOECHANGES_HANDLE "$G_POP3$\r$\n"

  Goto continue

ignore_tick:
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Identity" "PageStatus" "leftover_ticks"

continue:
  IntOp ${L_CBOX_INDEX} ${L_CBOX_INDEX} + 1
  IntOp ${L_DATA_INDEX} ${L_DATA_INDEX} + 1
  IntCmp ${L_DATA_INDEX} $G_OOELIST_INDEX next_row next_row

exit:
  Pop ${L_POP3PORT}
  Pop ${L_POP3USERNAME}
  Pop ${L_POP3SERVER}
  Pop ${L_EMAILADDRESS}
  Pop ${L_ACCOUNTNAME}

  Pop ${L_UNDO}
  Pop ${L_IDENTITY}
  Pop ${L_TEXT_ENTRY}
  Pop ${L_TEMP}
  Pop ${L_REGKEY}
  Pop ${L_DATA_INDEX}
  Pop ${L_CBOX_STATE}
  Pop ${L_CBOX_INDEX}

  !undef L_CBOX_INDEX
  !undef L_CBOX_STATE
  !undef L_DATA_INDEX
  !undef L_REGKEY
  !undef L_TEMP
  !undef L_TEXT_ENTRY
  !undef L_IDENTITY
  !undef L_UNDO

  !undef L_ACCOUNTNAME
  !undef L_EMAILADDRESS
  !undef L_POP3SERVER
  !undef L_POP3USERNAME
  !undef L_POP3PORT

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: SetOutlookPage (generates a custom page)
#
# This function is used to reconfigure Outlook accounts
#--------------------------------------------------------------------------

Function SetOutlookPage

  ; This is an initial attempt at providing reconfiguration of Outlook POP3 accounts
  ; (unlike the 'SetOutlookExpressPage' function, 'SetOutlookPage' is based upon theory
  ; instead of experiment)

  ; Each version of Outlook seems to use a slightly different location in the registry
  ; (this is an incomplete list but it is all that is to hand at the moment):
  ;
  ; Outlook 2000:
  ;   HKEY_CURRENT_USER\Software\Microsoft\Office\Outlook\OMI Account Manager\Accounts
  ;
  ; Outlook 98:
  ;   HKEY_CURRENT_USER\Software\Microsoft\Office\8.0\Outlook\OMI Account Manager\Accounts
  ;
  ; Outlook 97:
  ;   HKEY_CURRENT_USER\Software\Microsoft\Office\7.0\Outlook\OMI Account Manager\Accounts
  ;
  ; Before working through this list, we try to cheat by looking for the key
  ;
  ;   HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Account Manager\Outlook
  ;
  ; which may solve our problem (e.g. "Software\Microsoft\Office\Outlook\OMI Account Manager")

  ; All of the account data for the current user appears "under" the path defined
  ; above, e.g. if a user has several accounts, the account data is stored like this:
  ;    HKEY_CURRENT_USER\Software\Microsoft\Office\...\OMI Account Manager\Accounts\00000001
  ;    HKEY_CURRENT_USER\Software\Microsoft\Office\...\OMI Account Manager\Accounts\00000002
  ;    etc

  ; (This format is similar to that used by Outlook Express)

  !define L_ACCOUNT       $R9   ; path to data for current Outlook account (less the HKCU part)
  !define L_ACCT_INDEX    $R8   ; used to loop through Outlook accounts for the current user
  !define L_EMAILADDRESS  $R7   ; for an Outlook account
  !define L_OUTDATA       $R5   ; some data (it varies) for current Outlook account
  !define L_OUTLOOK       $R4   ; registry path for the Outlook accounts (less the HKCU part)
  !define L_POP3SERVER    $R3   ; POP3 server name for an Outlook account
  !define L_PORT          $R2   ; POP3 Port used for an Outlook Account
  !define L_STATUS        $R1   ; keeps track of the status of the account we are checking
  !define L_TEMP          $R0
  !define L_USERNAME      $9    ; POP3 username used for an Outlook account

  Push ${L_ACCOUNT}
  Push ${L_ACCT_INDEX}
  Push ${L_EMAILADDRESS}
  Push ${L_OUTDATA}
  Push ${L_OUTLOOK}
  Push ${L_POP3SERVER}
  Push ${L_PORT}
  Push ${L_STATUS}
  Push ${L_TEMP}
  Push ${L_USERNAME}

  !insertmacro MUI_HEADER_TEXT "$(PFI_LANG_OUTCFG_TITLE)" "$(PFI_LANG_OUTCFG_SUBTITLE)"

  ; Create timestamp used for all Outlook configuration activities
  ; and convert old-style 'undo' data to the new INI-file format

  Call GetDateTimeStamp
  Pop ${L_TEMP}
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "DateTime" "Outlook" "${L_TEMP}"
  IfFileExists "$G_USERDIR\outlook.reg" 0 check_for_outlook
  Push "outlook.reg"
  Call ConvertOOERegData

check_for_outlook:

  ; Check if user decided to skip all email client configuration

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioF.ini" "ClientEXE" "ConfigStatus"
    StrCmp ${L_STATUS} "SkipAll" exit

  ; Look for Outlook account data - if none found then quit

  ReadRegStr ${L_OUTLOOK} HKLM "Software\Microsoft\Internet Account Manager" "Outlook"
  StrCmp ${L_OUTLOOK} "" try_outlook_2000
  Push ${L_OUTLOOK}
  Push "OMI Account Manager"
  Call StrStr
  Pop ${L_TEMP}
  StrCmp ${L_TEMP} "" try_outlook_2000
  StrCpy ${L_TEMP} ${L_OUTLOOK} "" -9
  StrCmp ${L_TEMP} "\Accounts" got_outlook_path
  StrCpy ${L_OUTLOOK} "${L_OUTLOOK}\Accounts"
  Goto got_outlook_path

try_outlook_2000:
  EnumRegKey ${L_OUTLOOK} HKCU "Software\Microsoft\Office\Outlook\OMI Account Manager\Accounts" 0
  StrCmp ${L_OUTLOOK} "" try_outlook_98
  StrCpy ${L_OUTLOOK} "Software\Microsoft\Office\Outlook\OMI Account Manager\Accounts"
  Goto got_outlook_path

try_outlook_98:
  EnumRegKey ${L_OUTLOOK} HKCU "Software\Microsoft\Office\8.0\Outlook\OMI Account Manager\Accounts" 0
  StrCmp ${L_OUTLOOK} "" try_outlook_97
  StrCpy ${L_OUTLOOK} "Software\Microsoft\Office\8.0\Outlook\OMI Account Manager\Accounts"
  Goto got_outlook_path

try_outlook_97:
  EnumRegKey ${L_OUTLOOK} HKCU "Software\Microsoft\Office\7.0\Outlook\OMI Account Manager\Accounts" 0
  StrCmp ${L_OUTLOOK} "" exit
  StrCpy ${L_OUTLOOK} "Software\Microsoft\Office\7.0\Outlook\OMI Account Manager\Accounts"

got_outlook_path:
  FindWindow ${L_STATUS} "rctrl_renwnd32"
  IsWindow ${L_STATUS} 0 open_logfiles

  MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP|MB_DEFBUTTON2 "$(PFI_LANG_MBCLIENT_OUT)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_1)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_2)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_3)"\
             IDRETRY got_outlook_path IDIGNORE open_logfiles

abort_outlook_config:

  ; Either 'Abort' has been selected so we do not offer to reconfigure any Outlook accounts
  ; or 'Cancel' has been selected during the Outlook configuration process so we stop now

  !insertmacro MUI_INSTALLOPTIONS_WRITE   "ioB.ini" "Settings" "NumFields" "1"
  !insertmacro MUI_INSTALLOPTIONS_WRITE   "ioB.ini" "Settings" "BackEnabled" "0"
  !insertmacro PFI_IO_TEXT "ioB.ini" "1" "$(PFI_LANG_OUTCFG_IO_CANCELLED)"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "ioB.ini"
  StrCmp $G_OOECONFIG_HANDLE "" exit
  FileWrite $G_OOECONFIG_HANDLE "$\r$\n\
      $(PFI_LANG_OUTCFG_IO_CANCELLED)\
      $\r$\n"
  Goto finished_outlook_config

open_logfiles:
  !insertmacro MUI_INSTALLOPTIONS_WRITE   "ioB.ini" "Settings" "BackEnabled" "1"

  Call GetDateTimeStamp
  Pop ${L_TEMP}

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "DateTime" "Outlook" "${L_TEMP}"

  FileOpen  $G_OOECONFIG_HANDLE "$G_USERDIR\outconfig.txt" w
  FileWrite $G_OOECONFIG_HANDLE "[$G_WINUSERNAME] $(PFI_LANG_OUTCFG_LOG_BEFORE) (${L_TEMP})\
      $\r$\n$\r$\n"
  !insertmacro OOECONFIG_BEFORE_LOG  "$(PFI_LANG_OUTCFG_LOG_IDENTITY)"  20
  !insertmacro OOECONFIG_BEFORE_LOG  "$(PFI_LANG_OOECFG_LOG_ACCOUNT)"   20
  !insertmacro OOECONFIG_BEFORE_LOG  "$(PFI_LANG_OOECFG_LOG_EMAIL)"     30
  !insertmacro OOECONFIG_BEFORE_LOG  "$(PFI_LANG_OOECFG_LOG_SERVER)"    20
  !insertmacro OOECONFIG_BEFORE_LOG  "$(PFI_LANG_OOECFG_LOG_USER)"      20
  FileWrite $G_OOECONFIG_HANDLE "$(PFI_LANG_OOECFG_LOG_PORT)\
      $\r$\n$\r$\n"

  FileOpen  $G_OOECHANGES_HANDLE "$G_USERDIR\outchanges.txt" a
  FileSeek  $G_OOECHANGES_HANDLE 0 END
  FileWrite $G_OOECHANGES_HANDLE "[$G_WINUSERNAME] $(PFI_LANG_OUTCFG_LOG_AFTER) (${L_TEMP})\
      $\r$\n$\r$\n"
  !insertmacro OOECONFIG_CHANGES_LOG  "$(PFI_LANG_OUTCFG_LOG_IDENTITY)"   20
  !insertmacro OOECONFIG_CHANGES_LOG  "$(PFI_LANG_OOECFG_LOG_ACCOUNT)"    20
  !insertmacro OOECONFIG_CHANGES_LOG  "$(PFI_LANG_OOECFG_LOG_NEWSERVER)"  17
  !insertmacro OOECONFIG_CHANGES_LOG  "$(PFI_LANG_OOECFG_LOG_NEWUSER)"    40
  FileWrite $G_OOECHANGES_HANDLE "$(PFI_LANG_OOECFG_LOG_NEWPORT)\
      $\r$\n$\r$\n"

  ; Determine the separator character to be used when configuring an email account for POPFile

  Call GetSeparator
  Pop $G_SEPARATOR

  ; Start with an empty list of accounts and reset the list "pointers"

  Call ResetOutlookOutLookExpressAccountList

  ; Now check all of the Outlook accounts for the current user

  StrCpy ${L_ACCT_INDEX} 0

next_acct:

  ; Reset the text string used to keep track of the status of the email account we are checking

  StrCpy ${L_STATUS} ""

  EnumRegKey ${L_ACCOUNT} HKCU ${L_OUTLOOK} ${L_ACCT_INDEX}
  StrCmp ${L_ACCOUNT} "" finished_the_accounts
  StrCpy ${L_ACCOUNT} "${L_OUTLOOK}\${L_ACCOUNT}"

  ; Now extract the POP3 Server data, if this does not exist then this account is
  ; not configured for mail so move on. If the data is "127.0.0.1" assume the account has
  ; already been configured for use with POPFile.

  ReadRegStr ${L_OUTDATA} HKCU ${L_ACCOUNT} "POP3 Server"
  StrCmp ${L_OUTDATA} "" try_next_account

  ; Have found an email account so we add a new entry to the list (which can hold 6 accounts)

  IntOp $G_OOELIST_INDEX $G_OOELIST_INDEX + 1    ; used to access the [Account] data in ioB.ini
  IntOp $G_OOELIST_CBOX $G_OOELIST_CBOX + 1      ; field number for relevant checkbox

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Settings" "NumFields" "$G_OOELIST_CBOX"

  StrCmp ${L_OUTDATA} "127.0.0.1" 0 check_pop3_server
  StrCpy ${L_STATUS} "bad IP"
  Goto check_pop3_username

check_pop3_server:

  ; If 'POP3 Server' data contains the separator character, we cannot configure this account

  Push ${L_OUTDATA}
  Push $G_SEPARATOR
  Call StrStr
  Pop ${L_TEMP}
  StrCmp ${L_TEMP} "" check_pop3_username
  StrCpy ${L_STATUS} "bad servername"

check_pop3_username:

  ; Prepare to display the 'POP3 Server' data

  StrCpy ${L_POP3SERVER} ${L_OUTDATA}

  ReadRegStr ${L_OUTDATA} HKCU ${L_ACCOUNT} "SMTP Email Address"

  StrCpy ${L_EMAILADDRESS} ${L_OUTDATA}

  ReadRegDWORD ${L_PORT} HKCU ${L_ACCOUNT} "POP3 Port"
  StrCmp ${L_PORT} "" 0 port_ok
  StrCpy ${L_PORT} "110"

port_ok:
  ReadRegStr ${L_OUTDATA} HKCU ${L_ACCOUNT} "POP3 User Name"
  StrCpy ${L_USERNAME} ${L_OUTDATA}
  StrCmp ${L_USERNAME} "" bad_username

  ; If 'POP3 User Name' data contains the separator character, we cannot configure this account

  Push ${L_OUTDATA}
  Push $G_SEPARATOR
  Call StrStr
  Pop ${L_TEMP}
  StrCmp ${L_TEMP} "" configurable
  StrCmp ${L_STATUS} "" 0 configurable

bad_username:
  StrCpy ${L_STATUS} "bad username"
  Goto continue

configurable:
  StrCmp ${L_STATUS} "" 0 continue
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field $G_OOELIST_CBOX" "Flags" ""

continue:

  ; Find the Username used by Outlook for this identity and the Outlook Account Name
  ; (so we can unambiguously report which email account we are offering to reconfigure).

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field 1" "Text" "'$G_WINUSERNAME' $(PFI_LANG_OOECFG_IO_BOXHDR)"
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Identity" "Username" "$G_WINUSERNAME"

  ReadRegStr ${L_OUTDATA} HKCU ${L_ACCOUNT} "Account Name"

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioB.ini" "Field 8" "State"
  StrCpy ${L_TEMP} ""
  StrCmp ${L_STATUS} "" no_padding
  StrCpy ${L_TEMP} "\r\n\r\n"

no_padding:
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Field 8" "State" "${L_STATUS}${L_TEMP}${L_OUTDATA}"

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioB.ini" "Field 9" "State"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Field 9" "State" "${L_STATUS}${L_TEMP}${L_EMAILADDRESS}"

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioB.ini" "Field 10" "State"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Field 10" "State" "${L_STATUS}${L_TEMP}${L_POP3SERVER}"

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioB.ini" "Field 11" "State"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Field 11" "State" "${L_STATUS}${L_TEMP}${L_USERNAME}"

  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "AccountName" "${L_OUTDATA}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "EmailAddress" "${L_EMAILADDRESS}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "POP3server" "${L_POP3SERVER}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "POP3username" "${L_USERNAME}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "POP3port" "${L_PORT}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE  "ioB.ini" "Account $G_OOELIST_INDEX" "RegistryKey" "${L_ACCOUNT}"

  !insertmacro OOECONFIG_BEFORE_LOG  "$G_WINUSERNAME"    20
  !insertmacro OOECONFIG_BEFORE_LOG  "${L_OUTDATA}"      20
  !insertmacro OOECONFIG_BEFORE_LOG  "${L_EMAILADDRESS}" 30
  !insertmacro OOECONFIG_BEFORE_LOG  "${L_POP3SERVER}"   20
  !insertmacro OOECONFIG_BEFORE_LOG  "${L_USERNAME}"     20
  FileWrite $G_OOECONFIG_HANDLE "${L_PORT}\
      $\r$\n"

  IntCmp $G_OOELIST_INDEX 6 display_list try_next_account try_next_account

display_list:

  ; Display the Outlook account data with checkboxes enabled for those accounts we can configure

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Identity" "PageStatus" "new"

  !insertmacro MUI_INSTALLOPTIONS_INITDIALOG "ioB.ini"
  Pop $G_HWND                 ; HWND of dialog we want to modify

  ; In 'GetDlgItem', use (1200 + Field number - 1) to refer to the field to be changed

  GetDlgItem $G_DLGITEM $G_HWND 1200              ; Field 1 = IDENTITY label (above the box)
  CreateFont $G_FONT "MS Shell Dlg" 8 700        ; use a 'bolder' version of the font in use
  SendMessage $G_DLGITEM ${WM_SETFONT} $G_FONT 0

  !insertmacro MUI_INSTALLOPTIONS_SHOW_RETURN
  Pop ${L_TEMP}

  StrCmp ${L_TEMP} "back" abort_outlook_config
  StrCmp ${L_TEMP} "cancel" finished_outlook_config

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "Identity" "PageStatus"
  StrCmp ${L_TEMP} "updated" display_list
  StrCmp ${L_TEMP} "leftover_ticks" display_list

  Call ResetOutlookOutlookExpressAccountList

try_next_account:
  IntOp ${L_ACCT_INDEX} ${L_ACCT_INDEX} + 1
  goto next_acct

finished_the_accounts:
  IntCmp $G_OOELIST_INDEX 0 finished_outlook_config

display_list_again:
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Identity" "PageStatus" "new"

  !insertmacro MUI_INSTALLOPTIONS_INITDIALOG "ioB.ini"
  Pop $G_HWND                 ; HWND of dialog we want to modify

  ; In 'GetDlgItem', use (1200 + Field number - 1) to refer to the field to be changed

  GetDlgItem $G_DLGITEM $G_HWND 1200              ; Field 1 = IDENTITY label (above the box)
  CreateFont $G_FONT "MS Shell Dlg" 8 700        ; use a 'bolder' version of the font in use
  SendMessage $G_DLGITEM ${WM_SETFONT} $G_FONT 0

  !insertmacro MUI_INSTALLOPTIONS_SHOW_RETURN
  Pop ${L_TEMP}

  StrCmp ${L_TEMP} "back" abort_outlook_config
  StrCmp ${L_TEMP} "cancel" finished_outlook_config

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "Identity" "PageStatus"
  StrCmp ${L_TEMP} "updated" display_list_again
  StrCmp ${L_TEMP} "leftover_ticks" display_list_again

  Call ResetOutlookOutlookExpressAccountList

finished_outlook_config:
  FileWrite $G_OOECONFIG_HANDLE "$\r$\n\
      $(PFI_LANG_OOECFG_LOG_END)\
      $\r$\n$\r$\n"
  FileClose $G_OOECONFIG_HANDLE

  FileWrite $G_OOECHANGES_HANDLE "$\r$\n\
      $(PFI_LANG_OOECFG_LOG_END)\
      $\r$\n$\r$\n"
  FileClose $G_OOECHANGES_HANDLE

exit:
  Pop ${L_USERNAME}
  Pop ${L_TEMP}
  Pop ${L_STATUS}
  Pop ${L_PORT}
  Pop ${L_POP3SERVER}
  Pop ${L_OUTLOOK}
  Pop ${L_OUTDATA}
  Pop ${L_EMAILADDRESS}
  Pop ${L_ACCT_INDEX}
  Pop ${L_ACCOUNT}

  !undef L_ACCOUNT
  !undef L_ACCT_INDEX
  !undef L_EMAILADDRESS
  !undef L_OUTDATA
  !undef L_OUTLOOK
  !undef L_POP3SERVER
  !undef L_PORT
  !undef L_STATUS
  !undef L_TEMP
  !undef L_USERNAME

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: CheckOutlookRequests
#
# This function is used to confirm any Outlook Express account reconfiguration requests
#--------------------------------------------------------------------------

Function CheckOutlookRequests

  !define L_CBOX_INDEX   $R9
  !define L_CBOX_STATE   $R8
  !define L_DATA_INDEX   $R7
  !define L_REGKEY       $R6
  !define L_TEMP         $R5
  !define L_TEXT_ENTRY   $R4
  !define L_IDENTITY     $R3
  !define L_UNDO         $R2

  !define L_ACCOUNTNAME   $9
  !define L_EMAILADDRESS  $8
  !define L_POP3SERVER    $7
  !define L_POP3USERNAME  $6
  !define L_POP3PORT      $5

  Push ${L_CBOX_INDEX}
  Push ${L_CBOX_STATE}
  Push ${L_DATA_INDEX}
  Push ${L_REGKEY}
  Push ${L_TEMP}
  Push ${L_TEXT_ENTRY}
  Push ${L_IDENTITY}
  Push ${L_UNDO}

  Push ${L_ACCOUNTNAME}
  Push ${L_EMAILADDRESS}
  Push ${L_POP3SERVER}
  Push ${L_POP3USERNAME}
  Push ${L_POP3PORT}

  ; If user has cancelled the reconfiguration, there is nothing to do here

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "Settings" "NumFields"
  StrCmp ${L_TEMP} "1" exit

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_IDENTITY} "ioB.ini" "Identity" "Username"

  StrCpy ${L_CBOX_INDEX} 12
  StrCpy ${L_DATA_INDEX} 1

next_row:
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_CBOX_STATE} "ioB.ini" "Field ${L_CBOX_INDEX}" "Flags"
  StrCmp ${L_CBOX_STATE} "DISABLED" continue

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_CBOX_STATE} "ioB.ini" "Field ${L_CBOX_INDEX}" "State"
  StrCmp ${L_CBOX_STATE} "0" continue

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_ACCOUNTNAME}  "ioB.ini" "Account ${L_DATA_INDEX}" "AccountName"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_EMAILADDRESS} "ioB.ini" "Account ${L_DATA_INDEX}" "EMailAddress"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_POP3SERVER}   "ioB.ini" "Account ${L_DATA_INDEX}" "POP3server"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_POP3USERNAME} "ioB.ini" "Account ${L_DATA_INDEX}" "POP3username"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_POP3PORT}     "ioB.ini" "Account ${L_DATA_INDEX}" "POP3port"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_REGKEY}       "ioB.ini" "Account ${L_DATA_INDEX}" "RegistryKey"

  MessageBox MB_YESNO \
      "$(PFI_LANG_OUTCFG_MBIDENTITY) ${L_IDENTITY}\
      $\r$\n$\r$\n\
      $(PFI_LANG_OUTCFG_MBACCOUNT) ${L_ACCOUNTNAME}\
      $\r$\n$\r$\n\
      $(PFI_LANG_OOECFG_MBEMAIL) ${L_EMAILADDRESS}\
      $\r$\n$\r$\n\
      $(PFI_LANG_OOECFG_MBSERVER) 127.0.0.1 \
                                   ($(PFI_LANG_OOECFG_MBOLDVALUE) '${L_POP3SERVER}')\
      $\r$\n$\r$\n\
      $(PFI_LANG_OOECFG_MBUSERNAME) ${L_POP3SERVER}$G_SEPARATOR${L_POP3USERNAME} \
                                     ($(PFI_LANG_OOECFG_MBOLDVALUE) '${L_POP3USERNAME}')\
      $\r$\n$\r$\n\
      $(PFI_LANG_OOECFG_MBOEPORT) $G_POP3 \
                                   ($(PFI_LANG_OOECFG_MBOLDVALUE) '${L_POP3PORT}')\
      $\r$\n$\r$\n$\r$\n\
      $(PFI_LANG_OOECFG_MBQUESTION)\
      " IDNO ignore_tick

  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Identity" "PageStatus" "updated"
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Field ${L_CBOX_INDEX}" "Flags" "DISABLED"

  ReadINIStr  ${L_UNDO} "$G_USERDIR\pfi-outlook.ini" "History" "ListSize"
  StrCmp ${L_UNDO} "" 0 update_list_size
  StrCpy ${L_UNDO} 1
  WriteINIStr "$G_USERDIR\pfi-outlook.ini" "History" "ListSize" "1"
  Goto add_entry

update_list_size:
  IntOp ${L_UNDO} ${L_UNDO} + 1
  WriteINIStr "$G_USERDIR\pfi-outlook.ini" "History" "ListSize" "${L_UNDO}"

add_entry:
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioB.ini" "DateTime" "Outlook"
  WriteINIStr "$G_USERDIR\pfi-outlook.ini" "History" "Undo-${L_UNDO}" "Created on ${L_TEMP}"
  WriteINIStr "$G_USERDIR\pfi-outlook.ini" "History" "User-${L_UNDO}" "$G_WINUSERNAME"
  WriteINIStr "$G_USERDIR\pfi-outlook.ini" "History" "Type-${L_UNDO}" "$G_WINUSERTYPE"
  WriteINIStr "$G_USERDIR\pfi-outlook.ini" "History" "IniV-${L_UNDO}" "3"

  WriteINIStr "$G_USERDIR\pfi-outlook.ini" "Undo-${L_UNDO}" "Restored" "No"
  WriteINIStr "$G_USERDIR\pfi-outlook.ini" "Undo-${L_UNDO}" "RegistryKey" "${L_REGKEY}"
  WriteINIStr "$G_USERDIR\pfi-outlook.ini" "Undo-${L_UNDO}" "POP3UserName" "${L_POP3USERNAME}"
  WriteINIStr "$G_USERDIR\pfi-outlook.ini" "Undo-${L_UNDO}" "POP3Server" "${L_POP3SERVER}"
  WriteINIStr "$G_USERDIR\pfi-outlook.ini" "Undo-${L_UNDO}" "POP3Port" "${L_POP3PORT}"

  ; Reconfigure the Outlook account

  WriteRegStr HKCU ${L_REGKEY} "POP3 User Name" "${L_POP3SERVER}$G_SEPARATOR${L_POP3USERNAME}"
  WriteRegStr HKCU ${L_REGKEY} "POP3 Server" "127.0.0.1"
  WriteRegDWORD HKCU ${L_REGKEY} "POP3 Port" $G_POP3

  !insertmacro OOECONFIG_CHANGES_LOG  "${L_IDENTITY}"    20
  !insertmacro OOECONFIG_CHANGES_LOG  "${L_ACCOUNTNAME}" 20
  !insertmacro OOECONFIG_CHANGES_LOG  "127.0.0.1"        17
  !insertmacro OOECONFIG_CHANGES_LOG  "${L_POP3SERVER}$G_SEPARATOR${L_POP3USERNAME}"  40
  FileWrite $G_OOECHANGES_HANDLE "$G_POP3\
      $\r$\n"

  Goto continue

ignore_tick:
  !insertmacro MUI_INSTALLOPTIONS_WRITE    "ioB.ini" "Identity" "PageStatus" "leftover_ticks"

continue:
  IntOp ${L_CBOX_INDEX} ${L_CBOX_INDEX} + 1
  IntOp ${L_DATA_INDEX} ${L_DATA_INDEX} + 1
  IntCmp ${L_DATA_INDEX} $G_OOELIST_INDEX next_row next_row

exit:
  Pop ${L_POP3PORT}
  Pop ${L_POP3USERNAME}
  Pop ${L_POP3SERVER}
  Pop ${L_EMAILADDRESS}
  Pop ${L_ACCOUNTNAME}

  Pop ${L_UNDO}
  Pop ${L_IDENTITY}
  Pop ${L_TEXT_ENTRY}
  Pop ${L_TEMP}
  Pop ${L_REGKEY}
  Pop ${L_DATA_INDEX}
  Pop ${L_CBOX_STATE}
  Pop ${L_CBOX_INDEX}

  !undef L_CBOX_INDEX
  !undef L_CBOX_STATE
  !undef L_DATA_INDEX
  !undef L_REGKEY
  !undef L_TEMP
  !undef L_TEXT_ENTRY
  !undef L_IDENTITY
  !undef L_UNDO

  !undef L_ACCOUNTNAME
  !undef L_EMAILADDRESS
  !undef L_POP3SERVER
  !undef L_POP3USERNAME
  !undef L_POP3PORT

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: SetEudoraPage_Init
#
# This function adds language texts to the INI file used by the "SetEudoraPage" function
# (to make the custom page use the language selected by the user for the installer)
#--------------------------------------------------------------------------

Function SetEudoraPage_Init

  ; Ensure custom page matches the selected language (left-to-right or right-to-left order)

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Settings" "RTL" "$(^RTL)"

  ; We use the 'Back' button as an easy way to skip the 'Eudora' reconfiguration

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" \
              "Settings" "BackButtonText" "$(PFI_LANG_MAILCFG_IO_SKIPONE)"

  !insertmacro PFI_IO_TEXT "ioE.ini" "2" "$(PFI_LANG_EUCFG_IO_CHECKBOX)"
  !insertmacro PFI_IO_TEXT "ioE.ini" "3" "$(PFI_LANG_EUCFG_IO_RESTORE)"

  !insertmacro PFI_IO_TEXT "ioE.ini" "5" "$(PFI_LANG_EUCFG_IO_EMAIL)"
  !insertmacro PFI_IO_TEXT "ioE.ini" "6" "$(PFI_LANG_EUCFG_IO_SERVER)"
  !insertmacro PFI_IO_TEXT "ioE.ini" "7" "$(PFI_LANG_EUCFG_IO_USERNAME)"
  !insertmacro PFI_IO_TEXT "ioE.ini" "8" "$(PFI_LANG_EUCFG_IO_POP3PORT)"

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: SetEudoraPage (generates a custom page)
#
# This function is used to reconfigure Eudora personalities
#--------------------------------------------------------------------------

Function SetEudoraPage

  !define L_ININAME   $R9   ; used to get full pathname of the Eudora.ini file
  !define L_LENGTH    $R8   ; used when determining L_ININAME
  !define L_STATUS    $R7
  !define L_TEMP      $R6
  !define L_TERMCHR   $R5   ; used when determining L_ININAME

  !define L_ACCOUNT   $R4   ; persona details extracted from Eudora.ini file
  !define L_EMAIL     $R3   ; ditto
  !define L_SERVER    $R2   ; ditto
  !define L_USER      $R1   ; ditto
  !define L_PERPORT   $R0   ; ditto

  !define L_INDEX     $9   ; used when updating the undo history
  !define L_PERSONA   $8   ; persona name ('Dominant' entry is called 'Settings')
  !define L_CFGTIME   $7   ; timestamp used when updating the undo history

  !define L_DOMPORT   $6  ; current pop3 port for Dominant personality
  !define L_PREVDOM   $5  ; Dominant personality's pop3 port BEFORE we started processing

  Push ${L_ININAME}
  Push ${L_LENGTH}
  Push ${L_STATUS}
  Push ${L_TEMP}
  Push ${L_TERMCHR}

  Push ${L_ACCOUNT}
  Push ${L_EMAIL}
  Push ${L_SERVER}
  Push ${L_USER}
  Push ${L_PERPORT}

  Push ${L_INDEX}
  Push ${L_PERSONA}
  Push ${L_CFGTIME}

  Push ${L_DOMPORT}
  Push ${L_PREVDOM}

  ; Check if user decided to skip all email client configuration

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioF.ini" "ClientEXE" "ConfigStatus"
  StrCmp ${L_STATUS} "SkipAll" exit

  ; Look for Eudora registry entry which identifies the relevant INI file

  ReadRegStr ${L_STATUS} HKCU "Software\Qualcomm\Eudora\CommandLine" "current"
  StrCmp ${L_STATUS} "" 0 extract_INI_path

  ; No data in registry. Did the 'SetEmailClient' function find a path for the Eudora program?

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioF.ini" "ClientEXE" "Eudora"
  StrCmp ${L_STATUS} "" exit

  ; Look for the Eudora INI file

  Push ${L_STATUS}
  Call GetParent
  Pop ${L_ININAME}
  StrCpy ${L_ININAME} "${L_ININAME}\EUDORA.INI"
  IfFileExists "${L_ININAME}" gotname exit

extract_INI_path:

  ; Extract full path to the Eudora INI file

  StrCpy ${L_TEMP} -1
  StrLen ${L_LENGTH} ${L_STATUS}
  IntOp ${L_LENGTH} 0 - ${L_LENGTH}

  ; Check if we need to look for a space or double-quotes

  StrCpy ${L_ININAME} ${L_STATUS} 1 ${L_TEMP}
  StrCpy ${L_TERMCHR} '"'
  StrCmp ${L_ININAME} '"' loop
  StrCpy ${L_TERMCHR} ' '

  ; We want the last of the three filename 'tokens' in the value extracted from the registry

loop:
  IntOp ${L_TEMP} ${L_TEMP} - 1
  StrCpy ${L_ININAME} ${L_STATUS} 1 ${L_TEMP}
  StrCmp ${L_ININAME} ${L_TERMCHR} extract
  IntCmp ${L_TEMP} ${L_LENGTH} extract
  Goto loop

extract:
  IntOp ${L_TEMP} ${L_TEMP} + 1
  StrCpy ${L_ININAME} ${L_STATUS} "" ${L_TEMP}
  StrCmp ${L_TERMCHR} ' ' gotname
  StrCpy ${L_ININAME} ${L_ININAME} -1

gotname:
  !insertmacro MUI_HEADER_TEXT "$(PFI_LANG_EUCFG_TITLE)" "$(PFI_LANG_EUCFG_SUBTITLE)"

  ; If Eudora is running, ask the user to shut it down now (user may ignore our request)

check_if_running:
  FindWindow ${L_STATUS} "EudoraMainWindow"
  IsWindow ${L_STATUS} 0 continue

  MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP|MB_DEFBUTTON2 "$(PFI_LANG_MBCLIENT_EUD)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_1)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_2)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_3)"\
             IDRETRY check_if_running IDIGNORE continue

abort_eudora_config:

  ; Either 'Abort' has been selected so we do not offer to reconfigure any Eudora accounts
  ; or 'Cancel' has been selected during the Eudora configuration process so we stop now

  !insertmacro MUI_INSTALLOPTIONS_WRITE   "ioE.ini" "Settings" "NumFields" "1"
  !insertmacro MUI_INSTALLOPTIONS_WRITE   "ioE.ini" "Settings" "BackEnabled" "0"
  !insertmacro PFI_IO_TEXT "ioE.ini" "1" "$(PFI_LANG_EUCFG_IO_CANCELLED)"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "ioE.ini"
  Goto exit

continue:
  !insertmacro MUI_INSTALLOPTIONS_WRITE   "ioE.ini" "Settings" "BackEnabled" "1"
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioE.ini" "Field 2" "Text"
  StrCpy ${L_STATUS} "${L_STATUS} ($(PFI_LANG_EUCFG_IO_POP3PORT) $G_POP3)"
  !insertmacro PFI_IO_TEXT "ioE.ini" "2" "${L_STATUS}"

  Call GetDateTimeStamp
  Pop ${L_CFGTIME}

  ; Normally all Eudora personalities use whatever port the 'Dominant' personality uses.
  ; If the default POP3 port is used then there will be no 'POPPort' defined in Eudora.ini file

  ReadINIStr ${L_DOMPORT} "${L_ININAME}" "Settings" "POPPort"
  StrCmp ${L_DOMPORT} "" 0 not_implied_domport
  StrCpy ${L_DOMPORT} "Default"

not_implied_domport:
  StrCpy ${L_PREVDOM} ${L_DOMPORT}

  ; The <Dominant> personality data is stored separately from that of the other personalities

  !insertmacro PFI_IO_TEXT "ioE.ini" "4" "$(PFI_LANG_EUCFG_IO_DOMINANT)"
  StrCpy ${L_PERSONA} "Settings"
  StrCpy ${L_INDEX} -1
  Goto common_to_all

get_next_persona:
  IntOp ${L_INDEX} ${L_INDEX} + 1
  ReadINIStr ${L_PERSONA}  "${L_ININAME}" "Personalities" "Persona${L_INDEX}"
  StrCmp ${L_PERSONA} "" exit
  StrCpy ${L_TEMP} ${L_PERSONA} "" 8

  !insertmacro PFI_IO_TEXT "ioE.ini" "4" "'${L_TEMP}' $(PFI_LANG_EUCFG_IO_PERSONA)"

common_to_all:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 2" "State" "0"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 2" "Flags" ""
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 3" "Flags" ""

  ReadINIStr ${L_ACCOUNT} "${L_ININAME}" "${L_PERSONA}" "POPAccount"
  ReadINIStr ${L_EMAIL}   "${L_ININAME}" "${L_PERSONA}" "ReturnAddress"
  ReadINIStr ${L_SERVER}  "${L_ININAME}" "${L_PERSONA}" "POPServer"
  ReadINIStr ${L_USER}    "${L_ININAME}" "${L_PERSONA}" "LoginName"
  ReadINIStr ${L_STATUS}  "${L_ININAME}" "${L_PERSONA}" "UsesPOP"

  StrCmp ${L_PERSONA} "Settings" 0 not_dominant
  StrCpy ${L_PERPORT} ${L_DOMPORT}
  Goto check_account

not_dominant:
  ReadINIStr ${L_PERPORT} "${L_ININAME}" "${L_PERSONA}" "POPPort"
  StrCmp ${L_PERPORT} "" 0 check_account
  StrCpy ${L_PERPORT} "Dominant"

check_account:
  StrCmp ${L_ACCOUNT} "" 0 check_server
  StrCpy ${L_ACCOUNT} "N/A"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 2" "Flags" "DISABLED"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 3" "Flags" "DISABLED"

check_server:
  StrCmp ${L_SERVER} "127.0.0.1" disable
  StrCmp ${L_SERVER} "" 0 check_username
  StrCpy ${L_SERVER} "N/A"

disable:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 2" "Flags" "DISABLED"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 3" "Flags" "DISABLED"

check_username:
  StrCmp ${L_USER} "" 0 check_status
  StrCpy ${L_USER} "N/A"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 2" "Flags" "DISABLED"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 3" "Flags" "DISABLED"

check_status:
  StrCmp ${L_STATUS} 1 update_persona_details
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 2" "Flags" "DISABLED"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 3" "Flags" "DISABLED"

update_persona_details:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 9"  "Text" "${L_EMAIL}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 10" "Text" "${L_SERVER}"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 11" "Text" "${L_USER}"

  StrCmp ${L_PERPORT} "Default" default_pop3
  StrCmp ${L_PERPORT} "Dominant" 0 explicit_perport
  StrCmp ${L_PREVDOM} "Default" 0 explicit_domport
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 12" "Text" "(110)"
  Goto update_intro

default_pop3:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 12" "Text" "Default (110)"
  Goto update_intro

explicit_domport:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 12" "Text" "(${L_PREVDOM})"
  Goto update_intro

explicit_perport:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioE.ini" "Field 12" "Text" "${L_PERPORT}"

update_intro:
  StrCpy ${L_TEMP} "."
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioE.ini" "Field 2" "Flags"
  StrCmp ${L_STATUS} "DISABLED" write_intro
  StrCpy ${L_TEMP} "$(PFI_LANG_EUCFG_IO_INTRO_2)"

write_intro:
  !insertmacro PFI_IO_TEXT "ioE.ini" "1" "$(PFI_LANG_EUCFG_IO_INTRO_1)${L_TEMP}"

  !insertmacro MUI_INSTALLOPTIONS_INITDIALOG "ioE.ini"
  Pop $G_HWND                 ; HWND of dialog we want to modify

  ; In 'GetDlgItem', use (1200 + Field number - 1) to refer to the field to be changed

  GetDlgItem $G_DLGITEM $G_HWND 1203             ; Field 4 = PERSONA (text in groupbox frame)
  CreateFont $G_FONT "MS Shell Dlg" 8 700        ; use a 'bolder' version of the font in use
  SendMessage $G_DLGITEM ${WM_SETFONT} $G_FONT 0

  !insertmacro MUI_INSTALLOPTIONS_SHOW_RETURN
  Pop ${L_STATUS}
  StrCmp ${L_STATUS} "back" abort_eudora_config

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_STATUS} "ioE.ini" "Field 2" "State"
  StrCmp ${L_STATUS} "1" reconfigure_persona

  ; This personality is not to be reconfigured. However, if we have changed the POP3 port for
  ; the Dominant personality and this unchanged entry 'inherited' the Dominant personality's
  ; POP3 port then we need to ensure the unchanged port uses the old port setting to avoid
  ; 'breaking' the unchanged personality

  StrCmp ${L_PREVDOM} ${L_DOMPORT} get_next_persona
  StrCmp ${L_PERPORT} "Dominant" 0 get_next_persona

  ReadINIStr  ${L_STATUS} "$G_USERDIR\pfi-eudora.ini" "History" "ListSize"
  IntOp ${L_STATUS} ${L_STATUS} + 1
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "ListSize" "${L_STATUS}"

  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "Undo-${L_STATUS}" "Created on ${L_CFGTIME}"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "Path-${L_STATUS}" "${L_ININAME}"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "User-${L_STATUS}" "$G_WINUSERNAME"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "Type-${L_STATUS}" "$G_WINUSERTYPE"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "IniV-${L_STATUS}" "2"

  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "Restored" "No"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "Persona" "${L_PERSONA}"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "POPAccount" "*.*"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "POPServer" "*.*"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "LoginName" "*.*"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "POPPort" "Dominant"

  StrCmp ${L_PREVDOM} "Default" inherit_default_pop3
  WriteINIStr "${L_ININAME}" "${L_PERSONA}" "POPPort" ${L_PREVDOM}
  Goto get_next_persona

inherit_default_pop3:
  WriteINIStr "${L_ININAME}" "${L_PERSONA}" "POPPort" "110"
  Goto get_next_persona

reconfigure_persona:
  ReadINIStr  ${L_STATUS} "$G_USERDIR\pfi-eudora.ini" "History" "ListSize"
  StrCmp ${L_STATUS} "" 0 update_list_size
  StrCpy ${L_STATUS} 1
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "ListSize" "1"
  Goto add_entry

update_list_size:
  IntOp ${L_STATUS} ${L_STATUS} + 1
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "ListSize" "${L_STATUS}"

add_entry:
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "Undo-${L_STATUS}" "Created on ${L_CFGTIME}"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "Path-${L_STATUS}" "${L_ININAME}"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "User-${L_STATUS}" "$G_WINUSERNAME"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "Type-${L_STATUS}" "$G_WINUSERTYPE"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "History" "IniV-${L_STATUS}" "2"

  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "Restored" "No"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "Persona" "${L_PERSONA}"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "POPAccount" "${L_ACCOUNT}"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "POPServer" "${L_SERVER}"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "LoginName" "${L_USER}"
  WriteINIStr "$G_USERDIR\pfi-eudora.ini" "Undo-${L_STATUS}" "POPPort" "${L_PERPORT}"

  WriteINIStr "${L_ININAME}" "${L_PERSONA}" "POPAccount" "${L_SERVER}$G_SEPARATOR${L_USER}@127.0.0.1"
  WriteINIStr "${L_ININAME}" "${L_PERSONA}" "POPServer"  "127.0.0.1"
  WriteINIStr "${L_ININAME}" "${L_PERSONA}" "LoginName"  "${L_SERVER}$G_SEPARATOR${L_USER}"
  WriteINIStr "${L_ININAME}" "${L_PERSONA}" "POPPort"    $G_POP3
  StrCmp ${L_PERSONA} "Settings" 0 get_next_persona
  StrCpy ${L_DOMPORT} $G_POP3
  Goto get_next_persona

exit:
  Pop ${L_PREVDOM}
  Pop ${L_DOMPORT}

  Pop ${L_CFGTIME}
  Pop ${L_PERSONA}
  Pop ${L_INDEX}

  Pop ${L_PERPORT}
  Pop ${L_USER}
  Pop ${L_SERVER}
  Pop ${L_EMAIL}
  Pop ${L_ACCOUNT}

  Pop ${L_TERMCHR}
  Pop ${L_TEMP}
  Pop ${L_STATUS}
  Pop ${L_LENGTH}
  Pop ${L_ININAME}

  !undef L_ININAME
  !undef L_LENGTH
  !undef L_STATUS
  !undef L_TEMP
  !undef L_TERMCHR

  !undef L_ACCOUNT
  !undef L_EMAIL
  !undef L_SERVER
  !undef L_USER
  !undef L_PERPORT

  !undef L_INDEX
  !undef L_PERSONA
  !undef L_CFGTIME

  !undef L_DOMPORT
  !undef L_PREVDOM

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: StartPOPFilePage_Init (adds language texts to custom page INI file)
#
# This function adds language texts to the INI file used by the "StartPOPFilePage" function
# (to make the custom page use the language selected by the user for the installer)
#--------------------------------------------------------------------------

Function StartPOPFilePage_Init

  ; Ensure custom page matches the selected language (left-to-right or right-to-left order)

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Settings" "RTL" "$(^RTL)"

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
#
# The user is allowed to change their selection by returning to this page (by clicking 'Back'
# on the 'Finish' page) if corpus conversion is not required.
#
# The [Inherited] section in 'ioC.ini' has information on the system tray icon and console mode
# settings found in 'popfile.cfg'. Valid values are 0 (disabled), 1 (enabled) and ? (undefined).
# If any settings are undefined, this function adds the default settings to 'popfile.cfg'
# (i.e. console mode disabled, system tray icon enabled)
#--------------------------------------------------------------------------

Function StartPOPFilePage

  !define L_CFG    $R9
  !define L_TEMP   $R8

  Push ${L_CFG}
  Push ${L_TEMP}

  ; Ensure 'popfile.cfg' has valid settings for system tray icon and console mode
  ; (if necessary, add the default settings to the file and update the [Inherited] copies)

  FileOpen  ${L_CFG} "$G_USERDIR\popfile.cfg" a
  FileSeek  ${L_CFG} 0 END

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Inherited" "Console"
  StrCmp ${L_TEMP} "?" 0 check_trayicon
  FileWrite ${L_CFG} "windows_console 0$\r$\n"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Inherited" "Console" "0"

check_trayicon:
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Inherited" "TrayIcon"
  StrCmp ${L_TEMP} "?" 0 close_file
  FileWrite ${L_CFG} "windows_trayicon 1$\r$\n"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Inherited" "TrayIcon" "1"

close_file:
  FileClose ${L_CFG}

  IfRebootFlag 0 page_enabled

  ; We are running on a Win9x system which must be rebooted before Kakasi can be used,
  ; so we are unable to offer to start POPFile at this point

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 2" "State" "1"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 3" "State" "0"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 4" "State" "0"

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 1" "Flags" "DISABLED"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 2" "Flags" "DISABLED"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 3" "Flags" "DISABLED"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 4" "Flags" "DISABLED"

  Goto display_the_page

page_enabled:

  ; clear all three radio buttons ('do not start', 'use console', 'run in background')

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 2" "State" "0"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 3" "State" "0"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 4" "State" "0"

  ; If we have returned to this page from the 'Finish' page then we can use the [LastAction]
  ; data to select the appropriate radio button, otherwise we use the [Inherited] data.

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Run Status" "LastAction"
  StrCmp ${L_TEMP} "" use_inherited_data
  StrCmp ${L_TEMP} "console" console
  StrCmp ${L_TEMP} "background" background
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 2" "State" "1"
  Goto display_the_page

use_inherited_data:
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Inherited" "Console"
  StrCmp ${L_TEMP} "0" background

console:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 3" "State" "1"
  Goto display_the_page

background:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Field 4" "State" "1"

display_the_page:
  !insertmacro MUI_HEADER_TEXT "$(PFI_LANG_LAUNCH_TITLE)" "$(PFI_LANG_LAUNCH_SUBTITLE)"

  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "ioC.ini"

  Pop ${L_TEMP}
  Pop ${L_CFG}

  !undef L_CFG
  !undef L_TEMP

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: CheckLaunchOptions
# (the "leave" function for the custom page created by "StartPOPFilePage")
#
# This function is used to action the "start POPFile" option selected by the user.
# The user is allowed to return to this page and change their selection, so the
# previous state is stored in the INI file used for this custom page.
#
# If corpus conversion is required, this function will not launch POPFile
# (but it will still update 'popfile.cfg' to reflect the user's startup choice)
#--------------------------------------------------------------------------

Function CheckLaunchOptions

  !define L_CFG         $R9   ; file handle
  !define L_EXE         $R8   ; full path of perl EXE to be monitored
  !define L_TEMP        $R7
  !define L_TRAY        $R6   ; set to 'i' if system tray enabled, otherwise set to ""
  !define L_CONSOLE     $R5   ; new console mode: 0 = disabled, 1 = enabled
  !define L_TIMEOUT     $R4   ; used to wait for the UI to respond (when starting POPFile)

  Push ${L_CFG}
  Push ${L_EXE}
  Push ${L_TEMP}
  Push ${L_TRAY}
  Push ${L_CONSOLE}
  Push ${L_TIMEOUT}

  StrCpy ${L_TRAY} "i"    ; the default is to enable the system tray icon
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Inherited" "TrayIcon"
  StrCmp ${L_TEMP} "1" check_radio_buttons
  StrCpy ${L_TRAY} ""

check_radio_buttons:

  ; Field 2 = 'Do not run POPFile' radio button

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Field 2" "State"
  StrCmp ${L_TEMP} "0" run_popfile

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Run Status" "LastAction"
  StrCmp ${L_TEMP} "" exit_without_banner
  StrCmp ${L_TEMP} "no" exit_without_banner

  ; Selection has been changed from 'use console' or 'run in background' to 'do not run POPFile'

  StrCmp ${L_TEMP} "background" background_to_no
  StrCpy ${L_EXE} "$G_ROOTDIR\popfile${L_TRAY}f.exe"
  Goto lastaction_no

background_to_no:
  StrCpy ${L_EXE} "$G_ROOTDIR\popfile${L_TRAY}b.exe"

lastaction_no:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Run Status" "LastAction" "no"

  ; User has changed their mind: Shutdown the newly installed version of POPFile

  NSISdl::download_quiet http://127.0.0.1:$G_GUI/shutdown "$PLUGINSDIR\shutdown.htm"
  Pop ${L_TEMP}    ; Get the return value (and ignore it)
  Push ${L_EXE}
  Call WaitUntilUnlocked
  Goto exit_without_banner

run_popfile:

  ; Set ${L_EXE} to "" as we do not yet know if we are going to monitor a file in $G_ROOTDIR

  StrCpy ${L_EXE} ""

  ; Field 4 = 'Run POPFile in background' radio button

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Field 4" "State"
  StrCmp ${L_TEMP} "1" run_in_background

  ; Run POPFile using console window

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Run Status" "LastAction"
  StrCmp ${L_TEMP} "console" exit_without_banner
  StrCmp ${L_TEMP} "no" lastaction_console
  StrCmp ${L_TEMP} "" lastaction_console
  StrCpy ${L_EXE} "$G_ROOTDIR\popfile${L_TRAY}b.exe"

lastaction_console:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Run Status" "LastAction" "console"
  StrCpy ${L_CONSOLE} "1"
  Goto display_banner

run_in_background:
  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Run Status" "LastAction"
  StrCmp ${L_TEMP} "background" exit_without_banner
  StrCmp ${L_TEMP} "no" lastaction_background
  StrCmp ${L_TEMP} "" lastaction_background
  StrCpy ${L_EXE} "$G_ROOTDIR\popfile${L_TRAY}f.exe"

lastaction_background:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioC.ini" "Run Status" "LastAction" "background"
  StrCpy ${L_CONSOLE} "0"

display_banner:
  ReadINIStr ${L_TEMP} "$G_USERDIR\backup\backup.ini" "NonSQLCorpus" "Status"
  StrCmp ${L_TEMP} "new" exit_without_banner

  Banner::show /NOUNLOAD /set 76 "$(PFI_LANG_LAUNCH_BANNER_1)" "$(PFI_LANG_LAUNCH_BANNER_2)"

  ; Before starting the newly installed POPFile, ensure that no other version of POPFile
  ; is running on the same UI port as the newly installed version.

  NSISdl::download_quiet http://127.0.0.1:$G_GUI/shutdown "$PLUGINSDIR\shutdown.htm"
  Pop ${L_TEMP}    ; Get the return value (and ignore it)
  Push ${L_EXE}
  Call WaitUntilUnlocked
  Push ${L_CONSOLE}
  Call SetConsoleMode
  SetOutPath $G_ROOTDIR
  ClearErrors
  Exec '"$G_ROOTDIR\popfile.exe"'
  IfErrors 0 continue
  Sleep ${C_MIN_BANNER_DISPLAY_TIME}
  Banner::destroy
  MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST "An error occurred when the installer tried to start POPFile.\
      $\r$\n$\r$\n\
      Please use 'Start -> Programs -> POPFile -> Run POPFile' now.\
      $\r$\n$\r$\n\
      Click 'OK' once POPFile has been started."
  Goto exit_without_banner

continue:

  ; Wait until POPFile is ready to display the UI (may take a second or so)

  StrCpy ${L_TIMEOUT} ${C_STARTUP_LIMIT}   ; Timeout limit to avoid an infinite loop

check_if_ready:
  NSISdl::download_quiet http://127.0.0.1:$G_GUI "$PLUGINSDIR\ui.htm"
  Pop ${L_TEMP}                        ; Did POPFile return an HTML page?
  StrCmp ${L_TEMP} "success" remove_banner
  Sleep ${C_STARTUP_DELAY}
  IntOp ${L_TIMEOUT} ${L_TIMEOUT} - 1
  IntCmp ${L_TIMEOUT} 0 remove_banner remove_banner check_if_ready

remove_banner:
  Sleep ${C_MIN_BANNER_DISPLAY_TIME}
  Banner::destroy

exit_without_banner:

  Pop ${L_TIMEOUT}
  Pop ${L_CONSOLE}
  Pop ${L_TRAY}
  Pop ${L_TEMP}
  Pop ${L_EXE}
  Pop ${L_CFG}

  !undef L_CFG
  !undef L_EXE
  !undef L_TEMP
  !undef L_TRAY
  !undef L_CONSOLE
  !undef L_TIMEOUT

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: ConvertCorpus
#--------------------------------------------------------------------------

Function ConvertCorpus

  !define L_FOLDER_COUNT  $R9
  !define L_FOLDER_PATH   $R8

  Push ${L_FOLDER_COUNT}
  Push ${L_FOLDER_PATH}

  HideWindow
  ExecWait '"$PLUGINSDIR\monitorcc.exe" "$PLUGINSDIR\corpus.ini"'
  BringToFront

  ; Now remove any empty corpus folders (POPFile has deleted the files as they are converted)

  ReadINIStr ${L_FOLDER_COUNT} "$PLUGINSDIR\corpus.ini" "FolderList" "MaxNum"

loop:
  ReadINIStr ${L_FOLDER_PATH} "$PLUGINSDIR\corpus.ini" "FolderList" "Path-${L_FOLDER_COUNT}"
  StrCmp  ${L_FOLDER_PATH} "" try_next_one

  ; Remove this corpus bucket folder if it is completely empty

  RMDir ${L_FOLDER_PATH}

try_next_one:
  IntOp ${L_FOLDER_COUNT} ${L_FOLDER_COUNT} - 1
  IntCmp ${L_FOLDER_COUNT} 0 exit exit loop

exit:

  ; Remove the corpus folder if it is completely empty

  ReadINIStr ${L_FOLDER_PATH} "$G_USERDIR\backup\backup.ini" "NonSQLCorpus" "CorpusPath"
  RMDir ${L_FOLDER_PATH}

  Pop ${L_FOLDER_PATH}
  Pop ${L_FOLDER_COUNT}

  !undef L_FOLDER_COUNT
  !undef L_FOLDER_PATH

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: CheckRunStatus
# (the "pre" function for the 'Finish' page)
#
# The 'Finish' page contains two CheckBoxes: one to control whether or not the installer
# starts the POPFile User Interface and one to control whether or not the 'ReadMe' file is
# displayed. The User Interface only works when POPFile is running, so we must ensure its
# CheckBox can only be ticked if the installer has started POPFile.
#
# NB: User can switch back and forth between the 'Start POPFile' page and the 'Finish' page
# (when corpus conversion is not required)
#--------------------------------------------------------------------------

Function CheckRunStatus

  !define L_TEMP        $R9

  Push ${L_TEMP}

  IfRebootFlag 0 no_reboot_reqd

  ; We have installed Kakasi on a Win9x system and must reboot before using POPFile

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Settings" "BackEnabled" "0"

  Goto corpus_conversion_check

no_reboot_reqd:

  ; Enable the 'Run' CheckBox on the 'Finish' page (it may have been disabled on our last visit)

  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 4" "Flags" ""

  ; Get the status of the 'Do not run POPFile' radio button on the 'Start POPFile' page
  ; If user has not started POPFile, we cannot offer to display the POPFile User Interface

  !insertmacro MUI_INSTALLOPTIONS_READ ${L_TEMP} "ioC.ini" "Field 2" "State"
  StrCmp ${L_TEMP} "1" disable_UI_option

corpus_conversion_check:

  ; If corpus conversion (from flat file or BerkeleyDB format) is required, we need to wait
  ; until it has been completed before displaying the 'Finish' page (corpus conversion may take
  ; several minutes, during which time the UI will appear to have 'locked up')

  ReadINIStr ${L_TEMP} "$G_USERDIR\backup\backup.ini" "NonSQLCorpus" "Status"
  StrCmp ${L_TEMP} "new" 0 selection_ok

  WriteINIStr "$G_USERDIR\backup\backup.ini" "NonSQLCorpus" "Status" "old"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Settings" "BackEnabled" "0"
  Call ConvertCorpus
  Goto selection_ok

disable_UI_option:
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 4" "State" "0"
  !insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 4" "Flags" "DISABLED"

selection_ok:

  ; If POPFile is running in a console window, it might be obscuring the installer

  BringToFront

  Pop ${L_TEMP}

  !undef L_TEMP

FunctionEnd

#--------------------------------------------------------------------------
# Installer Function: RunUI
# (the "Run" function for the 'Finish' page)
#--------------------------------------------------------------------------

Function RunUI

  ExecShell "open" "http://127.0.0.1:$G_GUI"

FunctionEnd

#--------------------------------------------------------------------------
# Initialise the uninstaller
#--------------------------------------------------------------------------

Function un.onInit

  ; Retrieve the language used when this version was installed, and use it for the uninstaller

  !insertmacro MUI_UNGETLANGUAGE

  ; Before POPFile 0.21.0, POPFile and the minimal Perl shared the same folder structure.
  ; Phase 1 of the multi-user support introduced in 0.21.0 requires some slight changes
  ; to the folder structure.

  ; For increased flexibility, four global user variables are used in addition to $INSTDIR
  ; (this makes it easier to change the folder structure used by the installer)

  StrCpy $G_USERDIR   $INSTDIR

  ReadRegStr $G_ROOTDIR HKLM "SOFTWARE\POPFile Project\${C_PFI_PRODUCT}\MRI" "InstallPath"
  StrCpy $G_MPBINDIR  $G_ROOTDIR

  ; Email settings are stored on a 'per user' basis therefore we need to know which user is
  ; running the uninstaller so we can check if the email settings can be safely restored

	ClearErrors
	UserInfo::GetName
	IfErrors 0 got_name

  ; Assume Win9x system, so user has 'Admin' rights
  ; (UserInfo works on Win98SE so perhaps it is only Win95 that fails ?)

  StrCpy $G_WINUSERNAME "UnknownUser"
  StrCpy $G_WINUSERTYPE "Admin"
  Goto exit

got_name:
	Pop $G_WINUSERNAME
  StrCmp $G_WINUSERNAME "" 0 get_usertype
  StrCpy $G_WINUSERNAME "UnknownUser"

get_usertype:
  UserInfo::GetAccountType
	Pop $G_WINUSERTYPE
  StrCmp $G_WINUSERTYPE "Admin" exit
  StrCmp $G_WINUSERTYPE "Power" exit
  StrCmp $G_WINUSERTYPE "User" exit
  StrCmp $G_WINUSERTYPE "Guest" exit
  StrCpy $G_WINUSERTYPE "Unknown"

exit:
FunctionEnd

#--------------------------------------------------------------------------
# Uninstaller Function: un.PFIGUIInit
# (custom un.onGUIInit function)
#
# Used to complete the initialisation of the uninstaller using language-specific strings.
#--------------------------------------------------------------------------

Function un.PFIGUIInit

  !define L_TEMP        $R9

  Push ${L_TEMP}

  ReadINIStr ${L_TEMP} "$G_USERDIR\install.ini" "Settings" "Owner"
  StrCmp ${L_TEMP} "" continue_uninstall
  StrCmp ${L_TEMP} $G_WINUSERNAME continue_uninstall
  MessageBox MB_YESNO|MB_ICONSTOP|MB_DEFBUTTON2 \
      "$(PFI_LANG_UN_MBDIFFUSER_1) ('${L_TEMP}') !\
      $\r$\n$\r$\n\
      $(PFI_LANG_UN_MBNOTFOUND_2)" IDYES continue_uninstall
  Abort "$(PFI_LANG_UN_ABORT_1)"

continue_uninstall:
  Pop ${L_TEMP}

  !undef L_TEMP

FunctionEnd

#--------------------------------------------------------------------------
# Uninstaller Section
#--------------------------------------------------------------------------

Section "Uninstall"

  !define L_CFG         $R9   ; used as file handle
  !define L_EXE         $R8   ; full path of the EXE to be monitored
  !define L_LNE         $R7   ; a line from popfile.cfg
  !define L_OLDUI       $R6   ; holds old-style UI port (if previous POPFile is an old version)
  !define L_TEMP        $R5
  !define L_UNDOFILE    $R4   ; file holding original email client settings
  !define L_UNDOSTATUS  $R3   ; email client restore flag ('success' or 'fail')

  IfFileExists $G_USERDIR\popfile.cfg skip_confirmation
    MessageBox MB_YESNO|MB_ICONSTOP|MB_DEFBUTTON2 \
        "$(PFI_LANG_UN_MBNOTFOUND_1) '$G_USERDIR'.\
        $\r$\n$\r$\n\
        $(PFI_LANG_UN_MBNOTFOUND_2)" IDYES skip_confirmation
    Abort "$(PFI_LANG_UN_ABORT_1)"

skip_confirmation:

  ; Shutdown POPFile is it is running, so we can remove the SQL database and other user data

  Push "$G_ROOTDIR\popfileb.exe"
  Call un.CheckIfLocked
  Pop ${L_EXE}
  StrCmp ${L_EXE} "" 0 attempt_shutdown

  Push "$G_ROOTDIR\popfileib.exe"
  Call un.CheckIfLocked
  Pop ${L_EXE}
  StrCmp ${L_EXE} "" 0 attempt_shutdown

  Push "$G_ROOTDIR\popfilef.exe"
  Call un.CheckIfLocked
  Pop ${L_EXE}
  StrCmp ${L_EXE} "" 0 attempt_shutdown

  Push "$G_ROOTDIR\popfileif.exe"
  Call un.CheckIfLocked
  Pop ${L_EXE}
  StrCmp ${L_EXE} "" 0 attempt_shutdown

  Push "$G_MPBINDIR\wperl.exe"
  Call un.CheckIfLocked
  Pop ${L_EXE}
  StrCmp ${L_EXE} "" 0 attempt_shutdown

  Push "$G_MPBINDIR\perl.exe"
  Call un.CheckIfLocked
  Pop ${L_EXE}
  StrCmp ${L_EXE} "" remove_user_data

attempt_shutdown:
  StrCpy $G_GUI ""
  StrCpy ${L_OLDUI} ""

  ClearErrors
  FileOpen ${L_CFG} "$G_USERDIR\popfile.cfg" r

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
  DetailPrint "$(PFI_LANG_UN_LOG_1) $G_GUI"
  NSISdl::download_quiet http://127.0.0.1:$G_GUI/shutdown "$PLUGINSDIR\shutdown.htm"
  Pop ${L_TEMP}
  Goto check_shutdown

use_other_port:
  Push ${L_OLDUI}
  Call un.TrimNewlines
  Call un.StrCheckDecimal
  Pop ${L_OLDUI}
  StrCmp ${L_OLDUI} "" remove_user_data
  DetailPrint "$(PFI_LANG_UN_LOG_1) ${L_OLDUI}"
  NSISdl::download_quiet http://127.0.0.1:${L_OLDUI}/shutdown "$PLUGINSDIR\shutdown.htm"
  Pop ${L_TEMP}

check_shutdown:
  Push ${L_EXE}
  Call un.WaitUntilUnlocked
  Push ${L_EXE}
  Call un.CheckIfLocked
  Pop ${L_EXE}
  StrCmp ${L_EXE} "" remove_user_data

  DetailPrint "Unable to shutdown automatically - manual intervention requested"
  MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST "$(PFI_LANG_MBMANSHUT_1)\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBMANSHUT_2)\
      $\r$\n$\r$\n\
      $(PFI_LANG_MBMANSHUT_3)"

remove_user_data:
  Delete $G_USERDIR\popfile.cfg
  Delete $G_USERDIR\popfile.cfg.bak
  Delete $G_USERDIR\*.log
  Delete $G_USERDIR\expchanges.txt
  Delete $G_USERDIR\expconfig.txt
  Delete $G_USERDIR\outchanges.txt
  Delete $G_USERDIR\outconfig.txt

  ;------------------------------------

  StrCpy ${L_UNDOSTATUS} "success"

  ;------------------------------------
  ; Restore 'Outlook Express' settings
  ;------------------------------------

  StrCpy ${L_UNDOFILE} "pfi-outexpress.ini"
  IfFileExists "$G_USERDIR\${L_UNDOFILE}" 0 end_oe_restore
  Push  ${L_UNDOFILE}
  Push "$(PFI_LANG_UN_PROGRESS_4)"
  Call un.RestoreOOE
  Pop ${L_TEMP}

  StrCmp ${L_TEMP} "success" delete_oe_data
  StrCpy ${L_UNDOSTATUS} "fail"
  DetailPrint "$(PFI_LANG_UN_LOG_7): ${L_UNDOFILE}"
  MessageBox MB_YESNO|MB_ICONEXCLAMATION \
      "$(PFI_LANG_UN_MBCLIENT_1)\
      $\r$\n$\r$\n\
      $(PFI_LANG_UN_MBEMAIL_1)\
      $\r$\n$\r$\n\
      $(PFI_LANG_UN_MBEMAIL_2)" IDNO end_oe_restore
  ExecShell "open" "$G_USERDIR\${L_UNDOFILE}.errors.txt"
  Goto end_oe_restore

delete_oe_data:
  Delete "$G_USERDIR\${L_UNDOFILE}"
  Delete "$G_USERDIR\popfile.reg.bk*"

end_oe_restore:

  ;------------------------------------
  ; Restore 'Outlook' settings
  ;------------------------------------

  StrCpy ${L_UNDOFILE} "pfi-outlook.ini"
  IfFileExists "$G_USERDIR\${L_UNDOFILE}" 0 end_outlook_restore
  Push  ${L_UNDOFILE}
  Push "$(PFI_LANG_UN_PROGRESS_7)"
  Call un.RestoreOOE
  Pop ${L_TEMP}

  StrCmp ${L_TEMP} "success" delete_outlook_data
  StrCpy ${L_UNDOSTATUS} "fail"
  DetailPrint "$(PFI_LANG_UN_LOG_7): ${L_UNDOFILE}"
  MessageBox MB_YESNO|MB_ICONEXCLAMATION \
      "$(PFI_LANG_UN_MBCLIENT_2)\
      $\r$\n$\r$\n\
      $(PFI_LANG_UN_MBEMAIL_1)\
      $\r$\n$\r$\n\
      $(PFI_LANG_UN_MBEMAIL_2)" IDNO end_outlook_restore
  ExecShell "open" "$G_USERDIR\${L_UNDOFILE}.errors.txt"
  Goto end_outlook_restore

delete_outlook_data:
  Delete "$G_USERDIR\${L_UNDOFILE}"
  Delete "$G_USERDIR\outlook.reg.bk*"

end_outlook_restore:

  ;------------------------------------
  ; Restore 'Eudora' settings
  ;------------------------------------

  StrCpy ${L_UNDOFILE} "pfi-eudora.ini"
  IfFileExists "$G_USERDIR\${L_UNDOFILE}" 0 end_eudora_restore
  Push  ${L_UNDOFILE}
  Push "$(PFI_LANG_UN_PROGRESS_8)"
  Call un.RestoreEudora
  Pop ${L_TEMP}

  StrCmp ${L_TEMP} "success" delete_eudora_data
  StrCpy ${L_UNDOSTATUS} "fail"
  DetailPrint "$(PFI_LANG_UN_LOG_7): ${L_UNDOFILE}"
  MessageBox MB_YESNO|MB_ICONEXCLAMATION \
      "$(PFI_LANG_UN_MBCLIENT_3)\
      $\r$\n$\r$\n\
      $(PFI_LANG_UN_MBEMAIL_1)\
      $\r$\n$\r$\n\
      $(PFI_LANG_UN_MBEMAIL_2)" IDNO end_eudora_restore
  ExecShell "open" "$G_USERDIR\${L_UNDOFILE}.errors.txt"
  Goto end_eudora_restore

delete_eudora_data:
  Delete "$G_USERDIR\${L_UNDOFILE}"

end_eudora_restore:

  ;------------------------------------

  SetDetailsPrint textonly
  DetailPrint "$(PFI_LANG_UN_PROGRESS_5)"
  SetDetailsPrint listonly

  ; Win95 generates an error message if 'RMDir /r' is used on a non-existent directory

  IfFileExists "$G_USERDIR\corpus\*.*" 0 skip_nonsql_corpus
  RMDir /r $G_USERDIR\corpus

skip_nonsql_corpus:
  Delete $G_USERDIR\popfile.db
  Delete "$G_USERDIR\Run SQLite utility.lnk"

  IfFileExists "$G_USERDIR\messages\*." 0 skip_messages
  RMDir /r $G_USERDIR\messages

skip_messages:
  Delete $G_USERDIR\stopwords
  Delete $G_USERDIR\stopwords.bak
  Delete $G_USERDIR\stopwords.default

  ;------------------------------------
  ; If email client problems found, offer to leave uninstaller behind with the relevant files
  ;------------------------------------

  StrCmp ${L_UNDOSTATUS} "success" complete_uninstall
  MessageBox MB_YESNO|MB_ICONSTOP \
    "$(PFI_LANG_UN_MBRERUN_1)\
    $\r$\n$\r$\n\
    $(PFI_LANG_UN_MBRERUN_2)\
    $\r$\n$\r$\n\
    $(PFI_LANG_UN_MBRERUN_3)\
    $\r$\n$\r$\n\
    $(PFI_LANG_UN_MBRERUN_4)" IDYES removed

complete_uninstall:
  Delete $G_USERDIR\install.ini
  Delete "$G_USERDIR\uninstalluser.exe"

  RMDir $G_USERDIR

  StrCmp $APPDATA "" 0 appdata_valid
  RMDir "${C_ALT_DEFAULT_USERDATA}"
  Goto remove_uninstall_entry

appdata_valid:
  RMDir "${C_STD_DEFAULT_USERDATA}"

remove_uninstall_entry:
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${C_PFI_PRODUCT}_Data"
  DeleteRegKey /ifempty HKCU "SOFTWARE\${C_PFI_PRODUCT}"

  ; if $G_USERDIR was removed, skip these next ones

  IfFileExists $G_USERDIR 0 removed
    MessageBox MB_YESNO|MB_ICONQUESTION "$(PFI_LANG_UN_MBREMDIR_2)" IDNO removed
    DetailPrint "$(PFI_LANG_UN_LOG_8)"
    Delete $G_USERDIR\*.* ; this would be skipped if the user hits no
    RMDir /r $G_USERDIR
    StrCmp $APPDATA "" 0 appdata_valid_x
    RMDir "${C_ALT_DEFAULT_USERDATA}"
    Goto check_removal

  appdata_valid_x:
    RMDir "${C_STD_DEFAULT_USERDATA}"

  check_removal:
    IfFileExists $G_USERDIR 0 removed
      DetailPrint "$(PFI_LANG_UN_LOG_9)"
      MessageBox MB_OK|MB_ICONEXCLAMATION \
          "$(PFI_LANG_UN_MBREMERR_1): $G_USERDIR $(PFI_LANG_UN_MBREMERR_2)"
removed:

  SetDetailsPrint both

  !undef L_CFG
  !undef L_EXE
  !undef L_LNE
  !undef L_OLDUI
  !undef L_TEMP
  !undef L_UNDOFILE

SectionEnd

#--------------------------------------------------------------------------
# Uninstaller Function: un.RestoreOOE
#
# Used to restore Outlook or Outlook Express settings using data saved during installation
#
# Inputs:
#         (top of stack)          - text string to be shown in uninstaller window/log
#         (top of stack - 1)      - the name of the file holding the 'undo' data
#
# Outputs:
#         (top of stack)          - string with one of the following result codes:
#
#                                      "nofile"   (meaning no restore data file found)
#
#                                      "success"  (meaning all settings restored)
#
#                                      "foreign"  (meaning some data belongs to another user
#                                                  and could not be restored)
#
#                                      "corrupt"  (meaning the 'undo' data was corrupted)
#
#  Usage:
#
#         Push "pfi-outlook.ini"
#         Push "Restoring Outlook settings..."
#         Call un.RestoreOOE
#         Pop $R9
#
#         (if $R9 is "foreign", some data was not restored as it doesn't belong to current user)
#--------------------------------------------------------------------------

Function un.RestoreOOE

  !define L_INDEX       $R9
  !define L_INIV        $R8
  !define L_MESSAGE     $R7
  !define L_POP_PORT    $R6
  !define L_POP_SERVER  $R5
  !define L_POP_USER    $R4
  !define L_REG_KEY     $R3
  !define L_TEMP        $R2
  !define L_UNDOFILE    $R1
  !define L_USERNAME    $R0
  !define L_USERTYPE    $9
  !define L_ERRORLOG    $8

  Exch ${L_MESSAGE}
  Exch
  Exch ${L_UNDOFILE}

  Push ${L_INDEX}
  Push ${L_INIV}
  Push ${L_POP_PORT}
  Push ${L_POP_SERVER}
  Push ${L_POP_USER}
  Push ${L_REG_KEY}
  Push ${L_TEMP}
  Push ${L_USERNAME}
  Push ${L_USERTYPE}
  Push ${L_ERRORLOG}

  IfFileExists "$G_USERDIR\${L_UNDOFILE}" 0 nothing_to_restore

  Call un.GetDateTimeStamp
  Pop ${L_TEMP}

  FileOpen  ${L_ERRORLOG} "$G_USERDIR\${L_UNDOFILE}.errors.txt" a
  FileSeek  ${L_ERRORLOG} 0 END
  FileWrite ${L_ERRORLOG} "Time  : ${L_TEMP}\
      $\r$\n\
      Action: ${L_MESSAGE}\
      $\r$\n\
      User  : $G_WINUSERNAME\
      $\r$\n"

  SetDetailsPrint textonly
  DetailPrint "${L_MESSAGE}"
  SetDetailsPrint listonly

  ; Read the registry settings found in the 'undo' file and restore them if there are any.
  ; All are assumed to be in HKCU

  DetailPrint "$(PFI_LANG_UN_LOG_2): ${L_UNDOFILE}"
  ClearErrors
  ReadINIStr ${L_INDEX} "$G_USERDIR\${L_UNDOFILE}" "History" "ListSize"
  IfErrors ooe_restore_corrupt
  Push ${L_INDEX}
  Call un.StrCheckDecimal
  Pop ${L_INDEX}
  StrCmp ${L_INDEX} "" ooe_restore_corrupt
  DetailPrint "${L_MESSAGE}"

  StrCpy ${L_MESSAGE} "success"

read_ooe_undo_entry:

  ; Check the 'undo' entry has all of the necessary values

  ReadINIStr ${L_TEMP} "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "Restored"
  StrCmp ${L_TEMP} "Yes" next_ooe_undo

  ReadINIStr ${L_INIV} "$G_USERDIR\${L_UNDOFILE}" "History" "IniV-${L_INDEX}"
  IntCmp 3 ${L_INIV} 0 0 skip_user_checks

  ReadINIStr ${L_USERNAME} "$G_USERDIR\${L_UNDOFILE}" "History" "User-${L_INDEX}"
  StrCmp ${L_USERNAME} "" skip_ooe_undo
  StrCmp ${L_USERNAME} $G_WINUSERNAME 0 foreign_ooe_undo

  ReadINIStr ${L_USERTYPE} "$G_USERDIR\${L_UNDOFILE}" "History" "Type-${L_INDEX}"
  StrCmp ${L_USERTYPE} "" skip_ooe_undo

skip_user_checks:
  ReadINIStr ${L_REG_KEY} "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "RegistryKey"
  StrCmp ${L_REG_KEY} "" skip_ooe_undo

  ReadINIStr ${L_POP_USER} "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "POP3UserName"
  StrCmp ${L_POP_USER} "" skip_ooe_undo

  ReadINIStr ${L_POP_SERVER} "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "POP3Server"
  StrCmp ${L_POP_SERVER} "" skip_ooe_undo

  IntCmp 3 ${L_INIV} 0 0 skip_port_check

  ReadINIStr ${L_POP_PORT} "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "POP3Port"
  StrCmp ${L_POP_PORT} "" skip_ooe_undo

skip_port_check:

  ; During installation we changed the 'POP3 Server' to '127.0.0.1'
  ; and if this value still exists, we assume it is safe to restore the original data
  ; (if the value differs, we do not restore the settings)

  ReadRegStr ${L_TEMP} HKCU ${L_REG_KEY} "POP3 Server"
  StrCmp ${L_TEMP} "127.0.0.1" 0 ooe_undo_not_valid

  WriteRegStr   HKCU ${L_REG_KEY} "POP3 User Name" ${L_POP_USER}
  WriteRegStr   HKCU ${L_REG_KEY} "POP3 Server" ${L_POP_SERVER}

  IntCmp 3 ${L_INIV} 0 0 skip_port_restore

  WriteRegDWORD HKCU ${L_REG_KEY} "POP3 Port" ${L_POP_PORT}

skip_port_restore:
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "Restored" "Yes"

  DetailPrint "$(PFI_LANG_UN_LOG_3) POP3 User Name: ${L_POP_USER}"
  DetailPrint "$(PFI_LANG_UN_LOG_3) POP3 Server: ${L_POP_SERVER}"
  DetailPrint "$(PFI_LANG_UN_LOG_3) POP3 Port: ${L_POP_PORT}"

  Goto next_ooe_undo

foreign_ooe_undo:
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "Restored" "No (different user)"
  FileWrite ${L_ERRORLOG} "Error : [Undo-${L_INDEX}] (different user)$\r$\n"
  StrCpy ${L_MESSAGE} "foreign"
  DetailPrint "$(^Skipped)Undo-${L_INDEX}"
  Goto next_ooe_undo

ooe_undo_not_valid:
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "Restored" "No (data no longer valid)"
  FileWrite ${L_ERRORLOG} "Error : [Undo-${L_INDEX}] (data no longer valid)$\r$\n"
  DetailPrint "$(^Skipped)Undo-${L_INDEX}"
  Goto next_ooe_undo

skip_ooe_undo:
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "Restored" "No (undo data incomplete)"
  FileWrite ${L_ERRORLOG} "Error : [Undo-${L_INDEX}] (undo data incomplete)$\r$\n"
  StrCpy ${L_MESSAGE} "corrupt"
  DetailPrint "$(^Skipped)Undo-${L_INDEX}"

next_ooe_undo:
  IntOp ${L_INDEX} ${L_INDEX} - 1
  IntCmp ${L_INDEX} 0 quit_restore quit_restore read_ooe_undo_entry

ooe_restore_corrupt:
  FileWrite ${L_ERRORLOG} "Error : [History] data corrupted$\r$\n"
  StrCpy ${L_MESSAGE} "corrupt"
  DetailPrint "$(^Skipped)${L_UNDOFILE}"
  Goto quit_restore

nothing_to_restore:
  StrCpy ${L_MESSAGE} "nofile"
  Goto exit_now

quit_restore:
  StrCpy ${L_TEMP} ${L_MESSAGE}
  StrCmp ${L_TEMP} "success" save_result
  StrCpy ${L_TEMP} "failure"

save_result:
  FileWrite ${L_ERRORLOG} "Result: ${L_TEMP}$\r$\n$\r$\n"
  FileClose ${L_ERRORLOG}
  DetailPrint "$(PFI_LANG_UN_LOG_4): ${L_UNDOFILE}"
  FlushINI "$G_USERDIR\${L_UNDOFILE}"

exit_now:
  Pop ${L_ERRORLOG}
  Pop ${L_USERTYPE}
  Pop ${L_USERNAME}
  Pop ${L_TEMP}
  Pop ${L_REG_KEY}
  Pop ${L_POP_USER}
  Pop ${L_POP_SERVER}
  Pop ${L_POP_PORT}
  Pop ${L_INIV}
  Pop ${L_INDEX}

  Pop ${L_UNDOFILE}
  Exch ${L_MESSAGE}

  !undef L_INDEX
  !undef L_INIV
  !undef L_MESSAGE
  !undef L_POP_PORT
  !undef L_POP_SERVER
  !undef L_POP_USER
  !undef L_REG_KEY
  !undef L_TEMP
  !undef L_UNDOFILE
  !undef L_USERNAME
  !undef L_USERTYPE
  !undef L_ERRORLOG

FunctionEnd

#--------------------------------------------------------------------------
# Uninstaller Function: un.RestoreEudora
#
# Used to restore Eudora settings using data saved during installation
#
# Inputs:
#         (top of stack)          - text string to be shown in uninstaller window/log
#         (top of stack - 1)      - the name of the file holding the 'undo' data
#
# Outputs:
#         (top of stack)          - string with one of the following result codes:
#
#                                      "nofile"   (meaning no restore data file found)
#
#                                      "success"  (meaning all settings restored)
#
#                                      "foreign"  (meaning some data belongs to another user
#                                                  and could not be restored)
#
#                                      "corrupt"  (meaning the 'undo' data was corrupted)
#
#  Usage:
#
#         Push "pfi-eudora.ini"
#         Push "Restoring Eudora settings..."
#         Call un.RestoreEudora
#         Pop $R9
#
#         (if $R9 is "foreign", some data was not restored as it doesn't belong to current user)
#--------------------------------------------------------------------------
# Notes:
#
# (1) Some early versions of the 'SetEudoraPage' function used a special entry in the
#     pfi-eudora.ini file when only the POPPort entry for the Dominant personality was
#     changed. Although this special entry is no longer used, un.RestoreEudora still supports
#     it (for backwards compatibility reasons). The special entry used this format:
#
#           [Undo-x]
#           Persona=*.*
#           POPAccount=*.*
#           POPServer=*.*
#           LoginName=*.*
#           POPPort=value to be restored
#
#     where 'Undo-x' is a normal 'Undo' sequence number
#--------------------------------------------------------------------------

Function un.RestoreEudora

  !define L_INDEX       $R9
  !define L_ININAME     $R8   ; full path to the Eudora INI file modified by the installer
  !define L_MESSAGE     $R7
  !define L_PERSONA     $R6   ; full section name for a Eudora personality
  !define L_POP_ACCOUNT $R5   ; L_POP_* used to restore Eudora settings
  !define L_POP_LOGIN   $R4
  !define L_POP_PORT    $R3
  !define L_POP_SERVER  $R2
  !define L_TEMP        $R1
  !define L_UNDOFILE    $R0
  !define L_USERNAME    $9    ; used to check validity of email client data 'undo' data
  !define L_USERTYPE    $8    ; used to check validity of email client data 'undo' data
  !define L_ERRORLOG    $7

  Exch ${L_MESSAGE}
  Exch
  Exch ${L_UNDOFILE}

  Push ${L_INDEX}
  Push ${L_ININAME}
  Push ${L_PERSONA}
  Push ${L_POP_ACCOUNT}
  Push ${L_POP_LOGIN}
  Push ${L_POP_PORT}
  Push ${L_POP_SERVER}
  Push ${L_TEMP}
  Push ${L_USERNAME}
  Push ${L_USERTYPE}
  Push ${L_ERRORLOG}

  IfFileExists "$G_USERDIR\${L_UNDOFILE}" 0 nothing_to_restore

  SetDetailsPrint textonly
  DetailPrint "${L_MESSAGE}"
  SetDetailsPrint listonly

  ; If Eudora is running, ask the user to shut it down now (user may ignore our request)

check_if_running:
  FindWindow ${L_TEMP} "EudoraMainWindow"
  IsWindow ${L_TEMP} 0 restore_eudora

  MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP|MB_DEFBUTTON2 "$(PFI_LANG_MBCLIENT_EUD)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_4)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_5)\
             $\r$\n$\r$\n\
             $(PFI_LANG_MBCLIENT_STOP_6)"\
             IDABORT nothing_to_restore IDRETRY check_if_running

restore_eudora:

  Call un.GetDateTimeStamp
  Pop ${L_TEMP}

  FileOpen  ${L_ERRORLOG} "$G_USERDIR\${L_UNDOFILE}.errors.txt" a
  FileSeek  ${L_ERRORLOG} 0 END
  FileWrite ${L_ERRORLOG} "Time  : ${L_TEMP}\
      $\r$\n\
      Action: ${L_MESSAGE}\
      $\r$\n\
      User  : $G_WINUSERNAME\
      $\r$\n"

  DetailPrint "$(PFI_LANG_UN_LOG_2): ${L_UNDOFILE}"
  ClearErrors
  ReadINIStr ${L_INDEX} "$G_USERDIR\${L_UNDOFILE}" "History" "ListSize"
  IfErrors eudora_restore_corrupt
  Push ${L_INDEX}
  Call un.StrCheckDecimal
  Pop ${L_INDEX}
  StrCmp ${L_INDEX} "" eudora_restore_corrupt
  DetailPrint "${L_MESSAGE}"

  StrCpy ${L_MESSAGE} "success"

read_eudora_undo_entry:

  ; Check the 'undo' entry has all of the necessary values

  ReadINIStr ${L_TEMP} "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "Restored"
  StrCmp ${L_TEMP} "Yes" next_eudora_undo

  ReadINIStr ${L_ININAME} "$G_USERDIR\${L_UNDOFILE}" "History" "Path-${L_INDEX}"
  StrCmp ${L_ININAME} "" skip_eudora_undo
  IfFileExists ${L_ININAME} 0 skip_eudora_undo

  ; Very early versions of the Eudora 'undo' file do not have 'User-x' and 'Type-x' data
  ; so we ignore these two entries when processing such a file

  ReadINIStr ${L_TEMP} "$G_USERDIR\${L_UNDOFILE}" "History" "IniV-${L_INDEX}"
  StrCmp ${L_TEMP} "" basic_eudora_undo

  ReadINIStr ${L_USERNAME} "$G_USERDIR\${L_UNDOFILE}" "History" "User-${L_INDEX}"
  StrCmp ${L_USERNAME} "" skip_eudora_undo
  StrCmp ${L_USERNAME} $G_WINUSERNAME 0 foreign_eudora_undo

  ReadINIStr ${L_USERTYPE} "$G_USERDIR\${L_UNDOFILE}" "History" "Type-${L_INDEX}"
  StrCmp ${L_USERTYPE} "" skip_eudora_undo

basic_eudora_undo:
  ReadINIStr ${L_PERSONA} "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "Persona"
  StrCmp ${L_PERSONA} "" skip_eudora_undo

  ReadINIStr ${L_POP_ACCOUNT} "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "POPAccount"
  StrCmp ${L_POP_ACCOUNT} "" skip_eudora_undo

  ReadINIStr ${L_POP_SERVER} "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "POPServer"
  StrCmp ${L_POP_SERVER} "" skip_eudora_undo

  ReadINIStr ${L_POP_LOGIN} "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "LoginName"
  StrCmp ${L_POP_LOGIN} "" skip_eudora_undo

  ReadINIStr ${L_POP_PORT} "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "POPPort"
  StrCmp ${L_POP_PORT} "" skip_eudora_undo

  ClearErrors
  ReadINIStr ${L_TEMP} "${L_ININAME}" "${L_PERSONA}" "POPAccount"
  IfErrors eudora_undo_not_valid

  StrCmp ${L_POP_ACCOUNT} "*.*" restore_port_only

  WriteINIStr "${L_ININAME}" "${L_PERSONA}" "POPAccount" "${L_POP_ACCOUNT}"
  WriteINIStr "${L_ININAME}" "${L_PERSONA}" "POPServer" "${L_POP_SERVER}"
  WriteINIStr "${L_ININAME}" "${L_PERSONA}" "LoginName" "${L_POP_LOGIN}"

restore_port_only:

  ; Some early versions of the undo data use "*.*" to change the Dominant personality's port

  StrCmp ${L_PERSONA} "*.*" 0 restore_port
  StrCpy ${L_PERSONA} "Settings"

restore_port:
  StrCmp ${L_POP_PORT} "Dominant" remove_port_setting
  StrCmp ${L_POP_PORT} "Default"  remove_port_setting
  WriteINIStr "${L_ININAME}" "${L_PERSONA}" "POPPort" "${L_POP_PORT}"
  Goto restored

remove_port_setting:
  DeleteINIStr "${L_ININAME}" "${L_PERSONA}" "POPPort"

restored:
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "Restored" "Yes"

  StrCmp ${L_POP_SERVER} "*.*" log_port_restore
  DetailPrint "$(PFI_LANG_UN_LOG_3) ${L_PERSONA} 'POPServer': ${L_POP_SERVER}"
  DetailPrint "$(PFI_LANG_UN_LOG_3) ${L_PERSONA} 'LoginName': ${L_POP_LOGIN}"

log_port_restore:
  DetailPrint "$(PFI_LANG_UN_LOG_3) ${L_PERSONA} 'POPPort': ${L_POP_PORT}"

  Goto next_eudora_undo

foreign_eudora_undo:
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "Restored" "No (different user)"
  FileWrite ${L_ERRORLOG} "Error : [Undo-${L_INDEX}] (different user)$\r$\n"
  StrCpy ${L_MESSAGE} "foreign"
  DetailPrint "$(^Skipped)Undo-${L_INDEX}"
  Goto next_eudora_undo

eudora_undo_not_valid:
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "Restored" "No (data no longer valid)"
  FileWrite ${L_ERRORLOG} "Error : [Undo-${L_INDEX}] (data no longer valid)$\r$\n"
  DetailPrint "$(^Skipped)Undo-${L_INDEX}"
  Goto next_eudora_undo

skip_eudora_undo:
  WriteINIStr "$G_USERDIR\${L_UNDOFILE}" "Undo-${L_INDEX}" "Restored" "No (undo data incomplete)"
  FileWrite ${L_ERRORLOG} "Error : [Undo-${L_INDEX}] (undo data incomplete)$\r$\n"
  StrCpy ${L_MESSAGE} "corrupt"
  DetailPrint "$(^Skipped)Undo-${L_INDEX}"

next_eudora_undo:
  IntOp ${L_INDEX} ${L_INDEX} - 1
  IntCmp ${L_INDEX} 0 quit_restore quit_restore read_eudora_undo_entry

eudora_restore_corrupt:
  FileWrite ${L_ERRORLOG} "Error : [History] data corrupted$\r$\n"
  StrCpy ${L_MESSAGE} "corrupt"
  DetailPrint "$(^Skipped)${L_UNDOFILE}"
  Goto quit_restore

nothing_to_restore:
  StrCpy ${L_MESSAGE} "nofile"
  Goto exit_now

quit_restore:
  StrCpy ${L_TEMP} ${L_MESSAGE}
  StrCmp ${L_TEMP} "success" save_result
  StrCpy ${L_TEMP} "failure"

save_result:
  FileWrite ${L_ERRORLOG} "Result: ${L_TEMP}$\r$\n$\r$\n"
  FileClose ${L_ERRORLOG}
  DetailPrint "$(PFI_LANG_UN_LOG_4): ${L_UNDOFILE}"
  FlushINI "$G_USERDIR\${L_UNDOFILE}"

exit_now:
  Pop ${L_ERRORLOG}
  Pop ${L_USERTYPE}
  Pop ${L_USERNAME}
  Pop ${L_TEMP}
  Pop ${L_POP_SERVER}
  Pop ${L_POP_PORT}
  Pop ${L_POP_LOGIN}
  Pop ${L_POP_ACCOUNT}
  Pop ${L_PERSONA}
  Pop ${L_ININAME}
  Pop ${L_INDEX}

  Pop ${L_UNDOFILE}
  Exch ${L_MESSAGE}

  !undef L_INDEX
  !undef L_ININAME
  !undef L_PERSONA
  !undef L_POP_ACCOUNT
  !undef L_POP_LOGIN
  !undef L_POP_PORT
  !undef L_POP_SERVER
  !undef L_TEMP
  !undef L_UNDOFILE
  !undef L_USERNAME
  !undef L_USERTYPE
  !undef L_ERRORLOG

FunctionEnd

#--------------------------------------------------------------------------
# End of 'adduser.nsi'
#--------------------------------------------------------------------------