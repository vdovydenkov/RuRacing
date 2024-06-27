unit u_car;

interface
uses main, my_fmod;

const
  MaxTransm= 6; // Кол-во скоростей
  LnkSounds= 5; // Кол-во связаных объектов
  GenCycle= 55; // Основной игровой цикл в милисекундах
  // Стороны света
  PI_45= 45;
  PI_90= 90;
  PI_135= 135;
  PI_180= 180;
  PI_225= 225;
  PI_270= 270;
  PI_315= 315;
  PI_360= 359;

type
  TCarSound= class(TFMListenerSound) // From my_fmod.pas
  public

  procedure FM_Error(Err_St: string); OVERRIDE;
  end; // TCarSound= class(TFMListenerSound)
  TCarTitle= string[30];
  TCar= class(TObject)
  private
    FSpeed: single;
    FTransmission: integer;
    FThrottle: boolean;
    FBraking: boolean;
    FThrottleBack: boolean;
    FFriction: integer;
    FTurning: boolean;
    FTitle: TCarTitle;
    FOld_AutoCorrectMode: boolean;
    FIdent:  integer;

    MaxSpeed: integer;
    FAutoCorrectMode: boolean;
    FAutoSaySpeed: boolean;
    Vol_SaySpd:  single; // Коэффициент громкости чтения скорости
    FBrk_Snd_FN:  string;
    FBrk_Snd_Vol:  byte;
    FSpeedup_Snd_FN:  string;
    FSpeedup_Snd_Vol:  byte;
    FHorn_Snd_FN:  string;
    FHorn_Snd_Vol:  byte;
    FDynSound1:  integer;
    FDynSound2:  integer;
    FHorn:  boolean;

  procedure Set_Speed(NewValue: single);
  procedure Set_Transmission(NV: integer);
  procedure Set_Throttle(NV: boolean);
  procedure Set_Braking(NV: boolean);
  procedure Set_ThrottleBack(NV: boolean);
  procedure Set_Turning(NV: boolean);
  procedure Set_AutoCorrectMode(NV: boolean);
  procedure Set_AutoSaySpeed(NV: boolean);
  procedure Set_Default;
  function Get_ID:  integer;
  procedure Set_Horn(NV:  boolean);

  public
    Engine: TCarSound;
    LinkedSound: array[1..LnkSounds] of TFM3DSound;
    F1_Transm:  boolean;
    TrSpd: array[-1..MaxTransm] of integer;
    TimeCounter: integer;
    FDynam: single;
    FDynTurn: single;
    FCorner: single; // Целевой угол
    FIgn_Snd_FN:  string;
    FIgn_Snd_Vol: byte;
    FDimens:  integer;

  property Speed: single read FSpeed write Set_Speed;
  property Transmission: integer read FTransmission write Set_Transmission;
  property Throttle: boolean read FThrottle write Set_Throttle;
  property Braking: boolean read FBraking write Set_Braking;
  property ThrottleBack: boolean read FThrottleBack write Set_ThrottleBack;
  property Friction: integer read FFriction write FFriction default 0;
  property Turning: boolean read FTurning write Set_Turning default false;
  property Title: TCarTitle read FTitle;
  property AutoCorrectMode: boolean read FAutoCorrectMode write Set_AutoCorrectMode;
  property AutoSaySpeed: boolean read FAutoSaySpeed write Set_AutoSaySpeed;
  property ID:  integer read Get_ID default -1;
  property Horn:  boolean read FHorn write Set_Horn default false;

  constructor Create(FN_INI: string);
  destructor Destroy; OVERRIDE;
  procedure SynhSounds; // Синхронизация всех звуков со звуком двигателя
  procedure Step(StepLen: single);
  procedure Turn(Gor,Vert: single;Absolut: boolean);
  procedure Upd;
  procedure ToRightSide;
  procedure ToLeftSide;
  procedure AutoCorrect;
  procedure Goto_Start;
  end; // TCar class


implementation
uses SysUtils, inifiles, fmod, fmodtypes, fmoderrors, fmodpresets,
     err, compas, u_param;

var
  LastSpeed: integer;
  Vol:  integer;

constructor TCar.Create(FN_INI: string);
const
  Section_Car= 'CAR';
  Section_Sound= 'SOUND';

