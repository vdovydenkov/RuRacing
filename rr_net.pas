unit rr_net;
{$define PRO}
interface
{$ifdef PRO}
uses classes,
     my_fmod;

const
  NetSilenceDistance= 500;
  NetcarUpdateTime= 55;
  NS_START= 0; // Всем старт!
  NS_FINISH= 1;  // Финиш
  NS_CARINFO= 3; // Передача информации о расположении автомобилей
  NS_NEWCLIENT= 4; // Сообщение о подключении нового автомобиля
  NS_YOURPOS= 5; // Указание клиенту его позиции
  NS_NEWCLIENTINFO= 6; // Информация о новой машине
  NS_CRASH= 7; // Столкновение
  NS_Brk_On=  8; // Торможение
  NS_BRK_OFF=  9; // Конец торможения
  NS_HORN_ON=  10; // Клаксон
  NS_HORN_OFF=  11; // Выключен клаксон
  NS_CRASHOBJ=  12; // крах объекта окружающего мира
  // Удаление радара от слушателя
  Radar_Distance= 10;

type
  TNetMsg=  record
    Status:  byte;
    Num:  integer;
    X,Y,Z:  single;
    Alpha:  integer;
    Speed:  single;
  end; // TNetMsg= record

var
  Buf:  TNetMsg;
  NetNum:  byte = 0;
  NetWorld:  TList;
  NetRadar:  boolean = false;
  NR_Snd:  TFM3DSound = NIL;
  Radar_X,Radar_Z:  single;

procedure UpdateNetCar(Info:  TNetMsg);
procedure MoveNetCars;
function Car_Identifier(UID:  integer):  string;
procedure CreateNetCar(Info:  TNetMsg);
procedure CrashNetCar(Info:  TNetMsg);
procedure Brk_NetCar(Info:  TNetMsg;Stat:  boolean);
procedure Horn_NetCar(Info:  TNetMsg;Stat:  boolean);
procedure Calc_Posit(PX,PZ:  single;var NX,NZ:  single;
  Alpha:  single;Size:  byte);
procedure Send(Info:  TNetMsg);
procedure Send_To_All(Info:  TNetMsg);
procedure Update_Radar(X1,Z1:  single);
procedure SetNetRadar(Stat:  boolean);
procedure KillNetCar(Num:  integer);
procedure FinishNetCar;
procedure CrashNetObj(ObjNum:  integer);
{$endif}
implementation
{$ifdef PRO}
uses main, world, u_car, u_param;

procedure UpdateNetCar(Info:  TNetMsg);
var
  I:  integer;

begin
if NetWorld= NIL then exit;

for I:= NetWorld.Count-1 downto 0 do
  with PObjWorld(NetWorld.Items[I])^ do
    begin
    if Numb= Info.Num then
      begin
      Set_Posit(Info.X,Info.Y,Info.z);
      Alpha:= Info.Alpha;
      Speed:= Info.Speed;
      Freq:= Def_Freq +round(Speed*200);
      with PReflex^ do
        begin
        Set_Posit(Info.X,Info.Y,Info.z);
        Alpha:= Info.Alpha;
        Speed:= Info.Speed;
        end; // with PReflex^
      end;
    end;
end; // proc UpdateNetCar

procedure MoveNetCars;
var
  I:  integer;

begin
if NetWorld= NIL then exit;

for I:= NetWorld.Count-1 downto 0 do
  with PObjWorld(NetWorld.Items[I])^ do
    begin
    Step(Speed/(1000/NetcarUpdateTime));
    with PReflex^ do
      Step(Speed/(1000/NetcarUpdateTime));
    end; // With PObjWorld(NetWorld.Items[I])^
end; // proc MoveNetCars

function Car_Identifier(UID:  integer):  string;
begin
case UID of
 1:  Result:= 'sounds\ferrari.wav';
 2:  Result:= 'sounds\mac_mono.wav';
 3:  Result:= 'sounds\lada.wav';
else
  Result:= Param.Snd.Netcar_Engine;
  ;
  end; // case UID
end; // func Car_Identifier

procedure CreateNetCar(Info:  TNetMsg);
var
  NewObj:  PObjWorld;

begin
if NetWorld= NIL then exit;

