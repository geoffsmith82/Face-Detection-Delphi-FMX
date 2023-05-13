program FaceLandmark;

uses
  System.StartUpCopy,
  FMX.Forms,
  ufrmFaceLandmark in 'ufrmFaceLandmark.pas' {frmFaceLandmark};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmFaceLandmark, frmFaceLandmark);
  Application.Run;
end.
