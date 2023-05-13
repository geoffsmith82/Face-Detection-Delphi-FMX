program FaceDetectionLocal;

uses
  System.StartUpCopy,
  FMX.Forms,
  ufrmFaceDetect in 'ufrmFaceDetect.pas' {frmFaceDetect};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmFaceDetect, frmFaceDetect);
  Application.Run;
end.