var
  I: integer;
  Car_INI: TIniFile;
  St:  string;

begin
Engine:= TCarSound.Create;
for I:= 1 to LnkSounds do
  LinkedSound[I]:= TFM3DSound.Create;

Set_Default;
Car_INI:= TIniFile.Create(FN_INI);
with Car_INI do
  begin
  // [CAR]
  FIdent:= ReadInteger(Section_Car,'ID',-1);
  FTitle:= ReadString(Section_Car,'Title','Lada Revolution');
  MaxSpeed:= ReadInteger(Section_Car,'MaxSpeed',360);
  F1_Transm:= ReadBool(Section_Car,'F1Transm',false);
  TrSpd[1]:= ReadInteger(Section_Car,'Transm_1',30);
  TrSpd[2]:= ReadInteger(Section_Car,'Transm_2',70);
  TrSpd[3]:= ReadInteger(Section_Car,'Transm_3',130);
  TrSpd[4]:= ReadInteger(Section_Car,'Transm_4',200);
  TrSpd[5]:= ReadInteger(Section_Car,'Transm_5',280);

  FDynam:= ReadInteger(Section_Car,'Dynam',30);
  if FDynam< 1 then
    FDynam:= 1
  else
    if FDynam> 200 then
      FDynam:= 200;
  FDynam:= FDynam / 100;

  FDynTurn:= ReadInteger(Section_Car,'Dyn_Turning',25);
  if FDynTurn< 1 then
    FDynTurn:= 1
  else
    if FDynTurn> 200 then
      FDynTurn:= 200;
  FDynTurn:= FDynTurn/20;
  FDimens:= ReadInteger(Section_Car,'Dimensions',4);
  if FDimens< 1 then
    FDimens:= 1
  else
    if FDimens> 200 then
      FDimens:= 200;

  FAutoCorrectMode:= ReadBool(Section_Car,'AutoCorrectMode',true);
  FOld_AutoCorrectMode:= FAutoCorrectMode;
  FAutoSaySpeed:= ReadBool(Section_Car,'AutoSaySpeed',true);

  if (MaxSpeed< 25) or (MaxSpeed> 500) then
    MaxSpeed:= 100
  else
    MaxSpeed:= Round(MaxSpeed/3.6);

  for I:= 1 to 5 do
    TrSpd[I]:= Round(TrSpd[I]/3.6);

  // [SOUND]
  St:= ReadString(Section_Sound,'Engine','');
  if not FileExists(St) then
    RR_Error(NO_SND_ENGINE,St);
  Engine.FileName:= St;
  Engine.FVolume:= ReadInteger(Section_Sound,'Engine_Volume',100);
  Vol_SaySpd:= ReadFloat(Section_Sound,'Spd_Announc_Volume',1.8);
  FBrk_Snd_FN:= ReadString(Section_Sound,'Braking','');
  if not FileExists(FBrk_Snd_FN) then
    RR_Error(NO_SND_BRK,FBrk_Snd_FN);
  FBrk_Snd_Vol:= ReadInteger(Section_Sound,'Braking_Volume',100);
  FIgn_Snd_FN:= ReadString(Section_Sound,'Ignition','');
  if not FileExists(FIgn_Snd_FN) then
    RR_Error(No_Snd_Ign,FIgn_Snd_FN);
  FIgn_Snd_Vol:= ReadInteger(Section_Sound,'Ignition_Volume',100);
  FSpeedup_Snd_FN:= ReadString(Section_Sound,'Speedup','');
  if not FileExists(FSpeedup_Snd_FN) then
    RR_Error(NO_SND_SPD,FSpeedup_Snd_FN);
  FSpeedup_Snd_Vol:= ReadInteger(Section_Sound,'Speedup_Volume',100);
  FHorn_Snd_FN:= ReadString(Section_Sound,'Horn','');
  if not FileExists(FHorn_Snd_FN) then
    RR_Error(NO_SND_HORN,FHorn_Snd_FN);
  FHorn_Snd_Vol:= ReadInteger(Section_Sound,'Horn_Volume',200);
  FDynSound1:= ReadInteger(Section_Sound,'DynSound1',420);
  FDynSound2:= ReadInteger(Section_Sound,'DynSound2',1000);

  Free;
  end; // with Car_INI

