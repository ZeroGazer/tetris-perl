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
my $updateInterval = 500;

my @patterns = (["***",
                 "* *"],
                [" * ",
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
my @heights;		   # height of each columns; eg if column1 has 5 tiles with 1 space in between, heights[1] = 6; 
my @board;

sub update{
	#my $newBlock = $wGame->createRectangle(0, 0, $TILE_SIZE, $TILE_SIZE, '-fill' => '#00FF00', '-tag' => 'block');
	if (!$gameover){
		#moveDown();
		$wBase->after($updateInterval, \&update);
	}
}

sub start{
	$wBase->after($updateInterval, \&update);
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
#               '-command' => sub {$wBase->withdraw();exit(0)}
                                '-command' => sub {exit(0)}
                                );
    $wGame->pack();
    $wStartButton->pack('-side'=> 'left', '-fill' => 'y', '-expand' => 'y');
    $wQuitBitton->pack('-side'=> 'right', '-fill' => 'y', '-expand' => 'y');
}

sub moveRight{
	print "pressed right arrow : ($currentBlockCoors[2] < $MAX_COLS)?\n";
	
	if ($currentBlockCoors[2] < $MAX_COLS-1){
		
		for my $i (0..scalar(@currentPattern)-1){
			my $line = $currentPattern[$i];
			my @line = split(//, $line);
			
			my $xOffset = $currentBlockCoors[0];
			my $yOffset = $currentBlockCoors[1];
			for my $j (0..length($line)-1){
				my $k = length($line)-1-$j;
				if ($line[$k] eq "*") {
					if (${$board[$i+$yOffset]}[$xOffset+$k+1]) {return;} # if a cell right is filled, return with doing nth
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
	print "pressed left arrow : ($currentBlockCoors[0] > 0)?\n";
	
	if ($currentBlockCoors[0] > 0){
		
		for my $i (0..scalar(@currentPattern)-1){
			my $line = $currentPattern[$i];
			my @line = split(//, $line);
			
			my $xOffset = $currentBlockCoors[0];
			my $yOffset = $currentBlockCoors[1];
			for my $j (0..length($line)-1){
				if ($line[$j] eq "*") {
				print ("\${\$board[", $i+$yOffset, "]}[", $xOffset+$j-1, "] = ${$board[$i+$yOffset]}[$xOffset+$j-1] ");
					if (${$board[$i+$yOffset]}[$xOffset+$j-1]) {return;} # if a cell left is filled, return with doing nth
					last;
				}
			}
			print "\n";
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
	print "pressed down arrow\n";
	
	my $touchedGround = 0;
	# TODO : check touched ground or not
	
	if (!$touchedGround){
	
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
	print "pressed spacebar \n";
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
			print "$cell ";
		}
		print "\n";
	}
}

sub createTile{
    my $color   = $colors[int(rand (scalar (@colors)))];
    my $pattern = $patterns[int(rand (scalar(@patterns)))];
	my $xOffset, my $height = scalar(@$pattern), my $width;
	
	for my $i (0..scalar(@$pattern)-1){
		my $line = @$pattern[$i];
		my @line = split (//, $line);
		$xOffset = int(($MAX_COLS - length($line)) / 2);
		$width = scalar(@line);
		
		for my $j (0..scalar(@line)-1){
			my $char = @line[$j];
			if ($char eq "*"){
				# set 1 in @board
				my $unit = $wGame->createRectangle(($j+$xOffset)*$TILE_SIZE, $i*$TILE_SIZE, ($j+$xOffset+1)*$TILE_SIZE, ($i+1)*$TILE_SIZE, '-fill' => $color);
				push @currentBlock, $unit;
				${$board[$i]}[$j+$xOffset] = 1;
			}
		}
	}
	printBoard();
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

sub init{
	createScreen();
	drawLines();
	srand();
	$wBase->bind('<KeyPress-Left>', \&moveLeft);
	$wBase->bind('<KeyPress-Right>', \&moveRight);
	$wBase->bind('<KeyPress-Down>', \&moveDown);
	$wBase->bind('<KeyPress-space>', \&fallDown);
	clearBoard();
	# the following 4 lines are for testing
	${$board[1]}[7] = 1;
	${$board[1]}[1] = 1;
	$wGame->createRectangle(7*$TILE_SIZE, $TILE_SIZE, 8*$TILE_SIZE, 2*$TILE_SIZE, '-fill'=>'#FF0000');
	$wGame->createRectangle($TILE_SIZE, $TILE_SIZE, 2*$TILE_SIZE, 2*$TILE_SIZE, '-fill'=>'#FF0000');
	createTile();
	
	
	
	start();
}

init();

MainLoop();
