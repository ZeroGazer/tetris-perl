use strict;
use Tk;
use Win32::Sound;

my $MAX_COLS         = 10 ;       # 10 cells wide
my $MAX_ROWS         = 22 ;       # 15 cells high
my $TILE_SIZE        = 20;        # size of each tile in pixels 

# Widgets
my $wStartButton;                         # start button widget
my $wBase;                                # top level widget
my $wGame;                                # canvas
my $wLevel;
my $wScore;
my @wHistory;
my $updateTimer;

my $level = 1;
my $score = 0;
my $playing = 0;
my $basicUpdateInterval = 500;
my $updateInterval = $basicUpdateInterval;
my %history;

my @patterns = ([" * ",
                 "***",
                 "   "],
                ["    ",
                 "****",
                 "    ",
                 "    "],
                ["  *",
                 "***",
                 "   "],
                ["*  ",
                 "***",
                 "   "],
                [" **",
                 "** ",
                 "   "],
                ["** ",
                 " **",
                 "   "],
                ["**",
                 "**"]);
my @colors = qw(#BA55D3 #8EE5EE #FFA500 #0000FF #00FF00 #FF0000 #FFFF00);


my $nextIndex;
my @nextBlock;
my @currentBlock;
my @currentPattern;
my $currentColor;
my @currentBlockCoors; # x0, y0, x1, y1; 0 : left up; 1 : right bottom (in terms of the grid)
my @fixedBlock; # store ref to all blocks which hit ground
my @board;
my @colorInBoard; # -1:no color, 0:color0, ...

sub update{
    if ($playing){
        if (isHitGround()){ 
            rmbColor();

            # reset some data
            foreach my $block (@currentBlock){
                push (@fixedBlock, $block);
            }
            @currentBlock = ();

            clearRows();
            if (isHitSky()) { gameover(); } # gameover when hitting both ground and sky
            else{ 
                createTile();
                createNextTile();
            }
        }
        moveDown();
        $updateTimer = $wBase->after($updateInterval, \&update);
    }
}

sub start{
    if (!$playing){  
        Win32::Sound::Volume('100%');
        Win32::Sound::Play("bgm.wav", SND_ASYNC | SND_LOOP);
        $level = 1;
        $score = 0;
        $updateInterval = $basicUpdateInterval;
        $wGame->delete($wLevel);
        $wLevel = $wGame->createText(($MAX_COLS+5)*$TILE_SIZE, 2*$TILE_SIZE, -anchor=>"e", -text=>"$level");
        $wGame->delete($wScore);
        $wScore = $wGame->createText(($MAX_COLS+5)*$TILE_SIZE, 3*$TILE_SIZE, -anchor=>"e", -text=>"$score");
        printHistory();
        createNextTile();  
        createTile();
        $wBase->after($updateInterval, \&update);
        $playing = 1;
    }
}

sub printHistory{

    foreach my $widget (@wHistory){
        $wGame->delete($widget);
    }

    # history
    if (-e "score.txt"){
        open (INFILE, "<score.txt");
        while (my $line = <INFILE>){
            chomp ($line);
            my @line = split(/\t/, $line);
            $history{$line[0]} = $line[1];
        }

        my $count = 0;
        $wGame->createText(($MAX_COLS+1)*$TILE_SIZE, 11*$TILE_SIZE, -anchor=>"w", -text=>"Rank :");
        $wGame->createText(($MAX_COLS+1)*$TILE_SIZE, (12+$count)*$TILE_SIZE, -anchor=>"w", -text=>"Name");   # name
        $wGame->createText(($MAX_COLS+6)*$TILE_SIZE, (12+$count)*$TILE_SIZE, -anchor=>"e", -text=>"Score");   # score
        $wGame->createLine(($MAX_COLS+1)*$TILE_SIZE, (12.5+$count)*$TILE_SIZE, ($MAX_COLS+6)*$TILE_SIZE, (12.5+$count)*$TILE_SIZE);
        foreach my $key (sort { $history{$b} <=> $history{$a} or $a cmp $b } keys %history){

            # print "$key -> $history{$key}\n";
            push @wHistory, $wGame->createText(($MAX_COLS+1)*$TILE_SIZE, (11+$count)*$TILE_SIZE, -anchor=>"w", -text=>"$key");   # name
            push @wHistory, $wGame->createText(($MAX_COLS+6)*$TILE_SIZE, (11+$count)*$TILE_SIZE, -anchor=>"e", -text=>"$history{$key}");   # score
            $count ++;
            if ($count == 5){ last; }
        }
    }
}

sub createScreen{
    $wBase = MainWindow->new(-title => 'Tetris - Perl/Tk');

    $wGame = $wBase->Canvas('-width'  => ($MAX_COLS+7) * $TILE_SIZE,
                             '-height' => $MAX_ROWS  * $TILE_SIZE,
                             '-border' => 1,
                             '-relief' => 'ridge'); 
    $wGame->createText(($MAX_COLS+1)*$TILE_SIZE, 2*$TILE_SIZE, -anchor=>"w", -text=>"Level :",);
    $wLevel = $wGame->createText(($MAX_COLS+5)*$TILE_SIZE, 2*$TILE_SIZE, -anchor=>"e", -text=>"$level");
    $wGame->createText(($MAX_COLS+1)*$TILE_SIZE, 3*$TILE_SIZE, -anchor=>"w", -text=>"Score :",);
    $wScore = $wGame->createText(($MAX_COLS+5)*$TILE_SIZE, 3*$TILE_SIZE, -anchor=>"e", -text=>"$score");
    $wGame->createText(($MAX_COLS+1)*$TILE_SIZE, 5*$TILE_SIZE, -anchor=>"w", -text=>"Next Tetrominoe :");

    $wGame->createText(($MAX_COLS+1)*$TILE_SIZE, (17)*$TILE_SIZE, -anchor=>"w", -text=>"Up: rotate");
    $wGame->createText(($MAX_COLS+1)*$TILE_SIZE, (18)*$TILE_SIZE, -anchor=>"w", -text=>"Left: move left");
    $wGame->createText(($MAX_COLS+1)*$TILE_SIZE, (19)*$TILE_SIZE, -anchor=>"w", -text=>"Right: move right");
    $wGame->createText(($MAX_COLS+1)*$TILE_SIZE, (20)*$TILE_SIZE, -anchor=>"w", -text=>"Down: soft drop");
    $wGame->createText(($MAX_COLS+1)*$TILE_SIZE, (21)*$TILE_SIZE, -anchor=>"w", -text=>"Space: hard drop");
    printHistory();

    my $wStartButton = $wBase->Button('-text' => 'Start',
                              '-command' => \&start
                              );
    my $wQuitBitton = $wBase->Button('-text' => 'Quit',
                                '-command' => sub {exit(0)}
                                );
    $wGame->pack();
    $wStartButton->pack('-side'=> 'left', '-fill' => 'y', '-expand' => 'y');
    $wQuitBitton->pack('-side'=> 'right', '-fill' => 'y', '-expand' => 'y');
    $wBase->bind('<KeyPress-Left>', \&moveLeft);
    $wBase->bind('<KeyPress-Right>', \&moveRight);
    $wBase->bind('<KeyPress-Down>', \&moveDown);
    $wBase->bind('<KeyPress-space>', \&fallDown);
    $wBase->bind('<KeyPress-Up>', \&rotate);
}

sub rmbColor{

    my $colorIndex;
    for my $i (0..scalar(@colors)-1){
        if ($colors[$i] eq $currentColor) {$colorIndex = $i;}
    }

    my $xOffset = $currentBlockCoors[0];
    my $yOffset = $currentBlockCoors[1];
    for my $i (0..scalar(@currentPattern)-1){
        my @line = split(//, $currentPattern[$i]);

        for my $j (0..scalar(@line)-1){
            if ($line[$j] eq "*"){
                ${$colorInBoard[$yOffset+$i]}[$xOffset+$j] = $colorIndex;
            }
        }
    }
}

sub clearRow{
    $wBase->after(200);

    my $delRow = $_[0];

    # delete the row first
    for my $i (0..$MAX_COLS-1){
        ${$board[$delRow]}[$i] = 0;    
        ${$colorInBoard[$delRow]}[$i] = -1;
    }
    
    # move the tiles one unit below
    for my $col (0..$MAX_COLS-1){
        for my $row (1..$delRow){
            my $adjustedRow = $row = $delRow - $row;
            ${$board[$adjustedRow+1]}[$col] = ${$board[$adjustedRow]}[$col]; # move the data
            ${$colorInBoard[$adjustedRow+1]}[$col] = ${$colorInBoard[$adjustedRow]}[$col]; # move the data
        }
    }

    for my $block (@fixedBlock){
        $wGame->delete($block);
    }
    @fixedBlock = ();

    for my $row (0..$MAX_ROWS-1){
        for my $col (0..$MAX_COLS-1){
            if (${$board[$row]}[$col]){
                my $color = $colors[${$colorInBoard[$row]}[$col]];
                my $block = $wGame->createRectangle($col*$TILE_SIZE, $row*$TILE_SIZE, ($col+1)*$TILE_SIZE, ($row+1)*$TILE_SIZE, '-fill' => $color);
                push (@fixedBlock, $block);
            }
        }
    }
}

sub isFullRow{
    my $count = 0;
    for my $col (0..$MAX_COLS-1){
        if (${$board[$_[0]]}[$col]) { $count++; }
    }
    if ($count == $MAX_COLS) { return 1; }
    else                     { return 0; }
}

sub clearRows{
    my $count = 0;
    for my $row (0..$MAX_ROWS-1){
        if (isFullRow($row)){ clearRow($row); $count++; }
    }
    if ($count != 0) { calculateScore($count); }
}

sub calculateScore{
    my $count = $_[0];
    if ($count == 1){ $score += (100*$level); }
    else { 
        if ($count == 2) { $score += (300*$level); }
        else { 
            if ($count == 3) { $score += (600*$level); }
            else { if ($count == 4) { $score += (1000*$level); } } } }

    $wGame->delete($wScore);
    $wScore = $wGame->createText(($MAX_COLS+5)*$TILE_SIZE, 3*$TILE_SIZE, -anchor=>"e", -text=>"$score");

    adjustDifficulty();
}

sub adjustDifficulty{
    my $minus = 50;
    my @interval = (1000, 2500, 5000, 9000, 15000, 30000); 
    if ($updateInterval > 200) {
        for my $i (1..scalar(@interval)){
            my $k = scalar(@interval)-$i; # $k = len-1, len-2, ..., 1, 0
            if ($score >= $interval[$k]){
                $updateInterval = $basicUpdateInterval - $minus * ($k+1);
                $level = $k+2;
                $wGame->delete($wLevel);
                $wLevel = $wGame->createText(($MAX_COLS+5)*$TILE_SIZE, 2*$TILE_SIZE, -anchor=>"e", -text=>"$level");
                last;
            }
        }
    }
}

sub isHitSky{
    if ($currentBlockCoors[1] == 0) { return 1; }
    else                             { return 0; }
}

sub isHitGround{
    
    my $botMostY = $currentBlockCoors[3];
    for my $i (1..scalar(@currentPattern)){
        my $k = scalar(@currentPattern) - $i;
        my @line = split(//, $currentPattern[$k]);
        my $emptyCol = 1;

        for my $j (0..scalar(@line)-1){
            if ($line[$j] eq "*"){ $emptyCol = 0; last; }
        }
        if (!$emptyCol){ last; }
        $botMostY--;
    }

    if ($botMostY == $MAX_ROWS-1){ return 1; }
    else{
        for my $i (0..length($currentPattern[0])-1){
            for my $j (1..scalar(@currentPattern)){
                my $k = scalar(@currentPattern)-$j;
                my $line = $currentPattern[$k];
                my @line = split(//, $line);

                my $xOffset = $currentBlockCoors[0];
                my $yOffset = $currentBlockCoors[1];
                if ($line[$i] eq "*"){
                    if (${$board[$k+$yOffset+1]}[$i+$xOffset]) {return 1;}
                    last;
                }
            }
        }
        return 0;
    }
}

sub gameover{
    Win32::Sound::Stop();
    $wBase->afterCancel($updateTimer);
    $playing = 0;
    print "gameover!\n";

    my $min = 9999999;
    $_ < $min and $min = $_ for values %history;

    if ($score > $min || !(-e "score.txt") || scalar(%history)<5){
        my $wFinish = MainWindow->new;
        my $name;

        $wFinish->title("Input your name");

        $wFinish->Label(-text => "You are Top 5! Please enter your name : ")->pack();

        my $entry = $wFinish->Entry(-textvariable => \$name)->pack();

        $wFinish->Button(
            -text => "Ok",
            -command => sub {
                if ($history{$name} < $score){ $history{$name} = $score; }
                open(OUTFILE, ">score.txt");
                my $count = 0;
                foreach my $key (sort { $history{$b} <=> $history{$a} or $b cmp $a } keys %history) {
                    print OUTFILE "$key\t$history{$key}";
                    $count ++;
                    if ($count >= 5) { last; }
                    else { print OUTFILE "\n"; }
                }
                close(OUTFILE);
                $wFinish->destroy();
                restart();
            }
        )->pack();
    } else {
      restart();
    }
}

sub restart() {
    my $wRestart = MainWindow->new;
    my $name;

    $wRestart->title("Restart?");

    $wRestart->Label(-text => "Do you want to restart?")->pack();

    $wRestart->Button(
        -text => "Yes",
        -command => sub {
            $wRestart->destroy();
            foreach my $block (@fixedBlock) {
                $wGame->delete($block);
            }
            @fixedBlock = ();
            clearBoard();
            start();
        }
    )->pack(-side=> 'left');
    
    $wRestart->Button(
        -text => "No",
        -command => sub {
            exit(0);
        }
    )->pack(-side=> 'right');
    
    $wRestart->focusForce();
}

sub moveRight{

    my $rightMostX = $currentBlockCoors[2];
    for my $i (1..length($currentPattern[0])){
        my $k = length($currentPattern[0]) - $i;
        my $emptyCol = 1;

        for my $j (0..scalar(@currentPattern)-1){
            my @line = split(//, $currentPattern[$j]);
            if ($line[$k] eq "*"){ $emptyCol = 0; last; }
        }
        if (!$emptyCol){ last; }
        $rightMostX--;
    }

    if ($rightMostX < $MAX_COLS-1){
        
        for my $i (0..scalar(@currentPattern)-1){
            my $line = $currentPattern[$i];
            my @line = split(//, $line);
            
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0..length($line)-1){
                my $k = length($line)-1-$j;
                if ($line[$k] eq "*") {
                    if (${$board[$i+$yOffset]}[$xOffset+$k+1]) {return;} # if a cell's right is filled, return with doing nth
                    last;
                }
            }
        }
    
        # change @board data to 0
        for my $i (0..scalar(@currentPattern)-1){
            my $line = $currentPattern[$i];
            my @line = split(//, $line);
            
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0..length($line)-1){
                if ($line[$j] eq "*") {
                    ${$board[$i+$yOffset]}[$xOffset+$j] = 0;
                }
            }
        }
    
        # move the tile
        foreach my $unit (@currentBlock){
            $wGame->move($unit, $TILE_SIZE, 0);
        }
        $currentBlockCoors[0] += 1;
        $currentBlockCoors[2] += 1;
        
        # change @board data to 1
        for my $i (0..scalar(@currentPattern)-1){
            my $line = $currentPattern[$i];
            my @line = split(//, $line);
            
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0..length($line)-1){
                if ($line[$j] eq "*") {
                    ${$board[$i+$yOffset]}[$xOffset+$j] = 1;
                }
            }
        }
    }
}

sub moveLeft{
    
    my $leftMostX = $currentBlockCoors[0];
    for my $i (0..length($currentPattern[0])-1){
        my $emptyCol = 1;

        for my $j (0..scalar(@currentPattern)-1){
            my @line = split(//, $currentPattern[$j]);
            if ($line[$i] eq "*"){ $emptyCol = 0; last; }
        }
        if (!$emptyCol){ last; }
        $leftMostX++;
    }

    if ($leftMostX > 0){
        
        for my $i (0..scalar(@currentPattern)-1){
            my $line = $currentPattern[$i];
            my @line = split(//, $line);
            
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0..length($line)-1){
                if ($line[$j] eq "*") {
                    if (${$board[$i+$yOffset]}[$xOffset+$j-1]) {return;} # if a cell's left is filled, return with doing nth
                    last;
                }
            }
        }
    
        # change @board data to 0
        for my $i (0..scalar(@currentPattern)-1){
            my $line = $currentPattern[$i];
            my @line = split(//, $line);
            
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0..length($line)-1){
                if ($line[$j] eq "*") {
                    ${$board[$i+$yOffset]}[$xOffset+$j] = 0;
                }
            }
        }
    
        foreach my $unit (@currentBlock){
            $wGame->move($unit, -$TILE_SIZE, 0);
        }
        $currentBlockCoors[0] -= 1;
        $currentBlockCoors[2] -= 1;
        
        # change @board data to 1
        for my $i (0..scalar(@currentPattern)-1){
            my $line = $currentPattern[$i];
            my @line = split(//, $line);
            
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0..length($line)-1){
                if ($line[$j] eq "*") {
                    ${$board[$i+$yOffset]}[$xOffset+$j] = 1;
                }
            }
        }
    }
}

sub moveDown{

    my $botMostY = $currentBlockCoors[3];
    for my $i (1..scalar(@currentPattern)){
        my $k = scalar(@currentPattern) - $i;
        my @line = split(//, $currentPattern[$k]);
        my $emptyCol = 1;

        for my $j (0..scalar(@line)-1){
            if ($line[$j] eq "*"){ $emptyCol = 0; last; }
        }
        if (!$emptyCol){ last; }
        $botMostY--;
    }

    if ($botMostY < $MAX_ROWS-1){
    
        for my $i (0..length($currentPattern[0])-1){
            for my $j (1..scalar(@currentPattern)){
                my $k = scalar(@currentPattern)-$j;
                my $line = $currentPattern[$k];
                my @line = split(//, $line);

                my $xOffset = $currentBlockCoors[0];
                my $yOffset = $currentBlockCoors[1];
                if ($line[$i] eq "*"){
                    if (${$board[$k+$yOffset+1]}[$i+$xOffset]) {return;}
                    last;
                }
            }
        }

        # change @board data to 0
        for my $i (0..scalar(@currentPattern)-1){
            my $line = $currentPattern[$i];
            my @line = split(//, $line);
            
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0..length($line)-1){
                if ($line[$j] eq "*") {
                    ${$board[$i+$yOffset]}[$xOffset+$j] = 0;
                }
            }
        }
    
        foreach my $unit (@currentBlock){
            $wGame->move($unit, 0, $TILE_SIZE);
        }
        $currentBlockCoors[1] += 1;
        $currentBlockCoors[3] += 1;
        
        # change @board data to 1
        for my $i (0..scalar(@currentPattern)-1){
            my $line = $currentPattern[$i];
            my @line = split(//, $line);
            
            my $xOffset = $currentBlockCoors[0];
            my $yOffset = $currentBlockCoors[1];
            for my $j (0..length($line)-1){
                if ($line[$j] eq "*") {
                    ${$board[$i+$yOffset]}[$xOffset+$j] = 1;
                }
            }
        }
    }
}

sub fallDown{
    for my $i (1..$MAX_ROWS){
        moveDown();
    }
}

sub rotate{
  #print "pressed up arrow \n";

  my @currentPatternArray;
  my @newPatternArray;
  my @newPattern;
  for my $i (0..scalar(@currentPattern)-1){ # translate pattern into array
    my $line = $currentPattern[$i];
    my @line = split(//, $line);
      
    for my $j (0..length($line)-1){
      if ($line[$j] eq "*") {
        $currentPatternArray[$i][$j] = 1;
      } else {
        $currentPatternArray[$i][$j] = 0;
      }
    }
  }
  for my $i (0..scalar(@currentPattern)-1) { # rotate the array
    for my $j (0..scalar(@currentPattern)-1){
      $newPatternArray[$i][$j] = $currentPatternArray[scalar(@currentPattern)-1-$j][$i];
    }
  }
  for my $i (0..scalar(@currentPattern)-1) { # translate new array into pattern
    my $patternString;
    for my $j (0..scalar(@currentPattern)-1){
      if ($newPatternArray[$i][$j]) {
          $patternString = $patternString . "*";
      } else {
          $patternString = $patternString . " ";
      }
      @newPattern[$i] = $patternString;
    }
  }

  my @tempCoorsArray;

  # change @board data to 0
   for my $i (0..scalar(@currentPattern)-1){
    my $line = $currentPattern[$i];
    my @line = split(//, $line);
    
    my $xOffset = $currentBlockCoors[0];
    my $yOffset = $currentBlockCoors[1];
    for my $j (0..length($line)-1){
      if ($line[$j] eq "*") {
          my $coor = ($i+$yOffset) * 100 + $xOffset+$j;
          push (@tempCoorsArray, $coor);
        ${$board[$i+$yOffset]}[$xOffset+$j] = 0;
      }
    }
  }
  
    my $displacement = 0; # -1:left, 0:stay, 1:right

    # check if there is collision
    for my $i (0..scalar(@newPattern)-1){
        my $line = $newPattern[$i];
        my @line = split(//, $line);

        my $xOffset = $currentBlockCoors[0];
        my $yOffset = $currentBlockCoors[1];
        for my $j (0..length($line)-1){

            if ($line[$j] eq "*") {
                if ( (${$board[$i+$yOffset]}[$xOffset+$j])                 # collision
                    || ($i+$yOffset<0 || $i+$yOffset>$MAX_ROWS-1) ) {    # out of range (in terms of y coor)
                    # restore original state
                    foreach my $coor (@tempCoorsArray){
                        use integer;
                        my $row = $coor / 100;
                        my $col = $coor - $row * 100;
                        ${$board[$row]}[$col] = 1;
                    }
                    return; 
                }    
                else {
                    if ($xOffset+$j<0 || $xOffset+$j>$MAX_COLS-1){ # out of range (in terms of x-coor)
                        if ($xOffset+$j<0) { $displacement += 1; } # crash left boundary -> move right one cell
                        else { $displacement -= 1; }                # crash right boundary -> move left one cell
                    }
                }
            }
        }
    }

    if ($displacement != 0){ # not 0 -> need to displace
        if ($currentColor eq $colors[2]){ # lazy, only this is exception to the above counting method
            if ($displacement > 0) { $displacement = 1; }
            else { $displacement = -1; }
        }
        $currentBlockCoors[0] += $displacement;
        $currentBlockCoors[2] += $displacement;
    }

  # delete the tile
  foreach my $unit (@currentBlock){
    $wGame->delete($unit);
  }
  
  @currentPattern = @newPattern;
  # create the tile
  for my $i (0..scalar(@currentPattern)-1){
    my $line = $currentPattern[$i];
    my @line = split (//, $line);
  
    my $xOffset = $currentBlockCoors[0];
    my $yOffset = $currentBlockCoors[1];
    for my $j (0..scalar(@line)-1){
      my $char = @line[$j];
      if ($char eq "*"){
        # set 1 in @board
        my $unit = $wGame->createRectangle(($j+$xOffset)*$TILE_SIZE, ($i+$yOffset)*$TILE_SIZE, ($j+$xOffset+1)*$TILE_SIZE, ($i+1+$yOffset)*$TILE_SIZE, '-fill' => $currentColor);
        push @currentBlock, $unit;
      }
    }
  }
  
  # change @board data to 1
  for my $i (0..scalar(@currentPattern)-1){
    my $line = $currentPattern[$i];
    my @line = split(//, $line);
  
    my $xOffset = $currentBlockCoors[0];
    my $yOffset = $currentBlockCoors[1];
    for my $j (0..length($line)-1){
      if ($line[$j] eq "*") {
        ${$board[$i+$yOffset]}[$xOffset+$j] = 1;
      }
    }
  }
}

sub drawLines{
    for my $i (0 .. $MAX_ROWS){
        $wGame->createLine(0, $i*$TILE_SIZE, $MAX_COLS*$TILE_SIZE, $i*$TILE_SIZE, '-fill' => 'black');}
    for my $i (0 .. $MAX_COLS){
        $wGame->createLine($i*$TILE_SIZE, 0, $i*$TILE_SIZE, $MAX_ROWS*$TILE_SIZE, '-fill' => 'black');}
}

sub printBoard{
    foreach my $row (@board){
        foreach my $cell (@$row){
            if ($cell) {print "* ";}
            else       {print "  ";}
        }
        print "\n";
    }
}

sub createNextTile {
    # remove old tile
    foreach my $unit (@nextBlock){
        $wGame->delete($unit);
    }

    # create nxet tile
    $nextIndex = int(rand (scalar (@patterns)));
    my $color = $colors[$nextIndex];
    my $pattern = $patterns[$nextIndex];
    my $xOffset, my $height = scalar(@$pattern), my $width;
    @nextBlock = ();

    for my $i (0..scalar(@$pattern)-1){
        my $line = @$pattern[$i];
        my @line = split (//, $line);

        for my $j (0..scalar(@line)-1){
            my $char = @line[$j];
            if ($char eq "*"){
                my $unit = $wGame->createRectangle(($j+$MAX_COLS+2)*$TILE_SIZE, ($i+6)*$TILE_SIZE, ($j+$MAX_COLS+2+1)*$TILE_SIZE, ($i+1+6)*$TILE_SIZE, '-fill' => $color);
                push @nextBlock, $unit;
            }
        }
    }
}

sub createTile{
    my $randomIndex = $nextIndex;
    my $color   = $colors[$randomIndex];
    $currentColor = $color;
    my $pattern = $patterns[$randomIndex];
    my $xOffset, my $height = scalar(@$pattern), my $width;
    @currentBlock = ();

    for my $i (0..scalar(@$pattern)-1){
        my $line = @$pattern[$i];
        my @line = split (//, $line);
        $xOffset = int(($MAX_COLS - length($line)) / 2);
        $width = scalar(@line);
        
        for my $j (0..scalar(@line)-1){
            my $char = @line[$j];
            if ($char eq "*"){
                my $unit = $wGame->createRectangle(($j+$xOffset)*$TILE_SIZE, $i*$TILE_SIZE, ($j+$xOffset+1)*$TILE_SIZE, ($i+1)*$TILE_SIZE, '-fill' => $color);
                push @currentBlock, $unit;
                ${$board[$i]}[$j+$xOffset] = 1;
            }
        }
    }
    @currentPattern = @$pattern;
    @currentBlockCoors = ($xOffset, 0, $width+$xOffset-1, $height-1);
}

sub clearBoard{
    for my $i (0..$MAX_ROWS-1){
        for my $j (0..$MAX_COLS-1){
            $board[$i][$j] = 0;
            $colorInBoard[$i][$j] = -1;
        }
    }
}

sub init{
    createScreen();
    drawLines();
    srand();
    clearBoard();
}

init();

MainLoop();