TrSpd[-1]:= TrSpd[1]; TrSpd[0]:= 0; TrSpd[6]:= MaxSpeed;
end; // constr TCar.Create

destructor TCar.Destroy;
var
  I: integer;

begin
Engine.Free;
for I:= 1 to LnkSounds do
  LinkedSound[I].Free;
end; // destr TCar.Destroy

procedure TCar.Set_Default;
begin
with Engine do
  Loop:= true;

Goto_Start;
end; // proc TCar.Set_Default

procedure TCarSound.FM_Error(Err_St: string);
begin
RR_Error(LOAD_SOUND_ERROR,Err_St);
end; // TCarSound.FM_Error

procedure TCar.SynhSounds;
var
  I: integer;

begin
for I:= 1 to LnkSounds do
  with LinkedSound[I] do
    begin
    Posit:= Engine.Posit;
    FSOUND_3D_SetAttributes(Channel, @Posit, NIL);
    end; // with LinkedSound[I]
end; // proc TCar.SynhSounds

procedure TCar.Set_Speed(NewValue: single);
var
  NFreq: longint;
  Rnd_Speed: integer;
  CTransm:  integer;

begin
if Self= NIL then exit;

CTransm:= abs(Transmission);
if NewValue> MaxSpeed then
  NewValue:= MaxSpeed;
if NewValue< 0 then
  NewValue:= 0;

Car_Dimensions:= FDimens;

if NewValue= 0 then
  begin
  Braking:= false;
  ThrottleBack:= false;
  Car_Dimensions:= 0;
  end; // if NewValue= 0

if (NewValue> TrSpd[CTransm]) and (Throttle) then
  exit;

if (NewValue> 0) and (FSpeed= 0) and (CTransm> 2) then
  exit;

                                      if Throttle then
  begin
  NFreq:= ((FDynSound1 div CTransm)*round(NewValue*3.6));
  Engine.Freq:= Engine.Def_Freq +NFreq +CTransm*FDynSound2;
  end
else
  if round(3.6*FSpeed)> 0 then
    begin
    NFreq:= (round(3.6*(FSpeed-NewValue)))*((Engine.Freq -Engine.Def_Freq) div round(3.6*FSpeed));
    if (Engine.Freq -(NFreq+200))>= (Engine.Def_Freq div 2) then
      Engine.Freq:= Engine.Freq -(NFreq+200)
    else
      Engine.Freq:= Engine.Def_Freq div 2;
    end
  else
    Engine.Freq:= Engine.Def_Freq;

Rnd_Speed:= Round(3.6*NewValue);
if (FAutoSaySpeed) and (Rnd_Speed> 0) and (Rnd_Speed<> LastSpeed)
   and ((Rnd_Speed mod 10)= 0)
   and (not LinkedSound[4].Playing) then
  begin
  LastSpeed:= Rnd_Speed;
  with LinkedSound[4] do
    begin
    KillSamp;
    FileName:= 'sounds\'+IntToStr(Rnd_Speed)+'.mp3';
    Loop:= false;
    Vol:= round(Vol_SaySpd *Engine.FVolume);
    if Vol> 255 then
      FVolume:= 255
    else
      FVolume:= Vol;
    StartSound;
    end; // with LinkedSound[4]
  end; // if (NewValue mod 10) = 0

FSpeed:= NewValue;
Engine.Speed:= NewValue;
end; // proc TCar.Set_Speed

procedure TCar.Step(StepLen: single);
begin
Engine.Step(StepLen);
SynhSounds; // Подгоняем все связанные звуки
end; // proc TCar.Step

procedure TCar.Turn(Gor,Vert: single;Absolut: boolean);
var
  NV:  single; // Новое значение угла

begin
if (Self= NIL) or (Speed= 0) then exit;

if Absolut then
  begin
  if Gor< 0 then Gor:= 0;
  if Gor> PI_360 then Gor:= PI_360;
  FCorner:= Gor;
  if (Engine.Alpha= 0) and (Gor>= 270) then
    Engine.Alpha:= 359;
  if Gor<> Engine.Alpha then
    Turning:= true;
  exit;
  end; // if Absolut

NV:= Gor +Engine.Alpha;

