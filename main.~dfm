object MainForm: TMainForm
  Left = -4
  Top = -4
  Width = 808
  Height = 578
  Caption = 'Ru Racing'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 13
  object RRServer: TServerSocket
    Active = False
    Port = 0
    ServerType = stNonBlocking
    OnClientConnect = RRServerClientConnect
    OnClientDisconnect = RRServerClientDisconnect
    OnClientRead = RRServerClientRead
    Left = 392
    Top = 272
  end
  object RRClient: TClientSocket
    Active = False
    ClientType = ctNonBlocking
    Port = 0
    OnConnect = RRClientConnect
    OnDisconnect = RRClientDisconnect
    OnRead = RRClientRead
    OnError = RRClientError
    Left = 400
    Top = 280
  end
  object MainTimer: TTimer
    Enabled = False
    Interval = 55
    OnTimer = MainTimerTimer
    Left = 408
    Top = 288
  end
  object NetRadarTimer: TTimer
    Enabled = False
    OnTimer = NetRadarTimerTimer
    Left = 416
    Top = 296
  end
end