new(NewObj);
NewObj^:= TObjWorld.Create; // Инициируем
with NewObj^ do
  begin
  FType:= DYNAMIC;
  TextName:= 'Сетевой игрок';
  Start_X:= Info.X;
  Start_Y:= Info.Y;
  Start_Z:= Info.Z;
  Set_Posit(Start_X,Start_Y,Start_Z);
  FMinDist:= 10;
  AllWaySize:= 0;
  ObjSize:= 4;
  CanExplode:= false;
  Numb:= Info.Num;
  FVolume:= 255;
  FileName:= Car_Identifier(-1);
  StartSound;

  new(PReflex);
  PReflex^:= TFM3DSound.Create;
  end;
// Добавляем объект в список
NetWorld.Add(NewObj);
end; // proc CreateNetCar(Info:  TNetMsg);

procedure CrashNetCar(Info:  TNetMsg);
var
  I:  integer;

begin
if NetWorld= NIL then exit;

for I:= NetWorld.Count-1 downto 0 do
  with PObjWorld(NetWorld.Items[I])^ do
    begin
    if Numb= Info.Num then
      with PReflex^ do
        begin
        {
        if ListenerDistance> NetSilenceDistance then
          begin
          if Playing then KillSamp;
          exit;
          end;
        }
        KillSamp;
        FileName:= Param.Snd.Crash_1;
        Speed:= PObjWorld(NetWorld.Items[I])^.Speed;
        FMinDist:= PObjWorld(NetWorld.Items[I])^.FMinDist;
        if (Speed> 4) and (Speed <= 50) then
          FileName:= Param.Snd.Crash_2;
        if Speed> 50 then
          FileName:= Param.Snd.Crash_3;

        Loop:= false;
        FVolume:= 255;
        Set_Posit(PObjWorld(NetWorld.Items[I])^.Posit.x,PObjWorld(NetWorld.Items[I])^.Posit.y,PObjWorld(NetWorld.Items[I])^.Posit.z);
        StartSound;
        end;
    end;
end; // proc CrashNetCar(Info:  TNetMsg);

procedure Brk_NetCar(Info:  TNetMsg;Stat:  boolean);
var
  I:  integer;

begin
if NetWorld= NIL then exit;

for I:= NetWorld.Count-1 downto 0 do
  with PObjWorld(NetWorld.Items[I])^ do
    begin
    if Numb= Info.Num then
      with PReflex^ do
        begin
        // (ListenerDistance> NetSilenceDistance)
        if Stat= false then
          begin
          if Playing then Stop;
          exit;
          end; // if Stat= false
        if FileName= Param.Snd.Netcar_Braking then
          begin
          if Playing then
            exit
          else
            Play;
          end
        else // if FileName=
          begin
          KillSamp;
          FileName:= Param.Snd.Netcar_Braking;
          FMinDist:= PObjWorld(NetWorld.Items[I])^.FMinDist;
          Loop:= true;
          FVolume:= 255;
          Set_Posit(PObjWorld(NetWorld.Items[I])^.Posit.x,PObjWorld(NetWorld.Items[I])^.Posit.y,PObjWorld(NetWorld.Items[I])^.Posit.z);
          StartSound;
          end; // if FileName
        end; // if Numb= Info.Num
    end; // with PReflex^
end;

procedure Horn_NetCar(Info:  TNetMsg;Stat:  boolean);
var
  I:  integer;

begin
if NetWorld= NIL then exit;

for I:= NetWorld.Count-1 downto 0 do
  with PObjWorld(NetWorld.Items[I])^ do
    begin
    if Numb= Info.Num then
      with PReflex^ do
        begin
        // (ListenerDistance> NetSilenceDistance)
        if Stat= false then
          begin
          if Playing then Stop;
          exit;
          end; // if Stat= false
        if FileName= Param.Snd.Netcar_Horn then
          begin
          if Playing then
            exit
          else
            Play;
          end
        else // if FileName
          begin
          KillSamp;
          FileName:= Param.Snd.Netcar_Horn;
          FMinDist:= PObjWorld(NetWorld.Items[I])^.FMinDist;
          Loop:= true;
          FVolume:= 255;
          Set_Posit(PObjWorld(NetWorld.Items[I])^.Posit.x,PObjWorld(NetWorld.Items[I])^.Posit.y,PObjWorld(NetWorld.Items[I])^.Posit.z);
          StartSound;
          end; // if FileName
        end; // with PReflex^
    end; // if Numb= Info.Num
