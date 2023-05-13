program FaceLandmark;

uses
  System.StartUpCopy,
  FMX.Forms,
  FaceLandmarkFMX in '..\..\..\source\FaceLandmarkFMX.pas',
  ufrmFaceLandmark in 'ufrmFaceLandmark.pas' {frmFaceLandmark};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmFaceLandmark, frmFaceLandmark);
  Application.Run;
end.
