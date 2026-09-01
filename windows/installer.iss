#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef ReleaseTag
  #define ReleaseTag "v0.0.0"
#endif

#define AppName "轻书架Plus"
#define AppExeName "lightnovel_shelf_plus.exe"
#define AppId "{{AC65E487-D22D-4A4A-BE91-EFEE2D772716}"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=LightNovelShelf Plus
AppPublisherURL=https://github.com/Roroca-1/LightNovelShelf-Plus
AppSupportURL=https://github.com/Roroca-1/LightNovelShelf-Plus/issues
DefaultDirName={localappdata}\Programs\LightNovelShelfPlus
DefaultGroupName={#AppName}
AllowNoIcons=yes
DisableProgramGroupPage=auto
OutputDir=..\dist
OutputBaseFilename=LightNovelShelfPlus-{#ReleaseTag}-x86_64
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加快捷方式："; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"
Name: "{group}\卸载 {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "启动 {#AppName}"; Flags: nowait postinstall skipifsilent
