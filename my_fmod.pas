unit my_fmod;

interface
uses fmod, fmodtypes, fmoderrors, fmodpresets;

type
  // ������������ �����
  // �� ��� ������ �������� ����� "���������" � ������ ������� � ������������
  TFMSound= class(TObject)
  private
    FFileName: string; // ��� ��������� �����
    FSpeed: single; // �������� �������
    FFrequency: integer; // ������� �������������
    FAlpha: single; // ���� �������� � ��������� XZ
    FBeta: single; // ���� �������� � ��������� XY
    FPause:  boolean;

  procedure Set_FileName(FName: string); // ��� �����
  procedure Set_Volume(NewValue: byte); // ���������
  procedure Set_Speed(NewValue: single); // ��������
  procedure Set_Freq(NewValue: longint); // �������
  function Get_Freq: longint; // N������� �������
  procedure Set_Alpha(NV:  single);
  procedure Set_Beta(NV:  single);
  procedure Set_Pause(NV: boolean); VIRTUAL;

  public
    Samp: PFSoundSample; // ����
    Channel: longint; // �����
    FVolume: byte; // ���� - ���������
    FMinDist,FMaxDist: single;
    FSilenceDistance: single; // ��������� ��������
    Loop: boolean; // ����������� �����
    Posit, Velocity: TFSoundVector; // ������� � ������ ��������

  // ��� ��������� �����
  property FileName: string read FFileName write Set_FileName;
  // ���������
  property Volume: byte read FVolume write Set_Volume;
  // ��������
  property Speed: single read FSpeed write Set_Speed;
  // �������
  property Freq: longint read Get_Freq write Set_Freq;
  // ������� �� ��������� (��������� �������)
  property Def_Freq: integer read FFrequency; // ������� �� ���������
  // ���� � ��������� XZ
  property Alpha: single read FAlpha write Set_Alpha;
  // ���� � ��������� XY
  property Beta: single read FBeta write Set_Beta;
  // �����
  property Pause: boolean read FPause write Set_Pause default false;

  constructor Create;
  destructor Destroy; OVERRIDE;
  // ����������� ��������� -  ����� ������
  procedure FM_Error(Err_St: string); VIRTUAL;
  // ����������� ��������� �������� �����
  procedure LoadSamp; VIRTUAL;
  // ����������� ��������� - ������ ����
  procedure Play; VIRTUAL;
  // ������������� �� ����
  function Playing: boolean;
  // ����������� ��������� - ����������� ������� ����� � ������������
  procedure Set_Posit(X,Y,Z: single); VIRTUAL;
  // ����������� ��������� - ����������� ������� ��������
  procedure Set_Veloc(X,Y,Z: single); VIRTUAL;
  // ����������� ������� �� ���� ��������� �� �������� Delta
  // ������ �������� �� ����������, ������ ������� �������
  procedure Move(DX,DY,DZ: single);
  // ����������� ��������� - ����������� ����� � ������������ �� ���� ���
  // ������� �� ����������� ������� ��������
  procedure Step(StepLen: single); VIRTUAL;
  // ���������� ������������
  procedure Stop;
  // ��������� ����� � �������� ���������������
  procedure StartSound;
  // ������������� ������������ � ����������� ������ �� ������
  procedure KillSamp;
  end; // TFMSound= class

  // ����� "���������"
  TFMListenerSound= class(TFMSound)
  private

  procedure Set_Pause(NV: boolean); OVERRIDE;

  public

  // �������� �����
  procedure LoadSamp; OVERRIDE;
  // ������������
  procedure Play; OVERRIDE;
  //
  procedure SetHead(Gor,Vert: integer);
  // ������� "������" ���������
  // ���������:  ��������� ���� ���� �������� �� ����������� � �� ���������
  // ������ �� ��� OX
  // Absolut -  ������������ �� ������������ �������� ����, ��� ������� ���������� �������� ������� �����������
  procedure TurnHead(Gor,Vert: single;Absolut: boolean);
  // ����������� ������� "���������" ��� ����� � ��� ��������� ������� ��������
  procedure Set_Posit(X,Y,Z: single); OVERRIDE;
  // ��������� ��������� ������ ����� ������� ��������
  procedure Set_Veloc(X,Y,Z: single); OVERRIDE;
  // ��� "���������" � ����������� ������� ��������
  procedure Step(StepLen: single); OVERRIDE;
  end; // TFMListenerSound = class

  // ����� ������ � ������������
  TFM3DSound= class(TFMSound)
  private

  procedure Set_Min_Dist(NV: single);
  procedure Set_Max_Dist(NV: single);
  function GetListenerDistance: single; // ���������� �� ���������
  procedure Set_Pause(NV: boolean); OVERRIDE;

  public

  property MinDist: single read FMinDist write Set_Min_Dist;
  property MaxDist: single read FMaxDist write Set_Max_Dist;
  property ListenerDistance: single read GetListenerDistance;

  // �������� �����
  procedure LoadSamp; OVERRIDE;
  // ������������
  procedure Play; OVERRIDE;
  // ������� ������ ����� (0,0,0)
  // ���������: ������ � ���� ��������
  procedure Turn(Radius,T,CX,CY,CZ: single);
  // ��������� ������� ������� � ������������
  // ������ �������� �� �����������
  procedure Set_Posit(X,Y,Z: single); OVERRIDE;
  // ��������� ��������� ������ ����� ������� ��������
  procedure Set_Veloc(X,Y,Z: single); OVERRIDE;
  // ��� ������� � ����������� ������� ��������
  procedure Step(StepLen: single); OVERRIDE;
  end; // TFM3DSound= class(TFMSound)


