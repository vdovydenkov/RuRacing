unit menu;

interface
uses classes, my_fmod;

type
  TVocMenuItem= record
    Title: string[64];
    Value: string;
    Snd:  string[128];
  end; // TVocMenuItem= record
  PVocMenuItem= ^TVocMenuItem;

var
  ItemList: TList;
  CurItem:  integer;
  MnuSound:  TFM3DSound; // Звук для сообщений меню

procedure VocMenuSelection(Item:  integer);

implementation
uses SysUtils,
     main, u_param;

procedure VocMenuSelection(Item:  integer);
begin
with MnuSound do
  begin
  KillSamp;
  if (Item< 0) or (Item > ItemList.Count) then
    FileName:= Param.Snd.Menu_Border
  else
    begin
    CurItem:= Item;
    if Item= ItemList.Count then
      FileName:= Param.Snd.Menu_Exit
    else
      FileName:= PVocMenuItem(ItemList.Items[Item])^.Snd;
    end;
  Loop:= false;
  StartSound;
  end;
end; // proc VocMenuSelection

end. // End Of Unit
