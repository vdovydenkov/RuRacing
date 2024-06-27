unit world;

interface
uses classes,
     my_fmod;

const
  // Тип объектов
  Static= 0; // Неподвижный
  Dynamic= 1; // Движущийся
  Cyrc= 2; // Кружащийся
  Exploding= 3; // Взрывается
  Burning= 4; // Горит
  Linked= 5; // Связаный со слушателем
  // Периодичность обновления
  WorldUpdateTime= 55; // В миллисекундах

type
  PFM3DSound= ^TFM3DSound;
  TObjWorld= class(TFM3DSound)
  public
    FType: integer; // Тип объекта
    Final:  boolean;
    Labs:  integer;
    Next_Lab_Snd:  string;
    Next_Lab_Vol:  integer;
    Start_X,Start_Y,Start_Z: single;
    Finish_X,Finish_Y,Finish_Z: single; // Конечная точка
    AllWaySize:  single;
    // Радиус поворота для кружащегося объекта
    Cyrc_Radius: single;
    // Угол поворота для кружащегося объекта
    Cyrc_Corner: integer;
    Cyrc_X,Cyrc_Y,Cyrc_Z: single; // Центр вращения
    ObjSize: single; // Размер объекта в метрах
    // Если объект большой -  меняется алгоритм расчета его "точки звука"
    Big:  boolean;
    CanExplode: boolean;
    FN_Expl: string[128];
    FN_Burn: string[128];
    TextName: string[30];
    Cycle: longint;
    Reflex_Dist: integer;
    PReflex: PFM3DSound;
    OPoints:  integer;
    Numb:  byte;

  constructor Create;
  end; // TObjWorld= class(TFM3DSound)
  PObjWorld= ^TObjWorld;

var
  Obj: TList;

procedure WorldCreate;
procedure LoadWorld(FN_INI:  string);
procedure KillWorld;
procedure Train(SX,SY,SZ,FX,FY,FZ,TSpeed: single);
procedure WorldUpdate;

implementation
uses IniFiles, math, SysUtils, fmod, fmodtypes,
     main, u_param, my_utils;

var
  TrainSound:  ^string = NIL;

procedure WorldCreate;
begin
Obj:= TList.Create;
end; // proc WorldCreate

procedure LoadWorld(FN_INI:  string);
const
  SEC_DYNAMIC= 'DYNAMIC_';
  SEC_STATIC= 'STATIC_';
  SEC_CYRC= 'CYRC_';
  SEC_LINKED= 'LINKED_';
  SEC_TRAIN= 'TRAIN';
  IND_TITLE= 'Title';
  IND_SOUNDNAME=  'SoundName';
  IND_FINAL= 'IsFinal';
  IND_LABS= 'Labs';
  IND_SOUNDNEXTLAB= 'NextLabSound';
  IND_SOUNDNEXTLABVOL= 'NextLabVolume';
  IND_START=  'Start';
  IND_STARTX=  'Start_X';
  IND_STARTY=  'Start_Y';
  IND_STARTZ=  'Start_Z';
  IND_FINISH=  'Finish';
  IND_FINISHX= 'Finish_X';
  IND_FINISHY=  'Finish_Y';
  IND_FINISHZ= 'Finish_Z';
  IND_RNDSTART= 'RandomStart';
  IND_CYCLE= 'Cycle';
  IND_MINDIST= 'MinDistance';
  IND_MAXDIST= 'MaxDistance';
  IND_OBJSIZE= 'ObjSize';
  IND_BIG=  'Big';
  IND_CANEXPLODE= 'Exploding';
  IND_SOUNDEXPL= 'ExplSound';
  IND_SOUNDBURN= 'BurnSound';
  IND_SPEED= 'Speed';
  IND_SELDISTANCE= 'SilenceDistance';
  IND_CYRCRADIUS= 'Radius';
  IND_CYRC= 'Cyrc_Center';
  IND_REFL_DIST= 'Reflex_Distance';
  IND_REFL_SND= 'Reflex_Sound';
  IND_REFL_LOOP= 'Reflex_Loop';
  IND_REFL_VOL= 'Reflex_Volume';
  IND_PNT= 'Points';
  IND_POINT=  'Point';

var
  PObj: PObjWorld;
  I: integer;
  INI:  TIniFile;
  CurSec:  string;
  BX,BZ:  single;
  TmpSpeed:  integer;
  Tmp_Refl_Snd: string;
  SX,SY,SZ,FX,FY,FZ: single;
  RndX,RndY,RndZ:  single;
  St:  string;

