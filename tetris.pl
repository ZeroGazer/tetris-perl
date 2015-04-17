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

sub update{
	#my $newBlock = $wGame->createRectangle(0, 0, $TILE_SIZE, $TILE_SIZE, '-fill' => '#00FF00', '-tag' => 'block');
	print "\$gameover = $gameover\n";
	if (!$gameover){
		moveDown();
		$wBase->after($updateInterval, \&update);
	}
}

sub start {
	$wBase->after($updateInterval, \&update);
}

sub createScreen {
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

sub moveLeft{
	print "pressed left arrow\n";
}

sub moveRight{
	print "pressed right arrow\n";
}

sub moveDown{
	print "pressed down arrow\n";
	
	my $touchedGround = 0;
	# TODO : check touched ground or not
	
	if (!$touchedGround){
		foreach my $unit (@currentBlock){
			$wGame->move($unit, 0, $TILE_SIZE);
		}
	}
}

sub fallDown{
	print "pressed spacebar \n";
}

sub drawLines {
	for my $i (0 .. $MAX_ROWS){
		$wGame->createLine(0, $i*$TILE_SIZE, $MAX_COLS*$TILE_SIZE, $i*$TILE_SIZE, '-fill' => 'black');}
	for my $i (0 .. $MAX_COLS){
		$wGame->createLine($i*$TILE_SIZE, 0, $i*$TILE_SIZE, $MAX_ROWS*$TILE_SIZE, '-fill' => 'black');}
}

sub createTile{
    my $color   = $colors[int(rand (scalar (@colors)))];
    my $pattern = $patterns[int(rand (scalar(@patterns)))];
	for my $i (0..scalar(@$pattern)-1){
		my $line = @$pattern[$i];
		my @line = split (//, $line);
		my $xOffset = int(($MAX_COLS - length($line)) / 2);
		
		for my $j (0..scalar(@line)-1){
			my $char = @line[$j];
			if ($char eq "*"){
				my $unit = $wGame->createRectangle(($j+$xOffset)*$TILE_SIZE, $i*$TILE_SIZE, ($j+$xOffset+1)*$TILE_SIZE, ($i+1)*$TILE_SIZE, '-fill' => $color);
				push @currentBlock, $unit;
			}
		}
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
	createTile();
	
	
	start();
}

init();

MainLoop();
