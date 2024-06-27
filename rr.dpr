program rr;

uses
  Forms,
  main in 'main.pas' {MainForm},
  err in 'err.pas',
  u_car in 'u_car.pas',
  my_fmod in 'my_fmod.pas',
  world in 'world.pas',
  u_territory in 'u_territory.pas',
  compas in 'compas.pas',
  menu in 'menu.pas',
  u_param in 'u_param.pas',
  my_utils in 'my_utils.pas',
  rr_net in 'rr_net.pas',
  my_math in 'my_math.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Ru Racing';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
