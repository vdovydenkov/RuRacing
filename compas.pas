unit compas;

interface
uses fmod, fmodtypes, fmoderrors, fmodpresets,
     my_fmod;

const
  VoiceDistance= 5;

var
  Voc:  TFM3DSound = NIL;
  Voc_X,VOC_Z:  single;

procedure Compas_Init;
procedure SaySide(Corner:  single);
procedure Compas_Update(New_Pos,New_Vel: TFSoundVector);

implementation
uses u_param;

procedure Compas_Init;
begin
Voc:= TFM3DSound.Create;
Voc.MinDist:= 10;
end; // proc Compas_Init

procedure SaySide(Corner:  single);
var
  Posit:  TFSoundVector;

begin
if Voc= NIL then exit;
Voc.KillSamp;

if (Corner>= 45) and (Corner< 135) then
  begin
  Voc.FileName:= Param.Snd.North;
  Voc_X:= 0;
  Voc_Z:= VoiceDistance;
  end
else // Север
  begin
  if (Corner>= 135) and (Corner< 225) then
    begin
    Voc.FileName:= Param.Snd.West;
    Voc_X:= -VoiceDistance;
    Voc_Z:= 0;
    end
  else // Запад
    begin
    if (Corner>= 225) and (Corner< 315) then
      begin
      Voc.FileName:= Param.Snd.South;
      Voc_X:= 0;
      Voc_Z:= -VoiceDistance;
      end
    else // Юг
      begin
      Voc.FileName:= Param.Snd.East;
      Voc_X:= VoiceDistance;
      Voc_Z:= 0;
      end; // if Юг
    end; // if Запад
  end; // if Север

// Берем позицию слушателя
FSOUND_3D_Listener_GetAttributes(@Posit,NIL,NIL,NIL,NIL,NIL,NIL,NIL);
with Voc do
  begin
  Set_Posit(Posit.x+Voc_X,Posit.Y,Posit.z+Voc_Z);
  Loop:= false;
  FVolume:= Param.Snd.Vol_SaySide;
  StartSound;
  end; // with Voc
end; // proc SaySide

procedure Compas_Update(New_Pos,New_Vel: TFSoundVector);
begin
if Voc= NIL then exit;
if not Voc.Playing then exit;

with Voc do
  begin
  Set_Posit(New_Pos.x+Voc_X,New_Pos.y,New_Pos.z+Voc_Z);
  Set_Veloc(New_Vel.x,New_Vel.y,New_Vel.z);
  end; // with Voc
end; // proc Compas_Update

end.