implementation
uses SysUtils, Dialogs, math,
     my_math;

constructor TFMSound.Create;
begin
FFileName:= '';
FVolume:= 255;
Set_Posit(0,0,0);
Alpha:= 90;
Speed:= 0;
FMinDist:= 2.0;
FMaxDist:= 1000;
FSilenceDistance:= 2000;
end; // constr TFMSound.Create

destructor TFMSound.Destroy;
begin
if Samp <> NIL then
  begin
  FSOUND_Sample_Free(Samp);
  Samp:= NIL;
  end; // if Samp <> NIL
end; // destr TFMListenerSound.Destroy

function TFMSound.Playing: boolean;
begin
if Channel= 0 then
  Result:= false
else
  Result:= FSOUND_IsPlaying(Channel);
end; // func TFMSound.Playing

procedure TFMSound.Set_FileName(FName: string);
begin
if FileExists(FName) then
  FFileName:= FName
else
  FFileName:= '';
end; // proc TFMSound.Set_FileName

procedure TFMSound.Set_Volume(NewValue: byte);
begin
if Channel= 0 then exit;
FSOUND_SetVolume(Channel, NewValue);
FVolume:= NewValue;
end; // proc TFMSound.Set_Volume

procedure TFMSound.Set_Posit(X,Y,Z: single); // VIRTUAL
begin
end; // proc TFMSound.Set_Posit

procedure TFMSound.Set_Veloc(X,Y,Z: single); // VIRTUAL
begin
end; // proc TFMSound.Set_Veloc

procedure TFMSound.Step(StepLen: single); // VIRTUAL
begin
end; // proc TFMSound.Step

procedure TFMSound.Move(DX,DY,DZ: single);
begin
Set_Posit(Posit.x +DX, Posit.y +DY, Posit.z +DZ);
end; // proc TFMSound.Move

procedure TFMSound.LoadSamp; // VIRTUAL
begin
end; // proc TFMSound.LoadSamp

procedure TFMSound.Play; // VIRTUAL
begin
end; // proc TFMSound.Play

procedure TFMSound.FM_Error(Err_St: string); // VIRTUAL
begin
end; // TFMSound.FM_Error

procedure TFMSound.Set_Speed(NewValue: single);
begin
// ���� ����� �������� ������ ��� ����� ����
if NewValue<= 0 then
  begin
  FSpeed:= 0;
  // �������� ������ ��������
  Set_Veloc(0,0,0);
  exit;
  end; // if NewValue <= 0

FSpeed:= NewValue;

// ������������ ������ �������� �� ���� �����
Velocity.X:= FSpeed * CosTbl[round(Alpha)];
Velocity.Z:= FSpeed * SinTbl[round(Alpha)];
// ������ ������ �������� ��������� ����, ���� ��� ��������� � ���������
// ��� � ��� ����� ����� ������ �������� ��������
with Velocity do
  Set_Veloc(X,Y,Z);
