unit KBSound;
{$G+,R-,S-,A+}

interface

procedure PlayCue(Cue: byte);

implementation

uses Crt, KBState;

procedure PlayCue(Cue: byte);
var
  CueStep: integer;

begin
  if not Game.SoundDisabled then
  begin
    case Cue of
      0: begin
        Sound(524);
        Delay(300);
        Sound(660);
        Delay(150);
        Sound(784);
        Delay(150);
        Sound(1048);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1048);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1048);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1048);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1048);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1048);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1048);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1048);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1168);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1168);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1168);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1168);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1168);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1168);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1168);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1168);
        Delay(60);
        NoSound;
        Delay(15);
        Sound(1320);
        Delay(300);
        Sound(1168);
        Delay(300);
        Sound(1048);
        Delay(150);
        Sound(784);
        Delay(150);
        Sound(1048);
        Delay(150);
      end;

      1: for CueStep := 1 to 5 do
      begin
           Sound(Game.CueFrequency);
           Delay(40);
           NoSound;
           Delay(10);
         end;

      2: begin
        Sound(392);
        Delay(500);
        Sound(440);
        Delay(240);
        NoSound;
        Delay(10);
        Sound(440);
        Delay(240);
        NoSound;
        Delay(10);
        Sound(392);
        Delay(375);
        Sound(330);
        Delay(125);
        Sound(262);
        Delay(240);
      end;

      3: for CueStep := 1 to 50 do
      begin
           Sound(CueStep * 50);
           Delay(2);
         end;

      4: begin
        Sound(Game.CueFrequency);
        Delay(100);
      end;

      5: for CueStep := 500 downto 10 do
      begin
           Sound(CueStep);
           Delay(2);
           NoSound;
         end;

      6: begin
        Sound(3000);
        Delay(40);
      end;

      7: begin
        Sound(220);
        Delay(350);
        NoSound;
        Delay(25);
        Sound(220);
        Delay(350);
        NoSound;
        Delay(25);
        Sound(220);
        Delay(350);
        NoSound;
        Delay(25);
        Sound(175);
        Delay(1500);
      end;
    end;

    NoSound;
  end;
end;

begin
  Game.SoundDisabled := false;
end.