begin
INI:= TIniFile.Create(FN_INI);

if INI.SectionExists('WORLD') then
  with Param do
  begin
  St:= INI.ReadString('WORLD','Car_Start','0,0,0');
  StrToSingles(St,St_X,St_Y,St_Z);
  St:= INI.ReadString('WORLD','Center','0,0,0');
  StrToSingles(St,C_X,C_Y,C_Z);
  Alpha:= INI.ReadInteger('WORLD','Car_Alpha',90);
  Snd.Border:= INI.ReadString('WORLD','Border','sounds\edge.wav');
  end; // if INI.SectionExists('WORLD')

Randomize;
I:= 1;
while INI.SectionExists(SEC_DYNAMIC+IntToStr(I)) do
  begin
  CurSec:= SEC_DYNAMIC+IntToStr(I);
  new(PObj); // Отводим место под объект
  PObj^:= TObjWorld.Create; // Инициируем
  with PObj^ do
    begin
    FType:= DYNAMIC;
    TextName:= INI.ReadString(CurSec,IND_TITLE,'Неопознан');
    FileName:= INI.ReadString(CurSec,IND_SOUNDNAME,'');
    Final:= INI.ReadBool(CurSec,IND_FINAL,false);
    St:= INI.ReadString(CurSec,IND_START,'0,0,0');
    StrToSingles(St,Start_X,Start_Y,Start_Z);
    TmpSpeed:= INI.ReadInteger(CurSec,IND_SPEED,0);
    if TmpSpeed> 0 then
      begin
      St:= INI.ReadString(CurSec,IND_FINISH,'0,0,0');
      StrToSingles(St,Finish_X,Finish_Y,Finish_Z);
      AllWaySize:= sqrt(sqr(Finish_X -Start_X) +sqr(Finish_Y -Start_Y) +sqr(Finish_Z -Start_Z));
      // Расчитываем угол альфа, под которым объект
      // движется относительно оси OX.
      // Для этого расчитываем условный вектор скорости
      // То есть, переносим начальную точку в начало координат (0,0)
      // и расчитываем координаты конечной точки.
      BX:= Finish_X -Start_X;
      BZ:= Finish_Z -Start_Z;
      // Угол равен арктангенсу результата от деления Z на X
      if BX>= 0 then
        Alpha:= Round(RadToDeg(ArcTan(BZ/BX)))
      else // Плюс Пи для второй и третьей четверти
        Alpha:= Round(RadToDeg(ArcTan(BZ/BX))) +180;
      end; // TmpSpeed> 0

    if (Param.NetMenu= 0) and (INI.ReadBool(CurSec,IND_RNDSTART,true)) then
      begin
      RndX:= random(abs(round(Finish_X-Start_X)));
      RndY:= random(abs(round(Finish_Y-Start_Y)));
      RndZ:= random(abs(round(Finish_Z-Start_Z)));
      if Start_X> Finish_X then RndX:= -RndX;
      if Start_Y> Finish_Y then RndY:= -RndY;
      if Start_Z> Finish_Z then RndZ:= -RndZ;
      set_posit(Start_X+RndX,Start_Y+RndY,Start_Z+RndZ);
      end
    else
      set_posit(Start_X,Start_Y,Start_Z);

    Cycle:= INI.ReadInteger(CurSec,IND_CYCLE,1);
    FMinDist:= INI.ReadInteger(CurSec,IND_MINDIST,1);
    FMaxDist:= INI.ReadInteger(CurSec,IND_MAXDIST,1000);
    FSilenceDistance:= INI.ReadInteger(CurSec,IND_SELDISTANCE,800);
    ObjSize:= INI.ReadInteger(CurSec,IND_OBJSIZE,1);
    Big:= INI.ReadBool(CurSec,IND_BIG,false);
    CanExplode:= INI.ReadBool(CurSec,IND_CANEXPLODE,false);
    FN_Expl:= INI.ReadString(CurSec,IND_SOUNDEXPL,'');
    if not FileExists(FN_Expl) then
      CanExplode:= false;
    FN_Burn:= INI.ReadString(CurSec,IND_SOUNDBURN,'');
    if (Final) and (not CanExplode) then
      begin
      Labs:= INI.ReadInteger(CurSec,IND_LABS,1);
      Next_Lab_Snd:= INI.ReadString(CurSec,IND_SOUNDNEXTLAB,'');
      Next_Lab_Vol:= INI.ReadInteger(CurSec,IND_SOUNDNEXTLABVOL,255);
      end;
    Reflex_Dist:= INI.ReadInteger(CurSec,IND_REFL_DIST,5);
    Tmp_Refl_Snd:= INI.ReadString(CurSec,IND_REFL_SND,'');
    if not FileExists(Tmp_Refl_Snd) then
      Reflex_Dist:= 0
    else
      begin
      new(PReflex);
      PReflex^:= TFM3DSound.Create;
      with PReflex^ do
        begin
        FileName:= Tmp_Refl_Snd;
        Loop:= INI.ReadBool(CurSec,IND_REFL_LOOP,true);
        FVolume:= INI.ReadInteger(CurSec,IND_REFL_VOL,255);
        FMinDist:= PObj^.FMinDist;
        FMaxDist:= PObj^.FMaxDist;
        end; // with PReflex^
      end;
    OPoints:= INI.ReadInteger(CurSec,IND_PNT,-3000);
    Speed:= TmpSpeed;
    end;
  // Добавляем объект в список
  Obj.Add(PObj);
  inc(I);
  end; // while INI.SectionExists(SEC_DYNAMIC+IntToStr(I))

  // Секция статических объектов
