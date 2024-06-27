unit timer;

interface

procedure Timer_Start; // Запуск главного таймера
procedure Timer_Stop; // Отключение главного таймера

var
  Tmr_Counter: int64 = 0; // Счетчик таймера
  Tmr_Delay: Word = 1; // Период срабатывания таймера

implementation
uses Windows,
     main, err;

function timeSetEvent(uDelay, uResolution: UINT; lpTimeProc: Pointer;
  dwUser: DWORD; fuEvent: UINT): Integer; stdcall; external 'winmm';
function timeKillEvent(uID: UINT): Integer; stdcall; external 'winmm';

var
  uEventID: UINT; // Идентификатор события таймера

procedure ProcTime(uID, msg: UINT; dwUse, dw1, dw2: DWORD); stdcall;
// Реакция на срабатывание таймера (процедура обратного вызова)
begin
timeKillEvent(uEventID); // Останавливаем таймер
inc(Tmr_Counter);
Tick; // Выполняем процедуру из main.pas
uEventID := timeSetEvent(Tmr_Delay,0,@ProcTime,0,1); // Запускаем таймер
end;

procedure Timer_Start;
begin
Tmr_Counter:= 0; // Сбрасываем счетчик
// Запускаем таймер:
uEventID:= timeSetEvent(Tmr_Delay,0,@ProcTime,0,1);
if uEventID= 0 then
  FatalError('Не удалось запустить таймер');
end; // proc Timer_Start

procedure Timer_Stop;
begin
timeKillEvent(uEventID); // Останавливаем таймер
end; // proc Timer_Stop

end.
