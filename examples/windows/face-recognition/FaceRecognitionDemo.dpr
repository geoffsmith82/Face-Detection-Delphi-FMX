program FaceRecognitionDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  ufrmFaceRecognition in 'ufrmFaceRecognition.pas' {frmFaceRecognition};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmFaceRecognition, frmFaceRecognition);
  Application.Run;
end.
