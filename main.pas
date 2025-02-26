unit main;
{$define PRO}
{$define xDEBUG}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, shellapi, fmod, fmodtypes, fmoderrors, fmodpresets, ComCtrls, StdCtrls, math, ScktComp,
  my_fmod, u_param, ExtCtrls;

const
  // ������
  BUILD= '68';
  {$ifdef PRO}
  Version= '1.0.0.'+BUILD;
  NetUpd= 30;
  NetRadarUpd= 1000;
  {$else}
  Version= '0.4.3.'+BUILD;
  {$endif}
  // ������
  MD_PAUSE= 0;
  MD_INTRO= 1; // ����������
  MD_MENU= 2; // ����
  MD_GAME= 3; // ����
  MD_CONGRATULATION= 4;
  MD_LISTEN= 5; // ������� ����
  MD_BROWSER=  6; // ����� ������
  // ����� ��������� �����
  CARS_DIR= '\cars';
  WORLDS_DIR= '\worlds';
  CAR_TITLE_SECTION= 'CAR'; // ������ ini �����, ���������� �������� title
  CAR_TITLE_INDENT= 'title'; // �������� ����� - ���������
  INI_MASK= '\*.ini';

type
  TBrowseModeInfo=  record
    Posit:  TFSoundVector;
    Veloc:  TFSoundVector;
    Alpha:  integer;
    LastMode:  byte;
  end;
  TMainForm = class(TForm)
    RRServer: TServerSocket;
    RRClient: TClientSocket;
    MainTimer: TTimer;
    NetRadarTimer: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure RRClientConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure RRClientError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure RRClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure RRServerClientConnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure RRServerClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure RRServerClientRead(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure MainTimerTimer(Sender: TObject);
    procedure NetRadarTimerTimer(Sender: TObject);
    procedure RRClientDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
  end;

var
  MainForm: TMainForm;
  Stream: PFSoundStream;
  Mode: byte = 0;
  Level: byte = 1;
  Hronometr: longint;
  Exec_Path: string[128];
  Car_Dimensions: integer;
  SndIntro: TFMListenerSound;
  CarName:  ^string = NIL;
  WorldName:  ^string = NIL;
  Reboot: boolean = false;
  Points:  longint = 0; // ����
  Tmr_Counter:  int64 = 0;

procedure Tick;
procedure Crash(X,Y,Z: single;Dyn_Obj: boolean;UID:  integer);
procedure Congratulation;
procedure GotoNull(Snd_FN: string;Snd_Volume: integer);
procedure Extr_Braking(Stat:  boolean);
procedure BrowseModeOn;
procedure BrowseModeOff;

implementation
uses inifiles,
     u_car, err, world, U_Territory, Compas, menu
     {$ifdef PRO},
     rr_net
     {$endif};

{$R *.dfm}

var
  Car: TCar; // ������ - �������� ����������
  GoLeft, GoRight: boolean;
  Tmp_Freq:  longint;
  Cars_Path:  ^string = NIL; // ���� � ini ������ �����������
  Worlds_Path:  ^string = NIL;
  CurMenu:  integer = 1; // ����� ���� ����� ��������
  BrowseModeInfo:  TBrowseModeInfo;
  Browser:  TFSoundVector;
{$ifdef PRO}
  OldSpeed:  single;  // ���������� ��������

procedure LoadNetMenu;
var
  NewItem: PVocMenuItem;

begin
if ItemList= NIL then
  exit
else
  ItemList.Clear;

Mode:= MD_MENU;
CurMenu:= 0;

if MnuSound= NIL then
  MnuSound:= TFM3DSound.Create;
if SndIntro<> NIL then
  with SndIntro do
    begin
    if FileName<> Param.Snd.Menu_Background then
      begin
      KillSamp;
      FileName:= Param.Snd.Menu_Background;
      Loop:= true;
      FVolume:= 200;
      StartSound;
      end
    else
      if not Playing then
        Play;
    end; // if SndIntro<> NIL + with SndIntro
if Car<> NIL then
  with Car.Engine.Posit do
    MnuSound.Set_Posit(X,Y,Z);

new(NewItem);
with NewItem^ do
  begin
  Title:= '������� ����';
  Value:= '';
  Snd:= Param.Snd.Menu_NormGame;
  end; // with NewCar
ItemList.Add(NewItem);

new(NewItem);
with NewItem^ do
  begin
  Title:= '������������ � ������� ���� (����� �������)';
  Value:= '';
  Snd:= Param.Snd.Menu_ClientGame;
  end; // with NewCar
ItemList.Add(NewItem);

new(NewItem);
with NewItem^ do
  begin
  Title:= '������ ����� ������� ���� (����� �������)';
  Value:= '';
  Snd:= Param.Snd.Menu_ServerGame;
  end; // with NewCar
ItemList.Add(NewItem);

CurItem:= 0;
VocMenuSelection(0);
end; // proc LoadNetMenu
{$endif}

procedure LoadMainMenu;
var
  NewItem: PVocMenuItem;

begin
if ItemList= NIL then
  exit
else
  ItemList.Clear;

CurMenu:= 3;

if MnuSound= NIL then
  MnuSound:= TFM3DSound.Create;
if SndIntro<> NIL then
  with SndIntro do
    begin
    if Playing then
      KillSamp;
    FileName:= Param.Snd.Menu_Background;
    Loop:= true;
    FVolume:= 200;
    StartSound;
    end; // if SndIntro<> NIL + with SndIntro
if Car<> NIL then
  with Car.Engine.Posit do
    MnuSound.Set_Posit(X,Y,Z);

new(NewItem);
with NewItem^ do
  begin
  Title:= '������ ���� ������';
  Value:= '';
  Snd:= Param.Snd.Menu_Restart;
  end; // with NewCar
ItemList.Add(NewItem);

{$ifdef DEBUG}
new(NewItem);
with NewItem^ do
  begin
  Title:= '����� ������';
  Value:= '';
  Snd:= Param.Snd.Menu_BrowseMode;
  end; // with NewCar
ItemList.Add(NewItem);
{$endif}

{$ifdef PRO}
if MainForm.RRClient.Active then
  begin
  new(NewItem);
  with NewItem^ do
    begin
    Title:= '�������� ������� ����';
    Value:= '';
    Snd:= Param.Snd.Menu_Disconnect;
    end; // with NewCar
  ItemList.Add(NewItem);
  end; // if MainForm.RRClient.Active
{$endif}

CurItem:= 0;
VocMenuSelection(0);

if Mode= MD_CONGRATULATION then
  begin
  Car.Free; Car:= NIL;
  end;
Mode:= MD_MENU;
end; // proc LoadMainMenu

procedure CarMenuLoad;
const
  TLE_SECTION= 'CAR';
  TLE_INDENT= 'Title';
  SND_SECTION= 'CAR';
  SND_INDENT= 'Title_Sound';

var
  F: TSearchRec;
  IOR: integer;
  NewCar: PVocMenuItem;
  Ini: TIniFile;
  Car_Title: string;
  Car_Snd:  string;

begin
if Cars_Path= NIL then exit;

if ItemList= NIL then
  exit
else
  ItemList.Clear;

Mode:= MD_MENU;
CurMenu:= 1;

if MnuSound= NIL then
  MnuSound:= TFM3DSound.Create;
if SndIntro<> NIL then
  with SndIntro do
    begin
    if FileName<> Param.Snd.Menu_Background then
      begin
      KillSamp;
      FileName:= Param.Snd.Menu_Background;
      Loop:= true;
      FVolume:= 200;
      StartSound;
      end
    else
      if not Playing then
        Play;
    end; // if SndIntro<> NIL + with SndIntro
MnuSound.FileName:= Param.Snd.Menu_Title;
IOR:= FindFirst(Cars_Path^+INI_MASK,0,F);
while IOR= 0 do
  begin
  Ini:= TIniFile.Create(Cars_Path^+'\'+F.Name);
  Car_Title:= Ini.ReadString(TLE_SECTION,TLE_INDENT,F.Name);
  Car_Snd:= Ini.ReadString(SND_SECTION,SND_INDENT,'');
  Ini.Free;
  new(NewCar);
  with NewCar^ do
    begin
    Title:= Car_Title;
    Value:= Cars_Path^+'\'+F.Name;
    Snd:= Car_Snd;
    end; // with NewCar
  ItemList.Add(NewCar);
  IOR:= FindNext(F);
  end; // while IOR= 0

CurItem:= 0;
VocMenuSelection(0);
FreeMemory(Cars_Path);
end; // proc CarMenuLoad

procedure WorldMenuLoad;
const
  TLE_SECTION= 'WORLD';
  TLE_INDENT= 'Title';
  SND_SECTION= 'WORLD';
  SND_INDENT= 'Title_Sound';

var
  F: TSearchRec;
  IOR: integer;
  NewWorld: PVocMenuItem;
  Ini: TIniFile;
  World_Title: string;
  World_Snd:  string;

begin
if ItemList= NIL then
  exit
else
  ItemList.Clear;

Mode:= MD_MENU;
CurMenu:= 2;

if MnuSound= NIL then
  MnuSound:= TFM3DSound.Create;
if (SndIntro<> NIL) and (not SndIntro.Playing) then
  with SndIntro do
    begin
    FileName:= Param.Snd.Menu_Background;
    Loop:= true;
    FVolume:= 200;
    StartSound;
    end; // if SndIntro<> NIL + with SndIntro
MnuSound.FileName:= Param.Snd.Menu_Title;
IOR:= FindFirst(Worlds_Path^+INI_MASK,0,F);
while IOR= 0 do
  begin
  Ini:= TIniFile.Create(Worlds_Path^+'\'+F.Name);
  World_Title:= Ini.ReadString(TLE_SECTION,TLE_INDENT,F.Name);
  World_Snd:= Ini.ReadString(SND_SECTION,SND_INDENT,'');
  Ini.Free;
  new(NewWorld);
  with NewWorld^ do
    begin
    Title:= World_Title;
    Value:= Worlds_Path^+'\'+F.Name;
    Snd:= World_Snd;
    end; // with NewCar
  ItemList.Add(NewWorld);
  IOR:= FindNext(F);
  end; // while IOR= 0

CurItem:= 0;
VocMenuSelection(0);
FreeMemory(Worlds_Path);
end; // proc WorldMenuLoad

procedure Intro;
begin
Mode:= MD_INTRO;
with SndIntro do
  begin
  FileName:= Param.Snd.Intro;
  LoadSamp;
  Loop:= false;
  Play;
  end; // with Intro
end; // proc Intro;

procedure StartGame;
begin
if (CarName=NIL) or (WorldName=NIL) then
  exit;

Mode:= MD_PAUSE;

Car:= TCar.Create(CarName^);
freememory(CarName);
CarName:= NIL;

with SndIntro do
  begin
  KillSamp;
  FileName:= Car.FIgn_Snd_FN;
  Volume:= Car.FIgn_Snd_Vol;
  StartSound;
  end; // with SndIntro

ItemList.Clear;
MnuSound.KillSamp;

Car_Dimensions:= Car.FDimens;

WorldCreate;
TerritoriesCreate;

LoadWorld(WorldName^);
LoadTerritories(WorldName^);
FreeMemory(WorldName);
WorldName:= NIL;

Car.Goto_Start;

{$ifdef PRO}
// � ����������� �� ������, ���������� �������������
case Param.NetMenu of
 0:  // ������� ����
  begin
  Mode:= MD_GAME;
  MainForm.MainTimer.Enabled:= true;
  Hronometr:= Tmr_Counter;
  end; // Case ������� ����
 1: // ���� ������
  begin
  MainForm.Caption:= MainForm.Caption +' Client Mode';
  NetWorld:= TList.Create;
  with MainForm.RRClient do
    begin
    // �� ������ ������ ������� �������� ����������
    if Active then
      Active:= false;
    // ��������� ����� � ����
    Address:= Param.Clt_Addr;
    Port:= Param.Clt_Port;
    // ������������
    Active:= true;
    end;
  // ����
  Mode:= MD_LISTEN;
  end; // case - ������
 2: // ���� ������
  begin
  MainForm.Caption:= MainForm.Caption +' Server Mode';
  NetWorld:= TList.Create;
  with MainForm.RRServer do
    begin
    // �� ������ ������ ������� �������� ����������
    if Active then
      Active:= false;

    Port:= Param.Serv_Port;
    // ������������ - �������� �������
    Active:= true;
    end; // with MainForm.RRServer
  Mode:= MD_LISTEN;
  end; // case - ������
else // case Param.NetMenu
  Application.Terminate;
end; // case Param.NetMenu

{$else}
Mode:= MD_GAME;

MainForm.MainTimer.Enabled:= true;
Hronometr:= Tmr_Counter;
{$endif}

SndIntro.KillSamp;
Car.Engine.StartSound;
end; // proc StartGame;

procedure Tick;
begin
end; // proc Tick

procedure TMainForm.FormCreate(Sender: TObject);
begin
Caption:= 'Ru Racing - '+Version;

GoLeft:= false; GoRight:= false;

Read_Param(ExtractFileDir(Application.ExeName)+'\rr.ini');

with Browser do
  begin
  X:= Param.C_x; Y:= 50; Z:= Param.C_z;
  end;

ItemList:= TList.Create;
new(Cars_Path);
Cars_Path^:= ExtractFileDir(Application.ExeName)+CARS_DIR;
new(Worlds_Path);
Worlds_Path^:= ExtractFileDir(Application.ExeName)+WORLDS_DIR;
Compas_Init;

FSOUND_SetOutput(FSOUND_OUTPUT_DSOUND); // ����� ����� DirectX
FSOUND_SetDriver(0); // ������� �� ���������

if not FSOUND_Init(44100, 32, 0) then
  FatalError('������ ������������� �����: '+FMOD_ErrorString(FSOUND_GetError()));

// FSOUND_Reverb_SetProperties(FSOUND_PRESET_CITY);
FSOUND_3D_SetDopplerFactor(0.3);

SndIntro:= TFMListenerSound.Create;
Mode:= MD_INTRO;
Intro;
end; // proc TMainForm.FormCreate

procedure TMainForm.FormDestroy(Sender: TObject);
begin
MainForm.MainTimer.Enabled:= false;

{$ifdef PRO}
with RRClient do
  begin
  if Active then
    Active:= false;
  Close;
  end; // with RRClient
with RRServer do
  begin
  if Active then
    Active:= false;
  Close;
  end; // with RRServer

KillNetCar(-1);
{$endif}

SndIntro.Free; SndIntro:= NIL;
MnuSound.Free; MnuSound:= NIL;
Voc.Free; Voc:= NIL;
Car.Free; Car:= NIL;
ItemList.Free; ItemList:= NIL;

KillWorld;
KillTerritories;

FSOUND_Close();

if Reboot then
  ShellExecute(MainForm.Handle, nil, PChar(Application.ExeName), nil, nil, SW_RESTORE);;
end; // proc TMainForm.FormDestroy

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

var
  I:  integer;

begin
{$ifdef DEBUG}
if Mode= MD_BROWSER then
  begin
  case Key of
  VK_Escape:
    BrowseModeOff;
    end; // case Key
  exit;
  end;
{$endif}
{$ifdef PRO}
if Mode= MD_INTRO then
  begin
  if Param.NetMenu= 0 then
    LoadNetMenu
  else
    CarMenuLoad;
  exit;
  end;

if Mode= MD_LISTEN then
  begin
  if (Key<> VK_RETURN) or (not RRServer.Active) then
    exit;
  Buf.Status:= NS_START;
  with RRServer do
    for i:=0 to Socket.ActiveConnections-1 do
      Socket.Connections[i].SendBuf(Buf,sizeof(TNetMsg));
  MainForm.MainTimer.Enabled:= true;
  Hronometr:= Tmr_Counter;
  Mode:= MD_GAME;
  exit;
  end; // if Mode= MD_LISTEN
{$else}
if Mode= MD_INTRO then
  begin
  CarMenuLoad;
  exit;
  end;
{$endif}

if Mode= MD_MENU then
  begin
  case Key of
VK_ESCAPE:  if (CurMenu=3) and (Car <> NIL) then
    begin
    SndIntro.KillSamp;
    ItemList.Clear;
    Car.Engine.StartSound;
    Car.Engine.Freq:= Tmp_Freq;
    Mode:= MD_GAME;
    exit;
    end;
VK_UP:
    VocMenuSelection(CurItem-1);
VK_DOWN:
    VocMenuSelection(CurItem+1);
VK_HOME:
    VocMenuSelection(0);
VK_END:
    VocMenuSelection(ItemList.Count);
VK_RETURN:
    if CurItem< ItemList.Count then
      begin
      case CurMenu of
       {$ifdef PRO}
       0:  // ������� ����
        begin
        Param.NetMenu:= CurItem;
        CurMenu:= 1;
        CarMenuLoad;
        exit;
        end;
       {$endif}
       1: // ������������� ����
        begin
        new(CarName);
        CarName^:= PVocMenuItem(ItemList.Items[CurItem])^.Value;
        WorldMenuLoad;
        end;
       2:// ���� �����
        begin
        new(WorldName);
        WorldName^:= PVocMenuItem(ItemList.Items[CurItem])^.Value;
        CurMenu:= 3;
        StartGame;
        end;
       3: // ������� ����
        begin
        SndIntro.KillSamp;
        if CurItem= 0 then
          begin
          Reboot:= true;
          Application.Terminate;
          end;
        if CurItem= 1 then
          begin
          BrowseModeOn;
          exit;
          end;
        {$ifdef PRO}
        if (RRClient.Active) and (CurItem= 1) then
          begin
          RRClient.Active:= false;
          SndIntro.KillSamp;
          ItemList.Clear;
          Car.Engine.StartSound;
          Mode:= MD_GAME;
          end;
        {$endif}
        end;
      end;
      end
    else
      Application.Terminate;

  else // case Key
    begin
    VocMenuSelection(-1);
    exit;
    end;
    end; // case key of
  end; // if Mode= MD_MENU
if Mode= MD_CONGRATULATION then exit;

if Car= NIL then exit;

if Mode= MD_PAUSE then
  begin
  if Key= ord('P') then
    begin
    SndIntro.KillSamp;
    Car.Engine.StartSound;
    Car.Engine.Freq:= Tmp_Freq;
    Mode:= MD_GAME;
    end;
  if Key= VK_ESCAPE then
    begin
    CurItem:= 3;
    LoadMainMenu;
    end;
  exit;
  end; // if Mode= MD_PAUSE

case Key of
192:
  Compas.SaySide(Car.Engine.Alpha);
{$ifdef PRO}
ord('Q'):  if (RRServer.Active) or (RRClient.Active) then
  begin
  with SndIntro do
    begin
    KillSamp;
    FileName:= Param.Snd.KeyPress;
    Loop:= false;
    FVolume:= 255;
    StartSound;
    end;
  if not NetRadar then
    SetNetRadar(true)
  else
    SetNetRadar(false);
  end;
{$endif}
VK_SPACE:  if not Car.Horn then
  begin
  Car.Horn:= true;
  {$ifdef PRO}
  Buf.Status:= NS_HORN_ON;
  Buf.Num:= NetNum;
  Send(Buf);
  {$endif}
  end; // case VK_SPACE
VK_ESCAPE:
  begin
  Tmp_Freq:= Car.Engine.Freq;
  Car.Engine.KillSamp;
  for I:= 1 to LnkSounds do
    Car.LinkedSound[I].KillSamp;
  Car.ThrottleBack:= true;
  LoadMainMenu;
  end; // VK_ESCAPE
ord('P'):
  begin
  Tmp_Freq:= Car.Engine.Freq;
  Car.Engine.KillSamp;
  for I:= 1 to LnkSounds do
    Car.LinkedSound[I].KillSamp;
  with SndIntro do
    begin
    KillSamp;
    FileName:= Param.Snd.Pause;
    Loop:= true;
    Volume:= 255;
    StartSound;
    end;
  Mode:= MD_PAUSE;
  Car.ThrottleBack:= true;
  end;
ord('1'):
  Car.AutoCorrectMode:= not Car.AutoCorrectMode;
ord('2'):
  Car.AutoSaySpeed:= not Car.AutoSaySpeed;
ord('A'):
  if Car.F1_Transm then
    Car.Transmission:= Car.Transmission +1
  else
    Car.Transmission:= 1;
ord('Z'):
  if Car.F1_Transm then
    Car.Transmission:= Car.Transmission -1
  else
    Car.Transmission:= 2;
ord('S'):  if not Car.F1_Transm then
    Car.Transmission:= 3;
ord('X'):  if not Car.F1_Transm then
  Car.Transmission:= 4;
ord('D'):  if not Car.F1_Transm then
  Car.Transmission:= 5;
ord('C'):  if not Car.F1_Transm then
  Car.Transmission:= 6;
ord('F'):  if not Car.F1_Transm then
  Car.Transmission:= 0;
ord('V'):  if not Car.F1_Transm then
  Car.Transmission:= -1;
VK_UP:
  Car.Throttle:= true;
VK_DOWN:
    Car.Braking:= true;
VK_END:
    begin
    Car.Braking:= true;
    Car.TimeCounter:= 26;
    end;
VK_LEFT:  if Shift= [ssCtrl] then
    begin
    if Car.Transmission> -1 then
      Car.ToLeftSide
    else
      Car.ToRightSide;
    end
  else
    begin
    GoLeft:= true;
    Car.Turning:= false;
    end;
VK_DELETE:
  begin
  if Car.Transmission> -1 then
    Car.ToLeftSide
  else
    Car.ToRightSide;
  with SndIntro do
    begin
    KillSamp;
    FileName:= Param.Snd.KeyPress;
    Loop:= false;
    FVolume:= 255;
    StartSound;
    end;
  end;
VK_RIGHT:  if Shift= [ssCtrl] then
    begin
    if Car.Transmission> -1 then
      Car.ToRightSide
    else
      Car.ToLeftSide;
    end
  else
    begin
    GoRight:= true;
    Car.Turning:= false;
    end;
VK_NEXT:
  begin
  if Car.Transmission> -1 then
    Car.ToRightSide
  else
    Car.ToLeftSide;
  with SndIntro do
    begin
    KillSamp;
    FileName:= Param.Snd.KeyPress;
    Loop:= false;
    FVolume:= 255;
    StartSound;
    end;
  end;
VK_PRIOR: if Car.Engine.Volume<= 250 then
  Car.Engine.Volume:= Car.Engine.Volume +5;
VK_HOME: if Car.Engine.Volume> 5 then
  Car.Engine.Volume:= Car.Engine.Volume -5;
  end; // case Key
end; // proc FormKeyDown

procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if (Mode in [MD_CONGRATULATION,MD_PAUSE,MD_BROWSER]) then
  exit;

if Car= NIL then exit;

case Key of
VK_SPACE:  if Car.Horn then
  begin
  Car.Horn:= false;
  {$ifdef PRO}
  Buf.Status:= NS_HORN_OFF;
  Buf.Num:= NetNum;
  Send(Buf);
  {$endif}
  end; // case VK_SPACE
VK_UP:
  Car.ThrottleBack:= true;
VK_DOWN:
  Car.Braking:= false;
VK_END:
  Car.Braking:= false;
VK_LEFT:
  begin
  GoLeft:= false;
  if Car.AutoCorrectMode then
    Car.AutoCorrect;
  end; // case Key = VK_LEFT
VK_RIGHT:
  begin
  GoRight:= false;
  if Car.AutoCorrectMode then
    Car.AutoCorrect;
  end; // case Key = VK_RIGHT
  end; // case Key
end; // proc FormKeyUp

procedure Crash(X,Y,Z: single;Dyn_Obj: boolean;UID:  integer);
var
  CrashSpeed: single;
  Direction: shortint;
  Vec_X,Vec_Z:  single; // ������ ������������
{$ifdef PRO}
  I:  integer;
{$endif}

begin
Car.Turning:= false;
with Car do
  begin
  CrashSpeed:= Speed+1;
  if Car.Transmission= -1 then
    Direction:= 1
  else
    Direction:= -1;

  // ������, ��������� ���������� �������� - ������������� ������, � �������� - ����������
  // �������� ��� � ����� ����, ��� ����� �������� �� ��������� ����� ���������� ������.
  Vec_X:= Engine.Posit.x -X;
  Vec_Z:= Engine.Posit.z -Z;

  if not Dyn_OBJ then
    Step(Direction*CrashSpeed/7)
  else
    with Car.Engine do
      Set_Posit(Posit.x +Vec_X,Posit.y,Posit.z +Vec_Z);
  Speed:= 0;
  with LinkedSound[4] do
    begin
    KillSamp;
    FileName:= Param.Snd.Crash_1;
    if (CrashSpeed> 7) and (CrashSpeed <= 50) then
      FileName:= Param.Snd.Crash_2;
    if CrashSpeed> 50 then
      FileName:= Param.Snd.Crash_3;

    Loop:= false;
    Set_Posit(X,Y,Z);
    FVolume:= 255;
    {$ifdef PRO}
    if (Dyn_Obj) and (UID> -1) then
      begin
      Buf.Status:= NS_CRASHOBJ;
      Buf.Num:= UID;
      Send(Buf);
      end;
    {$endif}
    StartSound;
    end; // with LinkedSound[4]
{$ifdef PRO}
  Buf.Status:= NS_CRASH;
  Buf.X:= X; Buf.Y:= Y; Buf.Z:= Z;
  Buf.Num:= NetNum;
  Buf.Speed:= CrashSpeed;
  if MainForm.RRClient.Active then
    MainForm.RRClient.Socket.SendBuf(Buf,sizeof(TNetMsg));
  with MainForm.RRServer do
    if Active then
      for i:=0 to Socket.ActiveConnections-1 do
        Socket.Connections[i].SendBuf(Buf,sizeof(TNetMsg));
{$endif}
  end; // with Car
end; // proc Crash

procedure Congratulation;
var
  I: integer;
  CT: int64;
  Msg:  string; // ���������
  StrTime:  string;

begin
MainForm.MainTimer.Enabled:= false;
CT:= 55*(Tmr_Counter-Hronometr);

Mode:= MD_CONGRATULATION;

Car.Engine.Stop;

{$ifdef PRO}
Buf.Status:= NS_FINISH;
Buf.Num:= NetNum;
Send(Buf);
if NetRadar then
  SetNetRadar(false);

Car.Engine.Set_Posit(Param.C_X,50,Param.C_Z);
FSound_Update;
{$endif}

// ����� ��� ����� ������������� � "����������" ��������
Car.Speed:= 0;

KillWorld;
KillTerritories;
for I:= 1 to LnkSounds do
  Car.LinkedSound[I].KillSamp;
with SndIntro do
  begin
  KillSamp;
  FileName:= Param.Snd.Congratulation;
  Loop:= false;
  FVolume:= 255;
  StartSound;
  end; // with Car.LinkedSound[1]

Points:= Points -(CT div 10);
str((CT/1000):0:3,StrTime);
Msg:= '��� ���������: '+IntToStr(Points)+' �����.'+#13#10;
Msg:= Msg +'���� �����: '+StrTime+' ������.';
ShowMessage(Msg);
SndIntro.KillSamp;

LoadMainMenu;
end; // proc Congratulation

procedure GotoNull(Snd_FN: string;Snd_Volume: integer);
begin
Car.Goto_Start;

if SndIntro= NIL then
  exit;

with SndIntro do
  begin
  KillSamp;
  FileName:= Snd_FN;
  FVolume:= Snd_Volume;
  Loop:= false;
  StartSound;
  end; // with LinkedSound[3]
end; // proc GotoNull

procedure TMainForm.RRClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
{$ifdef PRO}
// ��������� ���������� �� ����������
with Buf do
  begin
  Status:= NS_NEWCLIENT;
  end; // with Buf

// ����������
if Socket.SendBuf(Buf,sizeof(TNetMsg))= sizeof(TNetMsg) then
  begin
  // ���� ������� - ����������� ������
  with SndIntro do
    begin
    KillSamp;
    FileName:= Param.Snd.ClientConnect;
    Loop:= false;
    FVolume:= 255;
    StartSound;
    end; // with SndIntro
  end; // if

{$endif}
end; // proc TMainForm.RRClientConnect

procedure TMainForm.RRClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
{$ifdef PRO}
case ErrorCode of
10061: // �� ����� ������
  begin
  with SndIntro do
    begin
    KillSamp;
    FileName:= Param.Snd.NoServer;
    Loop:= false;
    FVolume:= 255;
    StartSound;
    while Playing do;
    end; // with SndIntro
  Mode:= MD_GAME;
  MainForm.MainTimer.Enabled:= true;
  Hronometr:= Tmr_Counter;
  abort;
  end; // �� ����� ������
10053: // ������� ������� � ��������
  begin
  with SndIntro do
    begin
    KillSamp;
    FileName:= Param.Snd.ServerDisconnect;
    Loop:= false;
    FVolume:= 255;
    StartSound;
    while Playing do;
    end; // with SndIntro
  Mode:= MD_GAME;
  MainForm.MainTimer.Enabled:= true;
  Hronometr:= Tmr_Counter;
  abort;
  end; // ������� ������� � ��������
else // case
  ShowMessage(IntToStr(ErrorCode));
  end; // case ErrorCode
{$endif}
end;

procedure TMainForm.RRClientRead(Sender: TObject;
  Socket: TCustomWinSocket);

begin
{$ifdef PRO}
Socket.ReceiveBuf(Buf,sizeof(TNetMsg));
case Buf.Status of
NS_CRASHOBJ:
  CrashNetObj(Buf.Num);
NS_FINISH:
  FinishNetCar;
NS_BRK_ON:  // ������� ���������� ��������� ��������
  Brk_NetCar(Buf,true);
NS_BRK_OFF:  // ������� ���������� ���������� ����������
  Brk_NetCar(Buf,false);
NS_HORN_ON:  // ������� ���������� ��������
  Horn_NetCar(Buf,true);
NS_HORN_OFF:  // ������� ���������� �������� ���������
  Horn_NetCar(Buf,false);
NS_CARINFO:  // ���������� �� �������� ����������
  UpdateNetCar(Buf);
NS_CRASH: // ������������ �������� ����������
  CrashNetCar(Buf);
NS_YOURPOS: // �������� ����� ��������� ������� ����������
  begin
  Car.Engine.Set_Posit(Buf.X,Buf.Y,Buf.Z);
  NetNum:= Buf.Num;
  end; // �������� ����� ��������� ����������
NS_START:  // �����
  begin
  Mode:= MD_GAME;
  MainForm.MainTimer.Enabled:= true;
  Hronometr:= Tmr_Counter;
  end; // �����
NS_NEWCLIENTINFO:  // ����� ����������
  CreateNetCar(Buf);
end; // case Buf.Status
{$endif}
end; // proc TMainForm.RRClientRead

procedure TMainForm.RRServerClientConnect(Sender: TObject;
  Socket: TCustomWinSocket);
{$ifdef PRO}
var
  I:  integer;
{$endif}

begin
{$ifdef PRO}
Socket.ReceiveBuf(Buf,sizeof(TNetMsg));

// ���������� ��� �����
with Buf do
  begin
  Status:= NS_YOURPOS;
  Num:= RRServer.Socket.ActiveConnections;
  Y:= 0;
  // ����������� ��������� ������� ����� ������
  Calc_Posit(Car.Engine.Posit.X,Car.Engine.Posit.Z,X,Z,Car.Engine.Alpha-(PI/2),Num*(2*Car_Dimensions));
  end;

CreateNetCar(Buf);

// ����������� ������
with SndIntro do
  begin
  KillSamp;
  FileName:= Param.Snd.NewClient;
  Loop:= false;
  FVolume:= 255;
  StartSound;
  end; // with SndIntro

// ��������
Socket.SendBuf(Buf,sizeof(TNetMsg));

// ��������� ���������� �� ���� ��������,
// ����� ���������� (������ ��� �����������������
Buf.Status:= NS_NEWCLIENTINFO;
with RRServer do
  if Socket.ActiveConnections> 0 then
    for i:=0 to Socket.ActiveConnections-2 do
      Socket.Connections[i].SendBuf(Buf,sizeof(TNetMsg));

// ��������� �������� � ��������� ����������
// � �������� ������ ��� �����������������
with Buf do
  begin
  Status:= NS_NEWCLIENTINFO;
  Num:= 0;
  with Car.Engine do
    begin
    X:= Posit.x; Y:= Posit.y; Z:= Posit.z;
    end;
  end;
Socket.SendBuf(Buf,sizeof(TNetMsg));

{$endif}
end; // proc TMainForm.RRServerClientConnect

procedure TMainForm.RRServerClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
{$ifdef PRO}
with SndIntro do
  begin
  KillSamp;
  FileName:= Param.Snd.ClientDisconnect;
  Loop:= false;
  FVolume:= 255;
  StartSound;
  end; // with SndIntro

{$endif}
end;

procedure TMainForm.RRServerClientRead(Sender: TObject;
  Socket: TCustomWinSocket);
begin
{$ifdef PRO}
Socket.ReceiveBuf(Buf,sizeof(TNetMsg));
case Buf.Status of
NS_CRASHOBJ:
  CrashNetObj(Buf.Num);
NS_FINISH:
  FinishNetCar;
NS_BRK_ON:  // ������� ���������� ��������� ��������
  Brk_NetCar(Buf,true);
NS_BRK_OFF:  // ������� ���������� ���������� ����������
  Brk_NetCar(Buf,false);
NS_HORN_ON:  // ������� ���������� ��������
  Horn_NetCar(Buf,true);
NS_HORN_OFF:  // ������� ���������� �������� ���������
  Horn_NetCar(Buf,false);
NS_CARINFO:
  UpdateNetCar(Buf);
NS_CRASH: // ������������ ����������
  CrashNetCar(Buf);
end; // case Buf.Status

// ��������� ���������� �� ���� ��������
Send_To_All(Buf);
{$endif}
end; // proc TMainForm.RRServerClientRead

procedure Extr_Braking(Stat:  boolean);
begin
{$ifdef PRO}
if Stat= true then
  Buf.Status:= NS_BRK_ON
else
  Buf.Status:= NS_BRK_OFF;
Buf.Num:= NetNum;
Send(Buf);
{$endif}
end; // proc Extr_Braking;

procedure TMainForm.MainTimerTimer(Sender: TObject);
begin
inc(Tmr_Counter);

WorldUpdate;

if (Car= NIL) or (Mode<> MD_GAME) then exit;

TerritoriesUpdate;

Car.Upd;

if GoLeft then
  begin
  if Car.Transmission> -1 then
    Car.Turn(Car.FDynTurn,0,false)
  else
    Car.Turn(-Car.FDynTurn,0,false);
  end;
if GoRight then
  begin
  if Car.Transmission> -1 then
    Car.Turn(-Car.FDynTurn,0,false)
  else
    Car.Turn(Car.FDynTurn,0,false);
  end;

if (Car.Turning) and (Car.Engine.Alpha< Car.FCorner) then
  Car.Turn(Car.FDynTurn,0,false);
if (Car.Turning) and (Car.Engine.Alpha> Car.FCorner) then
  Car.Turn(-Car.FDynTurn,0,false);

Compas_Update(Car.Engine.Posit,Car.Engine.Velocity);

FSOUND_Update();

{$ifdef PRO}
if NetRadar then
  with Car.Engine.Posit do
    begin
    NR_Snd.Set_Posit(X+Radar_X,Y,Z+Radar_Z);
    NR_Snd.Speed:= Car.Engine.Speed;
    end; // with Car.Engine.Posit

MoveNetCars;

if (Param.StreamSpeed> 1) and ((Tmr_Counter mod Param.StreamSpeed)= 0) then
begin
if ((OldSpeed= 0) and (Car.Speed= 0)) then
  exit;

OldSpeed:= Car.Speed;
with Buf do
  begin
  Status:= NS_CARINFO;
  Num:= NetNum;
  X:= Car.Engine.Posit.x;
  Y:= Car.Engine.Posit.y;
  Z:= Car.Engine.Posit.z;
  Speed:= Car.Speed;
  Alpha:= round(Car.Engine.Alpha);
  end; // with Buf
Send(Buf);
end;
{$endif}
end;

procedure TMainForm.NetRadarTimerTimer(Sender: TObject);
{$ifdef PRO}
var
  Alph:  single;
{$endif}

begin
{$ifdef PRO}
if not NetRadar then
  exit;

Update_Radar(Car.Engine.Posit.x,Car.Engine.Posit.z);

with Car.Engine do
  begin
  if Radar_X>= 0 then
    Alph:= ArcTan(Radar_Z/Radar_X)
  else // ���� �� ��� ������ � ������� ��������
    Alph:= PI +ArcTan(Radar_Z/Radar_X);

  Alph:= Alph -Alpha;
  if Alph < 0 then
    Alph:= Alph +(2*PI);
  if Alph > 2*PI then
    Alph:= Alph -(2*PI);

  if (Alph> PI/2) and (Alph< 3*PI/2) then
    begin
    if NR_Snd.FileName<> Param.Snd.NetRadarBack then
      begin
      Nr_Snd.KillSamp;
      NR_Snd.FileName:= Param.Snd.NetRadarBack;
      Nr_Snd.StartSound;
      end;
    end
  else
    begin
    if NR_Snd.FileName<> Param.Snd.NetRadar then
      begin
      NR_Snd.KillSamp;
      NR_Snd.FileName:= Param.Snd.NetRadar;
      NR_Snd.StartSound;
      end;
    end;
  end; // with Car.Engine.Posit
{$endif}
end;

procedure TMainForm.RRClientDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
{$ifdef PRO}
// ��������� �����, ���� ��� �������
if NetRadar then
  SetNetRadar(false);
// ������� ��� ����������
KillNetCar(-1);
RRClient.Active:= false;

with SndIntro do
  begin
  KillSamp;
  FileName:= Param.Snd.ServerDisconnect;
  Loop:= false;
  FVolume:= 255;
  StartSound;
  end; // with SndIntro
{$endif}
end; // proc TMainForm.RRClientDisconnect

procedure BrowseModeOn;
begin
if Car.Engine.Playing then
  Car.Engine.Stop;

with BrowseModeInfo do
  begin
  LastMode:= Mode;
  Mode:= MD_BROWSER;
  Posit:= Car.Engine.Posit;
  Veloc:= Car.Engine.Velocity;
  Alpha:= round(Car.Engine.Alpha);
  end;

Car.Engine.Set_Veloc(0,0,0);
with Browser do
  Car.Engine.Set_Posit(X,Y,Z);
  Car.Engine.TurnHead(Param.Alpha,0,true);
end; // proc BrowseModeOn

procedure BrowseModeOff;
begin
if Mode<> MD_BROWSER then exit;

with BrowseModeInfo do
  begin
  Car.Engine.Set_Veloc(Veloc.x,Veloc.y,Veloc.z);
  Car.Engine.Set_Posit(Posit.x,Posit.y,Posit.z);
  Car.Turn(Alpha,0,true);
  Mode:= LastMode;
  end;

if Mode= MD_GAME then
  Car.Engine.Play;
if Mode= MD_MENU then
  SndIntro.StartSound;
end; // proc BrowseModeOff

end. // End of unit