end;

    procedure Calc_Posit(PX,PZ:  single;var NX,NZ:  single;
  Alpha:  single;Size:  byte);
// Расчёт точки старта сетевого автомобиля
// Параметры:  PX,PZ -  точка первого автомобиля
// NX,NZ -  сюда помещается результат расчётов,
// Alpha -  угол, относительно стартового автомобиля,
// Size -  расстояние до стартового автомобиля
begin
NX:= (Size *Cos(Alpha)) +PX;
NZ:= (Size *Sin(Alpha)) +PZ;
end; // proc Calc_Posit

procedure Send(Info:  TNetMsg);
var
  I:  integer;

begin
if MainForm.RRClient.Active then
  MainForm.RRClient.Socket.SendBuf(Info,sizeof(TNetMsg));

with MainForm.RRServer do
  if Active then
    for i:=0 to Socket.ActiveConnections-1 do
      Socket.Connections[i].SendBuf(Info,sizeof(TNetMsg));
end; // proc Send(Buf:  TNetMsg);

procedure Send_To_All(Info:  TNetMsg);
var
  I:  integer;

begin
if not MainForm.RRServer.Active then
  exit;

// Рассылаем информацию по всем клиентам
with MainForm do
  for i:=0 to RRServer.Socket.ActiveConnections-1 do
    RRServer.Socket.Connections[i].SendBuf(Info,sizeof(TNetMsg));
end; // proc Send_To_All

procedure Update_Radar(X1,Z1:  single);
var
  X,Z,L:  single;

begin
if NetWorld= NIL then exit;

if Not NetRadar then
  exit;

with PObjWorld(NetWorld.Items[0])^ do
  begin
  X:= Posit.X -X1;
  Z:= Posit.Z -Z1;
  end;

// Расчитываем длину
L:= sqrt(sqr(X) +sqr(Z));

Radar_X:= (Radar_Distance/L) *X;
Radar_Z:= (Radar_Distance/L) *Z;
end; // proc Update_Radar

procedure SetNetRadar(Stat:  boolean);
begin
if (Stat= true) and ((NetWorld= NIL) or (NetWorld.Count= 0)) then
  exit;

NetRadar:= Stat;

if NR_Snd= NIL then
  begin
  if Stat= false then exit;
  NR_Snd:= TFM3DSound.Create;
  end;

if Stat= true then
  begin
  with NR_Snd do
    begin
    FileName:= Param.Snd.NetRadar;
    Loop:= true;
    FVolume:= 255;
    StartSound;
    end;
  MainForm.NetRadarTimer.Enabled:= true;
  MainForm.NetRadarTimer.OnTimer(MainForm);
  end
else
  begin
  NR_Snd.KillSamp;
  MainForm.NetRadarTimer.Enabled:= false;
  end;
end; // proc SetNetRadar

procedure KillNetCar(Num:  integer);
var
  I:  integer;

begin
if NetWorld= NIL then exit;

for I:= NetWorld.Count-1 downto 0 do
  with PObjWorld(NetWorld.Items[I])^ do
  if (Num= -1) or (Numb= Num) then
    begin
    PReflex^.Free;
    KillSamp;
    Free;
    NetWorld.Delete(I);
    end;

if Num= -1 then
  begin
  NetWorld.Free; NetWorld:= NIL;
  end;
end;

procedure FinishNetCar;
begin
with SndIntro do
  begin
  KillSamp;
  FileName:= Param.Snd.NetFinish;
  Loop:= false;
  FVolume:= 255;
  StartSound;
  end;
end;

procedure CrashNetObj(ObjNum:  integer);
begin
with PObjWorld(Obj.Items[ObjNum])^ do
  begin
  KillSamp;
  FileName:= FN_Expl;
  Loop:= false;
  FType:= Exploding;
  Speed:= 0;
  CanExplode:= false;
  StartSound;
  end;
end; // proc CrashNetObj
{$endif}
end. // End Of Unit