I:= 1;
while INI.SectionExists(SEC_STATIC+IntToStr(I)) do
  begin
  CurSec:= SEC_STATIC+IntToStr(I);
  new(PObj); // Отводим место под объект
  PObj^:= TObjWorld.Create; // Инициируем
  with PObj^ do
    begin
    FType:= STATIC;
    TextName:= INI.ReadString(CurSec,IND_TITLE,'Неопознан');
    FileName:= INI.ReadString(CurSec,IND_SOUNDNAME,'');
    Final:= INI.ReadBool(CurSec,IND_FINAL,false);
    St:= INI.ReadString(CurSec,IND_START,'0,0,0');
    StrToSingles(St,Start_X,Start_Y,Start_Z);
    set_posit(Start_X,Start_Y,Start_Z);
    FMinDist:= INI.ReadInteger(CurSec,IND_MINDIST,1);
    FMaxDist:= INI.ReadInteger(CurSec,IND_MAXDIST,1000);
    FSilenceDistance:= INI.ReadInteger(CurSec,IND_SELDISTANCE,800);
    ObjSize:= INI.ReadInteger(CurSec,IND_OBJSIZE,1);
    Big:= INI.ReadBool(CurSec,IND_BIG,false);
    CanExplode:= INI.ReadBool(CurSec,IND_CANEXPLODE,false);
    FN_Expl:= INI.ReadString(CurSec,IND_SOUNDEXPL,'');
    if not FileExists(FN_Expl) then
      CanExplode:= false;
    FN_Burn:= INI.ReadString(CurSec,IND_SOUNDBURN,'');
    if (Final) and (not CanExplode) then
      begin
      Labs:= INI.ReadInteger(CurSec,IND_LABS,1);
      Next_Lab_Snd:= INI.ReadString(CurSec,IND_SOUNDNEXTLAB,'');
      Next_Lab_Vol:= INI.ReadInteger(CurSec,IND_SOUNDNEXTLABVOL,255);
      end;
    Reflex_Dist:= INI.ReadInteger(CurSec,IND_REFL_DIST,5);
    Tmp_Refl_Snd:= INI.ReadString(CurSec,IND_REFL_SND,'');
    if not FileExists(Tmp_Refl_Snd) then
      Reflex_Dist:= 0
    else
      begin
      new(PReflex);
      PReflex^:= TFM3DSound.Create;
      with PReflex^ do
        begin
        FileName:= Tmp_Refl_Snd;
        Loop:= INI.ReadBool(CurSec,IND_REFL_LOOP,true);
        FVolume:= INI.ReadInteger(CurSec,IND_REFL_VOL,255);
        FMinDist:= PObj^.FMinDist;
        FMaxDist:= PObj^.FMaxDist;
        end; // with PReflex^
      end;
    OPoints:= INI.ReadInteger(CurSec,IND_PNT,-1500);
    end;
  // Добавляем объект в список
  Obj.Add(PObj);
  inc(I);
  end; // while INI.SectionExists(SEC_DYNAMIC+IntToStr(I))