end; // proc TFMSound.Set_Speed

procedure TFMSound.Set_Freq(NewValue: longint);
begin
if Channel= 0 then exit;
FSOUND_SetFrequency(Channel,NewValue);
end; // proc TFMSound.Set_Freq

function TFMSound.Get_Freq: longint;
begin
Result:= 0;
if Channel = 0 then exit;
Result:= FSOUND_GetFrequency(Channel);
end; // func TFMSound.Get_Freq

procedure TFMSound.Stop;
begin
if Channel= 0 then exit;
FSOUND_StopSound(Channel);
end; // proc TFMSound.Stop

procedure TFMSound.KillSamp;
begin
if Samp= NIL then exit;
if Playing then
  Stop;
FSOUND_Sample_Free(Samp);
Samp:= NIL;
end; // proc TFMSound.KillSamp

procedure TFMSound.StartSound;
begin
LoadSamp;
Play;
end; // proc TFMSound.StartSound


// * TFMListenerSound *
procedure TFMListenerSound.LoadSamp; // OVERRIDE
begin
Samp:= FSOUND_Sample_Load(FSOUND_UNMANAGED, PChar(FileName), FSOUND_2D, 0, 0);
if Samp= NIL then
  FM_Error(FileName+' : '+FMOD_ErrorString(FSOUND_GetError()));
end; // proc TFMListenerSound.LoadSamp

procedure TFMListenerSound.Play; // OVERRIDE
begin
if (Samp= NIL) or (Playing) then exit;
Channel:= FSOUND_PlaySoundEx(FSOUND_FREE, Samp, NIL, true);
FFrequency:= FSOUND_GetFrequency(Channel);
FSOUND_SetVolume(Channel, FVolume);
if Loop then
  FSOUND_SetLoopMode(Channel, FSOUND_LOOP_NORMAL)
else
  FSOUND_SetLoopMode(Channel, FSOUND_LOOP_OFF);
FSOUND_SetPaused(Channel,false);
end; // proc TFMListenerSound.Play

procedure TFMListenerSound.SetHead(Gor,Vert: integer);
var
  Coord_X, Coord_Z: single;
  FX,FY,FZ,TX,TY,TZ: single;

begin
Alpha:= Gor;

Coord_X:= CosTbl[round(Alpha)];
Coord_Z:= SinTbl[round(Alpha)];
FSOUND_3D_Listener_GetAttributes(NIL, NIL, @FX, @FY, @FZ, @TX, @TY, @TZ);
FSOUND_3D_Listener_SetAttributes(NIL,NIL, Coord_X, FY, Coord_Z, TX, TY, TZ);
end; // proc TFMListenerSound.SetHead

procedure TFMListenerSound.TurnHead(Gor,Vert: single;Absolut: boolean);
var
  FX,FY,FZ,TX,TY,TZ: single;

begin
if Absolut then
  Alpha:= Gor
else
  // ����������� ���� �������� �� �������� ����
  Alpha:= Alpha +Gor;

// ����� ������� �������� forward � top �������
FSOUND_3D_Listener_GetAttributes(NIL, NIL, @FX, @FY, @FZ, @TX, @TY, @TZ);

// ����� ���������� �������� ������������� ��������� �������
// ����� ������� �������� (�������� Speed) �������� ��������
Velocity.X:= Speed * CosTbl[round(Alpha)];
Velocity.z:= Speed * SinTbl[round(Alpha)];
// ����������� ������� forward �������
// ��� ����� (������) ����� �������
FX:= cosTbl[round(Alpha)];
FZ:= SinTbl[round(Alpha)];
// ��������� ����� ��������
FSOUND_3D_Listener_SetAttributes(NIL, @Velocity, FX, FY, FZ, TX, TY, TZ);
end; // proc TFMListenerSound.TurnHead

procedure TFMListenerSound.Set_Posit(X,Y,Z: single); // OVERRIDE
var
  FX,FY,FZ,TX,TY,TZ: single;

begin
Posit.X:= X; Posit.Y:= Y; Posit.Z:= Z;
FSOUND_3D_Listener_GetAttributes(NIL, NIL, @FX, @FY, @FZ, @TX, @TY, @TZ);
FSOUND_3D_Listener_SetAttributes(@Posit, NIL, FX, FY, FZ, TX, TY, TZ);
end; // proc TFMListenerSound.Set_Posit

