use strict;
use Tk;

my $MAX_COLS         = 10 ;       # 10 cells wide
my $MAX_ROWS         = 15 ;       # 15 cells high
my $TILE_SIZE        = 20;        # size of each tile in pixels 

# Widgets
my $wStartButton;                         # start button widget
my $wBase;                                # top level widget
my $wGame;                                # canvas

my $gameover = 0;
my $playing = 0;
my $updateInterval = 500;

my @patterns = ([" * ",
                 "***"],
                ["****"],
                ["  *",
                 "***"],
                ["*  ",
                 "***"],
                [" **",
                 "** "],
                ["**",
                 "**"]);
my @colors = qw(#0000FF #00FF00 #FF0000 #FFFF00 #FF00FF #00FFFF);

my @currentBlock;
my @currentPattern;
my @currentBlockCoors; # x0, y0, x1, y1; 0 : left up; 1 : right bottom (in terms of the grid)
my @board;

sub update{
	if (!$gameover && $playing){
		moveDown();
		if (isHitGround()){ 
			clearRows();
			if (isHitSky()) { gameover(); } # gameover when hitting both ground and sky
			else			{ createTile(); }
		}
		$wBase->after($updateInterval, \&update);
	}
}

sub start{
	if (!$playing){	
		createTile();
		$wBase->after($updateInterval, \&update);
		$playing = 1;
	}
}

sub createScreen{
    $wBase = MainWindow->new(-title => 'Tetris - Perl/Tk');

    $wGame = $wBase->Canvas('-width'  => $MAX_COLS * $TILE_SIZE,
                             '-height' => $MAX_ROWS  * $TILE_SIZE,
                             '-border' => 1,
                             '-relief' => 'ridge');			
    $wStartButton = $wBase->Button('-text' => 'Start',
                              '-command' => \&start,
                              );
    my $wQuitBitton = $wBase->Button('-text' => 'Quit',
                                '-command' => sub {exit(0)}
                                );
    $wGame->pack();
    $wStartButton->pack('-side'=> 'left', '-fill' => 'y', '-expand' => 'y');
    $wQuitBitton->pack('-side'=> 'right', '-fill' => 'y', '-expand' => 'y');
}

sub clearRow{
	my $delRow = $_[0];
	# delete the row first
	for my $i (0..$MAX_COLS-1){
		${$board[$delRow]}[$i] = 0;
	}
	# move the tiles one unit below
	for my $col (0..$MAX_COLS-1){
		for my $row (1..$delRow){
			my $adjustedRow = $row = $delRow - $row;
			# move the data
			${$board[$adjustedRow+1]}[$col] = ${$board[$adjustedRow]}[$col];
			# move the tile visually 
			# TODO
		}
	}
}

sub isFullRow{
	my $count = 0;
	for my $col (0..$MAX_COLS-1){
		if (${$board[$_[0]]}[$col]) { $count++; }
	}
	if ($count == $MAX_COLS) { return 1; }
	else					 { return 0; }
}

sub clearRows{
	for my $row ($currentBlockCoors[1]..$currentBlockCoors[3]){
		if (isFullRow($row)) { clearRow($row); }
	}
}

sub isHitSky{
	if ($currentBlockCoors[1] == 0) { return 1; }
	else 							{ return 0; }
}

sub isHitGround{
	my $hit = 0;
	if ($currentBlockCoors[3] == $MAX_ROWS-1){ return 1; }
	else{
		my $lastRow = scalar(@currentPattern)-1;
		my @line = split(//, $currentPattern[$lastRow]);

		my $xOffset = $currentBlockCoors[0];
		my $yOffset = $currentBlockCoors[1];
		for my $i (0..length($currentPattern[0])-1){
			if (${$board[$lastRow+$yOffset+1]}[$i+$xOffset]){ return 1; }
		}
		return 0; 
	}
}

sub gameover{
	$gameover = 1;
	$playing = 0;
	print "gameover!";
}

sub moveRight{
	
	if ($currentBlockCoors[2] < $MAX_COLS-1){
		
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
	#printBoard();
}

sub moveLeft{
	
	if ($currentBlockCoors[0] > 0){
		
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
	#printBoard();
}

sub moveDown{
	
	if ($currentBlockCoors[3] < $MAX_ROWS-1){
	
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
	#printBoard();
}

sub fallDown{
	for my $i (1..$MAX_ROWS){
		moveDown();
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
			else	   {print "  ";}
		}
		print "\n";
	}
}

sub createTile{
    my $color   = $colors[int(rand (scalar (@colors)))];
    my $pattern = $patterns[int(rand (scalar(@patterns)))];
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
	#printBoard();
	@currentPattern = @$pattern;
	@currentBlockCoors = ($xOffset, 0, $width+$xOffset-1, $height-1);
}

sub clearBoard{
	for my $i (0..$MAX_ROWS-1){
		my @temp;
		for my $j (0..$MAX_COLS-1){
			push (@temp, 0);
		}
		push (@board, \@temp);
	}
}

sub createTempTile{
	my @coor = @_;
	$wGame->createRectangle($coor[1]*$TILE_SIZE, $coor[0]*$TILE_SIZE, ($coor[1]+1)*$TILE_SIZE, ($coor[0]+1)*$TILE_SIZE, '-fill'=>'#123456');
	${$board[$coor[0]]}[$coor[1]] = 1;
}

sub createTempTiles{
	my @coors = @_;
	for my $row ($coors[0]..$coors[2]){
		createTempTile($row, $coors[1]);
	}
}

sub init{
	createScreen();
	drawLines();
	srand();
	$wBase->bind('<KeyPress-Left>', \&moveLeft);
	$wBase->bind('<KeyPress-Right>', \&moveRight);
	$wBase->bind('<KeyPress-Down>', \&moveDown);
	$wBase->bind('<KeyPress-space>', \&fallDown);
	clearBoard();

	# the following lines are for testing
	createTempTiles(12,0,14,0);
	createTempTiles(12,1,14,1);
	createTempTiles(9,2,14,2);
	createTempTiles(10,3,14,3);
	createTempTiles(10,4,14,4);
	createTempTiles(13,5,14,5);
	createTempTiles(7,6,14,6);
	createTempTiles(13,8,14,8);
	createTempTiles(12,9,14,9);
}

init();

MainLoop();
