unit u_param;
{$define PRO}
interface

type
  TFilePath=  string[128];
  TParamSnd=  record
    Menu_Title:  TFilePath;
    Menu_Border:  TFilePath;
    Menu_Background:  TFilePath;
    Menu_Restart:  TFilePath;
    Menu_BrowseMode:  TFilePath;
    Menu_Exit:  TFilePath;
    Intro:  TFilePath;
    KeyPress:  TFilePath;
    Pause:  TFilePath;
    Crash_1:  TFilePath;
    Crash_2:  TFilePath;
    Crash_3:  TFilePath;
    Congratulation:  TFilePath;
    East:  TFilePath;
    North:  TFilePath;
    West:  TFilePath;
    South:  TFilePath;
    Vol_SaySide:  byte;
    Half_Corner:  TFilePath;
    Border:  TFilePath;
    {$ifdef PRO}
    Menu_NormGame:  TFilePath;
    Menu_ClientGame:  TFilePath;
    Menu_ServerGame:  TFilePath;
    Menu_Disconnect:  TFilePath;
    ClientConnect:  TFilePath;
    ClientDisconnect:  TFilePath;
    NoServer:  TFilePath;
    ServerDisconnect:  TFilePath;
    NewClient:  TFilePath;
    Netcar_Engine:  TFilePath;
    Netcar_Braking:  TFilePath;
    Netcar_Horn:  TFilePath;
    NetRadar:  TFilePath;
    NetRadarBack:  TFilePath;
    NetFinish:  TFilePath;
    {$endif}
  end; // TParamSnd= record
  TParam=  record
    NetMenu:  byte;
    StreamSpeed:  byte;
    Serv_Port:  integer;
    Clt_Addr:  string;
    Clt_Port:  integer;

    // Стартовая точка автомобиля
    St_X,St_Y,St_Z:  single;
    // Центр мира
    C_X,C_Y,C_Z:  single;
    // Стартовый угол поворота
    Alpha:  integer;

    Snd:  TParamSnd;
  end; // TParam= record

var
  Param:  TParam;

procedure Read_Param(FN_INI:  string);
function  Check_FN(FN:  string):  string;

implementation
uses IniFiles, SysUtils,
     err;

procedure Read_Param(FN_INI:  string);
const
  SND=  'SOUNDS';

var
  Ini:  TIniFile;

begin
Ini:= TIniFile.Create(FN_INI);

with Param do
  begin
  NetMenu:= Ini.ReadInteger('NET','NetMenu',0);
  StreamSpeed:= Ini.ReadInteger('NET','StreamSpeed',1);
  Serv_Port:= Ini.ReadInteger('NET','Server_Port',0);
  Clt_Addr:= Ini.ReadString('NET','Client_Addr','');
  Clt_Port:= Ini.ReadInteger('NET','Client_Port',0);

  St_X:= 0; St_Y:= 0; St_Z:= 0;
  Alpha:= 90;
  C_X:= 0; C_Y:= 0; C_Z:= 0;
  end; // with Param

with Param.Snd do
  begin
  Menu_Background:= Check_FN(Ini.ReadString(SND,'Menu_Background','sounds\menu.wav'));
  Menu_Restart:= Check_FN(Ini.ReadString(SND,'Menu_Restart','sounds\menu_restart.mp3'));
  Menu_Exit:= Check_FN(Ini.ReadString(SND,'Menu_Exit','sounds\menu_exit.mp3'));
  Menu_BrowseMode:= Check_FN(Ini.ReadString(SND,'Menu_BrowseMode','sounds\menu_browsemode.mp3'));
  Menu_Title:= Check_FN(Ini.ReadString(SND,'Menu_Title','sounds\menu.mp3'));
  Menu_Border:= Check_FN(Ini.ReadString(SND,'Menu_Border','sounds\menu_border.mp3'));
  Intro:= Check_FN(Ini.ReadString(SND,'Intro','sounds\intro.mp3'));
  KeyPress:= Check_FN(Ini.ReadString(SND,'KeyPress','sounds\press.wav'));
  Pause:= Check_FN(Ini.ReadString(SND,'Pause','sounds\pause.wav'));
  Crash_1:= Check_FN(Ini.ReadString(SND,'Crash_1','sounds\crash_0.wav'));
  Crash_2:= Check_FN(Ini.ReadString(SND,'Crash_2','sounds\crash_1.mp3'));
  Crash_3:= Check_FN(Ini.ReadString(SND,'Crash_3','sounds\crash_2.mp3'));
  Congratulation:= Check_FN(Ini.ReadString(SND,'Congratulation','sounds\trumpet.mp3'));
  East:= Check_FN(Ini.ReadString(SND,'East','sounds\east.mp3'));
  North:= Check_FN(Ini.ReadString(SND,'North','sounds\north.mp3'));
  West:= Check_FN(Ini.ReadString(SND,'West','sounds\west.mp3'));
  South:= Check_FN(Ini.ReadString(SND,'South','sounds\south.mp3'));
  Vol_SaySide:= Ini.ReadInteger(SND,'SaySide_Volume',255);
  Half_Corner:= Check_FN(Ini.ReadString(SND,'HalfCorner','sounds\half_corner.mp3'));
  Border:= Check_FN(Ini.ReadString(SND,'Border','sounds\edge.wav'));
  {$ifdef PRO}
  Menu_NormGame:= Check_FN(Ini.ReadString(SND,'Menu_NormalGame','sounds\menu_normal.mp3'));
  Menu_ClientGame:= Check_FN(Ini.ReadString(SND,'Menu_ClientGame','sounds\menu_client.mp3'));
  Menu_ServerGame:= Check_FN(Ini.ReadString(SND,'Menu_ServerGame','sounds\menu_server.mp3'));
  Menu_Disconnect:= Check_FN(Ini.ReadString(SND,'Menu_Disconnect','sounds\menu_disconnect.mp3'));
  ClientConnect:= Check_FN(Ini.ReadString(SND,'ClientConnect','sounds\new_client.wav'));
  ClientDisconnect:= Check_FN(Ini.ReadString(SND,'ClientDisconnect','sounds\clt_disc.mp3'));
  NoServer:= Check_FN(Ini.ReadString(SND,'NoServer','sounds\no_serv.mp3'));
  ServerDisconnect:= Check_FN(Ini.ReadString(SND,'ServerDisconnect','sounds\serv_disc.mp3'));
  NewClient:= Check_FN(Ini.ReadString(SND,'NewClient','sounds\new_client.wav'));
  Netcar_Engine:= Check_FN(Ini.ReadString(SND,'Netcar_Engine','sounds\netcar\engine.wav'));
  Netcar_Braking:= Check_FN(Ini.ReadString(SND,'Netcar_Braking','sounds\netcar\braking.wav'));
  Netcar_Horn:= Check_FN(Ini.ReadString(SND,'Netcar_Horn','sounds\netcar\horn.wav'));
  NetRadar:= Check_FN(Ini.ReadString(SND,'NetRadar','sounds\netcar\radar.wav'));
  NetRadarBack:= Check_FN(Ini.ReadString(SND,'NetRadarBack','sounds\netcar\radar_back.wav'));
  NetFinish:= Check_FN(Ini.ReadString(SND,'NetFinish','sounds\netcar\finish.wav'));
  {$endif}
  end;
Ini.Free;
end; // proc Read_Param;

function  Check_FN(FN:  string):  string;
begin
if not FileExists(FN) then
  begin
  RR_Error(FILE_NOT_FOUND,FN);
  Result:= '';
  exit;
  end;
Result:= FN;

end; // func Check_FN

end. // End Of Unit