procedure TFMListenerSound.Set_Veloc(X,Y,Z: single); // OVERRIDE
var
  FX,FY,FZ,TX,TY,TZ: single;

begin
// ����� ������� �������� forward ������� � top �������
FSOUND_3D_Listener_GetAttributes(NIL, NIL, @FX, @FY, @FZ, @TX, @TY, @TZ);
// ����������� ����� �������� ������� ��������
Velocity.X:= X; Velocity.Y:= Y; Velocity.Z:= Z;
// ������ ����� ��������
FSOUND_3D_Listener_SetAttributes(NIL, @Velocity, FX, FY, FZ, TX, TY, TZ);
end; // proc TFMListenerSound.Set_Veloc

procedure TFMListenerSound.Step(StepLen: single); // OVERRIDE
var
  FX,FY,FZ,TX,TY,TZ: single;
  K: single;

begin
if StepLen = 0 then exit;
// ����� ������� �������� forward ������� � top �������
FSOUND_3D_Listener_GetAttributes(NIL, NIL, @FX, @FY, @FZ, @TX, @TY, @TZ);
// ������������ �����������
// �� ����� ����� ������� �������� �������� �� ����� ������� ��������
K:= StepLen / Speed;
// � ����������� ������� ������� ���������� ���������� ������� ��������
// ����������� �� �����������
with Posit do
  begin
  X:= X +(K*Velocity.x);
  Y:= Y +(K*Velocity.y);
  Z:= Z +(K*Velocity.z);
  end; // with Posit
FSOUND_3D_Listener_SetAttributes(@Posit,NIL, FX, FY, FZ, TX, TY, TZ);
end; // proc TFMListenerSound.Step

procedure TFMListenerSound.Set_Pause(NV: boolean); // OVERRIDE
begin
if NV= FPause then exit;

if NV= true then
  begin
  if Playing then
    FSOUND_SetPaused(Channel,true)
  else
    begin
    if Samp= NIL then
      LoadSamp;
    Channel:= FSOUND_PlaySoundEx(FSOUND_FREE, Samp, NIL, true);
    FFrequency:= FSOUND_GetFrequency(Channel);
    FSOUND_SetVolume(Channel, FVolume);
    if Loop then
      FSOUND_SetLoopMode(Channel, FSOUND_LOOP_NORMAL)
    else
      FSOUND_SetLoopMode(Channel, FSOUND_LOOP_OFF);
    end; // else Playing
  end // if NV= true
else
  FSOUND_SetPaused(Channel,false);

FPause:= NV;
end; // proc TFMListenerSound.Set_Pause

// * TFM3DSound *
procedure TFM3DSound.LoadSamp; // OVERRIDE
begin
Samp:= FSOUND_Sample_Load(FSOUND_FREE, PChar(FileName), FSOUND_HW3D, 0, 0);
if Samp= NIL then
  FM_Error(FileName+' : '+FMOD_ErrorString(FSOUND_GetError()));
end; // proc TFM3DSound.LoadSamp

procedure TFM3DSound.Play; // OVERRIDE
begin
if (Samp= NIL) or (Playing) then exit;
FSOUND_Sample_SetMinMaxDistance(Samp,FMinDist,FMaxDist);
Channel:= FSOUND_PlaySoundEx(FSOUND_FREE, Samp, NIL, true);
FFrequency:= FSOUND_GetFrequency(Channel);
FSOUND_3D_SetAttributes(Channel,@Posit,@Velocity);
FSOUND_SetVolume(Channel, FVolume);
if Loop then
  FSOUND_SetLoopMode(Channel, FSOUND_LOOP_NORMAL)
else
  FSOUND_SetLoopMode(Channel, FSOUND_LOOP_OFF);
if FSilenceDistance> ListenerDistance then
  FSOUND_SetPaused(Channel,false);
end; // proc TFM3DSound.Play

procedure TFM3DSound.Turn(Radius,T,CX,CY,CZ: single);
var
  Coord_X, Coord_Z: single;

begin
Alpha:= Alpha +T;

Coord_X:= Radius * CosTbl[round(Alpha)];
Coord_Z:= Radius * SinTbl[round(Alpha)];
Set_Posit(Coord_X +CX,Posit.Y,Coord_Z +CZ);
end; // proc TFM3DSound.Turn