if ((Engine.Alpha< PI_45) and (NV>= PI_45))
   or ((Engine.Alpha> PI_45) and (NV<= PI_45))
   or ((Engine.Alpha< PI_135) and (NV>= PI_135))
   or ((Engine.Alpha> PI_135) and (NV<= PI_135))
   or ((Engine.Alpha< PI_225) and (NV>= PI_225))
   or ((Engine.Alpha> PI_225) and (NV<= PI_225))
   or ((Engine.Alpha< PI_315) and (NV>= PI_315))
   or ((Engine.Alpha> PI_315) and (NV<= PI_315)) then
  with LinkedSound[3] do
    begin
    KillSamp;
    FileName:= Param.Snd.Half_Corner;
    Loop:= false;
    FVolume:= Param.Snd.Vol_SaySide;
    StartSound;
    end; // Полуугол + with LinkedSound[3]

if (Turning)
   and (((Engine.Alpha< FCorner) and (NV>= FCorner))
   or ((Engine.Alpha> FCorner) and (NV<= FCorner))) then
  begin
  Turning:= false;
  Compas.SaySide(FCorner);
  Gor:= FCorner;
  if Gor= PI_360 then
    Gor:= 0;
  Absolut:= true;
  end
else // Turning
  if (not Turning)
     and (((Engine.Alpha< PI_90) and (NV>= PI_90))
     or ((Engine.Alpha> PI_90) and (NV<= PI_90))
     or ((Engine.Alpha< PI_180) and (NV>= PI_180))
     or ((Engine.Alpha> PI_180) and (NV<= PI_180))
     or ((Engine.Alpha< PI_270) and (NV>= PI_270))
     or ((Engine.Alpha> PI_270) and (NV<= PI_270))
     or ((Engine.Alpha< PI_360) and (NV>= PI_360))
     or ((Engine.Alpha> 0) and (NV<= 0))) then
    Compas.SaySide(Engine.Alpha);

Engine.TurnHead(Gor,Vert,Absolut);
end; // proc TCar.Turn

procedure TCar.Set_Braking(NV: boolean);
begin
if NV= FBraking then exit;
if NV= true then
  Throttle:= false
else
  begin
  TimeCounter:= 0;
  LinkedSound[2].KillSamp;
  Extr_Braking(false);
  ThrottleBack:= true;
  end;
FBraking:= NV;
end; // proc TCar.Set_Braking

procedure TCar.Set_Throttle(NV: boolean);
begin
if NV= FThrottle then exit;
if (NV) and ((Transmission= 0) or (Speed> TrSpd[Transmission]))then
  exit;

if (NV= true) and (Transmission<> 0) then
  begin
  ThrottleBack:= false;
  Braking:= false;
  end;
FThrottle:= NV;
end; // proc TCar.Set_Throttle

procedure TCar.Set_ThrottleBack(NV: boolean);
begin
if NV= FThrottleBack then exit;
if NV= true then
  Throttle:= false;
FThrottleBack:= NV;
end; // proc TCar.Set_ThrottleBack

procedure TCar.Set_Transmission(NV: integer);
begin
if ((FTransmission= -1) or (NV= -1)) and (Speed> 0) then
  exit;

if (NV< -1) or (NV= FTransmission) or (NV> MaxTransm) then
  exit;

if ((NV= MaxTransm) and (MaxSpeed= TrSpd[MaxTransm-1]))
   or ((NV= MaxTransm-1) and (MaxSpeed= TrSpd[MaxTransm-2])) then
  exit;

if Speed> TrSpd[NV] then
  ThrottleBack:= true;

FTransmission:= NV;
LinkedSound[1].KillSamp;
case NV of
-1:  LinkedSound[1].FileName:= 'sounds\tr_back.mp3';
0:
  begin
  ThrottleBack:= true;
  LinkedSound[1].FileName:= 'sounds\tr_neytral.mp3';
  end; // case NV = 0
1:  LinkedSound[1].FileName:= 'sounds\tr_1.mp3';
2:  LinkedSound[1].FileName:= 'sounds\tr_2.mp3';
3:  LinkedSound[1].FileName:= 'sounds\tr_3.mp3';
4:  LinkedSound[1].FileName:= 'sounds\tr_4.mp3';
5:  LinkedSound[1].FileName:= 'sounds\tr_5.mp3';
6:  LinkedSound[1].FileName:= 'sounds\tr_6.mp3';
end; // case NV
LinkedSound[1].FVolume:= 150;
LinkedSound[1].StartSound;
end; // TCar.Set_Transmission

