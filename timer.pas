unit timer;

interface

procedure Timer_Start; // ������ �������� �������
procedure Timer_Stop; // ���������� �������� �������

var
  Tmr_Counter: int64 = 0; // ������� �������
  Tmr_Delay: Word = 1; // ������ ������������ �������

implementation
uses Windows,
     main, err;

function timeSetEvent(uDelay, uResolution: UINT; lpTimeProc: Pointer;
  dwUser: DWORD; fuEvent: UINT): Integer; stdcall; external 'winmm';
function timeKillEvent(uID: UINT): Integer; stdcall; external 'winmm';

var
  uEventID: UINT; // ������������� ������� �������

procedure ProcTime(uID, msg: UINT; dwUse, dw1, dw2: DWORD); stdcall;
// ������� �� ������������ ������� (��������� ��������� ������)
begin
timeKillEvent(uEventID); // ������������� ������
inc(Tmr_Counter);
Tick; // ��������� ��������� �� main.pas
uEventID := timeSetEvent(Tmr_Delay,0,@ProcTime,0,1); // ��������� ������
end;

procedure Timer_Start;
begin
Tmr_Counter:= 0; // ���������� �������
// ��������� ������:
uEventID:= timeSetEvent(Tmr_Delay,0,@ProcTime,0,1);
if uEventID= 0 then
  FatalError('�� ������� ��������� ������');
end; // proc Timer_Start

procedure Timer_Stop;
begin
timeKillEvent(uEventID); // ������������� ������
end; // proc Timer_Stop

end.
