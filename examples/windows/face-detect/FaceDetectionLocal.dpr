program FaceDetectionLocal;

uses
  System.StartUpCopy,
  FMX.Forms,
  ufrmFaceDetect in 'ufrmFaceDetect.pas' {frmFaceDetect},
  FaceDetectFMX in '..\..\..\source\FaceDetectFMX.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmFaceDetect, frmFaceDetect);
  Application.Run;
end.