// Секция кружащихся объектов
I:= 1;
while INI.SectionExists(SEC_CYRC+IntToStr(I)) do
  begin
  CurSec:= SEC_CYRC+IntToStr(I);
  new(PObj); // Отводим место под объект
  PObj^:= TObjWorld.Create; // Инициируем
  with PObj^ do
    begin
    FType:= CYRC;
    Final:= INI.ReadBool(CurSec,IND_FINAL,false);
    TextName:= INI.ReadString(CurSec,IND_TITLE,'Неопознан');
    FileName:= INI.ReadString(CurSec,IND_SOUNDNAME,'');
    Cyrc_Radius:= INI.ReadInteger(CurSec,IND_CYRCRADIUS,1);
    St:= INI.ReadString(CurSec,IND_CYRC,'0,0,0');
    StrToSingles(St,Cyrc_X,Cyrc_Y,Cyrc_Z);
    Start_X:= Cyrc_X; Start_Y:= Cyrc_Y; Start_Z:= Cyrc_Radius +Cyrc_Z;
    set_posit(Start_X,Start_Y,Start_Z);
    Cycle:= INI.ReadInteger(CurSec,IND_CYCLE,1);
    FMinDist:= INI.ReadInteger(CurSec,IND_MINDIST,1);
    FMaxDist:= INI.ReadInteger(CurSec,IND_MAXDIST,1000);
    FSilenceDistance:= INI.ReadInteger(CurSec,IND_SELDISTANCE,800);
    ObjSize:= INI.ReadInteger(CurSec,IND_OBJSIZE,1);
    Big:= INI.ReadBool(CurSec,IND_BIG,false);
    CanExplode:= INI.ReadBool(CurSec,IND_CANEXPLODE,false);
    FN_Expl:= INI.ReadString(CurSec,IND_SOUNDEXPL,'');
    if not FileExists(FN_Expl) then
      CanExplode:= false;
    FN_Burn:= INI.ReadString(CurSec,IND_SOUNDBURN,'');
    if (Final) and (not CanExplode) then
      begin
      Labs:= INI.ReadInteger(CurSec,IND_LABS,1);
      Next_Lab_Snd:= INI.ReadString(CurSec,IND_SOUNDNEXTLAB,'');
      Next_Lab_Vol:= INI.ReadInteger(CurSec,IND_SOUNDNEXTLABVOL,255);
      end;
    Speed:= INI.ReadInteger(CurSec,IND_SPEED,0);
    // Расчитываем угол поворота в единицу времени равную
    // времени обновления окружающего мира
    Cyrc_Corner:= round((360/((2*PI*Cyrc_Radius)/Speed))/(1000/WorldUpdateTime));
    Reflex_Dist:= INI.ReadInteger(CurSec,IND_REFL_DIST,5);
    Tmp_Refl_Snd:= INI.ReadString(CurSec,IND_REFL_SND,'');
    if not FileExists(Tmp_Refl_Snd) then
      Reflex_Dist:= 0
    else
      begin
      new(PReflex);
      PReflex^:= TFM3DSound.Create;
      with PReflex^ do
        begin
        FileName:= Tmp_Refl_Snd;
        Loop:= INI.ReadBool(CurSec,IND_REFL_LOOP,true);
        FVolume:= INI.ReadInteger(CurSec,IND_REFL_VOL,255);
        FMinDist:= PObj^.FMinDist;
        FMaxDist:= PObj^.FMaxDist;
        end; // with PReflex^
      end;
    OPoints:= INI.ReadInteger(CurSec,IND_PNT,-3000);
    end;
  // Добавляем объект в список
  Obj.Add(PObj);
  inc(I);
  end; // while INI.SectionExists(SEC_CYRC+IntToStr(I))

// Поезд
if INI.SectionExists(SEC_TRAIN) then
  begin
  St:= INI.ReadString(SEC_TRAIN,IND_START,'0,0,0');
  StrToSingles(St,SX,SY,SZ);
  TmpSpeed:= INI.ReadInteger(SEC_TRAIN,IND_SPEED,0);
  St:= INI.ReadString(SEC_TRAIN,IND_FINISH,'0,0,0');
  StrToSingles(St,FX,FY,FZ);

  St:= INI.ReadString(SEC_TRAIN,IND_SOUNDNAME,'');
  if FileExists(St) then
    begin
    new(TrainSound);
    TrainSound^:= St;
    end;

  Train(SX,SY,SZ,FX,FY,FZ,TmpSpeed);
  end; // if INI.SectionExists(SEC_TRAIN)

