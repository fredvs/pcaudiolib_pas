program consolerec;

///WARNING : if FPC version < 2.7.1 => Do not forget to uncoment {$DEFINE consoleapp} in define.inc !

{$mode objfpc}{$H+}
   {$DEFINE UseCThreads}
uses
{$IFDEF UNIX}
  cthreads, 
  cwstring, {$ENDIF}
  Classes,
  SysUtils,
  CustApp,
  uos_flat;

type

  { TUOSConsole }

  TuosConsole = class(TCustomApplication)
  private
    procedure ConsolePlay;
  protected
    procedure doRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
  end;

var
  res, x, y,z: integer;
  ordir, opath, SoundFilename, PA_FileName, PC_FileName, SF_FileName, MP_FileName: string;
  PlayerIndex1, InputIndex1, OutputIndex1 : integer;
  
  { TuosConsole }

  procedure TuosConsole.ConsolePlay;
  begin
    ordir := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
 
 {$IFDEF Windows}
     {$if defined(cpu64)}
    PA_FileName := ordir + 'lib\Windows\64bit\LibPortaudio-64.dll';
    SF_FileName := ordir + 'lib\Windows\64bit\LibSndFile-64.dll';
    PC_FileName := ordir + 'lib\Windows\64bit\LibPcaudio-64.dll';
     {$else}
    PA_FileName := ordir + 'lib\Windows\32bit\LibPortaudio-32.dll';
    SF_FileName := ordir + 'lib\Windows\32bit\LibSndFile-32.dll';
    PC_FileName := ordir + 'lib\Windows\32bit\LibPcaudio-32.dll';
     {$endif}
    SoundFilename := ordir + 'sound\testrecord.wav';;
 {$ENDIF}

     {$if defined(cpu64) and defined(linux) }
    PA_FileName := ordir + 'lib/Linux/64bit/LibPortaudio-64.so';
    PC_FileName := ordir + 'lib/Linux/64bit/LibPcaudio-64.so';
    SF_FileName := ordir + 'lib/Linux/64bit/LibSndFile-64.so';
    SoundFilename := ordir + 'sound/testrecord.wav';
   {$ENDIF}
   
   {$if defined(cpu86) and defined(linux)}
    PA_FileName := ordir + 'lib/Linux/32bit/LibPortaudio-32.so';
    PC_FileName := ordir + 'lib/Linux/32bit/LibPcaudio-32.so';
    SF_FileName := ordir + 'lib/Linux/32bit/LibSndFile-32.so';
   SoundFilename := ordir + 'sound/testrecord.wav';
 {$ENDIF}
 
  {$if defined(linux) and defined(cpuarm)}
    PA_FileName := ordir + 'lib/Linux/arm_raspberrypi/libportaudio-arm.so';
    SF_FileName := ordir + ordir + 'lib/Linux/arm_raspberrypi/libsndfile-arm.so';
    SoundFilename := ordir + 'sound/testrecord.wav';
 {$ENDIF}
 
 {$IFDEF freebsd}
    {$if defined(cpu64)}
    PA_FileName := ordir + 'lib/FreeBSD/64bit/libportaudio-64.so';
    SF_FileName := ordir + 'lib/FreeBSD/64bit/libsndfile-64.so';
    {$else}
    PA_FileName := ordir + 'lib/FreeBSD/32bit/libportaudio-32.so';
    SF_FileName := ordir + 'lib/FreeBSD/32bit/libsndfile-32.so';
    {$endif}
    SoundFilename := ordir + 'sound/testrecord.wav';
 {$ENDIF}

 {$IFDEF Darwin}
    opath := ordir;
    opath := copy(opath, 1, Pos('/UOS', opath) - 1);
    PA_FileName := opath + '/lib/Mac/32bit/LibPortaudio-32.dylib';
    SF_FileName := opath + '/lib/Mac/32bit/LibSndFile-32.dylib';
    SoundFilename := opath + '/sound/testrecord.wav';
 {$ENDIF}
 
    // Load the libraries
   // function uos_loadlib(PortAudioFileName, PcAudioFileName, SndFileFileName, Mpg123FileName, Mp4ffFileName, FaadFileName,  opusfilefilename: PChar) : LongInt;

   res := uos_LoadLib(Pchar(PA_FileName), Pchar(PC_FileName), Pchar(SF_FileName), nil, nil, nil, nil) ;
     
    writeln;
    if res = 0 then
     writeln('Libraries are loaded.')
     else
    writeln('Libraries did not load.');

   if res = 0 then begin
    writeln();
   writeln('Please, say something to the microphone...');
    
   // create the recorder
    
  PlayerIndex1 := 0;
  
   if uos_CreatePlayer(PlayerIndex1) then
  
  begin
        uos_AddIntoFile(PlayerIndex1, Pchar(SoundFilename));
   //// add a Output into wav file (save record) with custom parameters

     InputIndex1 := uos_AddFromDevIn(PlayerIndex1, 1, -1, -1, -1, -1, -1, -1, 1);  
     // Second parameter: Device ( -1 = default, with TypeLibrary = PCaudio ---> -1 or 0 = Pulse, 1 = ALSA)
     // Last parameter: TypeLibrary : default : -1 (default = Portaudio) (Portaudio = 0, PCaudio = 1)
 
    
      if InputIndex1 > -1 then 

    /////// everything is ready, here we are, lets record...
    uos_Play(PlayerIndex1);
    
     sleep(3000);
        
     uos_stop(PlayerIndex1);
     end;
 end;
    
  // Time to play it
   writeln();
   writeln('OK, let play it...');
   sleep(100);
   //// Create the player.
    
  PlayerIndex1 := 0;
  
   if uos_CreatePlayer(PlayerIndex1) then
  
  begin
  
    //// add a Input from audio-file with default parameters
    //////////// PlayerIndex : Index of a existing Player
    ////////// FileName : filename of audio file
    //  result : -1 nothing created, otherwise Input Index in array

    InputIndex1 := uos_AddFromFile(PlayerIndex1,(pchar(SoundFilename)));
    
      if InputIndex1 > -1 then
  
    //// add a Output into device with default parameters
    //////////// PlayerIndex : Index of a existing Player
    //  result : -1 nothing created, otherwise Output Index in array
    
    {$if defined(cpuarm)}  // need a lower latency
        OutputIndex1 := uos_AddIntoDevOut(PlayerIndex1, -1, 0.3, -1, -1, -1, -1, -1, -1) ;
       {$else}
       
       //OutputIndex1 := uos_AddIntoDevOut(PlayerIndex1);
         OutputIndex1 := uos_AddIntoDevOut(PlayerIndex1, -1, -1, -1, -1, -1, -1, -1, 1) ;
       {$endif}
       
       if OutputIndex1 > -1 then 
    begin

    /////// everything is ready, here we are, lets play it...
    uos_Play(PlayerIndex1);
    sleep(4000);
   
    end;
end;

end;

  procedure TuosConsole.doRun;
  begin
    ConsolePlay;
 //   writeln('Press a key to exit...');
 //   readln;
   writeln();
   writeln('Ciao...');
     uos_free(); // Do not forget this !
    Terminate;   
  end;

constructor TuosConsole.Create(TheOwner: TComponent);
  begin
    inherited Create(TheOwner);
    StopOnException := True;
  end;

var
  Application: TUOSConsole;
begin
  Application := TUOSConsole.Create(nil);
  Application.Title := 'Console Recorder';
  Application.Run;
  Application.Free;
end.
