unit err;

interface

const
  FILE_NOT_FOUND=  1;
  LOAD_SOUND_ERROR=  2;
  NO_SND_ENGINE=  3;
  NO_SND_IGN=  4;
  NO_SND_BRK=  5;
  NO_SND_SPD=  6;
  NO_SND_HORN=  7;
  ERR_TEXT:  array[1..7] of string =
    ('���� �� ������',
    '������ �������� �����',
    '�� ������ ���� ��������� ����������',
    '�� ������ ���� ��������� ����������',
    '�� ������ ���� ���������� ����������',
    '�� ������ ���� ���������������� ��� ��� ������� ����������',
    '�� ������ ���� �������� ����������');

procedure RR_Error(No:  byte;Text:  string);
procedure FatalError(ErrSt: string); // ��������� ������

                                            implementation
uses Dialogs,
     main;

procedure RR_Error(No:  byte;Text:  string);
begin
ShowMessage(ERR_TEXT[No]+#13+#10+Text);
if No in [NO_SND_ENGINE] then
  halt;
end; // proc RR_Error

procedure FatalError(ErrSt: string);
begin
ShowMessage(ErrSt);
MainForm.Free;
end; // proc FatalError

end.