// Секция привязаных к слушателю объектов
I:= 1;
while INI.SectionExists(SEC_LINKED+IntToStr(I)) do
  begin
  CurSec:= SEC_LINKED+IntToStr(I);
  new(PObj); // Отводим место под объект
  PObj^:= TObjWorld.Create; // Инициируем
  with PObj^ do
    begin
    FType:= LINKED;
    TextName:= INI.ReadString(CurSec,IND_TITLE,'Неопознан');
    FileName:= INI.ReadString(CurSec,IND_SOUNDNAME,'');
    St:= INI.ReadString(CurSec,IND_POINT,'0,0,0');
    StrToSingles(St,Start_X,Start_Y,Start_Z);
    set_posit(Start_X,Start_Y,Start_Z);
    FMinDist:= INI.ReadInteger(CurSec,IND_MINDIST,1);
    FMaxDist:= INI.ReadInteger(CurSec,IND_MAXDIST,1000);
    end;
  // Добавляем объект в список
  Obj.Add(PObj);
  inc(I);
  end; // while INI.SectionExists(SEC_LINKED+IntToStr(I))

INI.Free;

for I:= 0 to Obj.Count-1 do
  with PObjWorld(Obj.Items[I])^ do
    begin
    LoadSamp;
    if PReflex<> NIL then
      PReflex^.LoadSamp;
    end;
end; // proc LoadWorld

procedure KillWorld;
var
  I: integer;

begin
if Obj<> NIL then
  begin
  for I:= 0 to Obj.Count-1 do
    with PObjWorld(Obj.Items[I])^ do
    begin
    if PReflex<> NIL then
      begin
      PReflex^.Free;
      PReflex:= NIL;
      end;
    PObjWorld(Obj.Items[I])^.Free;
    end; // for
  Obj.Free;
  Obj:= NIL;
  end;

end; // proc KillWorld

procedure Train(SX,SY,SZ,FX,FY,FZ,TSpeed: single);
const
  CVagon= 20;
  Vag_Distance= 14;

var
  I: integer;
  Vagon: PObjWorld;
  BX,BZ: single; // Координаты
  WaySize: single; // Длина пути
  Tmp_AWS:  single;

begin
if (OBJ= NIL) or (TrainSound= NIL) then exit;

Tmp_AWS:= (sqrt(sqr(FX -SX) +sqr(FY -SY) +sqr(FZ -SZ)));
for I:= 1 to CVagon do
  begin
  new(Vagon);
  Vagon^:= TObjWorld.Create;
  with Vagon^ do
    begin
    TextName:= 'Поезд';
    FileName:= TrainSound^;
    FType:= Dynamic;
    AllWaySize:= Tmp_AWS;
    // Начальная точка
    if SZ = FZ then
      Start_X:= SX+(I*Vag_Distance)
    else
      Start_X:= SX;
    if SX = FX then
      Start_Z:= SZ +(I*Vag_Distance)
    else
      Start_Z:= SZ;
    Start_Y:= SY;
    // Конечная точка
    Finish_X:= FX; Finish_Y:= FY; Finish_Z:= FZ;
    // Расчитываем угол альфа, под которым объект
    // движется относительно оси OX.
    // Для этого расчитываем условный вектор скорости
    // То есть, переносим начальную точку в начало координат (0,0,0)
    // и расчитываем координаты конечной точки.
    BX:= Finish_X -Start_X;
    BZ:= Finish_Z -Start_Z;
    // Теперь подсчитываем длину пути
    // То есть, длину вектора (0,0) - B
    WaySize:= sqrt(sqr(BX) +sqr(BZ));
    // Косинус угла поворота альфа равен X координате
    // деленной на длину вектора. Отсюда
    Alpha:= Round(RadToDeg(ArcCos(BX/WaySize)));

    Set_Posit(Start_X,Start_Y,Start_Z);
    if I< CVagon then
      begin
      FSilenceDistance:= 150;
      FMinDist:= 4;
      end
    else
      FMinDist:= 12;
    Speed:= TSpeed;
    end; // with Vagon^
  Obj.Add(Vagon);
  end; // for I 1 to CVagon

dispose(TrainSound);
end; // proc Train

procedure WorldUpdate;
var
  I: integer;
  LPos,LVel: TFSoundVector;
  CurWaySize:  single;
  // Tmp_X,Tmp_Z:  single;
  LD:  single;

begin
if Obj= NIL then exit;

FSOUND_3D_Listener_GetAttributes(@LPos,@LVel,NIL,NIL,NIL,NIL,NIL,NIL);