procedure TCar.Upd;
begin
if Self= NIL then exit;

if Transmission> -1 then
begin
if Throttle then
  begin
  if (Transmission= 1) or ((TrSpd[Transmission]>= Speed) and (TrSpd[Transmission-1]< Speed)) then
    Speed:= Speed +FDynam;
  if (Transmission> 1) and (TrSpd[Transmission-1]>= Speed) then
    begin
    Speed:= Speed +(FDynam/2);
    with LinkedSound[2] do
      begin
      if (Transmission< 4) and (FSpeedup_Snd_FN <> '')
         and (not LinkedSound[2].Playing) then
        begin
        KillSamp;
        FileName:= FSpeedup_Snd_FN;
        FVolume:= FSpeedup_Snd_Vol;
        Loop:= true;
        StartSound;
        end;
      end; // with LinkedSound[2]
    end
  else
    if (LinkedSound[2].Playing) and (LinkedSound[2].FileName= FSpeedup_Snd_FN) then
      LinkedSound[2].KillSamp;

  if (Transmission> 1) and (TrSpd[Transmission-2]> Speed) then
    ThrottleBack:= true;

  Step(Speed/(1000/GenCycle));
  end // if Throttle
else
  if ((not Braking) or (Speed= 0))
     and ((LinkedSound[2].Playing) and (LinkedSound[2].FileName= FSpeedup_Snd_FN)) then
    LinkedSound[2].KillSamp;

if (ThrottleBack and not Braking) and (Speed> 0) then
  begin
  Speed:= Speed -(0.5*FDynam);
  Step(Speed/(1000/GenCycle));
  exit;
  end; // if ThrottleBack and not Braking

if (Braking) and (Speed> 0) then
  begin
  if TimeCounter< 15 then
    Speed:= Speed -FDynam;
  if TimeCounter in [16..25] then
    Speed:= Speed -(1.5*FDynam);
  if TimeCounter> 25 then
    begin
    if (not LinkedSound[2].Playing) or (LinkedSound[2].FileName<> FBrk_Snd_FN) then
    begin
    with LinkedSound[2] do // Торможение
      begin
      Extr_Braking(true);
      KillSamp;
      FileName:= FBrk_Snd_FN;
      Loop:= true;
      FVolume:= FBrk_Snd_Vol;
      StartSound;
      end; // with LinkedSound[2]
    end; // if not playing
    Speed:= Speed -(3.5*FDynam);
    end; // TimeCounter> 20
  inc(TimeCounter);
  Step(Speed/(1000/GenCycle));
  end // if Braking
else
  TimeCounter:= 0;
end // if Transmission> -1
else
begin
if Throttle then
  begin
  Speed:= Speed +FDynam;
  Step(-Speed/(1000/GenCycle));
  end; // if Throttle
if (ThrottleBack and not Braking) and (Speed> 0) then
  begin
  Speed:= Speed -((0.75*FDynam) +Friction);
  Step(-Speed/(1000/GenCycle));
  exit;
  end; // if ThrottleBack and not Braking
if (Braking) and (Speed> 0) then
  begin
  if TimeCounter< 15 then
    Speed:= Speed -FDynam;
  if TimeCounter in [16..25] then
    Speed:= Speed -(2*FDynam);
  if TimeCounter> 25 then
    begin
    if (not LinkedSound[2].Playing) or (LinkedSound[2].FileName<> FBrk_Snd_FN) then
    begin
    Extr_Braking(true);
    with LinkedSound[2] do // Торможение
      begin
      KillSamp;
      FileName:= FBrk_Snd_FN;
      Loop:= true;
      FVolume:= FBrk_Snd_Vol;
      StartSound;
      end; // with LinkedSound[2]
    end; // if not playing
    Speed:= Speed -(3.5*FDynam);
    end; // TimeCounter> 25
  inc(TimeCounter);
  Step(-Speed/(1000/GenCycle));
  end // if Braking
else
  TimeCounter:= 0;
end; // else Transmission> -1
  end; // proc TCar.Upd

procedure TCar.ToRightSide;
var
  Alph:  integer;

begin
if FOld_AutoCorrectMode= true then
  FOld_AutoCorrectMode:= true
