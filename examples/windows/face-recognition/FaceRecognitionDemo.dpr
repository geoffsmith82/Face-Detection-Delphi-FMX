program FaceRecognitionDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  ufrmFaceRecognition in 'ufrmFaceRecognition.pas' {frmFaceRecognition},
  FaceRecognitionFMX in '..\..\..\source\FaceRecognitionFMX.pas',
  TensorFlowLiteFMX in '..\..\..\source\TensorFlowLiteFMX.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmFaceRecognition, frmFaceRecognition);
  Application.Run;
end.