for I:= Obj.Count-1 downto 0 do
  with PObjWorld(Obj.Items[I])^ do
    begin
    LD:= ListenerDistance;
    if FSilenceDistance<= LD then
      begin
      if Playing then
        Stop;
      end
    else
      if FType<> EXPLODING then
        Play;

    if (FType in [DYNAMIC,STATIC,CYRC,EXPLODING,BURNING])
       and (ObjSize> 0) and (Mode<> MD_BROWSER)
       and ((Car_Dimensions> 0) and (LD< (ObjSize+Car_Dimensions))) then
      begin
      Points:= Points +OPoints;
      if (Final) and (not CanExplode) then
        begin
        if Labs< 2 then
          Congratulation
        else
          begin
          dec(Labs);
          GotoNull(Next_Lab_Snd,Next_Lab_Vol);
          end; // if Labs < 2
        exit;
        end;
      if CanExplode then
        begin
        KillSamp;
        FileName:= FN_Expl;
        Loop:= false;
        FType:= Exploding;
        Speed:= 0;
        CanExplode:= false;
        StartSound;
        end; // if CanExplode
      Crash(Posit.x,Posit.y,Posit.z,true,I);
      Continue;
      end; // if ListenerDistance< ObjSize
    if (Reflex_Dist> 0) and (PReflex<> NIL) then
    if (LD< (Reflex_Dist+Car_Dimensions)) and (FType< EXPLODING) then
      begin
      with PReflex^ do
        begin
        Set_Posit(PObjWorld(Obj.Items[I])^.Posit.x, PObjWorld(Obj.Items[I])^.Posit.y, PObjWorld(Obj.Items[I])^.Posit.z);
        Speed:= PObjWorld(Obj.Items[I])^.Speed;
        FVolume:= 255;
       if not Playing then
          Play;
          end; // with
      end // if ListenerDistance< Reflex_Dist
    else
      begin
      if PReflex^.Playing then
        PReflex^.Stop;
      end;
    {
    if (Big)
       and (FType in [STATIC,EXPLODING,BURNING])
       and (Playing) then
      begin
      Tmp_X:= Posit.x -LPos.x;
      Tmp_Z:= Posit.z -LPos.z;
      K:= (LD-ObjSize)/LD;
      // Set_Posit((K*Tmp_X)+LPos.x,Posit.y,(K*Tmp_Z)+LPos.z);
      Posit.x:= (K*Tmp_X)+LPos.x;
      Posit.z:= (K*Tmp_Z)+LPos.z;
      end;
    }

    case FType of
    Dynamic:  if Speed> 0 then
      begin
      Step(Speed/(1000/WorldUpdateTime));
      if AllWaySize<= 0 then exit;
      CurWaySize:= sqrt(sqr(Posit.x -Start_X) +sqr(Posit.y -Start_Y) +sqr(Posit.z -Start_Z));
      if CurWaySize> AllWaySize then
        begin
        if Cycle= 1 then
          begin
          KillSamp;
          Obj.Delete(I);
          continue;
          end // if Cycle<= 0
        else
          begin
          Set_Posit(Start_X,Start_Y,Start_Z);
          dec(Cycle);
          end;
        end;
      end; // Dynamic
    Cyrc:
      begin
      Turn(Cyrc_Radius,Cyrc_Corner,Cyrc_X,Cyrc_Y,Cyrc_Z);
      end; // Cyrc
    Exploding:
      begin
      if not Playing then
        begin
        KillSamp;
        if Final then
          begin
          Congratulation;
          Exit;
          end;
        if FN_Burn<> '' then
          begin
          FileName:= FN_Burn;
          Loop:= true;
          StartSound;
          FType:= Burning;
          end // if not Empty(FN_Burn)
        else
          begin
          Obj.Delete(I);
          continue;
          end;
        end; // if not Playing
      end; // case Exploding
    Linked:
      if Mode= MD_GAME then
        Set_Posit(Start_X+LPos.X,Start_Y+LPos.Y,Start_Z+LPos.Z);
    end; // case FType
    end; // with PObjWorld(Obj.Items[I])^
end; // proc WorldUpdate

constructor TObjWorld.Create;
begin
inherited Create;
Loop:= true;
FType:= Static;
Cyrc_Radius:= 0;
Cyrc_X:= 0; Cyrc_Y:= 0; Cyrc_Z:= 0;
ObjSize:= 1;
CanExplode:= false;
FN_Expl:= 'sounds\explode_1.mp3';
FN_Burn:= 'sounds\burn.wav';
Cycle:= 1;
OPoints:= -3000;
Labs:= 1;
AllWaySize:= 0;
end; // constr Create

end. // End Of Unit

