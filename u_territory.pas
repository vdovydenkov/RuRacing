unit u_territory;

interface
uses classes,
     my_fmod;

const
  MaxEdgeDist= 25; // Расстояние до преграды
  Pnt_Crashing= -1500;

type
  TSnd= class
  public
    North,South,East,West: TFM3DSound;
  end; // TSnd= class

  TTerritoryType= (Edge);
  TTerritory= class
  public
    // Координаты ближнего левого нижнего угла
    Point_X,Point_Y,Point_Z: single;
    // Размеры области
    Size_X,Size_Y,Size_Z: single;
    // Тип территории
    FType: TTerritoryType;
  end; // TTerr= class
  PTerritory= ^TTerritory;

var
  Territory: TList;
  Snd: TSnd;

procedure TerritoriesCreate;
procedure LoadTerritories(FN_INI:  string);
procedure TerritoriesUpdate;
procedure KillTerritories;

implementation
uses IniFiles, SysUtils, fmod, fmodtypes,
     main, u_car, u_param;

procedure TerritoriesCreate;
begin
Territory:= TList.Create;
Snd:= TSnd.Create;
with Snd do
  begin
  North:= TFM3DSound.Create;
  South:= TFM3DSound.Create;
  East:= TFM3DSound.Create;
  West:= TFM3DSound.Create;
  end; // with Snd
end; // proc TerritoriesCreate

procedure LoadTerritories(FN_INI:  string);
const
  SEC_BUILDING= 'BUILDING_';
  IND_POINTX= 'Point_X';
  IND_POINTZ= 'Point_Z';
  IND_SIZEX= 'Size_X';
  IND_SIZEZ= 'Size_Z';

var
  PTerr: PTerritory;
  INI:  TIniFile;
  CurSec:  string;
  I:  integer;

begin
// Определяем звуки
with Snd.North do
  begin
  FileName:= Param.Snd.Border;
  Loop:= true;
  end; // with Snd.North
with Snd.South do
  begin
  FileName:= Param.Snd.Border;
  Loop:= true;
  end; // with Snd.South
with Snd.East do
  begin
  FileName:= Param.Snd.Border;
  Loop:= true;
  end; // with Snd.East
with Snd.West do
  begin
  FileName:= Param.Snd.Border;
  Loop:= true;
  end; // with Snd.West

INI:= TIniFile.Create(FN_INI);
I:= 1;
while INI.SectionExists(SEC_BUILDING+IntToStr(I)) do
  begin
  CurSec:= SEC_BUILDING+IntToStr(I);
  new(PTerr);
  PTerr^:= TTerritory.Create;
  with PTerr^ do
    begin
    Point_X:= INI.ReadInteger(CurSec,IND_POINTX,0);
    Point_Y:= 0;
    Point_Z:= INI.ReadInteger(CurSec,IND_POINTZ,0);
    Size_X:= INI.ReadInteger(CurSec,IND_SIZEX,0);
    Size_Y:= 0;
    Size_Z:= INI.ReadInteger(CurSec,IND_SIZEZ,0);
    FType:= Edge;
    end; // with PTerr^
  Territory.Add(PTerr);
  inc(I);
  end;

INI.Free;
end; // proc LoadTerritories

procedure TerritoriesUpdate;
var
  I: integer;
  LPos: TFSoundVector;
  North_Playing,South_Playing,East_Playing,West_Playing: boolean;

begin
if Territory= NIL then exit;

FSOUND_3D_Listener_GetAttributes(@LPos,NIL,NIL,NIL,NIL,NIL,NIL,NIL);

North_Playing:= false;
South_Playing:= false;
East_Playing:= false;
West_Playing:= false;
for I:= 0 to Territory.Count-1 do
  with PTerritory(Territory.Items[I])^ do
    begin
    case FType of
    Edge:
      begin
      // Проверяем преграду с востока (справа)
      if (LPos.x< Point_X) and (LPos.x> (Point_X -(MaxEdgeDist+Car_Dimensions)))
         and ((LPos.z>= Point_Z) and (LPos.z< (Point_Z+Size_Z))) then
        with Snd.East do
        begin
        East_Playing:= true;
        Set_Posit(Point_X, LPos.y, LPos.z);
        if not Playing then
          StartSound;
        end; // with Snd.East
      // Проверяем ограду с запада (слева)
      if (LPos.x> (Point_X+Size_X)) and (LPos.x< ((Point_X+Size_X) +(MaxEdgeDist+Car_Dimensions)))
         and ((LPos.z>= Point_Z) and (LPos.z< (Point_Z+Size_Z))) then
        with Snd.West do
        begin
        West_Playing:= true;
        Set_Posit((Point_X+Size_X), LPos.y, LPos.z);
        if not Playing then
          StartSound
        end; // with Snd.West
      // Проверяем ограду с севера (сверху)
      if (LPos.z< Point_Z) and (LPos.Z> (Point_Z -(MaxEdgeDist+Car_Dimensions)))
         and ((LPos.x> Point_X) and (LPos.x< (Point_X+Size_X))) then
        with Snd.North do
        begin
        North_Playing:= true;
        Set_Posit(LPos.x, LPos.y, Point_Z);
        if not Playing then
          StartSound;
        end; // with Snd.North
      // Проверяем ограду с юга (снизу)
      if (LPos.z> (Point_Z+Size_Z)) and (LPos.Z< ((Point_Z+Size_Z) +(MaxEdgeDist+Car_Dimensions)))
         and ((LPos.x> Point_X) and (LPos.x< (Point_X+Size_X))) then
        with Snd.South do
        begin
        South_Playing:= true;
        Set_Posit(LPos.x, LPos.y, (Point_Z+Size_Z));
        if not Playing then
          StartSound;
        end; // with Snd.South

      if (LPos.x<= (Point_X+Size_X)) and (LPos.x> Point_X)
         and ((LPos.z>= Point_Z) and (LPos.z<= (Point_Z+Size_Z))) then
          begin
          Points:= Points +Pnt_Crashing;
        Crash(LPos.x,LPos.y,LPos.z,false,-1);
        exit;
        end;
      end; // case FType=Edge
    end; // case FType
    end; // for
if not North_Playing then
  Snd.North.KillSamp;
if not South_Playing then
  Snd.South.KillSamp;
if not East_Playing then
  Snd.East.KillSamp;
if not West_Playing then
  Snd.West.KillSamp;
end; // proc TerritoriesUpdate

procedure KillTerritories;
begin
if Territory= NIL then exit;
Territory.Free; Territory:= NIL;
with Snd do
  begin
  North.Free; North:= NIL;
  South.Free; South:= NIL;
  East.Free; East:= NIL;
  West.Free; West:= NIL;
  end; // with Snd
Snd.Free; Snd:= NIL;
end; // proc KillTerritories

end. // End Of Unit