procedure TFM3DSound.Set_Posit(X,Y,Z: single); // OVERRIDE
begin
Posit.X:= X; Posit.Y:= Y; Posit.Z:= Z;
if Channel> 0 then
  FSOUND_3D_SetAttributes(Channel, @Posit, NIL);
end; // proc TFM3DSound.Set_Posit

procedure TFM3DSound.Set_Veloc(X,Y,Z: single); // OVERRIDE
begin
if Channel= 0 then exit;
Velocity.X:= X; Velocity.Y:= Y; Velocity.Z:= Z;
FSOUND_3D_SetAttributes(Channel, NIL, @Velocity);
end; // proc TFM3DSound.Set_Veloc

procedure TFM3DSound.Step(StepLen: single); // OVERRIDE
var
  K: single;

begin
if StepLen = 0 then exit;
// ������������ �����������
// �� ����� ����� ������� �������� �������� �� ����� ������� ��������
K:= StepLen / Speed;
// � ����������� ������� ������� ���������� ���������� ������� ��������
// ����������� �� �����������
with Posit do
  begin
  X:= X +(K*Velocity.x);
  Y:= Y +(K*Velocity.y);
  Z:= Z +(K*Velocity.z);
  end; // with Posit
FSOUND_3D_SetAttributes(Channel, @Posit, NIL);
end; // proc TFM3DSound.Step

procedure TFM3DSound.Set_Min_Dist(NV: single);
begin
if NV< 0 then exit;
FMinDist:= NV;
if Samp= NIL then exit;
FSOUND_Sample_SetMinMaxDistance(Samp,FMinDist,FMaxDist);
end; // proc TFM3DSound.Set_Min_Dist

procedure TFM3DSound.Set_Max_Dist(NV: single);
begin
if NV< 0 then exit;
FMaxDist:= NV;
if Samp= NIL then exit;
FSOUND_Sample_SetMinMaxDistance(Samp,FMinDist,FMaxDist);
end; // proc TFM3DSound.Set_Max_Dist

function TFM3DSound.GetListenerDistance: single;
// ���������� ���������� �� ���������
var
  LPos: TFSoundVector; // ������� ���������

begin
Result:= 0;
if Self= NIL then exit;
FSOUND_3D_Listener_GetAttributes(@LPos,NIL,NIL,NIL,NIL,NIL,NIL,NIL);
with Posit do
  Result:= sqrt(sqr(x -LPos.x) +sqr(y -LPos.y) +sqr(z -LPos.z));
end; // func TFM3DSound.GetListenerDistance

procedure TFM3DSound.Set_Pause(NV: boolean); // OVERRIDE;
begin
if NV= FPause then exit;

if NV= true then
  begin
  if Playing then
    FSOUND_SetPaused(Channel,true)
  else
    begin
    if Samp= NIL then
      LoadSamp;
    FSOUND_Sample_SetMinMaxDistance(Samp,FMinDist,FMaxDist);
    Channel:= FSOUND_PlaySoundEx(FSOUND_FREE, Samp, NIL, true);
    FFrequency:= FSOUND_GetFrequency(Channel);
    FSOUND_3D_SetAttributes(Channel,@Posit,@Velocity);
    FSOUND_SetVolume(Channel, FVolume);
    if Loop then
      FSOUND_SetLoopMode(Channel, FSOUND_LOOP_NORMAL)
    else
      FSOUND_SetLoopMode(Channel, FSOUND_LOOP_OFF);
    end; // else Playing
  end // if NV= true
else

  if FSilenceDistance> ListenerDistance then
    FSOUND_SetPaused(Channel,false);

FPause:= NV;
end; // proc TFM3DSound.Set_Pause

procedure TFMSound.Set_Alpha(NV: single);
begin
while NV< 0 do
  NV:= NV +360;
while NV> 359 do
  NV:= NV -360;

FAlpha:= NV;
end; // proc TFMSound.Set_Alpha

procedure TFMSound.Set_Beta(NV: single);
begin
FBeta:= NV;
end; // proc TFMSound.Set_Beta

procedure TFMSound.Set_Pause(NV: boolean);
begin
end; // TFMSound.Set_Pause

end. // End of unit