else
  FOld_AutoCorrectMode:= FAutoCorrectMode;
FAutoCorrectMode:= false;

Alph:= round(Engine.Alpha);
if (Alph> 0) and (Alph<= 90) then
  Turn(0,0,true);
if (Alph> 90) and (Alph<= 180) then
  Turn(90,0,true);
if (Alph> 180) and (Alph<= 270) then
  Turn(180,0,true);
if (Alph> 270) or (Alph= 0) then
  begin
  if Alph= 0 then
    Engine.Alpha:= PI_360;
  Turn(270,0,True);
  end;
end; // proc TCar.ToRightSide

procedure TCar.ToLeftSide;
var
  Alph:  integer;

begin
if FOld_AutoCorrectMode= true then
  FOld_AutoCorrectMode:= true
else
  FOld_AutoCorrectMode:= FAutoCorrectMode;
FAutoCorrectMode:= false;

Alph:= round(Engine.Alpha);
if (Alph>= 0) and (Alph< 90) then
  Turn(90,0,true);
if (Alph>= 90) and (Alph< 180) then
  Turn(180,0,true);
if (Alph>= 180) and (Alph< 270) then
  Turn(270,0,true);
if (Alph>= 270) then
  Turn(360,0,True);
end; // proc TCar.ToLeftSide

procedure TCar.AutoCorrect;
begin
if (not FAutoCorrectMode) or (Speed= 0) then exit;

if (Engine.Alpha>= PI_45) and (Engine.Alpha< PI_135) then
  Turn(90,0,true);
if (Engine.Alpha>= PI_135) and (Engine.Alpha< PI_225) then
  Turn(180,0,true);
if (Engine.Alpha>= PI_225) and (Engine.Alpha< PI_315) then
  Turn(270,0,true);
if Engine.Alpha>= PI_315 then
  Turn(360,0,true);
if Engine.Alpha< PI_45 then
  Turn(0,0,true);
end; // proc AutoCorrect

procedure TCar.Set_Turning(NV: boolean);
begin
if (NV= false) and (FOld_AutoCorrectMode= true) then
  begin
  FAutoCorrectMode:= true;
  FOld_AutoCorrectMode:= false;
  end;
FTurning:= NV;
end; // proc TCar.Set_Turning

procedure TCar.Set_AutoCorrectMode(NV: boolean);
begin
if NV= FAutoCorrectMode then exit;
with LinkedSound[1] do
  begin
  KillSamp;
  if NV then
    FileName:= 'sounds\on.mp3'
  else
    FileName:= 'sounds\off.mp3';
  MinDist:= 25;
  FVolume:= 255;
  StartSound;
  end; // with LinkedSound[1]
FAutoCorrectMode:= NV;
end; // proc TCar.Set_AutoCorrectMode

procedure TCar.Set_AutoSaySpeed(NV: boolean);
begin
if NV= FAutoSaySpeed then exit;
with LinkedSound[1] do
  begin
  KillSamp;
  if NV then
    FileName:= 'sounds\on.mp3'
  else
    FileName:= 'sounds\off.mp3';
  MinDist:= 25;
  FVolume:= 255;
  StartSound;
  end; // with LinkedSound[1]
FAutoSaySpeed:= NV;
end; // proc TCar.Set_AutoSaySpeed

procedure TCar.Goto_Start;
var
  I:  integer;

begin
Turning:= false;
with Engine do
  begin
  Set_Posit(Param.St_X,Param.St_Y,Param.St_Z);
  TurnHead(Param.Alpha,0,true);
  end; // with Engine

for I:= 1 to LnkSounds do
  LinkedSound[I].Set_Posit(Param.St_X,Param.St_Y,Param.St_Z);
end; // proc Goto_Start

function TCar.Get_ID:  integer;
begin
Result:= FIdent;
end; // func Get_ID

procedure TCar.Set_Horn(NV:  boolean);
begin
if FHorn_Snd_FN= '' then exit;

if NV then
  begin
  with LinkedSound[5] do
    begin
    KillSamp;
    FileName:= FHorn_Snd_FN;
    Loop:= true;
    FVolume:= FHorn_Snd_Vol;
    StartSound;
    end; // with LinkedSound[5]
  end
else
  LinkedSound[5].KillSamp;

FHorn:= NV;
end; // proc Set_Horn

end. // End of unit

